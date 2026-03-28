// Riverpod providers for budgets.
//
// Each budget is queried with its own correct period range so spending figures
// are accurate (not approximated from a full-year bucket). A projected end-of-
// period total is also computed from the current daily spend rate.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../models/budget.dart';
import '../repositories/budget_repository.dart';

part 'budget_provider.g.dart';

/// Pairs a [Budget] with actual spending and an end-of-period projection.
class BudgetWithSpending {
  const BudgetWithSpending({
    required this.budget,
    required this.spentCents,
    required this.projectedCents,
    required this.periodFrom,
    required this.periodTo,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
  });

  final Budget budget;

  /// Actual debits so far this period, in cents (always positive).
  final int spentCents;

  /// Projected spend by end of period based on current daily rate, in cents.
  /// Equal to [spentCents] if we are on the last day or past the period.
  final int projectedCents;

  /// Start and end of the current budget period (used for the UI label).
  final DateTime periodFrom;
  final DateTime periodTo;

  final String categoryName;
  final String? categoryColor;
  final String? categoryIcon;

  /// Remaining budget in cents (may be negative when over-budget).
  int get remainingCents => budget.amount - spentCents;

  /// Fraction of budget consumed by actual spend, clamped to [0, 1].
  double get progress =>
      budget.amount == 0 ? 0 : (spentCents / budget.amount).clamp(0.0, 1.0);

  /// Fraction of budget the projection fills, clamped to [0, 1].
  double get projectedProgress =>
      budget.amount == 0
          ? 0
          : (projectedCents / budget.amount).clamp(0.0, 1.0);

  bool get isOverBudget => spentCents > budget.amount;
  bool get isProjectedOver => projectedCents > budget.amount;
}

/// Computes the projected end-of-period spending given the amount spent so far,
/// the period start, and the period end.
///
/// Formula: spentCents / daysElapsed * totalDays
/// Returns [spentCents] unchanged when today is the last day or no days have
/// elapsed (avoids division by zero or nonsensical projections).
int _project({
  required int spentCents,
  required DateTime from,
  required DateTime to,
}) {
  final now = DateTime.now();
  final totalDays = to.difference(from).inDays + 1;
  // Days elapsed including today, but at least 1.
  final elapsed = now.difference(from).inDays + 1;
  if (elapsed <= 0 || elapsed >= totalDays) return spentCents;
  return (spentCents / elapsed * totalDays).round();
}

/// All budgets for the current household, each paired with correct-period
/// spending and an end-of-period projection.
///
/// Spending is fetched per-budget using its own [BudgetPeriod.currentRange]
/// so weekly budgets aren't inflated with a full year of transactions.
@riverpod
Future<List<BudgetWithSpending>> budgetData(BudgetDataRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return [];

  final repo = ref.read(budgetRepositoryProvider);

  final (budgets, cats) = await (
    repo.fetchBudgets(householdId),
    ref.read(categoriesProvider.future),
  ).wait;

  if (budgets.isEmpty) return [];

  final catMap = {for (final c in cats) c.id: c};

  // Fetch spending for every budget in parallel — each uses its own range.
  final spendingFutures = budgets.map((b) {
    final (from, to) = b.period.currentRange();
    return repo.fetchSpendingByCategory(
      householdId: householdId,
      from: from,
      to: to,
    );
  }).toList();

  final spendingMaps = await Future.wait(spendingFutures);

  return List.generate(budgets.length, (i) {
    final b = budgets[i];
    final (from, to) = b.period.currentRange();
    final spent = spendingMaps[i][b.categoryId] ?? 0;
    final projected = _project(spentCents: spent, from: from, to: to);
    final cat = catMap[b.categoryId];

    return BudgetWithSpending(
      budget: b,
      spentCents: spent,
      projectedCents: projected,
      periodFrom: from,
      periodTo: to,
      categoryName: cat?.name ?? 'Unknown',
      categoryColor: cat?.color,
      categoryIcon: cat?.icon,
    );
  });
}
