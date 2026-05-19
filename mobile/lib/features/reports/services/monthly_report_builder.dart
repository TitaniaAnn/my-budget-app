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

import '../../transactions/models/category.dart';
import '../../transactions/models/transaction.dart';
import '../models/monthly_report_data.dart';

MonthlyReportData buildMonthlyReport({
  required DateTime monthStart,
  required DateTime monthEnd,
  required String householdName,
  required List<Transaction> transactionsInMonth,
  required Map<String, int> spendingByCategory,
  required Map<String, Category> categoryLookup,
}) {
  var income = 0;
  var expenses = 0;
  var transferLegs = 0;
  for (final t in transactionsInMonth) {
    if (t.transferId != null) {
      transferLegs++;
      continue;
    }
    if (t.amount > 0) {
      income += t.amount;
    } else if (t.amount < 0) {
      expenses += t.amount.abs();
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
  var uncategorised = 0;
  for (final t in transactionsInMonth) {
    if (t.transferId != null) continue;
    if (t.amount >= 0) continue;
    if (t.categoryId != null) continue;
    if (t.receiptId != null) continue;
    uncategorised += t.amount.abs();
  }
  if (uncategorised > 0) {
    rows.add(MonthlyReportCategoryRow(
      name: 'Uncategorized',
      cents: uncategorised,
    ));
  }

  rows.sort((a, b) => b.cents.compareTo(a.cents));

  return MonthlyReportData(
    monthStart: monthStart,
    monthEnd: monthEnd,
    householdName: householdName,
    incomeCents: income,
    expensesCents: expenses,
    byCategory: rows,
    transferLegCount: transferLegs,
  );
}
