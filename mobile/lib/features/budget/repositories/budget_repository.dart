// Data access layer for budgets.
// Fetches budgets joined with their category, and provides actual spending
// totals for the current period by querying the transactions table.
//
// Audit L1 Phase 2b (budget reads cache-through) + Phase 4a
// (fetchSpendingByCategory falls back to a pure-Dart port of
// the SQL function when offline). The numbers match the SQL
// function's contract; see services/spending_calculator.dart
// for the algorithm + multi-currency rules.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../receipts/models/receipt_line_item.dart';
import '../../transactions/models/transaction.dart';
import '../models/budget.dart';
import '../services/spending_calculator.dart';

part 'budget_repository.g.dart';

@riverpod
BudgetRepository budgetRepository(BudgetRepositoryRef ref) {
  return BudgetRepository(db: ref.watch(appDatabaseProvider));
}

class BudgetRepository {
  BudgetRepository({AppDatabase? db}) : _db = db;
  final AppDatabase? _db;

  /// Fetches all budgets for [householdId] joined with their category row.
  Future<List<Budget>> fetchBudgets(String householdId) async {
    try {
      final data = await supabase
          .from('budgets')
          .select()
          .eq('household_id', householdId)
          .order('start_date', ascending: true);

      final budgets = data.map<Budget>(Budget.fromJson).toList();
      await _refreshBudgetCache(householdId, budgets);
      return budgets;
    } catch (_) {
      final cached = await _loadBudgetsFromCache(householdId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Returns a map of categoryId → net spent (in cents, as a positive number)
  /// for the given date range.
  ///
  /// Net = sum of debits minus refunds in the same category. A $50 grocery
  /// charge followed by a $10 refund posted to "Groceries" yields $40, not
  /// $50. The result can be negative if refunds exceed debits; the caller
  /// (budget UI) treats those as $0 spent.
  ///
  /// Categories with no activity in the range are absent from the map.
  ///
  /// Aggregation runs server-side via the `get_category_spending` RPC
  /// (migration 021) — a single row per category over the wire instead
  /// of every transaction in the range. RLS still applies (the RPC runs
  /// as the caller, no SECURITY DEFINER).
  ///
  /// Audit L1 Phase 4a — offline fallback. When the RPC fails
  /// (offline, captive portal, server 5xx), the fallback reads
  /// the cached transactions + line items for the household and
  /// runs `computeCategorySpending` (a byte-for-byte Dart port
  /// of the SQL function). The result has the same shape as the
  /// RPC response.
  ///
  /// [displayCurrency] is required for the FX identity branch —
  /// rows in the household's display currency convert at 1.0
  /// even though the rates map doesn't normally include the
  /// display→display entry. Callers that don't track multi-
  /// currency just pass 'USD' (or any matching currency); when
  /// [ratesToDisplay] is null the parameter is a no-op.
  Future<Map<String, int>> fetchSpendingByCategory({
    required String householdId,
    required DateTime from,
    required DateTime to,
    Map<String, double>? ratesToDisplay,
    String displayCurrency = 'USD',
  }) async {
    try {
      // p_rates JSONB defaults to NULL on the SQL side; passing
      // non-null tells the RPC to convert per-row to the display
      // currency. NULL preserves migration 029's single-currency
      // behaviour for callers that don't (yet) know about FX —
      // every existing path stays correct for USD-only households.
      final data = await supabase.rpc(
        'get_category_spending',
        params: {
          'p_household_id': householdId,
          'p_from': from.toIso8601String().substring(0, 10),
          'p_to': to.toIso8601String().substring(0, 10),
          'p_rates': ?ratesToDisplay,
        },
      );
      if (data == null) return {};
      return {
        for (final row in data as List)
          row['category_id'] as String: (row['net_cents'] as num).toInt(),
      };
    } catch (_) {
      final fromCache = await _computeSpendingFromCache(
        householdId: householdId,
        from: from,
        to: to,
        ratesToDisplay: ratesToDisplay,
        displayCurrency: displayCurrency,
      );
      if (fromCache != null) return fromCache;
      // Cache miss — surface the zero map so the UI shows
      // "no spending data" rather than throwing.
      return const {};
    }
  }

  /// Creates a new budget and returns it.
  ///
  /// [currency] defaults to 'USD' so existing callers keep their
  /// pre-multi-currency behaviour. The add-budget UI lets the user
  /// pick a 3-letter ISO code so a household with mixed-currency
  /// accounts can think in whichever currency is most natural per
  /// category.
  Future<Budget> createBudget({
    required String householdId,
    required String categoryId,
    required int amountCents,
    required BudgetPeriod period,
    required String createdBy,
    String currency = 'USD',
    DateTime? startDate,
  }) async {
    final data = await supabase
        .from('budgets')
        .insert({
          'household_id': householdId,
          'category_id': categoryId,
          'amount': amountCents,
          'currency': currency,
          'period': period.dbValue,
          'start_date': (startDate ?? DateTime.now())
              .toIso8601String()
              .substring(0, 10),
          'created_by': createdBy,
        })
        .select()
        .single();

    final budget = Budget.fromJson(data);
    await _writeBudgetCacheRow(budget);
    return budget;
  }

  /// Updates the amount, currency, and/or period of an existing budget.
  Future<Budget> updateBudget({
    required String budgetId,
    int? amountCents,
    String? currency,
    BudgetPeriod? period,
  }) async {
    final data = await supabase
        .from('budgets')
        .update({
          'amount': ?amountCents,
          'currency': ?currency,
          'period': ?period?.dbValue,
        })
        .eq('id', budgetId)
        .select()
        .single();

    final budget = Budget.fromJson(data);
    await _writeBudgetCacheRow(budget);
    return budget;
  }

  /// Deletes a budget by ID.
  Future<void> deleteBudget(String budgetId) async {
    await supabase.from('budgets').delete().eq('id', budgetId);
    await _deleteBudgetCacheRow(budgetId);
  }

  // ── Cache helpers ──────────────────────────────────────────

  Future<void> _refreshBudgetCache(
    String householdId,
    List<Budget> budgets,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.replaceBudgetsForHousehold(
        householdId,
        budgets.map(_budgetToCompanion).toList(),
      );
    } catch (_) {/**/}
  }

  Future<void> _writeBudgetCacheRow(Budget b) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.upsertBudget(_budgetToCompanion(b));
    } catch (_) {/**/}
  }

  Future<void> _deleteBudgetCacheRow(String id) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.deleteBudget(id);
    } catch (_) {/**/}
  }

  Future<List<Budget>?> _loadBudgetsFromCache(String householdId) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.loadBudgetsForHousehold(householdId);
      if (rows.isEmpty) return null;
      return rows.map(_budgetFromCacheRow).toList();
    } catch (_) {
      return null;
    }
  }

  /// Offline equivalent of the RPC. Reads cached transactions in
  /// the date range + their receipt line items, then runs the
  /// pure-Dart spending calculator. Returns null on any cache
  /// failure so the caller can decide what to surface; an empty
  /// map result means "we successfully computed and the household
  /// has no spending in this period."
  Future<Map<String, int>?> _computeSpendingFromCache({
    required String householdId,
    required DateTime from,
    required DateTime to,
    Map<String, double>? ratesToDisplay,
    required String displayCurrency,
  }) async {
    final db = _db;
    if (db == null) return null;
    try {
      // Pull every cached transaction for the household in the
      // window. The calculator does the rest of the filtering
      // (category != null, receipt-vs-unpaired branching).
      final txRows = await db.loadTransactionsForHousehold(
        householdId: householdId,
        from: from,
        to: to,
        // No paging — spending math needs every row in the
        // window. Bumping limit past the default 1000 covers a
        // very heavy month; the cache is local so the read is
        // cheap.
        limit: 1000000,
      );

      final transactions = <Transaction>[
        for (final row in txRows) _txFromCacheRow(row),
      ];

      // Collect the receipt ids referenced by paired transactions
      // in scope. The line-item branch of the calculator only
      // looks up these receipts.
      final receiptIds = <String>{
        for (final t in transactions)
          if (t.receiptId != null) t.receiptId!,
      };

      final liRows = await db.loadLineItemsForReceipts(receiptIds.toList());
      final lineItemsByReceiptId = <String, List<ReceiptLineItem>>{};
      for (final li in liRows) {
        final converted = _liFromCacheRow(li);
        (lineItemsByReceiptId[li.receiptId] ??= <ReceiptLineItem>[])
            .add(converted);
      }

      return computeCategorySpending(
        transactions: transactions,
        lineItemsByReceiptId: lineItemsByReceiptId,
        from: from,
        to: to,
        ratesToDisplay: ratesToDisplay,
        displayCurrency: displayCurrency,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Local cache-row → Transaction mapper. Kept private here
/// rather than importing TransactionsRepository's mappers —
/// circular dependencies + the mapper itself is small.
Transaction _txFromCacheRow(TransactionWithCategoryRow row) {
  final r = row.transaction;
  return Transaction(
    id: r.id,
    householdId: r.householdId,
    accountId: r.accountId,
    amount: r.amount,
    currency: r.currency,
    description: r.description,
    merchant: r.merchant,
    categoryId: r.categoryId,
    transactionDate: r.transactionDate,
    postedDate: r.postedDate,
    pending: r.pending,
    source: r.source,
    enteredBy: r.enteredBy,
    receiptId: r.receiptId,
    rateId: r.rateId,
    notes: r.notes,
    externalId: r.externalId,
    transferId: r.transferId,
    mlModelConfidence: r.mlModelConfidence,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}

ReceiptLineItem _liFromCacheRow(ReceiptLineItemsCacheRow r) {
  return ReceiptLineItem(
    id: r.id,
    receiptId: r.receiptId,
    description: r.description,
    amount: r.amount,
    quantity: r.quantity,
    unitPrice: r.unitPrice,
    categoryId: r.categoryId,
    isTax: r.isTax,
    isTip: r.isTip,
    isDiscount: r.isDiscount,
    sortOrder: r.sortOrder,
    ocrConfidenceBp: r.ocrConfidenceBp,
  );
}

BudgetsCacheCompanion _budgetToCompanion(Budget b) {
  return BudgetsCacheCompanion(
    id: Value(b.id),
    householdId: Value(b.householdId),
    categoryId: Value(b.categoryId),
    amount: Value(b.amount),
    currency: Value(b.currency),
    period: Value(b.period.dbValue),
    startDate: Value(b.startDate.toUtc()),
    endDate: Value(b.endDate?.toUtc()),
    createdBy: Value(b.createdBy),
    cachedAt: Value(DateTime.now().toUtc()),
  );
}

Budget _budgetFromCacheRow(BudgetsCacheRow r) {
  return Budget(
    id: r.id,
    householdId: r.householdId,
    categoryId: r.categoryId,
    amount: r.amount,
    currency: r.currency,
    period: BudgetPeriod.values.firstWhere(
      (p) => p.dbValue == r.period,
      // Defensive fallback for a cache row written by a newer
      // version of the app (added an enum variant) being read
      // by an older version. Monthly keeps the UI sensible.
      orElse: () => BudgetPeriod.monthly,
    ),
    startDate: r.startDate,
    endDate: r.endDate,
    createdBy: r.createdBy,
  );
}
