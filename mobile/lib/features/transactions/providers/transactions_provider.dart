// Riverpod providers for transactions and categories.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../repositories/transactions_repository.dart';

part 'transactions_provider.g.dart';

/// Fetches transactions for the current household with optional filters.
///
/// All params form the family key — each unique combination gets its own
/// cached AsyncValue so filter changes don't clear unrelated caches.
@riverpod
Future<List<Transaction>> transactions(
  TransactionsRef ref, {
  String? accountId,
  String? categoryId,
  String? search,
  DateTime? dateFrom,
  DateTime? dateTo,
}) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return [];

  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.fetchTransactions(
    householdId: householdId,
    accountId: accountId,
    categoryId: categoryId,
    search: search,
    from: dateFrom,
    to: dateTo,
  );
}

/// Fetches all categories (system + household).
/// Cached independently so it doesn't re-fetch every time transactions refresh.
@riverpod
Future<List<Category>> categories(CategoriesRef ref) async {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.fetchCategories();
}
