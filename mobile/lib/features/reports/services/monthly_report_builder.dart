// Pure function that turns raw household data into a [MonthlyReportData].
//
// Kept separate from the screen so it can be unit-tested without the
// widget tree, and kept separate from the PDF renderer so the data
// shape is decoupled from the output format.
//
// Income / expense totals follow the same Dart-side rules as
// DashboardData.monthlyIncome / monthlySpending:
//   * transfer legs (transferId != null) are excluded — moving money
//     between household accounts isn't real cash flow;
//   * sign of `amount` decides which side the row lands on.
//
// Per-category figures come from the Option B [spendingByCategory]
// map (the get_category_spending RPC, migration 029) so a paired
// transaction's spend flows through its receipt line items, not its
// own category. An "Uncategorized" bucket is added Dart-side from
// unpaired + uncategorised rows so users see those dollars too.
//
// Per-account closing balances are reconstructed by walking
// [transactionsAfterMonth] backward from each account's
// `current_balance`. See [closingBalancesAtMonthEnd] for the math
// and why transfer legs are NOT excluded from that walkback.

import '../../accounts/models/account.dart';
import '../../currency/services/convert.dart';
import '../../transactions/models/category.dart';
import '../../transactions/models/transaction.dart';
import '../models/monthly_report_data.dart';
import 'closing_balances.dart';

/// Builds a monthly report.
///
/// Multi-currency: when [displayCurrency] is supplied along with a
/// [ratesToDisplay] map, the income / expenses / uncategorized
/// totals are converted from each transaction's native currency
/// to [displayCurrency] before aggregation. Transactions in a
/// currency missing from [ratesToDisplay] are EXCLUDED from those
/// totals (including them at rate=1 would silently lie) and their
/// native currency surfaces in [MonthlyReportData.missingRateCurrencies]
/// so the renderer can footnote the gap.
///
/// Closing-balance rows are NOT converted — each is shown in its
/// account's native currency so the user sees real per-account
/// values. The PDF + preview format each row with its own currency.
///
/// `spendingByCategory` comes pre-aggregated from the
/// [get_category_spending] RPC, which in slice 1 does NOT yet
/// FX-convert across currencies. Slice 2 of the multi-currency arc
/// owes this rewrite. For now, a multi-currency household's
/// by-category figures may be wrong — the dashboard footnote on
/// the report flags the gap.
MonthlyReportData buildMonthlyReport({
  required DateTime monthStart,
  required DateTime monthEnd,
  required String householdName,
  required List<Transaction> transactionsInMonth,
  required Map<String, int> spendingByCategory,
  required Map<String, Category> categoryLookup,
  required List<Account> accounts,
  required List<Transaction> transactionsAfterMonth,
  required DateTime closingAsOf,
  String displayCurrency = 'USD',
  Map<String, double> ratesToDisplay = const {},
}) {
  var income = 0;
  var expenses = 0;
  var transferLegs = 0;
  final missing = <String>{};

  /// Converts a transaction's signed amount into the display
  /// currency, or returns null when no rate is available. Tracks
  /// the source currency in [missing] so the caller can warn.
  int? convertOrTrack(Transaction t) {
    if (t.currency == displayCurrency) return t.amount;
    final rate = ratesToDisplay[t.currency];
    if (rate == null) {
      missing.add(t.currency);
      return null;
    }
    return convertCents(t.amount, rate);
  }

  for (final t in transactionsInMonth) {
    if (t.transferId != null) {
      transferLegs++;
      continue;
    }
    final converted = convertOrTrack(t);
    if (converted == null) continue;
    if (converted > 0) {
      income += converted;
    } else if (converted < 0) {
      expenses += converted.abs();
    }
  }

  final rows = <MonthlyReportCategoryRow>[];
  for (final entry in spendingByCategory.entries) {
    // Mirror DashboardData.topCategories: refunds-exceed-spend
    // categories report negative cents from the RPC, which we
    // treat as zero in the report (the budget UI also clamps).
    if (entry.value <= 0) continue;
    final cat = categoryLookup[entry.key];
    if (cat == null) continue;
    rows.add(MonthlyReportCategoryRow(
      name: cat.name,
      cents: entry.value,
      colorHex: cat.color,
    ));
  }

  // Uncategorised bucket — only counts unpaired transactions, mirroring
  // the dashboard. Paired-but-uncategorised would be double-counted as
  // soon as the user fills in line item categories on the receipt.
  // Converted to display currency the same way income/expenses are.
  var uncategorised = 0;
  for (final t in transactionsInMonth) {
    if (t.transferId != null) continue;
    if (t.amount >= 0) continue;
    if (t.categoryId != null) continue;
    if (t.receiptId != null) continue;
    final converted = convertOrTrack(t);
    if (converted == null) continue;
    uncategorised += converted.abs();
  }
  if (uncategorised > 0) {
    rows.add(MonthlyReportCategoryRow(
      name: 'Uncategorized',
      cents: uncategorised,
    ));
  }

  rows.sort((a, b) => b.cents.compareTo(a.cents));

  final closingBalances = closingBalancesAtMonthEnd(
    accounts: accounts,
    transactionsAfterClose: transactionsAfterMonth,
    closingAsOf: closingAsOf,
  );

  return MonthlyReportData(
    monthStart: monthStart,
    monthEnd: monthEnd,
    householdName: householdName,
    incomeCents: income,
    expensesCents: expenses,
    byCategory: rows,
    transferLegCount: transferLegs,
    closingBalances: closingBalances,
    closingAsOf: closingAsOf,
    displayCurrency: displayCurrency,
    missingRateCurrencies: missing,
  );
}
