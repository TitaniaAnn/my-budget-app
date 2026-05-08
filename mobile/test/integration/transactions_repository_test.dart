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
import 'package:mybudget/features/transactions/models/category.dart';
import 'package:mybudget/features/transactions/repositories/transactions_repository.dart';
import 'package:mybudget/features/transactions/services/categorizer.dart';
import 'package:mybudget/features/transactions/services/category_matcher.dart';
import 'package:mybudget/features/transactions/services/ml_category_classifier.dart';

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

    // ── createTransaction + updateTransaction (UTC timestamp) ───────────
    //
    // Pins the .toUtc().toIso8601String() convention end-to-end. A
    // timezone-naive write would land in TIMESTAMPTZ shifted by the
    // host's UTC offset; this test catches that drift if it ever
    // returns.

    group('category_assigned_at UTC discipline', () {
      Future<DateTime> readAssignedAt(String txId) async {
        final row = await harness.client
            .from('transactions')
            .select('category_assigned_at')
            .eq('id', txId)
            .single();
        return DateTime.parse(row['category_assigned_at'] as String);
      }

      test('createTransaction writes category_assigned_at within seconds of '
          'now() in UTC', () async {
        final groceriesId = await harness.systemCategoryIdByName('Groceries');
        final created = await repo.createTransaction(
          householdId: harness.householdId,
          accountId: harness.accountId,
          enteredBy: harness.userId,
          amount: -1234,
          description: 'UTC TEST CREATE',
          transactionDate: DateTime.now(),
          categoryId: groceriesId,
        );
        final ts = await readAssignedAt(created.id);
        final skew = DateTime.now().toUtc().difference(ts.toUtc()).abs();
        expect(
          skew.inMinutes < 5,
          isTrue,
          reason:
              'category_assigned_at drifted by $skew — likely a '
              'timezone-naive write. Use .toUtc().toIso8601String().',
        );
      }, skip: reason);

      test('updateTransaction refreshes category_assigned_at in UTC', () async {
        final groceriesId = await harness.systemCategoryIdByName('Groceries');
        final coffeeId = await harness.systemCategoryIdByName(
          'Coffee & Drinks',
        );

        // Insert with a deliberately-old timestamp so we can prove the
        // update moves it to "now".
        final txId = await harness.insertTransaction(
          description: 'UTC TEST UPDATE',
          categoryId: groceriesId,
          categoryAssignedBy: 'user',
        );
        await harness.client
            .from('transactions')
            .update({
              'category_assigned_at': DateTime.utc(
                2020,
                1,
                1,
              ).toIso8601String(),
            })
            .eq('id', txId);

        await repo.updateTransaction(
          id: txId,
          amount: -1234,
          description: 'UTC TEST UPDATE',
          transactionDate: DateTime.now(),
          categoryId: coffeeId,
        );

        final ts = await readAssignedAt(txId);
        final skew = DateTime.now().toUtc().difference(ts.toUtc()).abs();
        expect(
          skew.inMinutes < 5,
          isTrue,
          reason:
              'updateTransaction left category_assigned_at at the old '
              'value or drifted by $skew. Should be near now() in UTC.',
        );
      }, skip: reason);
    });

    // ── bulkRecategorize ─────────────────────────────────────────────────
    //
    // Verifies the actual SQL effect of the grouped UPDATEs: matching
    // rows get their category_id, category_assigned_by, and
    // ml_model_confidence written; non-matching rows are left alone;
    // already-categorised rows are excluded from the input set.

    group('bulkRecategorize', () {
      test('keyword path: writes category + provenance, leaves '
          'ml_model_confidence null', () async {
        // Build a Categorizer that uses keyword matcher only (no ML).
        // Fetching system categories so the matcher can resolve
        // names → IDs.
        final catRows = await harness.client
            .from('categories')
            .select()
            .isFilter('household_id', null);
        final cats = (catRows as List)
            .map((r) => Category.fromJson(r as Map<String, dynamic>))
            .toList();
        final categorizer = Categorizer(
          categories: cats,
          keywordMatcher: CategoryMatcher(cats),
          // No ML classifier — exercises the keyword path.
        );

        final coffeeId = await harness.systemCategoryIdByName(
          'Coffee & Drinks',
        );
        final groceriesId = await harness.systemCategoryIdByName('Groceries');

        // Two rows the keyword matcher will hit, one it won't.
        final starbucksId = await harness.insertTransaction(
          description: 'STARBUCKS COFFEE 1234',
        );
        final walmartId = await harness.insertTransaction(
          description: 'WALMART SUPERCENTER',
        );
        final unknownId = await harness.insertTransaction(
          description: 'TOTALLY UNRECOGNISED MERCHANT XYZ',
        );

        // Pre-categorised row should NOT be touched (filter is
        // category_id IS NULL).
        final alreadyId = await harness.insertTransaction(
          description: 'STARBUCKS DOWNTOWN',
          categoryId: groceriesId, // wrong category on purpose
          categoryAssignedBy: 'user',
        );

        final updated = await repo.bulkRecategorize(
          householdId: harness.householdId,
          categorizer: categorizer,
        );

        // Expected: 2 rows updated (starbucks + walmart). Unknown stays
        // null; pre-categorised row stays as-is.
        expect(updated, 2);

        Future<Map<String, dynamic>> fetchRow(String id) async => await harness
            .client
            .from('transactions')
            .select('category_id, category_assigned_by, ml_model_confidence')
            .eq('id', id)
            .single();

        final starbucks = await fetchRow(starbucksId);
        expect(starbucks['category_id'], coffeeId);
        expect(starbucks['category_assigned_by'], 'keyword_matcher');
        expect(
          starbucks['ml_model_confidence'],
          isNull,
          reason:
              'keyword hits must NOT populate ml_model_confidence — the '
              'column is reserved for ML provenance.',
        );

        final walmart = await fetchRow(walmartId);
        expect(walmart['category_id'], groceriesId);
        expect(walmart['category_assigned_by'], 'keyword_matcher');
        expect(walmart['ml_model_confidence'], isNull);

        final unknown = await fetchRow(unknownId);
        expect(
          unknown['category_id'],
          isNull,
          reason:
              'unmatched rows must stay uncategorised — the matcher had '
              'no rule for this description.',
        );

        final already = await fetchRow(alreadyId);
        expect(
          already['category_id'],
          groceriesId,
          reason:
              'already-categorised rows must not be touched (the SELECT '
              'filter is category_id IS NULL).',
        );
        expect(already['category_assigned_by'], 'user');
      }, skip: reason);

      test(
        'ML path: writes category + ml_model_confidence in basis points',
        () async {
          // Build a Categorizer with a stub ML classifier so we can pin
          // the confidence-bp write without depending on shipped model
          // assets. The stub returns a fixed prediction for any input
          // it recognises.
          final catRows = await harness.client
              .from('categories')
              .select()
              .isFilter('household_id', null);
          final cats = (catRows as List)
              .map((r) => Category.fromJson(r as Map<String, dynamic>))
              .toList();
          final groceriesId = await harness.systemCategoryIdByName('Groceries');
          final categorizer = Categorizer(
            categories: cats,
            keywordMatcher: CategoryMatcher(cats),
            mlClassifier: _StubHighConfidenceMl(
              categoryName: 'Groceries',
              categoryId: groceriesId,
              confidence: 0.83, // → 8300 bp
            ),
            minMlConfidence: 0.55,
          );

          final txId = await harness.insertTransaction(
            description: 'OBSCURE BUT MODELED MERCHANT',
          );

          await repo.bulkRecategorize(
            householdId: harness.householdId,
            categorizer: categorizer,
          );

          final row = await harness.client
              .from('transactions')
              .select('category_id, category_assigned_by, ml_model_confidence')
              .eq('id', txId)
              .single();
          expect(row['category_id'], groceriesId);
          expect(row['category_assigned_by'], 'ml_model');
          // 0.83 → round(83) × 100 = 8300 bp. Also verifies the
          // basis-points conversion is integer-only at the wire layer.
          expect(row['ml_model_confidence'], 8300);
        },
        skip: reason,
      );
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
              password: Harness.testPassword,
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
              password: Harness.testPassword,
            );
            await other.dispose();
            // Restore our test user's session for any later test ordering.
            await harness.client.auth.signInWithPassword(
              email: harness.email,
              password: Harness.testPassword,
            );
          }
        },
        skip: reason,
      );
    });
  });
}

/// Minimal stand-in for [MlCategoryClassifier] used by the
/// `bulkRecategorize` ML-path test. Returns a fixed prediction for
/// every input — what we're testing is the repository's wire-format
/// handling of confidence (basis-points conversion + grouped UPDATE),
/// not the model itself.
class _StubHighConfidenceMl implements MlCategoryClassifier {
  _StubHighConfidenceMl({
    required this.categoryName,
    required this.categoryId,
    required this.confidence,
  });

  final String categoryName;
  final String categoryId;
  final double confidence;

  @override
  MlPrediction? predict({
    required String description,
    String? merchant,
    required int amountCents,
    required Map<String, Category> categoriesByName,
    String? accountType,
    double minConfidence = 0.55,
  }) {
    if (confidence < minConfidence) return null;
    return MlPrediction(
      categoryName: categoryName,
      categoryId: categoryId,
      confidence: confidence,
    );
  }

  @override
  double thresholdFor(String className, {required double defaultThreshold}) =>
      defaultThreshold;

  @override
  void dispose() {}

  @override
  int get inputSize => 0;
}
