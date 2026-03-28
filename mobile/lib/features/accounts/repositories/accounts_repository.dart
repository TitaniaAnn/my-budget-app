// Data access layer for the `accounts` table.
// All DB operations live here so the rest of the app stays decoupled from
// Supabase-specific query syntax.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/account.dart';

part 'accounts_repository.g.dart';

/// Provides a singleton [AccountsRepository] instance via Riverpod.
@riverpod
AccountsRepository accountsRepository(AccountsRepositoryRef ref) {
  return AccountsRepository();
}

class AccountsRepository {
  /// Fetches all active accounts for a household, ordered by creation date.
  /// RLS on the `accounts` table ensures only visible accounts are returned.
  Future<List<Account>> fetchAccounts(String householdId) async {
    final data = await supabase
        .from('accounts')
        .select()
        .eq('household_id', householdId)
        .eq('is_active', true)
        .order('created_at');

    return data.map<Account>(Account.fromJson).toList();
  }

  /// Inserts a new account row and returns the created [Account].
  /// [currentBalance] is the opening balance in cents.
  /// [creditLimit] should only be provided for [AccountType.creditCard].
  Future<Account> createAccount({
    required String householdId,
    required String ownerUserId,
    required String name,
    required AccountType accountType,
    String? institution,
    String? lastFour,
    required int currentBalance,
    int? creditLimit,
    String? color,
    double? interestRate,
  }) async {
    final data = await supabase
        .from('accounts')
        .insert({
          'household_id': householdId,
          'owner_user_id': ownerUserId,
          'name': name,
          'account_type': accountType.dbValue,
          'institution': institution,
          'last_four': lastFour,
          'current_balance': currentBalance,
          'credit_limit': creditLimit,
          'color': color,
          'interest_rate': interestRate,
          'currency': 'USD',
        })
        .select()
        .single();

    return Account.fromJson(data);
  }

  /// Updates account metadata and returns the updated [Account].
  Future<Account> updateAccount({
    required String accountId,
    required String name,
    String? institution,
    String? lastFour,
    required int currentBalance,
    int? creditLimit,
    String? color,
    double? interestRate,
  }) async {
    final data = await supabase
        .from('accounts')
        .update({
          'name': name,
          'institution': institution,
          'last_four': lastFour,
          'current_balance': currentBalance,
          'credit_limit': creditLimit,
          'color': color,
          'interest_rate': interestRate,
        })
        .eq('id', accountId)
        .select()
        .single();
    return Account.fromJson(data);
  }

  /// Updates the stored balance for an account (in cents).
  /// Called after manually adjusting a balance or reconciling with a statement.
  Future<void> updateBalance(String accountId, int cents) async {
    await supabase
        .from('accounts')
        .update({'current_balance': cents})
        .eq('id', accountId);
  }

  /// Soft-deletes an account by marking it inactive rather than destroying
  /// the row, so historical transaction data is preserved.
  Future<void> deleteAccount(String accountId) async {
    await supabase
        .from('accounts')
        .update({'is_active': false})
        .eq('id', accountId);
  }
}
