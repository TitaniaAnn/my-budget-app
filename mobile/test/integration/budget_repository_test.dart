// Integration tests for BudgetRepository.fetchSpendingByCategory.
//
// Pins the Option B semantics introduced in migration 026: a
// transaction with a receipt attached has its budget impact
// derived from receipt_line_items.category_id (with is_discount
// flipping sign), NOT from transactions.category_id. Unpaired
// transactions still aggregate directly.
//
// These are the riskiest cases because they exercise the SQL
// join across three tables (transactions ⋈ receipts ⋈
// receipt_line_items) — exactly the kind of behaviour that
// mocks can't honestly verify.
//
// Skipped when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY env
// vars aren't set.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/budget/repositories/budget_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('BudgetRepository (integration)', () {
    late Harness harness;
    late BudgetRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'budget-repo');
      repo = BudgetRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    // ─── fetchSpendingByCategory under Option B ──────────────────────────

    group('fetchSpendingByCategory (Option B rollup)', () {
      // Anchor date used by every test below — keeps the date window
      // tight and deterministic, away from "today".
      final anchor = DateTime.utc(2026, 5, 10);
      // Date window covering the anchor with slack on either side.
      final from = DateTime.utc(2026, 5, 1);
      final to = DateTime.utc(2026, 5, 31);

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

      Future<String> insertLineItem({
        required String receiptId,
        required int amountCents,
        required String categoryId,
        bool isDiscount = false,
      }) async {
        final row = await harness.client
            .from('receipt_line_items')
            .insert({
              'receipt_id': receiptId,
              'description': 'test item',
              'amount': amountCents,
              'category_id': categoryId,
              'is_tax': false,
              'is_tip': false,
              'is_discount': isDiscount,
              'sort_order': 0,
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

      // Tests in this group share a single harness household, so prior
      // tests' rows are still present when later ones run. Assertions
      // therefore measure the DELTA each test introduces, not the
      // absolute value — much more robust than per-test cleanup.
      Future<int> spendingFor(String categoryId) async {
        final result = await repo.fetchSpendingByCategory(
          householdId: harness.householdId,
          from: from,
          to: to,
        );
        return result[categoryId] ?? 0;
      }

      test('unpaired transaction aggregates under its category', () async {
        final groceriesId = await harness.systemCategoryIdByName('Groceries');
        final before = await spendingFor(groceriesId);

        await harness.insertTransaction(
          description: 'UNPAIRED GROCERIES',
          amountCents: -5000,
          categoryId: groceriesId,
          categoryAssignedBy: 'user',
          transactionDate: anchor,
        );

        final after = await spendingFor(groceriesId);
        expect(
          after - before,
          5000,
          reason:
              'an unpaired transaction must contribute exactly its '
              'amount via its own category_id — Option B only changes '
              'paired rows.',
        );
      }, skip: reason);

      test('paired transaction routes spending through its line items, '
          'NOT its own category_id', () async {
        // Tx is filed under Groceries but its receipt has line items
        // under Coffee — only Coffee should reflect the spend.
        final groceriesId = await harness.systemCategoryIdByName('Groceries');
        final coffeeId = await harness.systemCategoryIdByName(
          'Coffee & Drinks',
        );
        final groceriesBefore = await spendingFor(groceriesId);
        final coffeeBefore = await spendingFor(coffeeId);

        final receiptId = await insertReceipt();
        final txId = await harness.insertTransaction(
          description: 'COFFEE RUN FILED UNDER GROCERIES',
          amountCents: -2000,
          categoryId: groceriesId,
          categoryAssignedBy: 'user',
          transactionDate: anchor,
        );
        await pair(txId, receiptId);
        await insertLineItem(
          receiptId: receiptId,
          amountCents: 1800,
          categoryId: coffeeId,
        );

        final groceriesAfter = await spendingFor(groceriesId);
        final coffeeAfter = await spendingFor(coffeeId);

        expect(
          coffeeAfter - coffeeBefore,
          1800,
          reason:
              'paired tx must contribute via its line items — Coffee '
              'should gain exactly the \$18 line item amount.',
        );
        expect(
          groceriesAfter - groceriesBefore,
          0,
          reason:
              'a paired transaction must NOT also count under its own '
              'category_id — Groceries should not move when only line '
              'items under Coffee are added.',
        );
      }, skip: reason);

      test('is_discount line subtracts from its category', () async {
        final coffeeId = await harness.systemCategoryIdByName(
          'Coffee & Drinks',
        );
        final before = await spendingFor(coffeeId);

        final receiptId = await insertReceipt();
        final txId = await harness.insertTransaction(
          description: 'COFFEE WITH PROMO',
          amountCents: -1500,
          transactionDate: anchor,
        );
        await pair(txId, receiptId);
        // $20 coffee, $5 promo discount → $15 net spent in Coffee.
        await insertLineItem(
          receiptId: receiptId,
          amountCents: 2000,
          categoryId: coffeeId,
        );
        await insertLineItem(
          receiptId: receiptId,
          amountCents: 500,
          categoryId: coffeeId,
          isDiscount: true,
        );

        final after = await spendingFor(coffeeId);
        expect(
          after - before,
          1500,
          reason:
              'is_discount lines must subtract from their category — '
              '\$20 spent minus \$5 promo = \$15 net delta.',
        );
      }, skip: reason);

      test(
        'paired transaction with no line items contributes nothing',
        () async {
          // Documented Option B caveat — without at least one line item
          // a paired transaction simply doesn't show up in budgets.
          // Receipts with empty line item lists are a real intermediate
          // state (just-uploaded, OCR pending) so this matters.
          final groceriesId = await harness.systemCategoryIdByName('Groceries');
          final before = await spendingFor(groceriesId);

          final receiptId = await insertReceipt();
          final txId = await harness.insertTransaction(
            description: 'JUST UPLOADED, NO ITEMS YET',
            amountCents: -7000,
            categoryId: groceriesId,
            categoryAssignedBy: 'user',
            transactionDate: anchor,
          );
          await pair(txId, receiptId);

          final after = await spendingFor(groceriesId);
          expect(
            after - before,
            0,
            reason:
                'paired-with-no-line-items must contribute 0 to '
                'Groceries — the \$70 parent tx amount should be '
                'invisible without line items.',
          );
        },
        skip: reason,
      );

      test(
        'line item from a receipt outside the date window is excluded',
        () async {
          // The join filters by the parent transaction's date, not the
          // receipt's. A line item from a receipt whose tx is before
          // the window must NOT appear — otherwise editing line items
          // on an old receipt would silently change last month's budget.
          final coffeeId = await harness.systemCategoryIdByName(
            'Coffee & Drinks',
          );
          final receiptId = await insertReceipt();
          // Tx date deliberately outside the [from, to] window.
          final outsideTxId = await harness.insertTransaction(
            description: 'OLD COFFEE',
            amountCents: -1000,
            transactionDate: DateTime.utc(2026, 1, 15),
          );
          await pair(outsideTxId, receiptId);
          await insertLineItem(
            receiptId: receiptId,
            amountCents: 999999,
            categoryId: coffeeId,
          );

          final result = await repo.fetchSpendingByCategory(
            householdId: harness.householdId,
            from: from,
            to: to,
          );
          // The $9999.99 line item must not have leaked in.
          expect(
            (result[coffeeId] ?? 0),
            lessThan(999999),
            reason:
                'a line item from a receipt whose paired tx is outside '
                '[from, to] must NOT contribute to spending in the window.',
          );
        },
        skip: reason,
      );
    });
  });
}
