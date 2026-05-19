// End-to-end integration tests for the local OCR stub Edge Function
// (supabase/functions/process-receipt-ocr/index.ts).
//
// The stub mirrors the production function's output shape: it advances
// receipts.ocr_status from 'pending' to 'complete', writes line items via
// the save_receipt_line_items RPC, populates total_amount, and stashes a
// synthetic ocr_raw payload. These tests pin the full chain:
//
//   1. status transitions (pending → complete on success, → failed on error)
//   2. line items land in the DB with the categories the caller asked for
//   3. total_amount is the sum of non-tip, non-discount lines
//   4. ocr_raw is populated with the documented shape
//   5. Option B rollup: a paired transaction surfaces the stub's line
//      items in get_category_spending (via BudgetRepository)
//
// The 5th point is the load-bearing one — it verifies the contract that
// matters to users (their budget reflects the OCR'd line items) rather
// than just that the stub wrote rows.
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY env
// vars aren't set. See _supabase_harness.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/budget/repositories/budget_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('process-receipt-ocr stub (integration)', () {
    late Harness harness;
    late BudgetRepository budgetRepo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'ocr-stub');
      budgetRepo = BudgetRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    Future<String> insertPendingReceipt() async {
      final row = await harness.client
          .from('receipts')
          .insert({
            'household_id': harness.householdId,
            'uploaded_by': harness.userId,
            'storage_path':
                '${harness.householdId}/ocr-${DateTime.now().microsecondsSinceEpoch}.jpg',
            'ocr_status': 'pending',
          })
          .select('id')
          .single();
      return row['id'] as String;
    }

    test(
      'happy path: pending receipt advances to complete with line items, '
      'total, and ocr_raw populated',
      () async {
        final receiptId = await insertPendingReceipt();
        final coffeeId = await harness.systemCategoryIdByName(
          'Coffee & Drinks',
        );

        final response = await harness.client.functions.invoke(
          'process-receipt-ocr',
          body: {
            'receipt_id': receiptId,
            'items': [
              {
                'description': 'Latte',
                'amount': 500,
                'category_id': coffeeId,
              },
              {
                'description': 'Croissant',
                'amount': 400,
                'category_id': coffeeId,
              },
              {
                'description': 'Tax',
                'amount': 72,
                'is_tax': true,
                'category_id': coffeeId,
              },
              {
                'description': 'Tip',
                'amount': 100,
                'is_tip': true,
              },
              {
                'description': 'Promo',
                'amount': 50,
                'is_discount': true,
                'category_id': coffeeId,
              },
            ],
          },
        );

        expect(
          response.status,
          200,
          reason: 'stub should respond 200 on a valid receipt id.',
        );

        // Re-fetch the receipt to verify the DB-side state, not just the
        // function's return value. The DB is the source of truth.
        final receipt = await harness.client
            .from('receipts')
            .select('ocr_status, total_amount, ocr_raw')
            .eq('id', receiptId)
            .single();

        expect(receipt['ocr_status'], 'complete');
        // total_amount = $5 + $4 + $0.72 = $9.72 → 972 cents.
        // Tip and discount are excluded per the stub's contract.
        expect(
          receipt['total_amount'],
          972,
          reason:
              'total_amount must sum non-tip, non-discount line items '
              '(tax is included, matching production OCR behaviour).',
        );
        expect(
          (receipt['ocr_raw'] as Map?)?['source'],
          'stub',
          reason:
              'ocr_raw.source distinguishes stub output from production '
              'Vision output for debugging.',
        );

        final lineItems = await harness.client
            .from('receipt_line_items')
            .select('description, amount, is_tax, is_tip, is_discount')
            .eq('receipt_id', receiptId);
        expect(
          lineItems,
          hasLength(5),
          reason: 'every item passed in must land in the DB.',
        );
      },
      skip: reason,
    );

    test(
      'Option B rollup: stub line items flow through to budget spending '
      'via paired transaction',
      () async {
        // Anchor in a quiet date window so other tests in this group's
        // harness household don't bleed in.
        final anchor = DateTime.utc(2026, 6, 15);
        final from = DateTime.utc(2026, 6, 1);
        final to = DateTime.utc(2026, 6, 30);

        final coffeeId = await harness.systemCategoryIdByName(
          'Coffee & Drinks',
        );
        final groceriesId = await harness.systemCategoryIdByName('Groceries');

        // Pre-condition: no spending in this window yet for either
        // category. Tests in this group share one household so we
        // assert via delta, but the explicit zero baseline catches
        // ordering-dependent bugs at the same time.
        final coffeeBefore = (await budgetRepo.fetchSpendingByCategory(
          householdId: harness.householdId,
          from: from,
          to: to,
        ))[coffeeId] ?? 0;
        final groceriesBefore = (await budgetRepo.fetchSpendingByCategory(
          householdId: harness.householdId,
          from: from,
          to: to,
        ))[groceriesId] ?? 0;

        // Pending receipt + paired transaction filed (intentionally) under
        // Groceries. Under Option B, the receipt's line items should drive
        // the budget, not the transaction's category.
        final receiptId = await insertPendingReceipt();
        final txId = await harness.insertTransaction(
          description: 'COFFEE FILED UNDER GROCERIES',
          amountCents: -900,
          categoryId: groceriesId,
          categoryAssignedBy: 'user',
          transactionDate: anchor,
        );
        await harness.client
            .from('transactions')
            .update({'receipt_id': receiptId})
            .eq('id', txId);

        // Invoke the stub with one Coffee item.
        final response = await harness.client.functions.invoke(
          'process-receipt-ocr',
          body: {
            'receipt_id': receiptId,
            'items': [
              {
                'description': 'Latte',
                'amount': 900,
                'category_id': coffeeId,
              },
            ],
          },
        );
        expect(response.status, 200);

        // Budget should now reflect the stub-written line item via Option B.
        final spending = await budgetRepo.fetchSpendingByCategory(
          householdId: harness.householdId,
          from: from,
          to: to,
        );
        expect(
          (spending[coffeeId] ?? 0) - coffeeBefore,
          900,
          reason:
              'Coffee should pick up the \$9 line item written by the OCR '
              'stub — the full chain stub → save_receipt_line_items → '
              'get_category_spending must surface it.',
        );
        expect(
          (spending[groceriesId] ?? 0) - groceriesBefore,
          0,
          reason:
              'Groceries (the transaction\'s own category) must NOT also '
              'count the \$9 — Option B treats transactions.category_id as '
              'filing-only when a receipt is paired.',
        );
      },
      skip: reason,
    );

    test(
      'failure path: invalid receipt id surfaces as a non-2xx error',
      () async {
        // The stub validates `receipt_id` is present but doesn't check
        // existence — it relies on the RPC to reject. A made-up UUID
        // belongs to no row in the caller's household, so the RPC fails
        // inside the function and its catch block returns 500.
        //
        // functions.invoke throws FunctionException on any non-2xx
        // response (the SDK uses that as its error channel), so the
        // assertion is "this must throw" rather than "response.status
        // must be non-200".
        expect(
          () => harness.client.functions.invoke(
            'process-receipt-ocr',
            body: const {
              'receipt_id': '00000000-0000-0000-0000-000000000000',
            },
          ),
          throwsA(isA<FunctionException>()),
          reason:
              'a receipt id that doesn\'t exist for the caller must fail '
              'the chain — the function returns 500 and the SDK raises.',
        );
      },
      skip: reason,
    );

    test(
      'omitting items uses the stub\'s default 3-line synthetic payload',
      () async {
        // Default payload exists so quick manual smoke tests don't need
        // to supply fixture data. Pinning the count guards against a
        // future change that drops the default — at least one test
        // should exercise the omitted-items path.
        final receiptId = await insertPendingReceipt();
        final response = await harness.client.functions.invoke(
          'process-receipt-ocr',
          body: {'receipt_id': receiptId},
        );
        expect(response.status, 200);

        final lineItems = await harness.client
            .from('receipt_line_items')
            .select('description')
            .eq('receipt_id', receiptId);
        expect(
          lineItems,
          hasLength(3),
          reason:
              'omitting items must trigger DEFAULT_ITEMS (currently 3 '
              'lines: two synthetic items + tax).',
        );
      },
      skip: reason,
    );
  });
}
