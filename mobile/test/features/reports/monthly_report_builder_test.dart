// Tests for buildMonthlyReport — the pure function that turns raw
// household data into a MonthlyReportData. Pins the contracts that
// the screen and PDF renderer hang off:
//
//   * income / expenses exclude transfer legs (migration 030)
//   * by-category totals come from the Option B RPC map verbatim,
//     but stale ids missing from the category lookup are skipped
//   * an Uncategorized bucket is synthesised from unpaired +
//     uncategorised debits, NOT from paired-but-uncategorised
//     (those will get a category once line items are filled in,
//     and we'd otherwise double-count)
//   * negative net_cents categories from the RPC (refunds exceed
//     spend) are dropped — they'd render as a phantom positive
//     row otherwise
//   * by-category rows are sorted descending by cents

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/accounts/models/account.dart';
import 'package:mybudget/features/reports/models/monthly_report_data.dart';
import 'package:mybudget/features/reports/services/monthly_report_builder.dart';
import 'package:mybudget/features/transactions/models/category.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';

/// Wraps [buildMonthlyReport] with sane defaults for the closing-
/// balance inputs. Tests that don't care about closing balances
/// don't have to thread the new params; tests that DO care override
/// them explicitly.
MonthlyReportData _build({
  required DateTime monthStart,
  required DateTime monthEnd,
  required String householdName,
  required List<Transaction> transactionsInMonth,
  required Map<String, int> spendingByCategory,
  required Map<String, Category> categoryLookup,
  List<Account> accounts = const [],
  List<Transaction> transactionsAfterMonth = const [],
  DateTime? closingAsOf,
  String displayCurrency = 'USD',
  Map<String, double> ratesToDisplay = const {},
}) {
  return buildMonthlyReport(
    monthStart: monthStart,
    monthEnd: monthEnd,
    householdName: householdName,
    transactionsInMonth: transactionsInMonth,
    spendingByCategory: spendingByCategory,
    categoryLookup: categoryLookup,
    accounts: accounts,
    transactionsAfterMonth: transactionsAfterMonth,
    closingAsOf: closingAsOf ?? monthEnd,
    displayCurrency: displayCurrency,
    ratesToDisplay: ratesToDisplay,
  );
}

Category _cat(String id, String name, {String? color}) => Category(
  id: id,
  name: name,
  isIncome: false,
  sortOrder: 0,
  color: color,
);

Transaction _tx({
  required int amount,
  required DateTime date,
  String id = 't',
  String? transferId,
  String? categoryId,
  String? receiptId,
  String currency = 'USD',
}) {
  final ts = DateTime(2026, 1, 1);
  return Transaction(
    id: id,
    householdId: 'h',
    accountId: 'a',
    amount: amount,
    currency: currency,
    description: 'desc',
    transactionDate: date,
    pending: false,
    source: 'manual',
    createdAt: ts,
    updatedAt: ts,
    categoryId: categoryId,
    receiptId: receiptId,
    transferId: transferId,
  );
}

void main() {
  final monthStart = DateTime(2026, 5, 1);
  final monthEnd = DateTime(2026, 5, 31);
  final anyDay = DateTime(2026, 5, 15);

  group('buildMonthlyReport', () {
    test('income and expenses sum signed amounts on non-transfer rows', () {
      final r = _build(
        monthStart: monthStart,
        monthEnd: monthEnd,
        householdName: 'Test',
        transactionsInMonth: [
          _tx(amount: 200000, date: anyDay, id: 'salary'),
          _tx(amount: -3500, date: anyDay, id: 'groceries'),
          _tx(amount: -1200, date: anyDay, id: 'coffee'),
          _tx(amount: 800, date: anyDay, id: 'refund'),
        ],
        spendingByCategory: const {},
        categoryLookup: const {},
      );
      expect(r.incomeCents, 200800);
      expect(r.expensesCents, 4700);
      expect(r.netChangeCents, 200800 - 4700);
    });

    test(
      'transfer legs are excluded from BOTH income and expenses and counted '
      'in transferLegCount',
      () {
        final r = _build(
          monthStart: monthStart,
          monthEnd: monthEnd,
          householdName: 'Test',
          transactionsInMonth: [
            // Real activity.
            _tx(amount: 100000, date: anyDay, id: 'salary'),
            _tx(amount: -2000, date: anyDay, id: 'groceries'),
            // Two transfer legs — must NOT count.
            _tx(amount: -50000, date: anyDay, id: 'from', transferId: 'X'),
            _tx(amount: 50000, date: anyDay, id: 'to', transferId: 'X'),
          ],
          spendingByCategory: const {},
          categoryLookup: const {},
        );
        expect(
          r.incomeCents,
          100000,
          reason: 'salary only; the +\$500 transfer leg must not count.',
        );
        expect(
          r.expensesCents,
          2000,
          reason: 'groceries only; the -\$500 transfer leg must not count.',
        );
        expect(r.transferLegCount, 2);
      },
    );

    test('by-category rows come from the RPC map, joined by id', () {
      final groceries = _cat('g', 'Groceries', color: '#22c55e');
      final coffee = _cat('c', 'Coffee', color: '#f59e0b');
      final r = _build(
        monthStart: monthStart,
        monthEnd: monthEnd,
        householdName: 'Test',
        transactionsInMonth: const [],
        spendingByCategory: const {'g': 12000, 'c': 3000},
        categoryLookup: {'g': groceries, 'c': coffee},
      );
      expect(r.byCategory, hasLength(2));
      // Sorted by cents descending.
      expect(r.byCategory.first.name, 'Groceries');
      expect(r.byCategory.first.cents, 12000);
      expect(r.byCategory.first.colorHex, '#22c55e');
      expect(r.byCategory.last.name, 'Coffee');
      expect(r.byCategory.last.cents, 3000);
    });

    test('RPC ids missing from the lookup are silently skipped', () {
      final r = _build(
        monthStart: monthStart,
        monthEnd: monthEnd,
        householdName: 'Test',
        transactionsInMonth: const [],
        // 'phantom' has no entry in categoryLookup — a stale id from
        // a deleted category. Shouldn't crash; just drop the row.
        spendingByCategory: const {'g': 1000, 'phantom': 9999},
        categoryLookup: {'g': _cat('g', 'Groceries')},
      );
      expect(r.byCategory.map((row) => row.name), ['Groceries']);
    });

    test(
      'negative net_cents from the RPC (refunds exceed spend) drops the row',
      () {
        // The budget UI clamps these to zero rather than showing a
        // negative spending bar; the report follows suit.
        final r = _build(
          monthStart: monthStart,
          monthEnd: monthEnd,
          householdName: 'Test',
          transactionsInMonth: const [],
          spendingByCategory: const {'g': -500},
          categoryLookup: {'g': _cat('g', 'Groceries')},
        );
        expect(r.byCategory, isEmpty);
      },
    );

    test(
      'Uncategorized bucket counts unpaired + uncategorised debits only',
      () {
        final r = _build(
          monthStart: monthStart,
          monthEnd: monthEnd,
          householdName: 'Test',
          transactionsInMonth: [
            // Should count.
            _tx(amount: -1500, date: anyDay, id: 'unpaired-uncat'),
            // Should NOT count: paired (Option B will categorise it via
            // line items once they're filled in).
            _tx(
              amount: -2000,
              date: anyDay,
              id: 'paired-uncat',
              receiptId: 'r1',
            ),
            // Should NOT count: already has a category (lives in
            // byCategory via the RPC map, not in Uncategorized).
            _tx(
              amount: -500,
              date: anyDay,
              id: 'categorised',
              categoryId: 'g',
            ),
            // Should NOT count: transfer leg.
            _tx(amount: -800, date: anyDay, id: 'leg', transferId: 'X'),
            // Should NOT count: positive amount.
            _tx(amount: 1000, date: anyDay, id: 'income'),
          ],
          spendingByCategory: const {},
          categoryLookup: const {},
        );
        expect(r.byCategory, hasLength(1));
        expect(r.byCategory.single.name, 'Uncategorized');
        expect(r.byCategory.single.cents, 1500);
      },
    );

    test('no Uncategorized bucket appears when total is zero', () {
      final r = _build(
        monthStart: monthStart,
        monthEnd: monthEnd,
        householdName: 'Test',
        transactionsInMonth: const [],
        spendingByCategory: const {},
        categoryLookup: const {},
      );
      expect(r.byCategory, isEmpty);
    });

    // ── Multi-currency conversion (slice 2 of the multi-currency arc) ──
    //
    // The report converts per-transaction amounts to the display
    // currency before aggregating income/expenses/uncategorized.
    // Transactions in a currency that has no rate to the display
    // currency are EXCLUDED from those totals (silently including
    // them at rate=1 would lie) and their currency surfaces in
    // missingRateCurrencies so the renderer can footnote the gap.

    group('multi-currency aggregation', () {
      test('converts foreign-currency transactions via the rate map', () {
        // $1,000 USD salary + €500 EUR side-income. Display USD,
        // EUR→USD 1.0573. Income should sum the converted amounts.
        final r = _build(
          monthStart: monthStart,
          monthEnd: monthEnd,
          householdName: 'Test',
          transactionsInMonth: [
            _tx(amount: 100000, date: anyDay, id: 'us-salary'),
            _tx(
              amount: 50000,
              date: anyDay,
              id: 'eu-side',
              currency: 'EUR',
            ),
          ],
          spendingByCategory: const {},
          categoryLookup: const {},
          displayCurrency: 'USD',
          ratesToDisplay: const {'EUR': 1.0573},
        );
        expect(r.incomeCents, 100000 + 52865); // 50000 × 1.0573
        expect(r.displayCurrency, 'USD');
        expect(r.missingRateCurrencies, isEmpty);
      });

      test(
        'missing-rate transactions are EXCLUDED from totals and surface '
        'in missingRateCurrencies',
        () {
          // ¥10,000 JPY expense with no JPY→USD rate. The total
          // must NOT silently include it (would imply rate=1).
          final r = _build(
            monthStart: monthStart,
            monthEnd: monthEnd,
            householdName: 'Test',
            transactionsInMonth: [
              _tx(amount: -3500, date: anyDay, id: 'us-groceries'),
              _tx(
                amount: -1000000,
                date: anyDay,
                id: 'jp-noodles',
                currency: 'JPY',
              ),
            ],
            spendingByCategory: const {},
            categoryLookup: const {},
            displayCurrency: 'USD',
            ratesToDisplay: const {},
          );
          expect(
            r.expensesCents,
            3500,
            reason: 'JPY must not contribute at rate=1; only the USD '
                'expense counts toward the converted total.',
          );
          expect(r.missingRateCurrencies, {'JPY'});
        },
      );

      test('uncategorized bucket converts too', () {
        // Unpaired, uncategorised EUR expense — must convert via
        // the rate map before counting toward Uncategorized.
        final r = _build(
          monthStart: monthStart,
          monthEnd: monthEnd,
          householdName: 'Test',
          transactionsInMonth: [
            _tx(
              amount: -10000,
              date: anyDay,
              id: 'eu-misc',
              currency: 'EUR',
            ),
          ],
          spendingByCategory: const {},
          categoryLookup: const {},
          displayCurrency: 'USD',
          ratesToDisplay: const {'EUR': 1.05},
        );
        // 10000 × 1.05 = 10500 cents converted.
        expect(r.byCategory.single.name, 'Uncategorized');
        expect(r.byCategory.single.cents, 10500);
      });

      test('USD-only household with USD display sees no conversion', () {
        // Slice 1 promise: a single-currency household is unaffected.
        // No rates supplied, no missing-rate warnings emitted.
        final r = _build(
          monthStart: monthStart,
          monthEnd: monthEnd,
          householdName: 'Test',
          transactionsInMonth: [
            _tx(amount: 100000, date: anyDay, id: 'salary'),
            _tx(amount: -3500, date: anyDay, id: 'groceries'),
          ],
          spendingByCategory: const {},
          categoryLookup: const {},
          // Defaults: displayCurrency='USD', ratesToDisplay={}.
        );
        expect(r.incomeCents, 100000);
        expect(r.expensesCents, 3500);
        expect(r.missingRateCurrencies, isEmpty);
      });

      test(
        'transfer legs are still excluded regardless of currency / rate',
        () {
          // A transfer leg in EUR (uncommon but legal) must not
          // count as income/expense even when a rate IS available.
          // The transfer exclusion supersedes the FX path.
          final r = _build(
            monthStart: monthStart,
            monthEnd: monthEnd,
            householdName: 'Test',
            transactionsInMonth: [
              _tx(amount: 100000, date: anyDay, id: 'real-income'),
              _tx(
                amount: 50000,
                date: anyDay,
                id: 'eu-leg',
                currency: 'EUR',
                transferId: 'X',
              ),
            ],
            spendingByCategory: const {},
            categoryLookup: const {},
            displayCurrency: 'USD',
            ratesToDisplay: const {'EUR': 1.05},
          );
          expect(r.incomeCents, 100000);
          expect(r.transferLegCount, 1);
        },
      );
    });
  });
}
