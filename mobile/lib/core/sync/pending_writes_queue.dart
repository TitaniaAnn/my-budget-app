// Offline write queue + replay-on-reconnect. Audit L1 Phase 3a.
//
// Every mutating repository method that hits a transient failure
// (or sees the device known-offline) hands the payload off to
// this queue instead of throwing. The drain loop replays the
// queue in FIFO order against Supabase whenever connectivity
// returns.
//
// What this is:
//   * A Dart wrapper over the drift `pending_writes` table. The
//     table is the persistence; this class is the API.
//   * A dispatcher that knows how to translate (op_type, target,
//     payload) into a Supabase call.
//   * The replay loop's concurrency guard — at most one drain
//     in flight at a time.
//
// What this is NOT:
//   * Conflict resolution. The server is the source of truth;
//     if a replay UPDATE collides with another device's write,
//     last-write-wins (audit H7). The pending_writes row stays
//     until the replay succeeds — a permanent conflict would
//     have a non-transient error and surface in telemetry.
//   * Storage uploads. Receipt image bytes are too large to
//     cram into the payload column; the storage-upload queue
//     (Phase 4b) handles that case with its own surface.
//
// Caller contract (per-mutation):
//   1. Optimistically write to the appropriate cache table.
//   2. Try the network call (existing cache-through pattern).
//   3. On transient failure, enqueue the write here.
//   4. The drain loop replays on the next connectivity rise.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderSubscription;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../connectivity/connectivity_provider.dart';
import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../supabase/supabase_client.dart';

part 'pending_writes_queue.g.dart';

/// One logical mutation queued for later replay.
sealed class QueuedOp {
  const QueuedOp();
}

class QueuedInsert extends QueuedOp {
  const QueuedInsert({
    required this.table,
    required this.payload,
    this.rowId,
  });
  final String table;
  final Map<String, dynamic> payload;

  /// Client-generated UUID for the row, if the caller pre-
  /// assigned one. Null when the server is expected to mint the
  /// id (replay still works but the cache row may have a
  /// different id than the server eventually picks).
  final String? rowId;
}

class QueuedUpdate extends QueuedOp {
  const QueuedUpdate({
    required this.table,
    required this.rowId,
    required this.payload,
  });
  final String table;
  final String rowId;
  final Map<String, dynamic> payload;
}

class QueuedDelete extends QueuedOp {
  const QueuedDelete({required this.table, required this.rowId});
  final String table;
  final String rowId;
}

class QueuedRpc extends QueuedOp {
  const QueuedRpc({required this.rpcName, required this.params});
  final String rpcName;
  final Map<String, dynamic> params;
}

/// Outcome of a single replay attempt.
enum _ReplayOutcome { success, transientFailure, permanentFailure }

/// Aggregate result of a drain pass.
class DrainResult {
  const DrainResult({
    required this.attempted,
    required this.succeeded,
    required this.failed,
  });
  final int attempted;
  final int succeeded;
  final int failed;
}

/// Singleton-ish (per ProviderScope) queue exposed via Riverpod.
@Riverpod(keepAlive: true)
PendingWritesQueue pendingWritesQueue(PendingWritesQueueRef ref) {
  return PendingWritesQueue(db: ref.watch(appDatabaseProvider));
}

class PendingWritesQueue {
  PendingWritesQueue({required this.db});
  final AppDatabase db;
  final _uuid = const Uuid();

  /// Guard so two concurrent drains don't double-execute the
  /// same row. Single-instance: connectivity flip + lifecycle
  /// resume + manual trigger could all fire at the same moment.
  bool _draining = false;

  /// Add an op to the queue. Returns the queue row id (for
  /// telemetry / future cancel surfaces).
  Future<String> enqueue(QueuedOp op) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final companion = switch (op) {
      QueuedInsert(:final table, :final payload, :final rowId) =>
        PendingWritesCompanion(
          id: Value(id),
          opType: const Value('insert'),
          targetTable: Value(table),
          rowId: Value(rowId),
          payloadJson: Value(jsonEncode(payload)),
          createdAt: Value(now),
        ),
      QueuedUpdate(:final table, :final rowId, :final payload) =>
        PendingWritesCompanion(
          id: Value(id),
          opType: const Value('update'),
          targetTable: Value(table),
          rowId: Value(rowId),
          payloadJson: Value(jsonEncode(payload)),
          createdAt: Value(now),
        ),
      QueuedDelete(:final table, :final rowId) => PendingWritesCompanion(
        id: Value(id),
        opType: const Value('delete'),
        targetTable: Value(table),
        rowId: Value(rowId),
        payloadJson: const Value('{}'),
        createdAt: Value(now),
      ),
      QueuedRpc(:final rpcName, :final params) => PendingWritesCompanion(
        id: Value(id),
        opType: const Value('rpc'),
        rpcName: Value(rpcName),
        payloadJson: Value(jsonEncode(params)),
        createdAt: Value(now),
      ),
    };
    await db.enqueuePendingWrite(companion);
    return id;
  }

  /// Replay every pending write in FIFO order. Concurrency-
  /// guarded: a second concurrent call returns immediately with
  /// `attempted=0`. Continues past per-row failures so one
  /// stuck write doesn't block independent ones.
  Future<DrainResult> drain() async {
    if (_draining) {
      return const DrainResult(attempted: 0, succeeded: 0, failed: 0);
    }
    _draining = true;
    try {
      final rows = await db.loadPendingWrites();
      var succeeded = 0;
      var failed = 0;
      for (final row in rows) {
        final outcome = await _replayOne(row);
        switch (outcome) {
          case _ReplayOutcome.success:
            await db.deletePendingWrite(row.id);
            succeeded++;
          case _ReplayOutcome.transientFailure:
            // Row stays; drain may retry on next flip. attemptCount
            // already bumped + error recorded.
            failed++;
          case _ReplayOutcome.permanentFailure:
            // For now treat the same as transient — the row
            // stays in the queue and surfaces in the Settings
            // sync status. A future iteration could move
            // permanent failures into a dead-letter table.
            failed++;
        }
      }
      return DrainResult(
        attempted: rows.length,
        succeeded: succeeded,
        failed: failed,
      );
    } finally {
      _draining = false;
    }
  }

  Future<_ReplayOutcome> _replayOne(PendingWritesRow row) async {
    try {
      switch (row.opType) {
        case 'insert':
          await supabase
              .from(row.targetTable!)
              .upsert(
                jsonDecode(row.payloadJson) as Map<String, dynamic>,
                // If the row has a primary key column in the
                // payload (e.g. our client-generated UUID), upsert
                // makes the replay idempotent: a retry after a
                // half-failed first attempt either becomes a no-op
                // (row already exists) or fills in what's missing.
                ignoreDuplicates: false,
              );
        case 'update':
          await supabase
              .from(row.targetTable!)
              .update(jsonDecode(row.payloadJson) as Map<String, dynamic>)
              .eq('id', row.rowId!);
        case 'delete':
          await supabase
              .from(row.targetTable!)
              .delete()
              .eq('id', row.rowId!);
        case 'rpc':
          await supabase.rpc(
            row.rpcName!,
            params: jsonDecode(row.payloadJson) as Map<String, dynamic>,
          );
        default:
          // Unknown op_type — keep the row, mark failed. A future
          // version of the app may know how to handle it; a
          // typo on the way in shouldn't lose the user's intent.
          await db.markPendingWriteFailed(
            id: row.id,
            error: 'unknown opType: ${row.opType}',
          );
          return _ReplayOutcome.permanentFailure;
      }
      return _ReplayOutcome.success;
    } catch (e) {
      await db.markPendingWriteFailed(id: row.id, error: e.toString());
      return _isTransient(e)
          ? _ReplayOutcome.transientFailure
          : _ReplayOutcome.permanentFailure;
    }
  }

  /// Current queue depth. Used by the Settings sync indicator.
  Future<int> pendingCount() => db.pendingWritesCount();
}

/// Mirror of [retry.dart]'s transient-error classifier. Kept in
/// sync with that file — a write-side error class that's "worth
/// retrying" matches a read-side one. Auth/RLS/CHECK violations
/// stay non-transient so they don't sit in the queue forever
/// blocking the user.
bool _isTransient(Object error) {
  if (error is SocketException || error is TimeoutException) return true;
  final type = error.runtimeType.toString();
  if (type == 'ClientException') return true;
  if (error is PostgrestException) {
    final code = error.code;
    if (code != null && code.startsWith('PGRST5')) return true;
  }
  return false;
}

/// Side-effect provider: drains the queue whenever connectivity
/// flips false→true. keepAlive because the listener subscription
/// is process-lifetime.
///
/// Wiring lives here rather than in main.dart so the listener
/// and the queue stay co-located — future maintainers see the
/// trigger and the action together.
@Riverpod(keepAlive: true)
class PendingWritesAutoDrain extends _$PendingWritesAutoDrain {
  ProviderSubscription<bool>? _sub;

  @override
  void build() {
    _sub = ref.listen<bool>(
      isOnlineProvider,
      (prev, next) {
        if (prev == false && next == true) {
          // Don't await — autodrain is fire-and-forget. The
          // result surfaces in pendingCount() for the UI to poll.
          // ignore: discarded_futures
          ref.read(pendingWritesQueueProvider).drain();
        }
      },
    );
    ref.onDispose(() => _sub?.close());
  }
}
