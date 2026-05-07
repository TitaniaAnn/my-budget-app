// Integration tests for TransactionsRepository methods that exercise
// SQL semantics and RLS — the parts that mock-based tests can't cover
// honestly. Hits the local Supabase stack.
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY env
// vars aren't set, so a default `flutter test` run isn't disturbed.
//
// Run locally (after `supabase start` in repo root):
//   cd mobile
//   flutter test \
//     --dart-define=SUPABASE_TEST_URL=http://localhost:54421 \
//     --dart-define=SUPABASE_TEST_ANON_KEY=<key from `supabase status`> \
//     test/integration/

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/repositories/transactions_repository.dart';

import '_supabase_harness.dart';

void main() {
  // Gate the whole suite on env: we want a clean "skipped" line in the
  // default run rather than a hard failure.
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('TransactionsRepository (integration)', () {
    late Harness harness;
    late TransactionsRepository repo;

    setUpAll(() async {
      // setUpAll runs even when individual tests are skipped via the
      // `skip:` parameter, so we have to gate here too — otherwise the
      // bootstrap throws and tearDownAll fails on uninitialised
      // `harness`.
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'tx-repo');
      repo = TransactionsRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    // ── setUserCategory ─────────────────────────────────────────────────

    group('setUserCategory', () {
      test(
        'flips category_assigned_by to user and clears confidence',
        () async {
          final groceriesId = await harness.systemCategoryIdByName('Groceries');
          final coffeeId = await harness.systemCategoryIdByName(
            'Coffee & Drinks',
          );
          final txId = await harness.insertTransaction(
            categoryId: groceriesId,
            categoryAssignedBy: 'ml_model',
            mlModelConfidence: 4500,
          );

          await repo.setUserCategory(transactionId: txId, categoryId: coffeeId);

          final row = await harness.client
              .from('transactions')
              .select(
                'category_id, category_assigned_by, ml_model_confidence, '
                'category_assigned_at',
              )
              .eq('id', txId)
              .single();
          expect(row['category_id'], coffeeId);
          expect(row['category_assigned_by'], 'user');
          expect(row['ml_model_confidence'], isNull);
          // category_assigned_at must move to "now-ish" — confirm it's
          // recent rather than asserting an exact value. Postgres returns
          // TIMESTAMPTZ in UTC; compare in UTC so a host machine in a
          // non-UTC timezone doesn't false-fail. 5 minutes is generous
          // enough to absorb container/host clock skew.
          final ts = DateTime.parse(row['category_assigned_at'] as String);
          final skew = DateTime.now().toUtc().difference(ts.toUtc()).abs();
          expect(
            skew.inMinutes < 5,
            isTrue,
            reason: 'category_assigned_at should be near now() (skew=$skew)',
          );
        },
        skip: reason,
      );

      test('still flips provenance for keyword-matcher rows', () async {
        // Confirms the method isn't ML-only — a row originally assigned
        // by the keyword matcher also accepts the user-confirmation path.
        final groceriesId = await harness.systemCategoryIdByName('Groceries');
        final txId = await harness.insertTransaction(
          categoryId: groceriesId,
          categoryAssignedBy: 'keyword_matcher',
        );

        await repo.setUserCategory(
          transactionId: txId,
          categoryId: groceriesId,
        );

        final row = await harness.client
            .from('transactions')
            .select('category_assigned_by, ml_model_confidence')
            .eq('id', txId)
            .single();
        expect(row['category_assigned_by'], 'user');
        expect(row['ml_model_confidence'], isNull);
      }, skip: reason);
    });

    // ── fetchUncertain ──────────────────────────────────────────────────

    group('fetchUncertain', () {
      test('returns only ML rows below the confidence bound, '
          'ordered ascending', () async {
        final groceriesId = await harness.systemCategoryIdByName('Groceries');

        // Below bound, lowest confidence — should appear first.
        final lowId = await harness.insertTransaction(
          description: 'LOW CONF',
          categoryId: groceriesId,
          categoryAssignedBy: 'ml_model',
          mlModelConfidence: 3000,
        );
        // Below bound, mid confidence — should appear second.
        final midId = await harness.insertTransaction(
          description: 'MID CONF',
          categoryId: groceriesId,
          categoryAssignedBy: 'ml_model',
          mlModelConfidence: 4500,
        );
        // At bound (5500). The repo uses `lt`, not `lte`, so this row is
        // excluded.
        await harness.insertTransaction(
          description: 'AT BOUND',
          categoryId: groceriesId,
          categoryAssignedBy: 'ml_model',
          mlModelConfidence: 5500,
        );
        // High-confidence ML row — auto-applied; not uncertain.
        await harness.insertTransaction(
          description: 'HIGH CONF',
          categoryId: groceriesId,
          categoryAssignedBy: 'ml_model',
          mlModelConfidence: 9000,
        );
        // User-assigned row — confidence column populated by accident
        // (defensive: even if it leaked, this row is NOT uncertain
        // because the source is wrong).
        await harness.insertTransaction(
          description: 'USER',
          categoryId: groceriesId,
          categoryAssignedBy: 'user',
          mlModelConfidence: 3500,
        );
        // Keyword-matcher row — confidence column null, source wrong.
        await harness.insertTransaction(
          description: 'KW',
          categoryId: groceriesId,
          categoryAssignedBy: 'keyword_matcher',
        );

        final uncertain = await repo.fetchUncertain(
          householdId: harness.householdId,
        );

        // Filtering must catch exactly the two below-bound ML rows,
        // ordered ascending by confidence.
        expect(uncertain.map((t) => t.id).toList(), [lowId, midId]);
        expect(uncertain[0].mlModelConfidence, 3000);
        expect(uncertain[1].mlModelConfidence, 4500);
      }, skip: reason);

      test('respects custom maxConfidenceBp', () async {
        final groceriesId = await harness.systemCategoryIdByName('Groceries');
        // Add one row at 3000 and one at 4500. With maxConfidenceBp=4000,
        // only the 3000 row should surface.
        final lowId = await harness.insertTransaction(
          description: 'CUSTOM BOUND LOW',
          categoryId: groceriesId,
          categoryAssignedBy: 'ml_model',
          mlModelConfidence: 3000,
        );
        await harness.insertTransaction(
          description: 'CUSTOM BOUND HIGH',
          categoryId: groceriesId,
          categoryAssignedBy: 'ml_model',
          mlModelConfidence: 4500,
        );

        final result = await repo.fetchUncertain(
          householdId: harness.householdId,
          maxConfidenceBp: 4000,
        );
        // Other rows from the prior test in this group may still be
        // present; assert that the high-bound row is excluded and the
        // low-bound row included rather than asserting exact length.
        final ids = result.map((t) => t.id).toSet();
        expect(ids.contains(lowId), isTrue);
        expect(
          result.every((t) => (t.mlModelConfidence ?? 1 << 30) < 4000),
          isTrue,
          reason: 'every returned row must be strictly below maxConfidenceBp',
        );
      }, skip: reason);

      test('respects the limit parameter', () async {
        final result = await repo.fetchUncertain(
          householdId: harness.householdId,
          limit: 1,
        );
        expect(result.length, lessThanOrEqualTo(1));
      }, skip: reason);
    });

    // ── RLS sanity ──────────────────────────────────────────────────────
    //
    // The riskiest property in the repo is household isolation. This
    // test sets up a SECOND household with its own user, inserts a row
    // there, then confirms our test user's fetchUncertain doesn't see
    // it. If RLS is broken (e.g. a future migration weakens a policy),
    // this fails loudly — no fancy assertions needed.

    group('RLS isolation', () {
      test(
        'fetchUncertain does NOT return rows from a different household',
        () async {
          // Bootstrap a second harness — its own user, its own household.
          final other = await Harness.bootstrap(testTag: 'rls-isolation');
          try {
            // From the OTHER household's perspective, insert an uncertain
            // ML row. The signed-in client at this point is `other.client`
            // (Supabase.initialize is global; whoever signed in last is
            // the active session — which is `other` after bootstrap).
            final otherGroceriesId = await other.systemCategoryIdByName(
              'Groceries',
            );
            await other.insertTransaction(
              description: 'OTHER HOUSEHOLD UNCERTAIN ROW',
              categoryId: otherGroceriesId,
              categoryAssignedBy: 'ml_model',
              mlModelConfidence: 2500,
            );

            // Sign back in as our original test user so RLS evaluates
            // queries from their identity. Then fetchUncertain for the
            // FIRST household — and confirm the second-household row
            // doesn't appear, no matter which household_id we pass.
            await harness.client.auth.signInWithPassword(
              email: harness.email,
              password: 'test-password-12345',
            );
            final ourRows = await repo.fetchUncertain(
              householdId: harness.householdId,
            );
            expect(
              ourRows.any(
                (t) => t.description == 'OTHER HOUSEHOLD UNCERTAIN ROW',
              ),
              isFalse,
              reason:
                  'RLS leak: a row from a different household appeared in '
                  'our fetchUncertain result.',
            );

            // Belt-and-braces: even passing the OTHER household_id
            // explicitly should yield nothing — RLS gates on auth.uid(),
            // not on the parameter. Pre-Tier-2 RLS already enforces this;
            // the test pins the property.
            final cross = await repo.fetchUncertain(
              householdId: other.householdId,
            );
            expect(
              cross,
              isEmpty,
              reason: 'RLS leak: querying another household_id returned rows.',
            );
          } finally {
            // Sign back in as the second user just long enough to clean up
            // their household.
            await harness.client.auth.signInWithPassword(
              email: other.email,
              password: 'test-password-12345',
            );
            await other.dispose();
            // Restore our test user's session for any later test ordering.
            await harness.client.auth.signInWithPassword(
              email: harness.email,
              password: 'test-password-12345',
            );
          }
        },
        skip: reason,
      );
    });
  });
}
