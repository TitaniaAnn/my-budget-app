// Data access layer for budgets.
// Fetches budgets joined with their category, and provides actual spending
// totals for the current period by querying the transactions table.
//
// Audit L1 Phase 2b: cache-through on the budget set; the
// fetchSpendingByCategory RPC stays network-only (deferred to
// Phase 4 — FX-aware spending math ported to Dart).
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/budget.dart';

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
  /// Network-only for L1 Phase 2b. Offline returns an empty map (the
  /// budget UI shows budgets at $0 spent), not an exception. This is
  /// the right offline behaviour because:
  ///   (a) the RPC's FX-aware aggregation logic isn't trivially
  ///       portable to Dart (Option B rollup with line-item dedupe,
  ///       FX conversion per row, transfer exclusion);
  ///   (b) "I'm offline and don't know the latest spend" is more
  ///       honest than "I think you spent $0 this period."
  /// Phase 4 ports the SQL to Dart and lifts this restriction.
  Future<Map<String, int>> fetchSpendingByCategory({
    required String householdId,
    required DateTime from,
    required DateTime to,
    Map<String, double>? ratesToDisplay,
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
