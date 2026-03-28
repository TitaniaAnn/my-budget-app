// Riverpod providers for transactions and categories.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../repositories/transactions_repository.dart';

part 'transactions_provider.g.dart';

/// Fetches transactions for the current household, optionally filtered by
/// [accountId] (null = all accounts).
///
/// The [accountId] parameter makes this a "family" provider — each unique
/// accountId value gets its own cached AsyncValue, so switching between
/// the All / per-account filter views doesn't trigger a full rebuild.
@riverpod
Future<List<Transaction>> transactions(
  TransactionsRef ref, {
  String? accountId,
}) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return [];

  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.fetchTransactions(householdId: householdId, accountId: accountId);
}

/// Fetches all categories (system + household).
/// Cached independently so it doesn't re-fetch every time transactions refresh.
@riverpod
Future<List<Category>> categories(CategoriesRef ref) async {
  final repo = ref.watch(transactionsRepositoryProvider);
  return repo.fetchCategories();
}
