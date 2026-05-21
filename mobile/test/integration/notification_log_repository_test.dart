// Integration tests for NotificationLogRepository (migration 039).
//
// The shared notification_log table is the dedup ledger between the
// in-app engine and the server-side dispatcher. Atomic
// claim-by-key is the critical contract — the in-app pass and the
// Edge Function race on the same dedup_key and only one of them can
// fire. Pinned here:
//
//   * claimKeys with a fresh key returns the key (we won the race);
//   * claimKeys with a key already in the log returns nothing
//     (someone else got there first);
//   * mixed claim — some new, some existing — returns ONLY the new
//     ones, so the caller knows exactly what to surface;
//   * recentKeys honours the `since` cutoff so a long-running
//     install doesn't drown its evaluator in ancient dedup keys;
//   * RLS scopes everything to the current household — a row from
//     another household is invisible.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/notifications/repositories/notification_log_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('NotificationLogRepository (integration)', () {
    late Harness harness;
    late NotificationLogRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'notif-log');
      repo = NotificationLogRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    setUp(() async {
      if (reason != null) return;
      await harness.client
          .from('notification_log')
          .delete()
          .eq('household_id', harness.householdId);
    });

    test('claimKeys returns every fresh key on first call', () async {
      final claimed = await repo.claimKeys(
        householdId: harness.householdId,
        keys: ['budget_over:b1:2026-05-01', 'large_tx:t1'],
      );
      expect(
        claimed,
        {'budget_over:b1:2026-05-01', 'large_tx:t1'},
        reason:
            'a fresh key has no prior row; the INSERT lands and the '
            'caller is responsible for displaying the notification.',
      );
    }, skip: reason);

    test('claimKeys returns empty for a key already in the log', () async {
      await repo.claimKeys(
        householdId: harness.householdId,
        keys: ['budget_over:b1:2026-05-01'],
      );
      // Second claimer for the same key — must lose the race.
      final secondAttempt = await repo.claimKeys(
        householdId: harness.householdId,
        keys: ['budget_over:b1:2026-05-01'],
      );
      expect(
        secondAttempt,
        isEmpty,
        reason:
            'ON CONFLICT DO NOTHING — the second claimer sees zero '
            'returned rows and must skip the alert. Otherwise the user '
            'gets the same notification twice.',
      );
    }, skip: reason);

    test('claimKeys returns only the NEW keys in a mixed batch', () async {
      await repo.claimKeys(
        householdId: harness.householdId,
        keys: ['budget_over:b1:2026-05-01'],
      );
      final claimed = await repo.claimKeys(
        householdId: harness.householdId,
        keys: [
          'budget_over:b1:2026-05-01', // already in log
          'large_tx:t1', // fresh
          'budget_over:b2:2026-05-01', // fresh
        ],
      );
      expect(
        claimed,
        {'large_tx:t1', 'budget_over:b2:2026-05-01'},
        reason:
            'the partial-batch case is the real-world one — most '
            'passes have some keys the other side already saw and some '
            'genuinely new ones. Only the new keys fire.',
      );
    }, skip: reason);

    test('recentKeys filters by the since cutoff', () async {
      // Insert one stale row + two recent rows directly so we can
      // pin the timestamp filter. The repo's claimKeys path always
      // uses now() so we can't drive the stale case through it.
      final stale = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 100))
          .toIso8601String();
      await harness.client.from('notification_log').insert([
        {
          'household_id': harness.householdId,
          'dedup_key': 'old',
          'fired_at': stale,
          'source': 'client',
        },
      ]);
      await repo.claimKeys(
        householdId: harness.householdId,
        keys: ['new1', 'new2'],
      );

      final recent = await repo.recentKeys(
        householdId: harness.householdId,
        since: DateTime.now().toUtc().subtract(const Duration(days: 90)),
      );
      expect(
        recent,
        {'new1', 'new2'},
        reason:
            "rows older than the lookback window MUST drop out — "
            "otherwise a stale alert from months ago would keep "
            "blocking re-fires forever.",
      );
    }, skip: reason);

    test('recentKeys returns empty for an unseen household', () async {
      // Sanity check the RLS scope: a freshly minted UUID we don't
      // belong to has no visible rows.
      final foreign = await repo.recentKeys(
        householdId: '00000000-0000-0000-0000-000000000000',
        since: DateTime.now().toUtc().subtract(const Duration(days: 90)),
      );
      expect(foreign, isEmpty);
    }, skip: reason);

    test('pruneOlderThan deletes rows past the retention window', () async {
      // Insert one stale row + two fresh rows. After prune at 90
      // days only the fresh ones survive.
      final stale = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 100))
          .toIso8601String();
      await harness.client.from('notification_log').insert([
        {
          'household_id': harness.householdId,
          'dedup_key': 'stale',
          'fired_at': stale,
          'source': 'server',
        },
      ]);
      await repo.claimKeys(
        householdId: harness.householdId,
        keys: ['fresh1', 'fresh2'],
      );

      final deleted = await repo.pruneOlderThan(
        householdId: harness.householdId,
      );
      expect(
        deleted,
        1,
        reason:
            'exactly one row crossed the 90-day cutoff; the prune '
            'function must report it.',
      );

      // The two fresh rows must survive — pruning is strictly by age.
      final remaining = await repo.recentKeys(
        householdId: harness.householdId,
        since: DateTime.now().toUtc().subtract(const Duration(days: 365)),
      );
      expect(remaining, {'fresh1', 'fresh2'});
    }, skip: reason);

    test(
      'pruneOlderThan with a short retention drops everything past it',
      () async {
        await repo.claimKeys(
          householdId: harness.householdId,
          keys: ['a', 'b', 'c'],
        );

        // Pretend the retention is 0 days — everything is "older
        // than the cutoff" except rows fired at exactly now(), which
        // postgres's `<` strictness should treat as not-yet-expired.
        // Use 1 day so we don't race against millisecond timing.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final deleted = await repo.pruneOlderThan(
          householdId: harness.householdId,
          retention: Duration.zero,
        );
        // All three rows fired ~now, so a 0-day retention puts the
        // cutoff at "now" — STRICT less-than means rows at exactly
        // now() survive, but our 50ms delay above made them
        // fractionally older than the new cutoff.
        expect(deleted, 3);
      },
      skip: reason,
    );
  });
}
