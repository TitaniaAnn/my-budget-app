// Riverpod provider for the accounts list.
// Depends on [householdIdProvider] so it only runs after the household is known.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../models/account.dart';
import '../repositories/accounts_repository.dart';

part 'accounts_provider.g.dart';

/// Fetches all active accounts for the current household.
///
/// Invalidating this provider (e.g. after creating or deleting an account)
/// triggers a fresh fetch from Supabase automatically.
@riverpod
Future<List<Account>> accounts(AccountsRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return [];

  final repo = ref.watch(accountsRepositoryProvider);
  return repo.fetchAccounts(householdId);
}
