// Riverpod providers for budgets.
//
// Each budget is queried with its own correct period range so spending figures
// are accurate (not approximated from a full-year bucket). A projected end-of-
// period total is also computed from the current daily spend rate.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../../currency/providers/rates_to_display_provider.dart';
import '../../settings/providers/settings_provider.dart';
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
    required this.capCents,
    this.capIsMissingRate = false,
  });

  final Budget budget;

  /// Actual debits so far this period, in cents — already in the
  /// household's display currency (the [BudgetRepository.fetchSpendingByCategory]
  /// RPC converts when rates are configured).
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

  /// Budget cap converted to the household's display currency. For
  /// a USD budget in a USD household this is identical to
  /// `budget.amount`; for a EUR budget compared in USD this is
  /// budget.amount × the EUR→USD rate. The comparison getters
  /// below operate on this rather than `budget.amount` directly so
  /// the math is currency-symmetric.
  final int capCents;

  /// True when the budget is in a foreign currency and the
  /// household doesn't have a rate to convert it. The UI shows a
  /// "needs FX rate" indicator instead of a meaningless progress
  /// bar in this case. [progress] / [isOverBudget] etc. still
  /// return safe values (treated as 0% / not-over) so call sites
  /// don't have to special-case.
  final bool capIsMissingRate;

  /// Remaining budget in cents (may be negative when over-budget).
  int get remainingCents => capCents - spentCents;

  /// Fraction of budget consumed by actual spend, clamped to [0, 1].
  double get progress =>
      capCents == 0 ? 0 : (spentCents / capCents).clamp(0.0, 1.0);

  /// Fraction of budget the projection fills, clamped to [0, 1].
  double get projectedProgress =>
      capCents == 0 ? 0 : (projectedCents / capCents).clamp(0.0, 1.0);

  bool get isOverBudget => capCents > 0 && spentCents > capCents;
  bool get isProjectedOver => capCents > 0 && projectedCents > capCents;
}

/// Computes the projected end-of-period spending given the amount spent so far,
/// the period start, and the period end.
///
/// Formula: `spentCents / daysElapsed * totalDays`. Returns [spentCents]
/// unchanged when today is the last day or no days have elapsed (avoids
/// division by zero or nonsensical projections).
///
/// [now] defaults to `DateTime.now()`; tests pass a fixed value.
int projectEndOfPeriodSpend({
  required int spentCents,
  required DateTime from,
  required DateTime to,
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  final totalDays = to.difference(from).inDays + 1;
  // Days elapsed including today, but at least 1.
  final elapsed = n.difference(from).inDays + 1;
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

  // Pre-fetch household info + the shared FX rate map so the
  // spending RPC can convert per-row (slice 2-2) AND the budget
  // caps can convert for comparison (slice 3). ratesToDisplayProvider
  // is cached across the dashboard / budget / scenarios / runner /
  // monthly report so the underlying fx_rates fetch runs once per
  // session.
  final (budgets, cats, info, ratesToDisplay) = await (
    repo.fetchBudgets(householdId),
    ref.read(categoriesProvider.future),
    ref.read(householdInfoProvider.future),
    ref.watch(ratesToDisplayProvider.future),
  ).wait;

  if (budgets.isEmpty) return [];

  final catMap = {for (final c in cats) c.id: c};
  final rpcRates = ratesToDisplay.isEmpty ? null : ratesToDisplay;

  // Fetch spending for every budget in parallel — each uses its own range.
  final spendingFutures = budgets.map((b) {
    final (from, to) = b.period.currentRange();
    return repo.fetchSpendingByCategory(
      householdId: householdId,
      from: from,
      to: to,
      ratesToDisplay: rpcRates,
    );
  }).toList();

  final spendingMaps = await Future.wait(spendingFutures);

  return List.generate(budgets.length, (i) {
    final b = budgets[i];
    final (from, to) = b.period.currentRange();
    // Net spend can go negative when refunds exceed debits in a period;
    // floor at zero so the UI doesn't show "-$10 spent".
    final raw = spendingMaps[i][b.categoryId] ?? 0;
    final spent = raw < 0 ? 0 : raw;
    final projected = projectEndOfPeriodSpend(
      spentCents: spent,
      from: from,
      to: to,
    );
    final cat = catMap[b.categoryId];

    // Convert the budget's cap to display currency for comparison.
    // Same exclude-not-lie contract: missing rate → capCents=0 +
    // flagged, the UI shows "needs FX rate" rather than a phantom
    // 0% bar that looks like the user has full headroom.
    int capCents;
    var capIsMissingRate = false;
    if (b.currency == info.displayCurrency) {
      capCents = b.amount;
    } else {
      final rate = ratesToDisplay[b.currency];
      if (rate == null) {
        capCents = 0;
        capIsMissingRate = true;
      } else {
        capCents = (b.amount * rate).round();
      }
    }

    return BudgetWithSpending(
      budget: b,
      spentCents: spent,
      projectedCents: projected,
      periodFrom: from,
      periodTo: to,
      categoryName: cat?.name ?? 'Unknown',
      categoryColor: cat?.color,
      categoryIcon: cat?.icon,
      capCents: capCents,
      capIsMissingRate: capIsMissingRate,
    );
  });
}
