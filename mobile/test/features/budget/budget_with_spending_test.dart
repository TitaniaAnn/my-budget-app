// Tests for BudgetWithSpending getters (progress, remaining, over-budget) and
// the projectEndOfPeriodSpend math.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/budget/models/budget.dart';
import 'package:mybudget/features/budget/providers/budget_provider.dart';

Budget _budget({required int amount, BudgetPeriod period = BudgetPeriod.monthly}) {
  return Budget(
    id: 'b',
    householdId: 'h',
    categoryId: 'c',
    amount: amount,
    period: period,
    startDate: DateTime(2026, 4, 1),
    createdBy: 'u',
  );
}

BudgetWithSpending _bws({
  required int budgetCents,
  required int spentCents,
  int? projectedCents,
}) {
  final b = _budget(amount: budgetCents);
  return BudgetWithSpending(
    budget: b,
    spentCents: spentCents,
    projectedCents: projectedCents ?? spentCents,
    periodFrom: DateTime(2026, 4, 1),
    periodTo: DateTime(2026, 4, 30),
    categoryName: 'Groceries',
    categoryColor: null,
    categoryIcon: null,
  );
}

void main() {
  group('BudgetWithSpending', () {
    test('remainingCents = budget − spent', () {
      final b = _bws(budgetCents: 50000, spentCents: 20000);
      expect(b.remainingCents, 30000);
    });

    test('remainingCents goes negative when over-budget', () {
      final b = _bws(budgetCents: 50000, spentCents: 75000);
      expect(b.remainingCents, -25000);
    });

    test('progress is fraction of budget consumed, 0..1', () {
      expect(_bws(budgetCents: 10000, spentCents: 5000).progress, 0.5);
      expect(_bws(budgetCents: 10000, spentCents: 0).progress, 0);
      expect(_bws(budgetCents: 10000, spentCents: 10000).progress, 1);
    });

    test('progress clamps to 1 when over-budget', () {
      // Visual progress bar shouldn't exceed 100%.
      expect(_bws(budgetCents: 10000, spentCents: 25000).progress, 1.0);
    });

    test('progress is 0 when budget amount is 0', () {
      expect(_bws(budgetCents: 0, spentCents: 100).progress, 0);
    });

    test('isOverBudget triggers strictly above the limit', () {
      expect(_bws(budgetCents: 100, spentCents: 100).isOverBudget, isFalse);
      expect(_bws(budgetCents: 100, spentCents: 101).isOverBudget, isTrue);
    });

    test('isProjectedOver compares projected vs budget', () {
      final b = _bws(
        budgetCents: 10000,
        spentCents: 5000,
        projectedCents: 12000,
      );
      expect(b.isProjectedOver, isTrue);
      expect(b.isOverBudget, isFalse);
    });

    test('projectedProgress clamps to 1 just like progress', () {
      final b = _bws(
        budgetCents: 10000,
        spentCents: 5000,
        projectedCents: 30000,
      );
      expect(b.projectedProgress, 1.0);
    });
  });

  group('projectEndOfPeriodSpend', () {
    final from = DateTime(2026, 4, 1);
    final to = DateTime(2026, 4, 30); // 30-day period

    test('extrapolates from current burn rate', () {
      // 1/3 of the way through (day 10 of 30), spent $100 → projected $300.
      final result = projectEndOfPeriodSpend(
        spentCents: 10000,
        from: from,
        to: to,
        now: DateTime(2026, 4, 10),
      );
      expect(result, 30000);
    });

    test('returns spentCents on the last day of the period', () {
      final result = projectEndOfPeriodSpend(
        spentCents: 10000,
        from: from,
        to: to,
        now: DateTime(2026, 4, 30),
      );
      expect(result, 10000);
    });

    test('returns spentCents past the end of the period', () {
      final result = projectEndOfPeriodSpend(
        spentCents: 10000,
        from: from,
        to: to,
        now: DateTime(2026, 5, 5),
      );
      expect(result, 10000);
    });

    test('returns spentCents before the period starts', () {
      // elapsed becomes <= 0; we don't extrapolate from a phantom rate.
      final result = projectEndOfPeriodSpend(
        spentCents: 10000,
        from: from,
        to: to,
        now: DateTime(2026, 3, 25),
      );
      expect(result, 10000);
    });

    test('on day 1 projects spend × period length', () {
      // day 1 of 30, spent $30 → projected $30 * 30 / 1 = $900.
      final result = projectEndOfPeriodSpend(
        spentCents: 3000,
        from: from,
        to: to,
        now: from,
      );
      expect(result, 90000);
    });

    test('handles single-day periods (from == to)', () {
      // totalDays = 1, elapsed = 1 → returns spentCents unchanged.
      final result = projectEndOfPeriodSpend(
        spentCents: 5000,
        from: DateTime(2026, 4, 15),
        to: DateTime(2026, 4, 15),
        now: DateTime(2026, 4, 15),
      );
      expect(result, 5000);
    });

    test('zero spend stays zero', () {
      expect(
        projectEndOfPeriodSpend(
          spentCents: 0,
          from: from,
          to: to,
          now: DateTime(2026, 4, 10),
        ),
        0,
      );
    });
  });
}
