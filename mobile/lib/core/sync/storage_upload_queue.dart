// Offline storage upload queue + drain. Audit L1 Phase 4b.
//
// Receipt image bytes are too large for the pending_writes
// queue's payload_json column (typically 500KB-1.5MB). When
// ReceiptsRepository.uploadReceipt hits a transient failure
// during the storage upload OR the receipts INSERT, this queue:
//   1. Persists the image bytes to <docs>/pending_uploads/<id>.jpg
//      (plus a thumbnail copy if generation succeeded).
//   2. Inserts a row into pending_storage_uploads carrying the
//      target bucket / paths + the receipt INSERT payload as
//      JSON.
//   3. The drain loop reads each row in FIFO order and replays:
//        a. Upload full-res bytes to Supabase Storage.
//        b. Upload thumbnail bytes (if present).
//        c. INSERT the receipts row.
//        d. Delete local files + the queue row.
//      A partial failure (e.g. step b) keeps the row + bumps
//      attemptCount; the next pass picks up where it left off
//      (every step is idempotent — Storage upload on a path
//      that already exists overwrites; the INSERT carries the
//      client-generated id so a half-completed prior attempt
//      becomes a no-op via upsert on conflict).
//
// What this is NOT:
//   * A UI layer. ReceiptsRepository's caller still sees a
//     successful Receipt on enqueue (an optimistic one with the
//     local file path so the UI can render); the Settings →
//     Sync surface (Phase 5c) shows the queue depth.
//   * A retry policy. Same _maxAttempts cap as the
//     pending_writes queue (10 attempts then park).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderSubscription;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../connectivity/connectivity_provider.dart';
import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../supabase/supabase_client.dart';
import 'transient_error.dart';

part 'storage_upload_queue.g.dart';

/// Aggregate result of a drain pass.
class StorageDrainResult {
  const StorageDrainResult({
    required this.attempted,
    required this.succeeded,
    required this.failed,
  });
  final int attempted;
  final int succeeded;
  final int failed;
}

/// Per-row replay outcome — internal classifier.
enum _StorageOutcome { success, transient, permanent }

@Riverpod(keepAlive: true)
StorageUploadQueue storageUploadQueue(StorageUploadQueueRef ref) {
  return StorageUploadQueue(db: ref.watch(appDatabaseProvider));
}

class StorageUploadQueue {
  StorageUploadQueue({required this.db});
  final AppDatabase db;
  final _uuid = const Uuid();
  bool _draining = false;

  static const _maxAttempts = 10;

  /// Persist full-res [imageBytes] (+ optional [thumbnailBytes])
  /// to disk and enqueue a row. Returns the queue row id
  /// (= the client-generated receipt id; embedded in
  /// receiptMetadataJson so the eventual INSERT is idempotent).
  ///
  /// The caller — ReceiptsRepository.uploadReceipt's catch
  /// branch — gets this id back and can render an optimistic
  /// Receipt that points at the local file until the drain
  /// succeeds and the next fetch picks up the canonical row.
  Future<String> enqueue({
    required String receiptId,
    required List<int> imageBytes,
    List<int>? thumbnailBytes,
    required String householdId,
    required String targetBucket,
    required String targetStoragePath,
    String? targetThumbnailPath,
    required Map<String, dynamic> receiptMetadata,
  }) async {
    final dir = await _pendingDir();
    final imagePath = p.join(dir.path, '$receiptId.jpg');
    await File(imagePath).writeAsBytes(imageBytes, flush: true);
    String? thumbnailPath;
    if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
      thumbnailPath = p.join(dir.path, '${receiptId}_thumb.jpg');
      await File(thumbnailPath).writeAsBytes(thumbnailBytes, flush: true);
    }
    final now = DateTime.now().toUtc();
    await db.enqueuePendingStorageUpload(
      PendingStorageUploadsCompanion(
        id: Value(receiptId),
        localFilePath: Value(imagePath),
        thumbnailLocalPath: Value(thumbnailPath),
        targetBucket: Value(targetBucket),
        targetStoragePath: Value(targetStoragePath),
        targetThumbnailPath: Value(targetThumbnailPath),
        receiptMetadataJson: Value(jsonEncode(receiptMetadata)),
        createdAt: Value(now),
      ),
    );
    return receiptId;
  }

  /// Replay every pending storage upload in FIFO order. Same
  /// concurrency guard + max-attempts shape as
  /// PendingWritesQueue.drain.
  Future<StorageDrainResult> drain() async {
    if (_draining) {
      return const StorageDrainResult(
        attempted: 0,
        succeeded: 0,
        failed: 0,
      );
    }
    _draining = true;
    try {
      final rows = await db.loadPendingStorageUploads();
      var succeeded = 0;
      var failed = 0;
      var attempted = 0;
      for (final row in rows) {
        if (row.attemptCount >= _maxAttempts) {
          failed++;
          continue;
        }
        attempted++;
        final outcome = await _replayOne(row);
        switch (outcome) {
          case _StorageOutcome.success:
            await _cleanup(row);
            await db.deletePendingStorageUpload(row.id);
            succeeded++;
          case _StorageOutcome.transient:
            failed++;
          case _StorageOutcome.permanent:
            failed++;
        }
      }
      return StorageDrainResult(
        attempted: attempted,
        succeeded: succeeded,
        failed: failed,
      );
    } finally {
      _draining = false;
    }
  }

  Future<int> pendingCount() => db.pendingStorageUploadsCount();

  Future<_StorageOutcome> _replayOne(PendingStorageUploadsRow row) async {
    try {
      // Step 1: upload full-res bytes. uploadBinary overwrites
      // on path collision (idempotent across retries).
      final file = File(row.localFilePath);
      if (!await file.exists()) {
        // Local file vanished between enqueue and replay — best
        // effort: skip the upload, attempt the INSERT anyway
        // (the storage_path will resolve to a 404 image but the
        // row exists so the user can re-attach).
        await db.markPendingStorageUploadFailed(
          id: row.id,
          error: 'local file missing: ${row.localFilePath}',
        );
        return _StorageOutcome.permanent;
      }
      await supabase.storage
          .from(row.targetBucket)
          .uploadBinary(
            row.targetStoragePath,
            await file.readAsBytes(),
            fileOptions: FileOptions(
              contentType: row.contentType,
              upsert: true,
            ),
          );

      // Step 2: thumbnail (optional).
      final thumbLocal = row.thumbnailLocalPath;
      final thumbTarget = row.targetThumbnailPath;
      if (thumbLocal != null && thumbTarget != null) {
        final thumbFile = File(thumbLocal);
        if (await thumbFile.exists()) {
          await supabase.storage
              .from(row.targetBucket)
              .uploadBinary(
                thumbTarget,
                await thumbFile.readAsBytes(),
                fileOptions: FileOptions(
                  contentType: row.contentType,
                  upsert: true,
                ),
              );
        }
      }

      // Step 3: INSERT receipts row with the embedded id so the
      // upsert is idempotent across retries.
      final metadata =
          jsonDecode(row.receiptMetadataJson) as Map<String, dynamic>;
      // Always pin the id in the payload — defensive against an
      // older enqueue that pre-dated this invariant.
      metadata['id'] ??= row.id;
      await supabase
          .from('receipts')
          .upsert(metadata, onConflict: 'id', ignoreDuplicates: false);

      return _StorageOutcome.success;
    } catch (e) {
      await db.markPendingStorageUploadFailed(id: row.id, error: e.toString());
      return isTransientWriteError(e)
          ? _StorageOutcome.transient
          : _StorageOutcome.permanent;
    }
  }

  Future<void> _cleanup(PendingStorageUploadsRow row) async {
    try {
      final file = File(row.localFilePath);
      if (await file.exists()) await file.delete();
    } catch (_) {/**/}
    final thumb = row.thumbnailLocalPath;
    if (thumb != null) {
      try {
        final thumbFile = File(thumb);
        if (await thumbFile.exists()) await thumbFile.delete();
      } catch (_) {/**/}
    }
  }

  Future<Directory> _pendingDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'pending_uploads'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Test-only seam for callers that want to pre-generate a
  /// row id (e.g. so the optimistic Receipt model carries the
  /// same id as the eventual server row).
  String generateReceiptId() => _uuid.v4();
}

/// Side-effect provider: drains the storage queue on the
/// false→true connectivity edge. keepAlive so the listener
/// subscription is process-lifetime. Same pattern as
/// PendingWritesAutoDrain.
@Riverpod(keepAlive: true)
class StorageUploadAutoDrain extends _$StorageUploadAutoDrain {
  ProviderSubscription<bool>? _sub;

  @override
  void build() {
    _sub = ref.listen<bool>(
      isOnlineProvider,
      (prev, next) {
        if (prev == false && next == true) {
          // ignore: unawaited_futures
          ref.read(storageUploadQueueProvider).drain();
        }
      },
    );
    ref.onDispose(() => _sub?.close());
  }
}
