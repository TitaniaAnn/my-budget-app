// Drift round-trip tests for the pending_storage_uploads table
// added in L1 Phase 4b. In-memory SQLite; no Supabase, no file
// system. The drain dispatcher itself is integration-only (it
// needs the local Supabase stack + real files); these tests
// pin the persistence layer.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  PendingStorageUploadsCompanion sample({
    required String id,
    String localFilePath = '/tmp/uploads/r-1.jpg',
    String? thumbnailLocalPath,
    String targetBucket = 'receipts',
    String targetStoragePath = 'hh-1/r-1.jpg',
    String? targetThumbnailPath,
    String receiptMetadataJson = '{"id":"r-1","household_id":"hh-1"}',
    DateTime? createdAt,
  }) {
    return PendingStorageUploadsCompanion(
      id: Value(id),
      localFilePath: Value(localFilePath),
      thumbnailLocalPath: Value(thumbnailLocalPath),
      targetBucket: Value(targetBucket),
      targetStoragePath: Value(targetStoragePath),
      targetThumbnailPath: Value(targetThumbnailPath),
      receiptMetadataJson: Value(receiptMetadataJson),
      createdAt: Value(createdAt ?? DateTime.utc(2026, 5, 28, 12)),
    );
  }

  group('AppDatabase.enqueuePendingStorageUpload', () {
    test('persists a single row with the embedded fields', () async {
      await db.enqueuePendingStorageUpload(
        sample(
          id: 'r-1',
          thumbnailLocalPath: '/tmp/uploads/r-1_thumb.jpg',
          targetThumbnailPath: 'hh-1/r-1_thumb.jpg',
        ),
      );
      final rows = await db.loadPendingStorageUploads();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'r-1');
      expect(rows.single.thumbnailLocalPath, '/tmp/uploads/r-1_thumb.jpg');
      expect(rows.single.targetThumbnailPath, 'hh-1/r-1_thumb.jpg');
      expect(rows.single.contentType, 'image/jpeg');
      expect(rows.single.attemptCount, 0);
    });
  });

  group('AppDatabase.loadPendingStorageUploads', () {
    test('returns rows in created_at ASC (FIFO)', () async {
      await db.enqueuePendingStorageUpload(
        sample(id: 'first', createdAt: DateTime.utc(2026, 5, 28, 12)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await db.enqueuePendingStorageUpload(
        sample(id: 'second', createdAt: DateTime.utc(2026, 5, 28, 13)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await db.enqueuePendingStorageUpload(
        sample(id: 'third', createdAt: DateTime.utc(2026, 5, 28, 14)),
      );
      final rows = await db.loadPendingStorageUploads();
      expect(rows.map((r) => r.id), ['first', 'second', 'third']);
    });

    test('returns empty when nothing is queued', () async {
      expect(await db.loadPendingStorageUploads(), isEmpty);
    });
  });

  group('AppDatabase.markPendingStorageUploadFailed', () {
    test('bumps attemptCount + stores error', () async {
      await db.enqueuePendingStorageUpload(sample(id: 'r-1'));
      await db.markPendingStorageUploadFailed(
        id: 'r-1',
        error: 'network blip',
      );
      var row = (await db.loadPendingStorageUploads()).single;
      expect(row.attemptCount, 1);
      expect(row.lastError, 'network blip');

      await db.markPendingStorageUploadFailed(id: 'r-1', error: 'again');
      row = (await db.loadPendingStorageUploads()).single;
      expect(row.attemptCount, 2);
      expect(row.lastError, 'again');
    });
  });

  group('AppDatabase.deletePendingStorageUpload', () {
    test('removes one row by id, leaves others alone', () async {
      await db.enqueuePendingStorageUpload(sample(id: 'r-keep'));
      await db.enqueuePendingStorageUpload(sample(id: 'r-drop'));
      await db.deletePendingStorageUpload('r-drop');
      final rows = await db.loadPendingStorageUploads();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'r-keep');
    });
  });

  group('AppDatabase.pendingStorageUploadsCount', () {
    test('returns the row count', () async {
      expect(await db.pendingStorageUploadsCount(), 0);
      await db.enqueuePendingStorageUpload(sample(id: 'r-a'));
      await db.enqueuePendingStorageUpload(sample(id: 'r-b'));
      expect(await db.pendingStorageUploadsCount(), 2);
    });
  });
}
