// List provider for the household's recurring rules.
//
// Watches [householdIdProvider] so it refetches when the household
// changes. Returns rules ordered by next_occurrence_date ASC, the
// same default sort the repository uses — soonest-due first matches
// the management screen's "what's coming up" intent.
//
// Includes inactive rules; the management screen filters Dart-side
// when the user toggles "Show paused" so flipping between modes
// doesn't trigger a refetch.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/household_provider.dart';
import '../models/recurring_transaction.dart';
import '../repositories/recurring_transactions_repository.dart';

part 'recurring_transactions_provider.g.dart';

@riverpod
Future<List<RecurringTransaction>> recurringTransactions(
  RecurringTransactionsRef ref,
) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return const [];
  final repo = ref.read(recurringTransactionsRepositoryProvider);
  return repo.fetchAll(householdId);
}
