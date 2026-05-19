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
import 'package:mybudget/features/reports/services/monthly_report_builder.dart';
import 'package:mybudget/features/transactions/models/category.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';

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
}) {
  final ts = DateTime(2026, 1, 1);
  return Transaction(
    id: id,
    householdId: 'h',
    accountId: 'a',
    amount: amount,
    currency: 'USD',
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
      final r = buildMonthlyReport(
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
        final r = buildMonthlyReport(
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
      final r = buildMonthlyReport(
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
      final r = buildMonthlyReport(
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
        final r = buildMonthlyReport(
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
        final r = buildMonthlyReport(
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
      final r = buildMonthlyReport(
        monthStart: monthStart,
        monthEnd: monthEnd,
        householdName: 'Test',
        transactionsInMonth: const [],
        spendingByCategory: const {},
        categoryLookup: const {},
      );
      expect(r.byCategory, isEmpty);
    });
  });
}
