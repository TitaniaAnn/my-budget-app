// Pure-Dart aggregation from a daily-balance time series to one
// point per calendar month. Lives apart from growth_advisor.dart
// to avoid an import cycle: the dashboard provider needs to call
// the aggregator to populate DashboardData, and the rules read
// DashboardData — putting the aggregator next to the rules would
// fold dashboard_provider → growth_advisor → dashboard_provider.

/// Aggregates [dailyPoints] (output of
/// [reconstructHistoricalNetWorth], oldest-first) into one
/// balance point per calendar month between the earliest data
/// point and the current month.
///
/// Each emitted point's [balanceCents] is the latest known
/// balance at or before that month's last day. Months with no
/// transactions of their own pick up the carry-forward value from
/// the latest prior transaction date — that's how net worth
/// actually behaves between activity bursts.
///
/// The current month uses [currentBalanceCents] verbatim with
/// [now] as the monthEnd, treating "as of today" as that month's
/// running total. Strict "last calendar day" would either be in
/// the past (and stale) or in the future (uncomputable); "today"
/// is the most useful interpretation for trajectory rules.
///
/// Returns an empty list when [dailyPoints] is empty AND no
/// currentBalance was provided. With [currentBalanceCents]
/// supplied, returns a single point for the current month so a
/// fresh household with no history still has *some* signal.
List<({DateTime monthEnd, int balanceCents})> aggregateMonthEndNetWorth(
  List<({DateTime date, int balanceCents})> dailyPoints, {
  required DateTime now,
  required int currentBalanceCents,
}) {
  // Single-point fallback: a brand new household has no
  // transaction history, but we still know "today's net worth"
  // from the accounts table. One point is enough to render a
  // value; trajectory rules need ≥ 3 anyway, so this path stays
  // silent in the rule layer.
  if (dailyPoints.isEmpty) {
    return [
      (
        monthEnd: DateTime(now.year, now.month, now.day),
        balanceCents: currentBalanceCents,
      ),
    ];
  }

  final start = dailyPoints.first.date;
  final startMonth = DateTime(start.year, start.month, 1);
  final currentMonth = DateTime(now.year, now.month, 1);

  final result = <({DateTime monthEnd, int balanceCents})>[];
  var cursor = startMonth;

  while (!cursor.isAfter(currentMonth)) {
    final isCurrentMonth =
        cursor.year == currentMonth.year && cursor.month == currentMonth.month;
    final monthEnd = isCurrentMonth
        // "Now" rather than the calendar last-day, because the
        // calendar last-day is in the future for any mid-month
        // call.
        ? DateTime(now.year, now.month, now.day)
        // Day 0 of next month == last day of this month, the
        // standard DateTime trick.
        : DateTime(cursor.year, cursor.month + 1, 0);

    final balance = isCurrentMonth
        ? currentBalanceCents
        : _balanceAtOrBefore(dailyPoints, monthEnd);

    // Skip months that fall entirely before any data we have —
    // shouldn't happen given startMonth's definition, but
    // defensive: a month with no derivable balance is better
    // omitted than emitted as 0 (would tank a rolling average).
    if (balance != null) {
      result.add((monthEnd: monthEnd, balanceCents: balance));
    }

    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }

  return result;
}

/// Latest point in [points] (sorted oldest-first) whose date is
/// at or before [target]. Null when [target] is older than every
/// point we have.
int? _balanceAtOrBefore(
  List<({DateTime date, int balanceCents})> points,
  DateTime target,
) {
  // Walk backward — typical call pattern is "find the last point
  // before this month's end," which is usually within the last
  // handful of entries.
  for (var i = points.length - 1; i >= 0; i--) {
    if (!points[i].date.isAfter(target)) return points[i].balanceCents;
  }
  return null;
}
