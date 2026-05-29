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
  /// Audit 2026-05-26 C6: rowId is REQUIRED. A queued INSERT
  /// without a client-generated id can't be replayed
  /// idempotently — if the first attempt succeeded server-side
  /// but the response packet dropped, the retry would mint a
  /// second row. Every caller MUST pre-generate a UUID and
  /// embed it in the payload as 'id'; we cross-check at runtime
  /// that the payload contains that id.
  QueuedInsert({
    required this.table,
    required this.payload,
    required this.rowId,
  }) : assert(
         payload['id'] == rowId,
         'QueuedInsert: payload[\'id\'] must equal rowId so the '
         'replay UPSERT can conflict-resolve on the id column. '
         'Got payload[\'id\']=${payload['id']}, rowId=$rowId.',
       );
  final String table;
  final Map<String, dynamic> payload;

  /// Client-generated UUID for the row. Postgres' DEFAULT
  /// uuid_generate_v4() only fires when the column is omitted;
  /// passing an explicit id is accepted and is what makes the
  /// replay UPSERT idempotent across retries.
  final String rowId;
}

class QueuedUpdate extends QueuedOp {
  /// [expectedUpdatedAt] (audit 2026-05-26 H5) carries the
  /// optimistic-lock precondition from the online write path
  /// through to replay. Without it, a phone offline at 9am
  /// would queue an UPDATE; phone B updates the same row at
  /// 10am with different values; phone A reconnects at 11am
  /// and the queue replay clobbers B's edit silently. With it,
  /// the replay's .eq('updated_at', expectedUpdatedAt) misses
  /// (server's updated_at trigger refreshed it on B's write),
  /// the UPDATE matches zero rows, we surface it as a conflict
  /// instead of silently overwriting.
  ///
  /// Encoded as ISO-8601 UTC in the payload at enqueue time;
  /// passed to the replay's eq filter at drain time. Null
  /// means "no precondition" — caller explicitly opted out
  /// (e.g. a fresh create where last-write-wins is safe).
  const QueuedUpdate({
    required this.table,
    required this.rowId,
    required this.payload,
    this.expectedUpdatedAt,
  });
  final String table;
  final String rowId;
  final Map<String, dynamic> payload;
  final DateTime? expectedUpdatedAt;
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
///
/// `authExpired` is distinct from the failure pair because it
/// signals "stop draining — the rest of the queue would all hit
/// the same wall." The drain loop short-circuits on this and
/// the sign-out listener handles the downstream cleanup.
enum _ReplayOutcome { success, transientFailure, permanentFailure, authExpired }

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
      QueuedUpdate(
        :final table,
        :final rowId,
        :final payload,
        :final expectedUpdatedAt,
      ) =>
        PendingWritesCompanion(
          id: Value(id),
          opType: const Value('update'),
          targetTable: Value(table),
          rowId: Value(rowId),
          // Wrap the payload with the optional precondition so
          // the replay (a different process from enqueue) can
          // read both off one column. Schema-less envelope by
          // design — drift's payload_json is opaque text.
          payloadJson: Value(
            jsonEncode({
              'payload': payload,
              if (expectedUpdatedAt != null)
                'expected_updated_at': expectedUpdatedAt.toUtc()
                    .toIso8601String(),
            }),
          ),
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

  /// Audit 2026-05-26 H2: cap how many times drain attempts a
  /// row before it's parked. Without a cap, every connectivity
  /// flip retries every stuck row forever (RLS denial,
  /// permanent CHECK failure, etc.) with `attemptCount` growing
  /// unbounded. 10 is the magic number — small enough that a
  /// permanently-stuck row stops thrashing within ~10 reconnect
  /// cycles, large enough that genuine flaky-network sequences
  /// still drain on a later attempt.
  static const int _maxAttempts = 10;

  /// Replay every pending write in FIFO order. Concurrency-
  /// guarded: a second concurrent call returns immediately with
  /// `attempted=0`. Continues past per-row failures so one
  /// stuck write doesn't block independent ones.
  ///
  /// Rows whose attemptCount has hit [_maxAttempts] are SKIPPED
  /// — they stay in pending_writes for visibility (Settings
  /// → Sync shows the count) but no longer thrash the network.
  /// A future iteration moves them to a dead_letter table; for
  /// now the skip keeps the queue honest.
  Future<DrainResult> drain() async {
    if (_draining) {
      return const DrainResult(attempted: 0, succeeded: 0, failed: 0);
    }
    _draining = true;
    try {
      final rows = await db.loadPendingWrites();
      var succeeded = 0;
      var failed = 0;
      var attempted = 0;
      for (final row in rows) {
        // H2: skip rows past the max-attempts cap.
        if (row.attemptCount >= _maxAttempts) {
          failed++;
          continue;
        }
        attempted++;
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
            // Same as transient for now — row stays + counts
            // up. Hitting _maxAttempts parks it. Audit's call
            // for a dead-letter table + jittered backoff is a
            // separate follow-up.
            failed++;
          case _ReplayOutcome.authExpired:
            // Audit H3: stop draining immediately. The session
            // is gone; subsequent replays in this loop would
            // all hit the same wall AND the sign-out listener
            // will wipe the cache + queue. Return what we have
            // so the caller sees the partial result; the next
            // drain (after re-auth) starts fresh.
            return DrainResult(
              attempted: attempted,
              succeeded: succeeded,
              failed: failed + (rows.length - attempted),
            );
        }
      }
      return DrainResult(
        attempted: attempted,
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
                // Audit C6: explicit onConflict pinned to the id
                // column. QueuedInsert.assert guarantees the
                // payload carries `id`, so a half-completed first
                // attempt (server INSERTed, response dropped)
                // becomes a no-op on retry instead of minting a
                // duplicate row with a fresh server-generated id.
                onConflict: 'id',
                ignoreDuplicates: false,
              );
        case 'update':
          // Audit H5: unwrap the envelope ({payload, optional
          // expected_updated_at}) and apply the optimistic-lock
          // filter if present. Zero-rows-affected with a
          // precondition means a concurrent write beat ours —
          // mark the row failed so it stops thrashing and
          // surfaces as "conflict" in the queue.
          final decoded = jsonDecode(row.payloadJson) as Map<String, dynamic>;
          final updatePayload =
              decoded['payload'] as Map<String, dynamic>;
          final expectedUpdatedAt =
              decoded['expected_updated_at'] as String?;
          var updateBuilder = supabase
              .from(row.targetTable!)
              .update(updatePayload)
              .eq('id', row.rowId!);
          if (expectedUpdatedAt != null) {
            updateBuilder = updateBuilder.eq(
              'updated_at',
              expectedUpdatedAt,
            );
          }
          final affected = await updateBuilder.select('id') as List;
          if (expectedUpdatedAt != null && affected.isEmpty) {
            await db.markPendingWriteFailed(
              id: row.id,
              error:
                  'CONFLICT: row updated_at changed between enqueue '
                  'and replay (concurrent write from another device)',
            );
            // Treat as permanent so it counts up against
            // _maxAttempts and parks. A future iteration moves
            // these to a typed conflicts table per the audit.
            return _ReplayOutcome.permanentFailure;
          }
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
      if (_isAuthExpired(e)) return _ReplayOutcome.authExpired;
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

/// Audit 2026-05-26 H3: detect JWT-expired / unauthenticated
/// shapes so the drain can stop and let the sign-out flow take
/// over. Without this, an expired session reaches the
/// permanent-failure branch and the row sits in the queue
/// forever — `attemptCount` grows on every reconnect, but no
/// progress is possible until re-auth.
///
/// PGRST301 is PostgREST's "JWT expired"; AuthException is the
/// supabase_flutter shape. AuthApiException carries an HTTP
/// status — 401 is the auth-required signal.
bool _isAuthExpired(Object error) {
  if (error is AuthException) return true;
  if (error is PostgrestException) {
    if (error.code == 'PGRST301') return true;
  }
  // HTTP shapes that wrap into a generic exception sometimes
  // surface a 401 in the message. Best-effort match.
  final s = error.toString().toLowerCase();
  if (s.contains('401') && s.contains('unauthorized')) return true;
  if (s.contains('jwt expired')) return true;
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
