// Pure-Dart port of the Postgres `get_category_spending`
// function (migration 037). Audit L1 Phase 4a.
//
// Used by BudgetRepository's offline fallback when
// fetchSpendingByCategory's RPC can't reach the server. The SQL
// function lives at supabase/migrations/037_category_spending_fx_aware.sql
// and its contract is replicated here byte-for-byte so the
// budget UI shows the same numbers online and offline.
//
// Algorithm (matches the SQL function):
//   * Unpaired transactions (receipt_id IS NULL, category_id
//     IS NOT NULL): negate amount (spending is positive in the
//     output, transactions store outflows as negative), apply
//     FX, group by category.
//   * Paired transactions (receipt_id IS NOT NULL): contribute
//     via their receipt's line items rather than the transaction
//     amount itself. Each receipt is counted ONCE even when
//     paired with multiple in-range transactions (the SQL
//     EXISTS gate has the same effect — line items aggregate
//     over their own table).
//   * Discount line items: amount sign flips (the SQL has
//     `CASE WHEN li.is_discount THEN -li.amount ELSE li.amount END`).
//   * FX: each row converts via [ratesToDisplay]; rows in
//     [displayCurrency] use the identity 1.0 (matching the
//     dashboard's `_converted` helper — the rates map does NOT
//     normally include the display→display entry).
//
// Multi-currency contract (mirrors the SQL function's exclude-
// not-lie semantic):
//   * [ratesToDisplay] NULL → every row counts at face value
//     (rate=1). Single-currency household behavior.
//   * [ratesToDisplay] non-null + row's currency in the map →
//     convert.
//   * [ratesToDisplay] non-null + row's currency NOT in the
//     map AND not the display currency → drop the row. Better
//     to under-report than to lie at rate=1.
//
// Negative result clamping is the CALLER's job — the SQL
// function returns net_cents which can go negative when
// refunds exceed debits in a period. budget_provider.dart
// already floors at zero for display.

import '../../receipts/models/receipt_line_item.dart';
import '../../transactions/models/transaction.dart';

/// Returns `{category_id → net spending in display-currency
/// cents}` for transactions in [from..to] (inclusive). Empty
/// map when nothing in scope. Categories with no activity in
/// the window don't appear (parity with the SQL function).
Map<String, int> computeCategorySpending({
  required List<Transaction> transactions,
  required Map<String, List<ReceiptLineItem>> lineItemsByReceiptId,
  required DateTime from,
  required DateTime to,
  required Map<String, double>? ratesToDisplay,
  required String displayCurrency,
}) {
  double rateFor(String currency) {
    if (ratesToDisplay == null) return 1.0;
    if (currency == displayCurrency) return 1.0;
    return ratesToDisplay[currency] ?? 0.0;
  }

  final result = <String, int>{};
  final countedReceipts = <String>{};

  for (final tx in transactions) {
    // Date filter — inclusive both ends, calendar-day comparison.
    // The cache stores dates with time 00:00 UTC (because the
    // server column is DATE), so a simple !isBefore/!isAfter
    // pair is exact at the day boundary.
    if (tx.transactionDate.isBefore(from) ||
        tx.transactionDate.isAfter(to)) {
      continue;
    }

    if (tx.receiptId == null) {
      // Unpaired transaction: contribute -amount * fx.
      if (tx.categoryId == null) continue;
      final rate = rateFor(tx.currency);
      if (rate == 0.0) continue;
      final contribution = -(tx.amount * rate).round();
      result.update(
        tx.categoryId!,
        (v) => v + contribution,
        ifAbsent: () => contribution,
      );
    } else {
      // Paired: aggregate via line items. Dedup by receipt id
      // so an installment plan (one receipt, two transactions)
      // counts once.
      final receiptId = tx.receiptId!;
      if (!countedReceipts.add(receiptId)) continue;
      final items = lineItemsByReceiptId[receiptId];
      if (items == null) continue;
      final rate = rateFor(tx.currency);
      if (rate == 0.0) continue;
      for (final li in items) {
        if (li.categoryId == null) continue;
        final amount = li.isDiscount ? -li.amount : li.amount;
        final contribution = (amount * rate).round();
        result.update(
          li.categoryId!,
          (v) => v + contribution,
          ifAbsent: () => contribution,
        );
      }
    }
  }

  return result;
}
