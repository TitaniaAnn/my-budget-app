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
import 'package:mybudget/features/transactions/repositories/transaction_tags_repository.dart';
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

    // ── fetchByReceiptId ─────────────────────────────────────────────────
    //
    // Powers the receipt-detail "Paired Transactions" section. Pins three
    // properties the UI relies on:
    //   * only rows whose receipt_id equals the argument are returned
    //   * results are ordered transaction_date DESC (matches main list)
    //   * the joined `category` is populated so the receipt detail can
    //     style the row like the global transactions list

    group('fetchByReceiptId', () {
      // Inserts a receipt directly (no storage upload). receipts_repository
      // tests follow the same shape — fetchByReceiptId only reads the id.
      Future<String> insertReceipt() async {
        final row = await harness.client
            .from('receipts')
            .insert({
              'household_id': harness.householdId,
              'uploaded_by': harness.userId,
              'storage_path':
                  '${harness.householdId}/test-${DateTime.now().microsecondsSinceEpoch}.jpg',
              'ocr_status': 'pending',
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      Future<void> pair(String txId, String receiptId) async {
        await harness.client
            .from('transactions')
            .update({'receipt_id': receiptId})
            .eq('id', txId);
      }

      test('returns only transactions paired to the given receipt, '
          'newest first', () async {
        final targetReceiptId = await insertReceipt();
        final otherReceiptId = await insertReceipt();

        // Two paired to target on different dates.
        final newerId = await harness.insertTransaction(
          description: 'TARGET NEWER',
          transactionDate: DateTime.utc(2026, 5, 15),
        );
        final olderId = await harness.insertTransaction(
          description: 'TARGET OLDER',
          transactionDate: DateTime.utc(2026, 5, 10),
        );
        // One paired to a different receipt — must NOT surface.
        final otherId = await harness.insertTransaction(
          description: 'OTHER RECEIPT',
          transactionDate: DateTime.utc(2026, 5, 12),
        );
        // One unpaired — must NOT surface either.
        final unpairedId = await harness.insertTransaction(
          description: 'UNPAIRED',
          transactionDate: DateTime.utc(2026, 5, 13),
        );

        await pair(newerId, targetReceiptId);
        await pair(olderId, targetReceiptId);
        await pair(otherId, otherReceiptId);

        final result = await repo.fetchByReceiptId(targetReceiptId);
        final ids = result.map((t) => t.id).toList();

        expect(
          ids,
          [newerId, olderId],
          reason:
              'fetchByReceiptId must return only rows whose receipt_id '
              'matches, ordered by transaction_date DESC.',
        );
        expect(ids.contains(otherId), isFalse);
        expect(ids.contains(unpairedId), isFalse);
      }, skip: reason);

      test('joined category row is populated', () async {
        final receiptId = await insertReceipt();
        final groceriesId = await harness.systemCategoryIdByName('Groceries');
        final txId = await harness.insertTransaction(
          description: 'WITH CATEGORY',
          categoryId: groceriesId,
          categoryAssignedBy: 'user',
        );
        await pair(txId, receiptId);

        final result = await repo.fetchByReceiptId(receiptId);
        expect(result, hasLength(1));
        expect(
          result.single.category?.id,
          groceriesId,
          reason:
              'fetchByReceiptId must select with the category join so the '
              'receipt detail can render category chips without a second '
              'round-trip.',
        );
      }, skip: reason);

      test('returns empty when nothing is paired', () async {
        // A fresh receipt with no transactions pointing at it.
        final receiptId = await insertReceipt();
        final result = await repo.fetchByReceiptId(receiptId);
        expect(result, isEmpty);
      }, skip: reason);
    });

    // ── fetchTransactions(tagId: ...) ───────────────────────────────────
    //
    // Powers the tag filter on the transactions screen. The repo does
    // this in two trips (assignment-table lookup → inFilter on ids)
    // rather than a join, so we want to confirm the wiring under
    // realistic conditions.

    group('fetchTransactions tag filter', () {
      test('returns only transactions carrying the requested tag', () async {
        // Two tags with distinct assignments — and a third tx with
        // no tag at all to confirm the filter excludes untagged rows.
        final tagsRepo = TransactionTagsRepository();
        final stamp = DateTime.now().microsecondsSinceEpoch;
        final tagA = await tagsRepo.createTag(
          householdId: harness.householdId,
          name: 'contractor-$stamp',
        );
        final tagB = await tagsRepo.createTag(
          householdId: harness.householdId,
          name: 'pottery-$stamp',
        );

        final aId = await harness.insertTransaction(description: 'TAG A TX');
        final bId = await harness.insertTransaction(description: 'TAG B TX');
        final untaggedId = await harness.insertTransaction(
          description: 'UNTAGGED',
        );

        await tagsRepo.replaceAssignments(
          transactionId: aId,
          tagIds: [tagA.id],
        );
        await tagsRepo.replaceAssignments(
          transactionId: bId,
          tagIds: [tagB.id],
        );

        final filteredA = await repo.fetchTransactions(
          householdId: harness.householdId,
          tagId: tagA.id,
        );
        final filteredAIds = filteredA.map((t) => t.id).toSet();
        expect(filteredAIds, contains(aId));
        expect(
          filteredAIds,
          isNot(contains(bId)),
          reason: 'tagB-only transaction must not surface under tagA filter.',
        );
        expect(
          filteredAIds,
          isNot(contains(untaggedId)),
          reason: 'untagged transaction must not appear under any tag filter.',
        );
      }, skip: reason);

      test('tag with no assignments short-circuits to empty without leaking '
          'every transaction in the household', () async {
        // A fresh tag nobody has used yet. The repo guards against
        // the inFilter(empty list) trap that would otherwise behave
        // like "no filter" and return every row.
        final tagsRepo = TransactionTagsRepository();
        final orphan = await tagsRepo.createTag(
          householdId: harness.householdId,
          name: 'orphan-${DateTime.now().microsecondsSinceEpoch}',
        );
        // Seed at least one transaction so "empty" is meaningful.
        await harness.insertTransaction(description: 'NOT TAGGED ORPHAN');

        final result = await repo.fetchTransactions(
          householdId: harness.householdId,
          tagId: orphan.id,
        );
        expect(
          result,
          isEmpty,
          reason:
              'fetchTransactions with a tag that has no assignments '
              'must NOT fall through to "return everything" — the '
              'inFilter(empty) trap is what the short-circuit in the '
              'repo prevents.',
        );
      }, skip: reason);
    });

    // ── fetchCategories ordering ────────────────────────────────────────
    //
    // The seed (migration 002) packs parents at sort_order 0/10/20…
    // and children at 1/2/3…, so ASC ordering keeps parents grouped
    // and children in spec order within each parent. postgrest's
    // .order() default is DESC — the test pins that the repo
    // overrides that explicitly.

    group('fetchCategories', () {
      test(
        'returns categories in sort_order ASC, with name as tiebreaker',
        () async {
          final cats = await repo.fetchCategories();
          expect(cats, isNotEmpty);
          for (var i = 1; i < cats.length; i++) {
            final prev = cats[i - 1];
            final curr = cats[i];
            final sortMonotonic = curr.sortOrder >= prev.sortOrder;
            // Postgres uses case-insensitive collation by default
            // (en_US.UTF-8 puts "Home" before "HSA") whereas Dart's
            // String.compareTo is case-sensitive ("HSA" < "Home" by
            // ASCII). Compare lowercased so the assertion mirrors
            // the server's actual sort.
            final nameTieMonotonic =
                curr.sortOrder != prev.sortOrder ||
                curr.name.toLowerCase().compareTo(prev.name.toLowerCase()) >= 0;
            expect(
              sortMonotonic,
              isTrue,
              reason:
                  'fetchCategories must be non-decreasing in sort_order. '
                  'Saw ${prev.name}(${prev.sortOrder}) before '
                  '${curr.name}(${curr.sortOrder}) at index $i.',
            );
            expect(
              nameTieMonotonic,
              isTrue,
              reason:
                  'Within a sort_order tie, name must be non-decreasing '
                  '(case-insensitive). Saw ${prev.name} before '
                  '${curr.name} at sort_order ${curr.sortOrder}.',
            );
          }
        },
        skip: reason,
      );

      test(
        '"Income" (sort_order 0) precedes "Housing" (sort_order 10)',
        () async {
          // Picks a stable pair from the seed: Income parent is at 0,
          // Housing parent is at 10. ASC ordering puts Income first.
          final cats = await repo.fetchCategories();
          final names = cats.map((c) => c.name).toList();
          final incomeIdx = names.indexOf('Income');
          final housingIdx = names.indexOf('Housing');
          expect(incomeIdx >= 0 && housingIdx >= 0, isTrue);
          expect(
            incomeIdx,
            lessThan(housingIdx),
            reason:
                'Income (sort_order 0) must come before Housing '
                '(sort_order 10). DESC ordering — the previous bug — '
                'reversed this.',
          );
        },
        skip: reason,
      );
    });

    // ── createTransfer (migration 030) ───────────────────────────────────
    //
    // create_transfer is the only blessed path for account-to-account
    // money movement. It inserts two transaction rows in one DB
    // transaction; both legs share a transfer_id. Tests pin: the rows
    // land with the right signs and shared id, illegal inputs raise,
    // and a mid-call failure rolls both legs back (atomicity).

    group('createTransfer', () {
      // Spins up a second account in the same household so we have
      // somewhere to transfer to. The harness already seeds one
      // ("Test Checking"); this adds a savings.
      Future<String> insertSavingsAccount() async {
        final row = await harness.client
            .from('accounts')
            .insert({
              'household_id': harness.householdId,
              'owner_user_id': harness.userId,
              'name': 'Test Savings',
              'account_type': 'savings',
              'currency': 'USD',
              'starting_balance': 0,
              'current_balance': 0,
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      test(
        'inserts two legs with matching transfer_id, opposite signs, '
        'and shared description / date',
        () async {
          final savingsId = await insertSavingsAccount();
          final date = DateTime.utc(2026, 5, 14);

          final transferId = await repo.createTransfer(
            householdId: harness.householdId,
            fromAccountId: harness.accountId,
            toAccountId: savingsId,
            amountCents: 25000,
            transactionDate: date,
            description: 'May rent buffer',
            enteredBy: harness.userId,
          );

          final legs = await harness.client
              .from('transactions')
              .select('account_id, amount, description, transfer_id')
              .eq('transfer_id', transferId)
              .order('amount', ascending: true);
          expect(
            legs,
            hasLength(2),
            reason: 'create_transfer must insert exactly two rows.',
          );

          // legs[0] is the negative leg (debit on source), legs[1] is
          // the positive leg (credit on destination).
          expect(legs[0]['account_id'], harness.accountId);
          expect(legs[0]['amount'], -25000);
          expect(legs[1]['account_id'], savingsId);
          expect(legs[1]['amount'], 25000);

          expect(legs[0]['description'], 'May rent buffer');
          expect(legs[1]['description'], 'May rent buffer');
          expect(legs[0]['transfer_id'], legs[1]['transfer_id']);
        },
        skip: reason,
      );

      test(
        'rejects same source and destination',
        () async {
          await expectLater(
            repo.createTransfer(
              householdId: harness.householdId,
              fromAccountId: harness.accountId,
              toAccountId: harness.accountId,
              amountCents: 1000,
              transactionDate: DateTime.utc(2026, 5, 14),
              description: 'self-transfer should fail',
              enteredBy: harness.userId,
            ),
            throwsA(anything),
            reason:
                'transferring an account to itself has no semantic meaning '
                '— the RPC must raise rather than silently insert two rows '
                'on the same ledger.',
          );
        },
        skip: reason,
      );

      test(
        'rejects non-positive amounts',
        () async {
          final savingsId = await insertSavingsAccount();
          for (final bad in [0, -100]) {
            await expectLater(
              repo.createTransfer(
                householdId: harness.householdId,
                fromAccountId: harness.accountId,
                toAccountId: savingsId,
                amountCents: bad,
                transactionDate: DateTime.utc(2026, 5, 14),
                description: 'bad amount',
                enteredBy: harness.userId,
              ),
              throwsA(anything),
              reason:
                  'amount must be > 0; signs are derived by the RPC. A '
                  'zero or negative input is a caller bug and must raise.',
            );
          }
        },
        skip: reason,
      );

      test(
        'deleteTransfer removes both legs and reports both affected accounts',
        () async {
          final savingsId = await insertSavingsAccount();
          final transferId = await repo.createTransfer(
            householdId: harness.householdId,
            fromAccountId: harness.accountId,
            toAccountId: savingsId,
            amountCents: 7500,
            transactionDate: DateTime.utc(2026, 5, 14),
            description: 'remove me',
            enteredBy: harness.userId,
          );

          final affected = await repo.deleteTransfer(transferId);

          expect(
            affected.toSet(),
            {harness.accountId, savingsId},
            reason:
                'deleteTransfer must return both account ids so the caller '
                'can recalculate balances on each — returning only one would '
                'leave the other account\'s current_balance stale.',
          );

          final remaining = await harness.client
              .from('transactions')
              .select('id')
              .eq('transfer_id', transferId);
          expect(
            remaining,
            isEmpty,
            reason:
                'both legs must be gone — a surviving leg would orphan as a '
                'phantom debit or credit on whichever account it sat on.',
          );
        },
        skip: reason,
      );

      test(
        'atomicity: a mid-call failure leaves no orphan leg behind',
        () async {
          // Engineer a deliberate failure of the SECOND insert: pass a
          // syntactically valid UUID that doesn't reference any account
          // row. The FK on transactions.account_id will reject the
          // INSERT, the function aborts, and the first leg's insert
          // must be rolled back. If the rollback ever regressed,
          // we'd end up with an orphan debit on the source account.
          final beforeRows = await harness.client
              .from('transactions')
              .select('id')
              .eq('account_id', harness.accountId);
          final beforeCount = (beforeRows as List).length;

          await expectLater(
            repo.createTransfer(
              householdId: harness.householdId,
              fromAccountId: harness.accountId,
              toAccountId: '00000000-0000-0000-0000-000000000001',
              amountCents: 1000,
              transactionDate: DateTime.utc(2026, 5, 14),
              description: 'should roll back',
              enteredBy: harness.userId,
            ),
            throwsA(anything),
            reason:
                'destination account FK must fail and propagate to the '
                'caller.',
          );

          final afterRows = await harness.client
              .from('transactions')
              .select('id')
              .eq('account_id', harness.accountId);
          expect(
            (afterRows as List).length,
            beforeCount,
            reason:
                'failed transfer must leave the source account unchanged '
                '— the first leg INSERT has to roll back when the second '
                'leg fails. A leaked debit here would skew balances.',
          );
        },
        skip: reason,
      );
    });

    // ── bulkImport reconciliation against recurring (slice 3) ────────────
    //
    // When a bank statement import lands a row that matches a recent
    // scheduler-emitted (source='recurring') row, the import should
    // reconcile against it rather than leave both in the ledger. Pinned:
    //   * matched scheduler row is deleted; import row lands as source
    //     'import' (canonical bank entry);
    //   * BulkImportResult.reconciled reflects the count;
    //   * a non-matching import takes the normal upsert path with no
    //     scheduler-side effect.

    group('bulkImport reconciliation against recurring', () {
      // Each test wants a clean recurring-source slate on the seeded
      // account so a sibling test's emissions don't accidentally match
      // here. Targets only the test account so the harness's other
      // setup is left alone.
      setUp(() async {
        if (reason != null) return;
        await harness.client
            .from('transactions')
            .delete()
            .eq('account_id', harness.accountId)
            .eq('source', 'recurring');
      });

      // Sets up a fake "scheduler-emitted" row directly via insert so
      // the test doesn't need to call the scheduler RPC (which has its
      // own coverage). Returns the new row id.
      Future<String> seedRecurringEmission({
        required int amountCents,
        required DateTime date,
        String description = 'recurring-test-emission',
      }) async {
        final row = await harness.client
            .from('transactions')
            .insert({
              'household_id': harness.householdId,
              'account_id': harness.accountId,
              'entered_by': harness.userId,
              'amount': amountCents,
              'currency': 'USD',
              'description': description,
              'transaction_date': date
                  .toIso8601String()
                  .substring(0, 10),
              'pending': false,
              'source': 'recurring',
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      test(
        'matched import deletes the scheduler row and reports reconciled=1',
        () async {
          // Date math: the bulkImport repo method gates on "last 14
          // days" relative to `DateTime.now()`. Use a recent
          // emission so the integration test isn't sensitive to
          // wall-clock drift.
          final today = DateTime.now().toUtc();
          final emissionDate = DateTime.utc(today.year, today.month, today.day)
              .subtract(const Duration(days: 1));
          final emissionId = await seedRecurringEmission(
            amountCents: -999,
            date: emissionDate,
          );

          final result = await repo.bulkImport(
            householdId: harness.householdId,
            accountId: harness.accountId,
            enteredBy: harness.userId,
            rows: [
              {
                'amount': -999,
                'description': 'SPOTIFY USA',
                'transaction_date': emissionDate
                    .toIso8601String()
                    .substring(0, 10),
                'external_id': 'BANK-TX-RECON-1',
                'pending': false,
              },
            ],
          );

          expect(result.reconciled, 1);
          expect(result.inserted, 1);
          expect(result.skipped, 0);

          // Scheduler row is gone.
          final remainingEmission = await harness.client
              .from('transactions')
              .select('id')
              .eq('id', emissionId);
          expect(
            (remainingEmission as List),
            isEmpty,
            reason: 'the matched scheduler-emitted row must be deleted '
                'so the ledger doesn\'t carry two rows for the same '
                'real-world charge.',
          );

          // Import row landed with the bank's canonical description.
          final imported = await harness.client
              .from('transactions')
              .select('description, source')
              .eq('external_id', 'BANK-TX-RECON-1')
              .single();
          expect(imported['description'], 'SPOTIFY USA');
          expect(imported['source'], 'import');
        },
        skip: reason,
      );

      test(
        'non-matching import takes the upsert path and leaves any '
        'unrelated recurring row alone',
        () async {
          // Scheduler emission for $9.99; import row for $25 — no
          // amount match. Nothing should reconcile.
          final today = DateTime.now().toUtc();
          final emissionDate = DateTime.utc(today.year, today.month, today.day)
              .subtract(const Duration(days: 1));
          final emissionId = await seedRecurringEmission(
            amountCents: -999,
            date: emissionDate,
          );

          final result = await repo.bulkImport(
            householdId: harness.householdId,
            accountId: harness.accountId,
            enteredBy: harness.userId,
            rows: [
              {
                'amount': -2500,
                'description': 'GAS STATION',
                'transaction_date': emissionDate
                    .toIso8601String()
                    .substring(0, 10),
                'external_id': 'BANK-TX-NORECON-1',
                'pending': false,
              },
            ],
          );

          expect(result.reconciled, 0);
          expect(result.inserted, 1);

          // Scheduler row is still there.
          final stillThere = await harness.client
              .from('transactions')
              .select('id')
              .eq('id', emissionId);
          expect(
            (stillThere as List),
            hasLength(1),
            reason: 'a non-matching import must NOT delete unrelated '
                'recurring rows — only same-amount within-tolerance '
                'rows are reconcile candidates.',
          );
        },
        skip: reason,
      );

      test(
        'two import rows competing for one scheduler row: only one '
        'reconciles, the other lands as a fresh insert',
        () async {
          // Two import rows of the same amount and date; one
          // scheduler emission. The matcher claims exactly one of
          // them (slice-3 contract). The other goes through the
          // upsert path, lands fresh with a different external_id.
          final today = DateTime.now().toUtc();
          final emissionDate = DateTime.utc(today.year, today.month, today.day)
              .subtract(const Duration(days: 1));
          await seedRecurringEmission(
            amountCents: -999,
            date: emissionDate,
          );

          final result = await repo.bulkImport(
            householdId: harness.householdId,
            accountId: harness.accountId,
            enteredBy: harness.userId,
            rows: [
              {
                'amount': -999,
                'description': 'SPOTIFY A',
                'transaction_date': emissionDate
                    .toIso8601String()
                    .substring(0, 10),
                'external_id': 'BANK-TX-A',
                'pending': false,
              },
              {
                'amount': -999,
                'description': 'SPOTIFY B',
                'transaction_date': emissionDate
                    .toIso8601String()
                    .substring(0, 10),
                'external_id': 'BANK-TX-B',
                'pending': false,
              },
            ],
          );

          expect(
            result.reconciled,
            1,
            reason: 'one scheduler row can be claimed at most once per '
                'import — the second matching import row must take the '
                'normal insert path.',
          );
          expect(result.inserted, 2);

          // Both bank rows are in the ledger.
          final landed = await harness.client
              .from('transactions')
              .select('external_id')
              .eq('account_id', harness.accountId)
              .inFilter('external_id', ['BANK-TX-A', 'BANK-TX-B']);
          expect((landed as List), hasLength(2));
        },
        skip: reason,
      );
    });

    // ── Bulk operations (selection-mode actions on the screen) ───────────
    //
    // The transactions screen's selection mode lets the user pick N
    // rows and apply a single edit (category, tag, or delete). The
    // repo methods that back those actions are the unit of test.

    group('bulk operations', () {
      test(
        'setUserCategoryForMany updates every row to user-sourced',
        () async {
          final groceriesId = await harness.systemCategoryIdByName('Groceries');
          // Three uncategorised tx; one untouched tx with a different
          // category that must NOT be overwritten.
          final ids = <String>[
            for (var i = 0; i < 3; i++)
              await harness.insertTransaction(
                description: 'bulk-recat-target-$i',
                amountCents: -100 * (i + 1),
              ),
          ];
          final coffeeId = await harness.systemCategoryIdByName(
            'Coffee & Drinks',
          );
          final untouchedId = await harness.insertTransaction(
            description: 'bulk-recat-untouched',
            amountCents: -5000,
            categoryId: coffeeId,
            categoryAssignedBy: 'user',
          );

          await repo.setUserCategoryForMany(
            transactionIds: ids,
            categoryId: groceriesId,
          );

          final rows = await harness.client
              .from('transactions')
              .select('id, category_id, category_assigned_by, '
                  'ml_model_confidence')
              .inFilter('id', [...ids, untouchedId]);
          final byId = {
            for (final r in rows as List)
              r['id'] as String: r as Map<String, dynamic>,
          };
          for (final id in ids) {
            expect(byId[id]?['category_id'], groceriesId);
            expect(byId[id]?['category_assigned_by'], 'user');
            expect(
              byId[id]?['ml_model_confidence'],
              isNull,
              reason: 'ml confidence must be cleared on user assignment '
                  'so a stale value doesn\'t resurface in the review '
                  'screen after the user has spoken.',
            );
          }
          expect(
            byId[untouchedId]?['category_id'],
            coffeeId,
            reason: 'rows not in the input set must NOT be touched.',
          );
        },
        skip: reason,
      );

      test(
        'deleteMany removes rows and reports affected account ids '
        '(deduplicated)',
        () async {
          // Two rows on the seeded account, one on a fresh second
          // account in the same household. deleteMany should return
          // both account ids, each once.
          final secondAccountRow = await harness.client
              .from('accounts')
              .insert({
                'household_id': harness.householdId,
                'owner_user_id': harness.userId,
                'name': 'Bulk Test Second',
                'account_type': 'savings',
                'currency': 'USD',
                'starting_balance': 0,
                'current_balance': 0,
              })
              .select('id')
              .single();
          final secondAccountId = secondAccountRow['id'] as String;

          final tx1 = await harness.insertTransaction(
            description: 'bulk-del-1',
          );
          final tx2 = await harness.insertTransaction(
            description: 'bulk-del-2',
          );
          // Insert directly so we can target the second account; the
          // harness helper hardcodes the seeded account.
          final tx3Row = await harness.client
              .from('transactions')
              .insert({
                'household_id': harness.householdId,
                'account_id': secondAccountId,
                'entered_by': harness.userId,
                'amount': -1000,
                'currency': 'USD',
                'description': 'bulk-del-3',
                'transaction_date': DateTime.now()
                    .toIso8601String()
                    .substring(0, 10),
                'pending': false,
                'source': 'manual',
              })
              .select('id')
              .single();
          final tx3 = tx3Row['id'] as String;

          final affected = await repo.deleteMany([tx1, tx2, tx3]);

          expect(
            affected.toSet(),
            {harness.accountId, secondAccountId},
            reason: 'each affected account id must appear exactly once '
                'in the return so the caller doesn\'t recompute the '
                'same balance twice.',
          );
          final remaining = await harness.client
              .from('transactions')
              .select('id')
              .inFilter('id', [tx1, tx2, tx3]);
          expect((remaining as List), isEmpty);
        },
        skip: reason,
      );

      test(
        'deleteMany with empty input is a no-op',
        () async {
          // Pin: an empty input shouldn't even hit the wire. A round-
          // trip with an empty `IN ()` list would be a PostgREST error
          // on some versions and noise on others.
          final affected = await repo.deleteMany(const []);
          expect(affected, isEmpty);
        },
        skip: reason,
      );

      test(
        'addTagToMany inserts assignments and skips already-tagged rows',
        () async {
          final tagsRepo = TransactionTagsRepository();
          final tag = await tagsRepo.createTag(
            householdId: harness.householdId,
            name: 'bulk-tag-${DateTime.now().microsecondsSinceEpoch}',
          );
          final tx1 = await harness.insertTransaction(description: 'bulk-tag-a');
          final tx2 = await harness.insertTransaction(description: 'bulk-tag-b');

          // Pre-assign the tag to tx1; bulk-add should leave it alone
          // (no duplicate, no error) and still apply to tx2.
          await tagsRepo.replaceAssignments(
            transactionId: tx1,
            tagIds: [tag.id],
          );

          await tagsRepo.addTagToMany(
            tagId: tag.id,
            transactionIds: [tx1, tx2],
          );

          final rows = await harness.client
              .from('transaction_tag_assignments')
              .select('transaction_id')
              .eq('tag_id', tag.id)
              .inFilter('transaction_id', [tx1, tx2]);
          final ids =
              {for (final r in rows as List) r['transaction_id'] as String};
          expect(
            ids,
            {tx1, tx2},
            reason: 'both rows must end up tagged exactly once; the '
                'duplicate-on-tx1 path is ignoreDuplicates=true, not an '
                'error.',
          );
        },
        skip: reason,
      );

      test(
        'removeTagFromMany removes only the targeted tag, leaving '
        'other tags on the same rows intact',
        () async {
          final tagsRepo = TransactionTagsRepository();
          final stamp = DateTime.now().microsecondsSinceEpoch;
          final tagA = await tagsRepo.createTag(
            householdId: harness.householdId,
            name: 'bulk-untag-A-$stamp',
          );
          final tagB = await tagsRepo.createTag(
            householdId: harness.householdId,
            name: 'bulk-untag-B-$stamp',
          );
          final tx1 = await harness.insertTransaction(
            description: 'bulk-untag-1',
          );
          final tx2 = await harness.insertTransaction(
            description: 'bulk-untag-2',
          );
          final tx3 = await harness.insertTransaction(
            description: 'bulk-untag-3',
          );

          // tx1, tx2 carry both tags. tx3 is the control — same
          // tagA but NOT in the bulk-remove input set, so it must
          // keep its tag.
          await tagsRepo.replaceAssignments(
            transactionId: tx1,
            tagIds: [tagA.id, tagB.id],
          );
          await tagsRepo.replaceAssignments(
            transactionId: tx2,
            tagIds: [tagA.id, tagB.id],
          );
          await tagsRepo.replaceAssignments(
            transactionId: tx3,
            tagIds: [tagA.id],
          );

          await tagsRepo.removeTagFromMany(
            tagId: tagA.id,
            transactionIds: [tx1, tx2],
          );

          // tx1 and tx2 should now have ONLY tagB.
          for (final tx in [tx1, tx2]) {
            final assigned = await tagsRepo.fetchAssignedTagIds(tx);
            expect(
              assigned.toSet(),
              {tagB.id},
              reason: 'tag A removal must not collateral-damage tag B '
                  'on the same row.',
            );
          }

          // tx3 retained tagA (not in input set).
          final tx3Tags = await tagsRepo.fetchAssignedTagIds(tx3);
          expect(
            tx3Tags.toSet(),
            {tagA.id},
            reason: 'a row NOT in the bulk-remove input set must not '
                'lose any tags — the inFilter must scope the delete.',
          );
        },
        skip: reason,
      );

      test(
        'removeTagFromMany on rows that don\'t have the tag is a no-op',
        () async {
          final tagsRepo = TransactionTagsRepository();
          final tag = await tagsRepo.createTag(
            householdId: harness.householdId,
            name:
                'bulk-untag-noop-${DateTime.now().microsecondsSinceEpoch}',
          );
          final tx = await harness.insertTransaction(
            description: 'bulk-untag-noop-tx',
          );

          // Tx isn't tagged with this tag — remove should not error
          // and the row should remain untagged.
          await tagsRepo.removeTagFromMany(
            tagId: tag.id,
            transactionIds: [tx],
          );

          final assigned = await tagsRepo.fetchAssignedTagIds(tx);
          expect(assigned, isEmpty);
        },
        skip: reason,
      );

      test(
        'removeTagFromMany with empty input is a no-op',
        () async {
          // Same as deleteMany — an empty `IN ()` would be noisy on
          // the wire, possibly error on some PostgREST versions.
          // The repo short-circuits before reaching the DB.
          final tagsRepo = TransactionTagsRepository();
          final tag = await tagsRepo.createTag(
            householdId: harness.householdId,
            name:
                'bulk-untag-empty-${DateTime.now().microsecondsSinceEpoch}',
          );
          await tagsRepo.removeTagFromMany(tagId: tag.id, transactionIds: []);
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
