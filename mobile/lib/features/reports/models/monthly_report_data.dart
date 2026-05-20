// Computed shape for a monthly activity report. Pure data, immutable,
// no JSON marshalling — the report isn't persisted, just rendered.
//
// `byCategory` entries are sorted by `cents` descending; the renderer
// trusts the order it gets and doesn't re-sort. Same contract for
// `closingBalances`, sorted descending by absolute balance so heavy
// accounts surface first.

import '../../accounts/models/account.dart';

class MonthlyReportData {
  const MonthlyReportData({
    required this.monthStart,
    required this.monthEnd,
    required this.householdName,
    required this.incomeCents,
    required this.expensesCents,
    required this.byCategory,
    required this.transferLegCount,
    required this.closingBalances,
    required this.closingAsOf,
    this.displayCurrency = 'USD',
    this.missingRateCurrencies = const {},
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

  /// Per-account balance at [closingAsOf], computed by walking
  /// transactions backward from `accounts.current_balance`. Sorted
  /// descending by absolute balance — large positions (or large
  /// debts) surface first. Empty when the household has no accounts.
  ///
  /// Transfer legs are NOT excluded from the walkback: each leg
  /// genuinely moves money between accounts, so subtracting them is
  /// exactly what we want.
  final List<MonthlyReportAccountBalance> closingBalances;

  /// The actual as-of timestamp for [closingBalances]. Equal to
  /// [monthEnd] for past months; for a report covering the current
  /// month (the month hasn't ended yet) this is "now" — the balances
  /// reflect today, with the renderer adapting its label accordingly.
  final DateTime closingAsOf;

  /// 3-letter ISO code the totals are denominated in. For
  /// USD-only households this is 'USD' and the renderer omits any
  /// "in EUR" suffix; multi-currency households see it surfaced.
  final String displayCurrency;

  /// Currencies that appeared on at least one account / transaction
  /// but had no FX rate to [displayCurrency]. Empty when every
  /// position was either in [displayCurrency] or had a usable rate.
  /// The PDF renderer surfaces this as a footnote so a partial
  /// conversion doesn't look like a complete one.
  final Set<String> missingRateCurrencies;

  /// income - expenses. Positive = saved, negative = spent down.
  int get netChangeCents => incomeCents - expensesCents;
}

class MonthlyReportAccountBalance {
  const MonthlyReportAccountBalance({
    required this.accountName,
    required this.accountType,
    required this.balanceCents,
    this.nativeCurrency = 'USD',
  });

  final String accountName;
  final AccountType accountType;

  /// Signed cents: liabilities (credit cards, mortgages) come through
  /// as negative — the renderer relies on the sign for colour and
  /// the absolute-value sort.
  ///
  /// In [nativeCurrency] (the account's own currency). The
  /// renderer is responsible for formatting it with that currency's
  /// symbol — multi-currency households see per-account totals in
  /// each account's native units rather than converted.
  final int balanceCents;

  /// 3-letter ISO code for [balanceCents]. Defaults to 'USD' so
  /// single-currency households are unaffected.
  final String nativeCurrency;
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
