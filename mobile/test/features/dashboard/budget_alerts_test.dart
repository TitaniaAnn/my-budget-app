// Tests for classifyBudgetAlerts — the pure function powering the
// dashboard's Budget Health surface.
//
// Contracts pinned:
//   * three buckets (over → projected over → approaching limit), in
//     priority order, never overlapping;
//   * budgets that fail all three conditions are dropped;
//   * within each bucket, the most-urgent row sorts first;
//   * a budget meeting multiple conditions (e.g. already-over AND
//     projected-over) appears in exactly one bucket — the more
//     urgent one.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/budget/models/budget.dart';
import 'package:mybudget/features/budget/providers/budget_provider.dart';
import 'package:mybudget/features/dashboard/services/budget_alerts.dart';

BudgetWithSpending _bws({
  required String id,
  required int budgetCents,
  required int spentCents,
  int? projectedCents,
  String categoryName = 'Cat',
}) {
  final b = Budget(
    id: id,
    householdId: 'h',
    categoryId: id,
    amount: budgetCents,
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 4, 1),
    createdBy: 'u',
  );
  return BudgetWithSpending(
    budget: b,
    spentCents: spentCents,
    projectedCents: projectedCents ?? spentCents,
    periodFrom: DateTime(2026, 4, 1),
    periodTo: DateTime(2026, 4, 30),
    categoryName: categoryName,
    categoryColor: null,
    categoryIcon: null,
    // Default cap to the budget amount so single-currency tests
    // don't have to thread FX through; multi-currency cases (none
    // here) would override.
    capCents: budgetCents,
  );
}

void main() {
  group('classifyBudgetAlerts', () {
    test(
      'drops budgets that are fine: under budget AND not projected over '
      'AND below 80% progress',
      () {
        final result = classifyBudgetAlerts([
          _bws(id: 'a', budgetCents: 50000, spentCents: 1000),
          _bws(
            id: 'b',
            budgetCents: 50000,
            spentCents: 30000,
            projectedCents: 35000,
          ),
        ]);
        expect(
          result,
          isEmpty,
          reason:
              'budgets at 2% and 60% projected to 70% are healthy and '
              'must not surface — the alert list is for actionable items.',
        );
      },
    );

    test('over-budget sorts ahead of projected-over and approaching-limit', () {
      final result = classifyBudgetAlerts([
        // Approaching limit: 85% spent, projection stays in bounds.
        _bws(
          id: 'approach',
          budgetCents: 10000,
          spentCents: 8500,
          projectedCents: 9000,
        ),
        // Already over: 110% spent.
        _bws(id: 'over', budgetCents: 10000, spentCents: 11000),
        // Projected over: 50% spent, pace puts it at 130%.
        _bws(
          id: 'projected',
          budgetCents: 10000,
          spentCents: 5000,
          projectedCents: 13000,
        ),
      ]);
      expect(result.map((a) => a.budget.budget.id), [
        'over',
        'projected',
        'approach',
      ]);
      expect(result[0].state, BudgetAlertState.overBudget);
      expect(result[1].state, BudgetAlertState.projectedOver);
      expect(result[2].state, BudgetAlertState.approachingLimit);
    });

    test('within over-budget, biggest overage first', () {
      final result = classifyBudgetAlerts([
        _bws(id: 'small', budgetCents: 10000, spentCents: 10500),
        _bws(id: 'big', budgetCents: 10000, spentCents: 15000),
      ]);
      expect(result.map((a) => a.budget.budget.id), ['big', 'small']);
    });

    test('within projected-over, biggest projected overage first', () {
      final result = classifyBudgetAlerts([
        // Both 50% spent; projections diverge.
        _bws(
          id: 'small',
          budgetCents: 10000,
          spentCents: 5000,
          projectedCents: 10500,
        ),
        _bws(
          id: 'big',
          budgetCents: 10000,
          spentCents: 5000,
          projectedCents: 15000,
        ),
      ]);
      expect(result.map((a) => a.budget.budget.id), ['big', 'small']);
    });

    test('within approaching-limit, highest progress first', () {
      final result = classifyBudgetAlerts([
        _bws(id: 'eighty', budgetCents: 10000, spentCents: 8000),
        _bws(id: 'ninety', budgetCents: 10000, spentCents: 9000),
      ]);
      expect(result.map((a) => a.budget.budget.id), ['ninety', 'eighty']);
    });

    test(
      'an already-over budget that is also projected even higher appears '
      'ONLY in the over bucket',
      () {
        // A row that satisfies both conditions must not be double-counted
        // — otherwise the same category would render twice on the
        // dashboard with different framing.
        final result = classifyBudgetAlerts([
          _bws(
            id: 'over+proj',
            budgetCents: 10000,
            spentCents: 11000,
            projectedCents: 15000,
          ),
        ]);
        expect(result, hasLength(1));
        expect(result.single.state, BudgetAlertState.overBudget);
      },
    );

    test(
      'a budget at 85% with no projection overrun lands in approaching, '
      'not projectedOver',
      () {
        // Defaulting projectedCents = spentCents (a user with no time
        // elapsed) used to silently pass the projected-over check when
        // the budget was already at the limit. Pin: 85% spent with
        // projected == spent must land in approachingLimit.
        final result = classifyBudgetAlerts([
          _bws(
            id: 'still-ok',
            budgetCents: 10000,
            spentCents: 8500,
            projectedCents: 8500,
          ),
        ]);
        expect(result.single.state, BudgetAlertState.approachingLimit);
      },
    );
  });
}
