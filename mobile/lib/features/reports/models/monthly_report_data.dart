// Computed shape for a monthly activity report. Pure data, immutable,
// no JSON marshalling — the report isn't persisted, just rendered.
//
// `byCategory` entries are sorted by `cents` descending; the renderer
// trusts the order it gets and doesn't re-sort.

class MonthlyReportData {
  const MonthlyReportData({
    required this.monthStart,
    required this.monthEnd,
    required this.householdName,
    required this.incomeCents,
    required this.expensesCents,
    required this.byCategory,
    required this.transferLegCount,
  });

  /// First day of the report's calendar month (00:00 local).
  final DateTime monthStart;

  /// Last day of the report's calendar month, inclusive.
  final DateTime monthEnd;

  /// Display name pulled from the households table at build time.
  final String householdName;

  /// Positive cash inflow over the month, transfers excluded.
  final int incomeCents;

  /// Positive cash outflow over the month, transfers excluded.
  /// (Stored as a positive number; the report shows it without sign.)
  final int expensesCents;

  /// Per-category spending breakdown, sorted by [cents] descending.
  /// Includes an "Uncategorized" bucket when applicable. Discount
  /// line items (Option B is_discount) already net out inside [cents].
  final List<MonthlyReportCategoryRow> byCategory;

  /// Count of transfer legs in the window. Surfaced as a footnote so
  /// users can sanity-check why income/expense totals don't include
  /// account-to-account movement.
  final int transferLegCount;

  /// income - expenses. Positive = saved, negative = spent down.
  int get netChangeCents => incomeCents - expensesCents;
}

class MonthlyReportCategoryRow {
  const MonthlyReportCategoryRow({
    required this.name,
    required this.cents,
    this.colorHex,
  });

  final String name;
  final int cents;

  /// "#RRGGBB" from the categories table when present. Renderer
  /// uses this for the colour swatch beside each row.
  final String? colorHex;
}
