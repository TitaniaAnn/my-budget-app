// Integration tests for ScenariosRepository.fetchHistoricalNetWorth.
//
// The pure walkback function (`reconstructHistoricalNetWorth`) is
// already pinned in unit tests with hand-fed delta maps. This file
// covers the SQL half — does the .from('transactions').select(...)
// filter pull exactly the rows the pure function expects? Audit T4
// flagged this gap.
//
// Pinned here:
//
//   * a household with no transactions in the lookback window
//     returns just the "today" point at the current net worth (the
//     base case the pure function emits);
//   * a household with one transaction yesterday returns two
//     points — yesterday's end-of-day balance + today's — with
//     yesterday's balance correctly walked back by the delta;
//   * lookbackDays excludes transactions older than the cutoff
//     (a tx 400 days ago doesn't appear when lookbackDays=365);
//   * RLS scopes to the calling household — a transaction in
//     another household doesn't pollute this household's walkback.
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY
// env vars aren't set.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/scenarios/repositories/scenarios_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('ScenariosRepository.fetchHistoricalNetWorth (integration)', () {
    late Harness harness;
    late ScenariosRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'scenarios-hist');
      repo = ScenariosRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    setUp(() async {
      if (reason != null) return;
      // Clean slate per test — the harness reuses one user/household
      // across tests, so any prior test's transactions would
      // contaminate the walkback.
      await harness.client
          .from('transactions')
          .delete()
          .eq('household_id', harness.householdId);
    });

    Future<void> insertTx({
      required int amountCents,
      required DateTime date,
      String description = 'walkback-test',
    }) async {
      await harness.client.from('transactions').insert({
        'household_id': harness.householdId,
        'account_id': harness.accountId,
        'entered_by': harness.userId,
        'amount': amountCents,
        'currency': 'USD',
        'description': description,
        'transaction_date': date.toIso8601String().substring(0, 10),
        'pending': false,
        'source': 'manual',
      });
    }

    test(
      'empty ledger returns just the "today" anchor at the current net worth',
      () async {
        final result = await repo.fetchHistoricalNetWorth(
          householdId: harness.householdId,
          currentNetWorth: 12345,
        );
        expect(result, hasLength(1));
        expect(
          result.single.balanceCents,
          12345,
          reason:
              'with no transactions, today\'s balance IS today\'s '
              'walkback — the pure function emits exactly the anchor.',
        );
      },
      skip: reason,
    );

    test('two transaction dates: the older end-of-day balance is the newer '
        'one plus the undo of the newer day\'s delta', () async {
      // The walkback emits one point per transaction date plus the
      // anchor. Each step from newer→older undoes the NEWER day's
      // delta, because end-of-(older) = end-of-(newer) - delta(newer).
      //
      // Setup: -$30 yesterday, -$50 two days ago, anchor $1000.
      //   end-of-today      = $1000 (no tx today)
      //   end-of-yesterday  = $1000 (yesterday's -$30 already applied)
      //   end-of-(2 d ago)  = end-of-yesterday - delta(yesterday)
      //                     = $1000 - (-$30) = $1030
      //
      // Use LOCAL-time date arithmetic so the dates we write into
      // `transaction_date` match what reconstructHistoricalNetWorth
      // uses internally (it derives `todayKey` from a local-zone
      // DateTime.now()). UTC arithmetic skews by a day near UTC
      // boundaries and collides "yesterday" with the anchor's skip
      // branch.
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final yesterday = todayDate.subtract(const Duration(days: 1));
      final twoDaysAgo = todayDate.subtract(const Duration(days: 2));
      await insertTx(amountCents: -3000, date: yesterday);
      await insertTx(amountCents: -5000, date: twoDaysAgo);

      final result = await repo.fetchHistoricalNetWorth(
        householdId: harness.householdId,
        currentNetWorth: 100000,
      );
      expect(
        result,
        hasLength(3),
        reason: 'two transaction dates + the today anchor = 3 points',
      );
      // Oldest-first ordering (the function reverses internally).
      expect(
        result[0].balanceCents,
        103000,
        reason:
            'two-days-ago end-of-day = yesterday\'s \$1000 minus '
            'yesterday\'s -\$30 delta = \$1030. This is the actual '
            'walkback step the off-by-one bug used to live in.',
      );
      expect(
        result[1].balanceCents,
        100000,
        reason:
            'yesterday end-of-day = today \$1000 minus today\'s '
            '0 delta = \$1000 (today has no transactions).',
      );
      expect(result[2].balanceCents, 100000);
    }, skip: reason);

    test(
      'transactions older than lookbackDays are excluded from the walkback',
      () async {
        // Two transactions: one inside the window (10 days ago) and
        // one far outside (400 days ago, default window is 365). Only
        // the recent one should appear in the result. Local-zone
        // date arithmetic to match the algorithm's "today" basis.
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        await insertTx(
          amountCents: -2000,
          date: todayDate.subtract(const Duration(days: 10)),
          description: 'in-window',
        );
        await insertTx(
          amountCents: -50000,
          date: todayDate.subtract(const Duration(days: 400)),
          description: 'out-of-window',
        );

        final result = await repo.fetchHistoricalNetWorth(
          householdId: harness.householdId,
          currentNetWorth: 100000,
        );
        // Anchor + one in-window point = 2 entries. If the
        // lookbackDays gate broke, we'd see 3 (anchor + both
        // transaction dates).
        expect(
          result,
          hasLength(2),
          reason:
              'the 400-day-ago tx is outside the default 365-day '
              'lookback and must NOT contribute a walkback point.',
        );
        // Today's anchor is the last element (newest); the in-window
        // tx's date is the first (oldest).
        expect(result.last.balanceCents, 100000);
      },
      skip: reason,
    );

    test('RLS scopes the walkback to the caller\'s household — a foreign '
        'household\'s transactions are invisible', () async {
      // Insert a transaction in OUR household + a transaction in
      // ANOTHER household with overlapping date. The foreign tx
      // must not appear in our walkback even though it shares a
      // date with our row.
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final yesterday = todayDate.subtract(const Duration(days: 1));
      await insertTx(amountCents: -1000, date: yesterday);

      // Bootstrap a second household and insert a tx there. The
      // bootstrap signs us in as `other`; sign back in as the
      // original harness afterwards.
      final other = await Harness.bootstrap(testTag: 'scenarios-hist-rls');
      await harness.client.from('transactions').insert({
        'household_id': other.householdId,
        'account_id': other.accountId,
        'entered_by': other.userId,
        'amount': -99999,
        'currency': 'USD',
        'description': 'OTHER HOUSEHOLD',
        'transaction_date': yesterday.toIso8601String().substring(0, 10),
        'pending': false,
        'source': 'manual',
      });
      await harness.client.auth.signInWithPassword(
        email: harness.email,
        password: Harness.testPassword,
      );

      try {
        final result = await repo.fetchHistoricalNetWorth(
          householdId: harness.householdId,
          currentNetWorth: 50000,
        );
        // Our household has 1 tx date → 2 walkback points (today
        // anchor + yesterday). If RLS leaked, the foreign tx would
        // share the same date and we'd still see 2 points, but the
        // delta map would be polluted and the walkback would drift.
        // Easier RLS check: confirm the foreign description never
        // appears in our window by querying the same surface.
        expect(result, hasLength(2));
        expect(result.last.balanceCents, 50000);

        // Belt-and-suspenders: a direct query that the foreign row
        // is invisible. The walkback collapses both deltas into the
        // same date so it's hard to see a leak through; this is
        // unambiguous.
        final visible = await harness.client
            .from('transactions')
            .select('description')
            .eq('description', 'OTHER HOUSEHOLD');
        expect(
          visible,
          isEmpty,
          reason:
              'RLS on transactions must hide the foreign row '
              'from our user — that\'s the underlying property the '
              'walkback inherits.',
        );
      } finally {
        // Clean up the second household for harness disposal.
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
