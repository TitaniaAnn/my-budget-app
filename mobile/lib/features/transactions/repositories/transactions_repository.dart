// Data access layer for transactions and categories.
// Transactions are fetched with a join on categories so the UI gets
// category name/color/icon in a single round-trip.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/transaction.dart';
import '../models/category.dart';

part 'transactions_repository.g.dart';

/// Provides a singleton [TransactionsRepository] instance via Riverpod.
@riverpod
TransactionsRepository transactionsRepository(TransactionsRepositoryRef ref) {
  return TransactionsRepository();
}

class TransactionsRepository {
  /// Fetches transactions for a household, optionally filtered by [accountId].
  ///
  /// Joins the categories table so [Transaction.category] is populated.
  /// Results are paginated via [limit] and [offset]; ordered newest-first.
  Future<List<Transaction>> fetchTransactions({
    required String householdId,
    String? accountId,
    String? categoryId,
    String? search,
    DateTime? from,
    DateTime? to,
    int limit = 1000,
    int offset = 0,
  }) async {
    var query = supabase
        .from('transactions')
        .select('*, category:categories(*)')
        .eq('household_id', householdId);

    if (accountId != null) query = query.eq('account_id', accountId);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (search != null && search.isNotEmpty) {
      query = query.ilike('description', '%$search%');
    }
    if (from != null) {
      query = query.gte('transaction_date', from.toIso8601String().substring(0, 10));
    }
    if (to != null) {
      query = query.lte('transaction_date', to.toIso8601String().substring(0, 10));
    }

    final data = await query
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return data.map<Transaction>(Transaction.fromJson).toList();
  }

  /// Creates a household-specific category and returns it.
  Future<Category> createCategory({
    required String householdId,
    required String name,
    required bool isIncome,
    String? parentId,
    String? icon,
    String? color,
  }) async {
    final data = await supabase
        .from('categories')
        .insert({
          'household_id': householdId,
          'name': name,
          'is_income': isIncome,
          'parent_id': parentId,
          'icon': icon,
          'color': color,
          'sort_order': 500,
        })
        .select()
        .single();
    return Category.fromJson(data);
  }

  /// Deletes a household category. System categories (householdId=null) are
  /// protected by RLS and will reject this call server-side.
  Future<void> deleteCategory(String categoryId) async {
    await supabase.from('categories').delete().eq('id', categoryId);
  }

  /// Fetches all categories (system + household-specific).
  /// System categories have household_id IS NULL; RLS exposes them to everyone.
  Future<List<Category>> fetchCategories() async {
    final data = await supabase
        .from('categories')
        .select()
        .order('sort_order')
        .order('name');
    return data.map<Category>(Category.fromJson).toList();
  }

  /// Inserts a single manually-entered transaction and returns it with
  /// the category row joined.
  Future<Transaction> createTransaction({
    required String householdId,
    required String accountId,
    required String enteredBy,
    required int amount,
    required String description,
    required DateTime transactionDate,
    String? merchant,
    String? categoryId,
    String? rateId,
    String? notes,
  }) async {
    final data = await supabase
        .from('transactions')
        .insert({
          'household_id': householdId,
          'account_id': accountId,
          'entered_by': enteredBy,
          'amount': amount,
          'currency': 'USD',
          'description': description,
          'merchant': merchant,
          'category_id': categoryId,
          'rate_id': rateId,
          'transaction_date':
              transactionDate.toIso8601String().substring(0, 10),
          'source': 'manual',
        })
        .select('*, category:categories(*)')
        .single();

    return Transaction.fromJson(data);
  }

  /// Fetches all transactions within a date range for dashboard summaries.
  /// Joins categories so spending-by-category can be computed in Dart.
  Future<List<Transaction>> fetchTransactionsForDashboard({
    required String householdId,
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await supabase
        .from('transactions')
        .select('*, category:categories(*)')
        .eq('household_id', householdId)
        .gte('transaction_date', from.toIso8601String().substring(0, 10))
        .lte('transaction_date', to.toIso8601String().substring(0, 10))
        .order('transaction_date', ascending: false);

    return data.map<Transaction>(Transaction.fromJson).toList();
  }

  /// Updates a manually-entered transaction.
  Future<void> updateTransaction({
    required String id,
    required int amount,
    required String description,
    String? merchant,
    String? categoryId,
    String? rateId,
    required DateTime transactionDate,
    String? notes,
  }) async {
    await supabase.from('transactions').update({
      'amount': amount,
      'description': description,
      'merchant': merchant,
      'category_id': categoryId,
      'rate_id': rateId,
      'transaction_date': transactionDate.toIso8601String().substring(0, 10),
      'notes': notes,
    }).eq('id', id);
  }

  /// Hard-deletes a transaction row.
  Future<void> deleteTransaction(String id) async {
    await supabase.from('transactions').delete().eq('id', id);
  }

  /// Re-runs the category matcher on all uncategorized transactions for
  /// [householdId] (optionally scoped to [accountId]) and bulk-updates their
  /// category_id. Returns the number of transactions updated.
  Future<int> bulkRecategorize({
    required String householdId,
    String? accountId,
    required String? Function(String description, {required bool isIncome}) matcher,
  }) async {
    var query = supabase
        .from('transactions')
        .select('id, description, amount')
        .eq('household_id', householdId)
        .isFilter('category_id', null);

    if (accountId != null) query = query.eq('account_id', accountId);

    final rows = await query;
    if (rows.isEmpty) return 0;

    final updates = <Map<String, dynamic>>[];
    for (final row in rows) {
      final categoryId = matcher(
        row['description'] as String,
        isIncome: (row['amount'] as int) > 0,
      );
      if (categoryId != null) {
        updates.add({'id': row['id'] as String, 'category_id': categoryId});
      }
    }

    for (final update in updates) {
      await supabase
          .from('transactions')
          .update({'category_id': update['category_id']})
          .eq('id', update['id'] as String);
    }

    return updates.length;
  }

  /// Bulk-inserts imported transactions.
  ///
  /// Uses upsert with conflict resolution on (account_id, external_id) so
  /// re-importing the same CSV is safe — duplicates are silently ignored.
  /// Returns the number of rows submitted (including any that were skipped).
  Future<int> bulkImport({
    required String householdId,
    required String accountId,
    required String enteredBy,
    required List<Map<String, dynamic>> rows,
  }) async {
    if (rows.isEmpty) return 0;

    final enriched = rows
        .map((r) => {
              ...r,
              'household_id': householdId,
              'account_id': accountId,
              'entered_by': enteredBy,
              'currency': 'USD',
              'source': 'import',
            })
        .toList();

    await supabase
        .from('transactions')
        .upsert(enriched, onConflict: 'account_id,external_id');

    return enriched.length;
  }
}
