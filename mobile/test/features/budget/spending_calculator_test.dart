// Unit tests for the pure-Dart port of get_category_spending
// (Phase 4a). Pinned: every contract bullet from the SQL
// function's doc has at least one assertion here.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/budget/services/spending_calculator.dart';
import 'package:mybudget/features/receipts/models/receipt_line_item.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';

void main() {
  // Sane defaults so each test only spells out the fields it
  // cares about.
  Transaction makeTx({
    String id = 't-1',
    String householdId = 'hh-1',
    String accountId = 'a-1',
    int amount = -1000,
    String currency = 'USD',
    String description = 'tx',
    String? categoryId = 'cat-food',
    DateTime? transactionDate,
    String? receiptId,
  }) {
    final date = transactionDate ?? DateTime.utc(2026, 5, 15);
    return Transaction(
      id: id,
      householdId: householdId,
      accountId: accountId,
      amount: amount,
      currency: currency,
      description: description,
      categoryId: categoryId,
      transactionDate: date,
      pending: false,
      source: 'manual',
      receiptId: receiptId,
      createdAt: date,
      updatedAt: date,
    );
  }

  ReceiptLineItem makeLi({
    String id = 'li-1',
    String receiptId = 'r-1',
    String description = 'item',
    int amount = 500,
    String? categoryId = 'cat-food',
    bool isDiscount = false,
    int sortOrder = 0,
  }) {
    return ReceiptLineItem(
      id: id,
      receiptId: receiptId,
      description: description,
      amount: amount,
      categoryId: categoryId,
      isTax: false,
      isTip: false,
      isDiscount: isDiscount,
      sortOrder: sortOrder,
    );
  }

  final from = DateTime.utc(2026, 5, 1);
  final to = DateTime.utc(2026, 5, 31);

  group('Unpaired transactions', () {
    test('one transaction → negated amount under its category', () {
      final result = computeCategorySpending(
        transactions: [makeTx(amount: -2500)],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, {'cat-food': 2500});
    });

    test('multiple in same category → sum', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(id: 't1', amount: -1000),
          makeTx(id: 't2', amount: -3000),
          makeTx(id: 't3', amount: -250),
        ],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, {'cat-food': 4250});
    });

    test('refunds (positive amount) net against debits', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(id: 't1', amount: -5000), // debit
          makeTx(id: 't2', amount: 1000), // refund
        ],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      // -((-5000) + 1000) = 4000
      expect(result, {'cat-food': 4000});
    });

    test('null category_id → excluded from rollup', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(id: 't1', amount: -1000, categoryId: null),
          makeTx(id: 't2', amount: -500, categoryId: 'cat-food'),
        ],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, {'cat-food': 500});
    });
  });

  group('Date filtering (inclusive on both ends)', () {
    test('rows outside [from, to] dropped', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(
            id: 't-early',
            amount: -1000,
            transactionDate: DateTime.utc(2026, 4, 30),
          ),
          makeTx(
            id: 't-in',
            amount: -2000,
            transactionDate: DateTime.utc(2026, 5, 15),
          ),
          makeTx(
            id: 't-late',
            amount: -3000,
            transactionDate: DateTime.utc(2026, 6, 1),
          ),
        ],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, {'cat-food': 2000});
    });

    test('boundary days included on both ends', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(
            id: 't-start',
            amount: -1000,
            transactionDate: from,
          ),
          makeTx(
            id: 't-end',
            amount: -2000,
            transactionDate: to,
          ),
        ],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, {'cat-food': 3000});
    });
  });

  group('Paired receipts — Option B rollup', () {
    test('line items dictate spend; transaction.category is filing-only', () {
      // A paired transaction's own category_id is filing-only.
      // The actual spending hits line-item categories.
      final result = computeCategorySpending(
        transactions: [
          makeTx(
            id: 't-paired',
            amount: -5000,
            categoryId: 'cat-misc',
            receiptId: 'r-1',
          ),
        ],
        lineItemsByReceiptId: {
          'r-1': [
            makeLi(id: 'li-1', amount: 3000, categoryId: 'cat-groceries'),
            makeLi(id: 'li-2', amount: 2000, categoryId: 'cat-household'),
          ],
        },
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      // cat-misc gets nothing — the transaction's category is
      // not the source of truth for paired rows.
      expect(result, {'cat-groceries': 3000, 'cat-household': 2000});
    });

    test('one receipt paired with multiple in-range transactions counts once',
        () {
      // Installments: one receipt, two paired transactions.
      // The receipt's line items should contribute exactly once.
      final result = computeCategorySpending(
        transactions: [
          makeTx(id: 't-leg1', amount: -2500, receiptId: 'r-1'),
          makeTx(id: 't-leg2', amount: -2500, receiptId: 'r-1'),
        ],
        lineItemsByReceiptId: {
          'r-1': [makeLi(amount: 5000, categoryId: 'cat-furniture')],
        },
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, {'cat-furniture': 5000});
    });

    test('discount line item flips sign', () {
      final result = computeCategorySpending(
        transactions: [makeTx(amount: -4500, receiptId: 'r-1')],
        lineItemsByReceiptId: {
          'r-1': [
            makeLi(id: 'li-buy', amount: 5000, categoryId: 'cat-groceries'),
            makeLi(
              id: 'li-coupon',
              amount: 500,
              categoryId: 'cat-groceries',
              isDiscount: true,
            ),
          ],
        },
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, {'cat-groceries': 4500});
    });

    test('paired receipt without cached line items contributes nothing', () {
      // Documented caveat from the project root CLAUDE.md.
      final result = computeCategorySpending(
        transactions: [makeTx(amount: -5000, receiptId: 'r-missing')],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, isEmpty);
    });

    test('line items with null category_id skipped', () {
      final result = computeCategorySpending(
        transactions: [makeTx(amount: -3000, receiptId: 'r-1')],
        lineItemsByReceiptId: {
          'r-1': [
            makeLi(id: 'li-tax', amount: 200, categoryId: null),
            makeLi(id: 'li-tip', amount: 500, categoryId: null),
            makeLi(id: 'li-food', amount: 2300, categoryId: 'cat-dining'),
          ],
        },
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, {'cat-dining': 2300});
    });
  });

  group('FX-aware (multi-currency)', () {
    test('ratesToDisplay null → every row at face (legacy)', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(id: 't-usd', amount: -1000, currency: 'USD'),
          makeTx(id: 't-eur', amount: -1000, currency: 'EUR'),
        ],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      // No conversion — both contribute at face value.
      expect(result, {'cat-food': 2000});
    });

    test('display-currency rows use 1.0 identity even when not in map', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(id: 't-usd', amount: -1000, currency: 'USD'),
        ],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: {'EUR': 1.10},
        displayCurrency: 'USD',
      );
      expect(result, {'cat-food': 1000});
    });

    test('foreign rows convert via the map', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(id: 't-eur', amount: -1000, currency: 'EUR'),
          makeTx(id: 't-gbp', amount: -1000, currency: 'GBP'),
        ],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: {'EUR': 1.10, 'GBP': 1.25},
        displayCurrency: 'USD',
      );
      // EUR: 1000 * 1.10 = 1100; GBP: 1000 * 1.25 = 1250; total 2350.
      expect(result, {'cat-food': 2350});
    });

    test('missing rate + non-null map → exclude (not lie at 1.0)', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(id: 't-usd', amount: -1000, currency: 'USD'),
          makeTx(id: 't-jpy', amount: -1000, currency: 'JPY'),
        ],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: {'EUR': 1.10},
        displayCurrency: 'USD',
      );
      // JPY row dropped (no rate); USD row counts at identity.
      expect(result, {'cat-food': 1000});
    });

    test('line items inherit the paired transaction currency', () {
      final result = computeCategorySpending(
        transactions: [
          makeTx(amount: -3000, currency: 'EUR', receiptId: 'r-1'),
        ],
        lineItemsByReceiptId: {
          'r-1': [makeLi(amount: 3000, categoryId: 'cat-dining')],
        },
        from: from,
        to: to,
        ratesToDisplay: {'EUR': 1.10},
        displayCurrency: 'USD',
      );
      // 3000 EUR * 1.10 EUR→USD = 3300. The line item picked up
      // the transaction's currency for FX.
      expect(result, {'cat-dining': 3300});
    });
  });

  group('Empty inputs', () {
    test('no transactions → empty result', () {
      final result = computeCategorySpending(
        transactions: const [],
        lineItemsByReceiptId: const {},
        from: from,
        to: to,
        ratesToDisplay: null,
        displayCurrency: 'USD',
      );
      expect(result, isEmpty);
    });
  });
}
