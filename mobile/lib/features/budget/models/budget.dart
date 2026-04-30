// Budget model — mirrors the `budgets` table.
// A budget sets a spending limit for one category over a recurring period.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

/// Maps to the `budget_period` Postgres enum.
enum BudgetPeriod {
  @JsonValue('weekly') weekly,
  @JsonValue('biweekly') biweekly,
  @JsonValue('monthly') monthly,
  @JsonValue('semiannual') semiannual,
  @JsonValue('annual') annual;

  String get label => switch (this) {
        BudgetPeriod.weekly => '1 Week',
        BudgetPeriod.biweekly => '2 Weeks',
        BudgetPeriod.monthly => 'Monthly',
        BudgetPeriod.semiannual => '6 Months',
        BudgetPeriod.annual => 'Annual',
      };

  /// Exact string stored in the Postgres `budget_period` enum.
  /// Used when building INSERT/UPDATE payloads manually.
  String get dbValue => switch (this) {
        BudgetPeriod.weekly => 'weekly',
        BudgetPeriod.biweekly => 'biweekly',
        BudgetPeriod.monthly => 'monthly',
        BudgetPeriod.semiannual => 'semiannual',
        BudgetPeriod.annual => 'annual',
      };

  /// Returns the [from, to] date range for the current cycle of this period.
  ///
  /// Weekly/biweekly cycles are anchored to Monday of the current week.
  /// Biweekly uses the ISO week number to determine which two-week block
  /// we are currently in, so the cycle is consistent across the year.
  ///
  /// [now] defaults to `DateTime.now()`; tests pass a fixed value.
  (DateTime from, DateTime to) currentRange({DateTime? now}) {
    final today = () {
      final n = now ?? DateTime.now();
      return DateTime(n.year, n.month, n.day);
    }();

    switch (this) {
      case BudgetPeriod.weekly:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (monday, sunday);

      case BudgetPeriod.biweekly:
        // Anchor biweekly blocks to the first Monday of the year.
        // Even ISO week numbers → block start is the Monday of that week.
        // Odd ISO week numbers → block start is the Monday of the previous week.
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final weekOfYear = _isoWeekNumber(monday);
        final blockStart = weekOfYear.isOdd
            ? monday.subtract(const Duration(days: 7))
            : monday;
        final blockEnd = blockStart.add(const Duration(days: 13));
        return (blockStart, blockEnd);

      case BudgetPeriod.monthly:
        return (
          DateTime(today.year, today.month, 1),
          DateTime(today.year, today.month + 1, 0), // last day of month
        );

      case BudgetPeriod.semiannual:
        // H1: Jan–Jun, H2: Jul–Dec
        final isH1 = today.month <= 6;
        return (
          DateTime(today.year, isH1 ? 1 : 7, 1),
          DateTime(today.year, isH1 ? 6 : 12, isH1 ? 30 : 31),
        );

      case BudgetPeriod.annual:
        return (
          DateTime(today.year, 1, 1),
          DateTime(today.year, 12, 31),
        );
    }
  }
}

/// Returns the ISO 8601 week number (1–53) for [date].
int _isoWeekNumber(DateTime date) {
  // ISO week starts Monday; Jan 4 is always in week 1.
  final jan4 = DateTime(date.year, 1, 4);
  final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
  final diff = date.difference(startOfWeek1).inDays;
  if (diff < 0) {
    // Date falls in the last week of the previous year.
    return _isoWeekNumber(DateTime(date.year - 1, 12, 31));
  }
  return (diff ~/ 7) + 1;
}

/// Immutable representation of a row in the `budgets` table.
///
/// [amount] is in cents. A budget is active when [endDate] is null or in
/// the future. Use the repository to create / update / delete budgets.
@freezed
class Budget with _$Budget {
  const factory Budget({
    required String id,
    required String householdId,
    required String categoryId,
    /// Spending limit in cents for the given [period].
    required int amount,
    required BudgetPeriod period,
    required DateTime startDate,
    /// Null means the budget repeats indefinitely.
    DateTime? endDate,
    required String createdBy,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) =>
      _$BudgetFromJson(json);
}
