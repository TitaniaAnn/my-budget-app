// Data access for the shared notification dedup log (migrations 039
// + 046).
//
// Two writers fire into this table: the in-app engine here, and the
// server-side dispatcher (Edge Function `send-notification`). The PK
// is `(household_id, dedup_key, user_id)` so the first writer to
// claim a key for a GIVEN user wins — the second's INSERT no-ops via
// ON CONFLICT and the engine on that side skips the alert. The
// result is "this user sees this kind of event at most once"
// regardless of which path detected it.
//
// Per-user dedup (migration 046) means member A claiming a key
// doesn't affect member B — they each get their own row keyed by
// their own user_id. Before that change any household member could
// silence anyone else's alerts by pre-claiming the dedup key.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';

part 'notification_log_repository.g.dart';

@riverpod
NotificationLogRepository notificationLogRepository(
  NotificationLogRepositoryRef ref,
) {
  return NotificationLogRepository();
}

/// The "broadcast / legacy" user_id used for rows that predate the
/// migration 046 per-user dedup keying. New writes carry a real
/// user_id; this sentinel only matches existing backfilled rows and
/// any server path that hasn't been retrofitted yet.
const String _sentinelUserId = '00000000-0000-0000-0000-000000000000';

class NotificationLogRepository {
  /// Reads dedup keys fired FOR THIS USER in the household since
  /// [since]. Used by the in-app runner to merge server-side fires
  /// into its own `lastFiredByKey` map before evaluating — without
  /// this merge an online user could see the same alert via push
  /// AND via the in-app surface.
  ///
  /// Scoped to [userId] because migration 046 makes dedup per-user:
  /// another member's claim doesn't suppress this user's evaluation.
  /// The server's broadcast / legacy claims (rows with the sentinel
  /// zero-UUID user_id) are also merged in — those rows represent
  /// "everyone in the household already saw this", which is the
  /// pre-046 contract still preserved for backfilled rows.
  Future<Set<String>> recentKeys({
    required String householdId,
    required String userId,
    required DateTime since,
  }) async {
    final data = await supabase
        .from('notification_log')
        .select('dedup_key')
        .eq('household_id', householdId)
        .inFilter('user_id', [userId, _sentinelUserId])
        .gte('fired_at', since.toUtc().toIso8601String());
    return {for (final row in data) row['dedup_key'] as String};
  }

  /// Removes every notification_log row for the household. Used by
  /// the "Reset notification history" affordance in Settings — the
  /// caller is expected to also clear the in-app lastFiredByKey
  /// SharedPreferences map, otherwise the merge step in the runner
  /// will repopulate the dedup map from scratch on the next pass
  /// anyway. Returning void: a deletion of 0 rows is a valid no-op
  /// (already-empty household), not a failure.
  Future<void> clearAll({required String householdId}) async {
    await supabase
        .from('notification_log')
        .delete()
        .eq('household_id', householdId);
  }

  /// Deletes log rows older than [retention] for the current
  /// household. Mirrors the in-app `lastFiredByKey` 90-day cap so
  /// the dedup table can't grow unbounded. Returns the number of
  /// rows deleted — fire-and-forget callers can ignore it.
  Future<int> pruneOlderThan({
    required String householdId,
    Duration retention = const Duration(days: 90),
  }) async {
    final res = await supabase.rpc(
      'prune_notification_log',
      params: {
        'p_household_id': householdId,
        'p_retention_days': retention.inDays,
      },
    );
    return (res as int?) ?? 0;
  }

  /// Atomically claims [keys] for [userId] in [householdId]. The
  /// set of keys the caller actually inserted comes back — anything
  /// missing was already in this user's log (the server pushed to
  /// THIS user first, or a previous in-app pass) and should NOT be
  /// displayed by this caller.
  ///
  /// [userId] must be the caller's own `auth.uid()`; RLS rejects
  /// anything else. Per-user dedup means another household member's
  /// claim on the same key doesn't suppress this user's row.
  Future<Set<String>> claimKeys({
    required String householdId,
    required String userId,
    required Iterable<String> keys,
  }) async {
    final list = keys.toList();
    if (list.isEmpty) return const {};
    final rows = [
      for (final k in list)
        {
          'household_id': householdId,
          'dedup_key': k,
          'user_id': userId,
          'source': 'client',
        },
    ];
    // ignoreDuplicates: true → ON CONFLICT (household_id, dedup_key,
    // user_id) DO NOTHING. The returned rows are only the new
    // inserts; the ones already in this user's log come back empty.
    final inserted = await supabase
        .from('notification_log')
        .upsert(
          rows,
          onConflict: 'household_id,dedup_key,user_id',
          ignoreDuplicates: true,
        )
        .select('dedup_key');
    return {for (final row in inserted) row['dedup_key'] as String};
  }
}
