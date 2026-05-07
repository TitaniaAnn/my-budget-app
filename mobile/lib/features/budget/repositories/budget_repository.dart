// Data access layer for budgets.
// Fetches budgets joined with their category, and provides actual spending
// totals for the current period by querying the transactions table.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/budget.dart';

part 'budget_repository.g.dart';

@riverpod
BudgetRepository budgetRepository(BudgetRepositoryRef ref) {
  return BudgetRepository();
}

class BudgetRepository {
  /// Fetches all budgets for [householdId] joined with their category row.
  Future<List<Budget>> fetchBudgets(String householdId) async {
    final data = await supabase
        .from('budgets')
        .select()
        .eq('household_id', householdId)
        .order('start_date', ascending: true);

    return data.map<Budget>(Budget.fromJson).toList();
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
  Future<Map<String, int>> fetchSpendingByCategory({
    required String householdId,
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await supabase.rpc(
      'get_category_spending',
      params: {
        'p_household_id': householdId,
        'p_from': from.toIso8601String().substring(0, 10),
        'p_to': to.toIso8601String().substring(0, 10),
      },
    );
    if (data == null) return {};
    return {
      for (final row in data as List)
        row['category_id'] as String: (row['net_cents'] as num).toInt(),
    };
  }

  /// Creates a new budget and returns it.
  Future<Budget> createBudget({
    required String householdId,
    required String categoryId,
    required int amountCents,
    required BudgetPeriod period,
    required String createdBy,
    DateTime? startDate,
  }) async {
    final data = await supabase
        .from('budgets')
        .insert({
          'household_id': householdId,
          'category_id': categoryId,
          'amount': amountCents,
          'period': period.dbValue,
          'start_date': (startDate ?? DateTime.now())
              .toIso8601String()
              .substring(0, 10),
          'created_by': createdBy,
        })
        .select()
        .single();

    return Budget.fromJson(data);
  }

  /// Updates the amount and/or period of an existing budget.
  Future<Budget> updateBudget({
    required String budgetId,
    int? amountCents,
    BudgetPeriod? period,
  }) async {
    final data = await supabase
        .from('budgets')
        .update({'amount': ?amountCents, 'period': ?period?.dbValue})
        .eq('id', budgetId)
        .select()
        .single();

    return Budget.fromJson(data);
  }

  /// Deletes a budget by ID.
  Future<void> deleteBudget(String budgetId) async {
    await supabase.from('budgets').delete().eq('id', budgetId);
  }
}
