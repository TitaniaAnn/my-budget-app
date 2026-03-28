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
    int limit = 100,
    int offset = 0,
  }) async {
    // Filters must be applied before .order()/.range() because those return
    // PostgrestTransformBuilder which no longer exposes .eq().
    var query = supabase
        .from('transactions')
        .select('*, category:categories(*)')
        .eq('household_id', householdId);

    if (accountId != null) {
      query = query.eq('account_id', accountId);
    }

    final data = await query
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return data.map<Transaction>(Transaction.fromJson).toList();
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
          // Store only the date portion (YYYY-MM-DD) — the column is DATE not TIMESTAMPTZ.
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
