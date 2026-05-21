// Data access for the shared notification dedup log (migration 039).
//
// Two writers fire into this table: the in-app engine here, and the
// server-side dispatcher (Edge Function `send-notification`). The PK
// is `(household_id, dedup_key)` so the first writer to claim a key
// wins — the second's INSERT no-ops via ON CONFLICT and the engine
// on that side skips the alert. The result is "user sees this kind
// of event at most once" regardless of which path detected it.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';

part 'notification_log_repository.g.dart';

@riverpod
NotificationLogRepository notificationLogRepository(
  NotificationLogRepositoryRef ref,
) {
  return NotificationLogRepository();
}

class NotificationLogRepository {
  /// Reads dedup keys fired in the household since [since]. Used by
  /// the in-app runner to merge server-side fires into its own
  /// `lastFiredByKey` map before evaluating — without this merge an
  /// online user could see the same alert via push AND via the
  /// in-app surface.
  Future<Set<String>> recentKeys({
    required String householdId,
    required DateTime since,
  }) async {
    final data = await supabase
        .from('notification_log')
        .select('dedup_key')
        .eq('household_id', householdId)
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

  /// Atomically claims [keys] for [householdId]. The set of keys
  /// the caller actually inserted comes back — anything missing was
  /// already in the log (server fired it first, or a previous in-app
  /// pass) and should NOT be displayed by this caller.
  ///
  /// Used so the in-app side and the server agree on a single
  /// notification per logical event.
  Future<Set<String>> claimKeys({
    required String householdId,
    required Iterable<String> keys,
  }) async {
    final list = keys.toList();
    if (list.isEmpty) return const {};
    final rows = [
      for (final k in list)
        {'household_id': householdId, 'dedup_key': k, 'source': 'client'},
    ];
    // ignoreDuplicates: true → ON CONFLICT (household_id, dedup_key)
    // DO NOTHING. The returned rows are only the new inserts; the
    // ones already in the log come back empty.
    final inserted = await supabase
        .from('notification_log')
        .upsert(
          rows,
          onConflict: 'household_id,dedup_key',
          ignoreDuplicates: true,
        )
        .select('dedup_key');
    return {for (final row in inserted) row['dedup_key'] as String};
  }
}
