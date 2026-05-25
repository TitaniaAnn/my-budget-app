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
        userId: harness.userId,
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
        userId: harness.userId,
        keys: ['budget_over:b1:2026-05-01'],
      );
      // Second claimer for the same (household, key, user) — must
      // lose the race.
      final secondAttempt = await repo.claimKeys(
        householdId: harness.householdId,
        userId: harness.userId,
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
        userId: harness.userId,
        keys: ['budget_over:b1:2026-05-01'],
      );
      final claimed = await repo.claimKeys(
        householdId: harness.householdId,
        userId: harness.userId,
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
          'user_id': harness.userId,
          'fired_at': stale,
          'source': 'client',
        },
      ]);
      await repo.claimKeys(
        householdId: harness.householdId,
        userId: harness.userId,
        keys: ['new1', 'new2'],
      );

      final recent = await repo.recentKeys(
        householdId: harness.householdId,
        userId: harness.userId,
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
        userId: harness.userId,
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
          'user_id': harness.userId,
          'fired_at': stale,
          'source': 'server',
        },
      ]);
      await repo.claimKeys(
        householdId: harness.householdId,
        userId: harness.userId,
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
        userId: harness.userId,
        since: DateTime.now().toUtc().subtract(const Duration(days: 365)),
      );
      expect(remaining, {'fresh1', 'fresh2'});
    }, skip: reason);

    test('clearAll wipes every row for the household', () async {
      await repo.claimKeys(
        householdId: harness.householdId,
        userId: harness.userId,
        keys: ['k1', 'k2', 'k3'],
      );

      await repo.clearAll(householdId: harness.householdId);

      final remaining = await repo.recentKeys(
        householdId: harness.householdId,
        userId: harness.userId,
        since: DateTime.now().toUtc().subtract(const Duration(days: 365)),
      );
      expect(
        remaining,
        isEmpty,
        reason:
            'Reset notification history must clear every dedup row '
            'so previously-fired alerts can fire again.',
      );

      // And after a clear, the same keys can be re-claimed (proves
      // the rows really left, not just stale-flagged).
      final reclaimed = await repo.claimKeys(
        householdId: harness.householdId,
        userId: harness.userId,
        keys: ['k1', 'k2', 'k3'],
      );
      expect(reclaimed, {'k1', 'k2', 'k3'});
    }, skip: reason);

    test(
      'pruneOlderThan with a short retention drops everything past it',
      () async {
        await repo.claimKeys(
          householdId: harness.householdId,
          userId: harness.userId,
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

    // ── H4 (migration 046): per-user dedup ────────────────────────────
    test(
      'per-user dedup: member A claiming a key does NOT silence member B',
      () async {
        // Pre-046 the PK was (household_id, dedup_key) — any member
        // could pre-claim ANY key in the household, including ones
        // namespaced after another member's budget alerts. With the
        // user_id added to the PK, A and B each occupy their own
        // dedup namespace.
        //
        // Setup: invite a second user into A's household via
        // household_members, then sign in as B and confirm B can
        // claim the exact same key A already claimed.

        await repo.claimKeys(
          householdId: harness.householdId,
          userId: harness.userId,
          keys: ['budget_over:dining:2026-05-01'],
        );

        // Bootstrap a second user. Their bootstrap signs them in;
        // then directly insert them into A's household_members so
        // their JWT can claim under the SAME household_id.
        final other = await Harness.bootstrap(testTag: 'notif-log-multi');
        // Use service-role-equivalent path: do the member-add as the
        // original owner who has owner permission on the household.
        await harness.client.auth.signInWithPassword(
          email: harness.email,
          password: Harness.testPassword,
        );
        await harness.client.from('household_members').insert({
          'household_id': harness.householdId,
          'user_id': other.userId,
          'role': 'partner',
          'display_name': 'B',
        });

        // Sign back in as the new member.
        await harness.client.auth.signInWithPassword(
          email: other.email,
          password: Harness.testPassword,
        );

        try {
          final claimedByOther = await repo.claimKeys(
            householdId: harness.householdId,
            userId: other.userId,
            keys: ['budget_over:dining:2026-05-01'],
          );
          expect(
            claimedByOther,
            {'budget_over:dining:2026-05-01'},
            reason:
                'member B must be able to claim a key member A already '
                'claimed — per-user dedup means their (household, key, '
                'user_id) tuple is distinct.',
          );
        } finally {
          // Restore A's session for any tearDown that follows.
          await harness.client.auth.signInWithPassword(
            email: harness.email,
            password: Harness.testPassword,
          );
          await other.dispose();
        }
      },
      skip: reason,
    );

    test('RLS rejects a write with user_id != auth.uid()', () async {
      // Defense in depth: even if a malicious client crafted a
      // payload setting user_id to another member's id (to
      // silence them), the INSERT policy added in migration 046
      // rejects it.
      final other = await Harness.bootstrap(testTag: 'notif-log-rls');
      final otherUserId = other.userId;
      // Sign back in as A; try to claim under B's user_id.
      await harness.client.auth.signInWithPassword(
        email: harness.email,
        password: Harness.testPassword,
      );

      try {
        await expectLater(
          harness.client.from('notification_log').insert({
            'household_id': harness.householdId,
            'dedup_key': 'attack',
            'user_id': otherUserId, // ← someone else's
            'source': 'client',
          }),
          throwsA(anything),
          reason:
              'WITH CHECK must reject when user_id != auth.uid(); '
              'otherwise a member could pre-claim another member\'s '
              'dedup slot and silence them.',
        );
      } finally {
        await harness.client.auth.signInWithPassword(
          email: other.email,
          password: Harness.testPassword,
        );
        await other.dispose();
        await harness.client.auth.signInWithPassword(
          email: harness.email,
          password: Harness.testPassword,
        );
      }
    }, skip: reason);
  });
}
