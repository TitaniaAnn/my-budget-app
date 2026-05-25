// Pure classification + sort logic for the dashboard's Budget Health
// surface. Lives in /services/ (not /screens/) so it's unit-testable
// without the widget tree.
//
// The original surface filtered on `isOverBudget || progress >= 0.8`,
// which has two gaps:
//   1. A user on pace to overshoot (e.g. 60% spent on day 10 of 30 →
//      projection 180%) gets no warning until the 80% absolute
//      threshold is crossed — by which point they've lost most of
//      the chance to course-correct.
//   2. The 80% threshold is time-agnostic. 75% on day 5 is a flashing
//      red light; 75% on day 25 is fine — the original treated them
//      identically.
//
// This module fixes (1) by adding a third state `projectedOver` so
// projected-over-but-not-yet-over budgets surface. (2) is partly
// addressed because `projectedOver` is what catches the early-month
// overspenders that pure-actual filters miss.

import '../../budget/providers/budget_provider.dart';

/// Why a budget appears in the dashboard alerts. Ordered by priority:
/// [overBudget] is rendered first, [projectedOver] next, then
/// [approachingLimit].
enum BudgetAlertState {
  /// Actual spending has already exceeded the budget amount.
  overBudget,

  /// Currently within budget but the daily-rate projection puts the
  /// end-of-period total over. Computed by
  /// [projectEndOfPeriodSpend] in budget_provider.dart.
  projectedOver,

  /// At or above 80% of the budget by actual spend, and projection
  /// stays within bounds — included so a user who's slowing their
  /// pace but already deep in still sees a near-the-line warning.
  approachingLimit,
}

/// One row in the dashboard's Budget Health list.
class BudgetAlert {
  const BudgetAlert({required this.budget, required this.state});
  final BudgetWithSpending budget;
  final BudgetAlertState state;
}

/// Filters [budgets] to those that warrant a dashboard alert and
/// sorts them so the most urgent appear first.
///
/// Sort order:
///   1. [BudgetAlertState.overBudget] — biggest overage first
///      (spentCents - capCents, descending).
///   2. [BudgetAlertState.projectedOver] — biggest projected overage
///      first (projectedCents - capCents, descending).
///   3. [BudgetAlertState.approachingLimit] — highest progress first.
///
/// All overage math uses [BudgetWithSpending.capCents] (the cap
/// converted to the household's display currency) rather than the
/// raw `budget.amount`. In a multi-currency household, a EUR €100
/// budget and a USD $100 budget have the same `amount` but very
/// different display-currency caps; comparing on raw amount sorts
/// them as equal-overage when they are not.
///
/// A single budget appears in exactly one bucket; the state cascade
/// short-circuits so an already-over budget isn't double-listed as
/// "projected over" or "approaching limit".
List<BudgetAlert> classifyBudgetAlerts(List<BudgetWithSpending> budgets) {
  final over = <BudgetAlert>[];
  final projected = <BudgetAlert>[];
  final approaching = <BudgetAlert>[];

  for (final b in budgets) {
    if (b.isOverBudget) {
      over.add(BudgetAlert(budget: b, state: BudgetAlertState.overBudget));
    } else if (b.isProjectedOver) {
      projected.add(
        BudgetAlert(budget: b, state: BudgetAlertState.projectedOver),
      );
    } else if (b.progress >= 0.8) {
      approaching.add(
        BudgetAlert(budget: b, state: BudgetAlertState.approachingLimit),
      );
    }
  }

  over.sort((a, b) {
    final aOver = a.budget.spentCents - a.budget.capCents;
    final bOver = b.budget.spentCents - b.budget.capCents;
    return bOver.compareTo(aOver);
  });
  projected.sort((a, b) {
    final aOver = a.budget.projectedCents - a.budget.capCents;
    final bOver = b.budget.projectedCents - b.budget.capCents;
    return bOver.compareTo(aOver);
  });
  approaching.sort((a, b) => b.budget.progress.compareTo(a.budget.progress));

  return [...over, ...projected, ...approaching];
}
