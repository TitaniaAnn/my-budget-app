// Data access layer for the `accounts` table.
// All DB operations live here so the rest of the app stays decoupled from
// Supabase-specific query syntax.
//
// Audit L1 Phase 1: this repository is cache-through. Reads try the
// network first; on any failure (offline, captive portal, server
// 5xx that survives the retry helper) the cached SQLite mirror
// supplies the data. Writes go to the network as before; on
// success the cache is updated in lockstep so the next read sees
// the same row. The public API is unchanged — callers don't
// distinguish a cache hit from a server hit.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/account.dart';

part 'accounts_repository.g.dart';

/// Provides a singleton [AccountsRepository] instance via Riverpod.
@riverpod
AccountsRepository accountsRepository(AccountsRepositoryRef ref) {
  return AccountsRepository(db: ref.watch(appDatabaseProvider));
}

class AccountsRepository {
  /// The [db] parameter is nullable for the legacy
  /// `AccountsRepository()` zero-arg constructor used by older
  /// tests. Production code goes through the Riverpod provider
  /// above, which always passes the singleton database.
  AccountsRepository({AppDatabase? db}) : _db = db;
  final AppDatabase? _db;

  /// Fetches all active accounts for a household, newest first.
  /// RLS on the `accounts` table ensures only visible accounts are returned.
  ///
  /// `ascending: false` is the current (and intentional) behavior —
  /// a recently-added account appears at the top of the list so the
  /// user can find it without scrolling. Stated explicitly because
  /// postgrest's .order() default happens to match, and an
  /// uninformed reader (or a library upgrade that flips the default)
  /// could quietly change the UX.
  ///
  /// Cache-through: server response refreshes the local mirror. On
  /// any network failure the cached mirror is returned instead,
  /// keeping the UI usable offline. Cache-empty + network-fail
  /// rethrows the original error so the user sees the real
  /// network error (not a silent "nothing here").
  Future<List<Account>> fetchAccounts(String householdId) async {
    try {
      final data = await supabase
          .from('accounts')
          .select()
          .eq('household_id', householdId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final accounts = data.map<Account>(Account.fromJson).toList();
      await _refreshCacheForHousehold(householdId, accounts);
      return accounts;
    } catch (e) {
      final cached = await _loadFromCache(householdId);
      if (cached != null) return cached;
      rethrow;
    }
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
    required int startingBalance,
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
          'starting_balance': startingBalance,
          'current_balance': startingBalance,
          'credit_limit': creditLimit,
          'color': color,
          'interest_rate': interestRate,
          'currency': 'USD',
        })
        .select()
        .single();

    final account = Account.fromJson(data);
    await _writeCacheRow(account);
    return account;
  }

  /// Updates account metadata and returns the updated [Account].
  Future<Account> updateAccount({
    required String accountId,
    required String name,
    String? institution,
    String? lastFour,
    required int startingBalance,
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
          'starting_balance': startingBalance,
          'credit_limit': creditLimit,
          'color': color,
          'interest_rate': interestRate,
        })
        .eq('id', accountId)
        .select()
        .single();
    final account = Account.fromJson(data);
    await _writeCacheRow(account);
    return account;
  }

  /// Updates the stored balance for an account (in cents).
  /// Called after manually adjusting a balance or reconciling with a statement.
  ///
  /// Cache note: this write doesn't return the updated row, so the
  /// cached `current_balance` will be stale until the next
  /// fetchAccounts call. Acceptable for Phase 1 — the dashboard
  /// invalidates and re-fetches on every balance adjustment.
  Future<void> updateBalance(String accountId, int cents) async {
    await supabase
        .from('accounts')
        .update({'current_balance': cents})
        .eq('id', accountId);
  }

  /// Recalculates [accountId]'s balance by summing all transaction amounts
  /// and writes the result back to `current_balance`.
  /// Call this after any bulk transaction import.
  ///
  /// Implemented as a single Postgres RPC so the read-sum-write happens
  /// atomically — a concurrent transaction insert can't be lost between
  /// the read and the write.
  ///
  /// Cache note: same as updateBalance — the server-side mutation
  /// doesn't refresh the local mirror. Next fetchAccounts call
  /// reconciles.
  Future<void> recalculateBalance(String accountId) async {
    await supabase.rpc(
      'recalculate_account_balance',
      params: {'p_account_id': accountId},
    );
  }

  /// Soft-deletes an account by marking it inactive rather than destroying
  /// the row, so historical transaction data is preserved.
  ///
  /// Cache write: the cached list filters on `is_active=true`, so
  /// removing the row from cache (rather than updating its
  /// is_active flag) keeps the cache in sync with what
  /// fetchAccounts would return.
  Future<void> deleteAccount(String accountId) async {
    await supabase
        .from('accounts')
        .update({'is_active': false})
        .eq('id', accountId);
    await _deleteCacheRow(accountId);
  }

  // ── Cache helpers ──────────────────────────────────────────
  // All wrapped in try/catch so the cache layer is opportunistic:
  // a corrupt SQLite file or a disk-full error doesn't break the
  // user-visible network round-trip. We log via stderr (debug
  // builds) but never rethrow from a cache helper.

  Future<void> _refreshCacheForHousehold(
    String householdId,
    List<Account> accounts,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.replaceAccountsForHousehold(
        householdId,
        accounts.map(_toCompanion).toList(),
      );
    } catch (_) {
      // Cache failure is non-fatal — we have the data in memory.
    }
  }

  Future<void> _writeCacheRow(Account account) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.upsertAccount(_toCompanion(account));
    } catch (_) {
      // Cache failure is non-fatal.
    }
  }

  Future<void> _deleteCacheRow(String accountId) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.deleteAccount(accountId);
    } catch (_) {
      // Cache failure is non-fatal.
    }
  }

  Future<List<Account>?> _loadFromCache(String householdId) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.loadAccountsForHousehold(householdId);
      if (rows.isEmpty) return null;
      return rows.map(_fromCacheRow).toList();
    } catch (_) {
      return null;
    }
  }
}

/// Maps an Account model to the drift Companion for cache writes.
///
/// `account_type` is stored as the Postgres dbValue (e.g.
/// 'credit_card') so the row can round-trip through the cache and
/// resolve back to the same enum variant on read. `cachedAt` is
/// stamped at write time.
AccountsCacheCompanion _toCompanion(Account a) {
  return AccountsCacheCompanion(
    id: Value(a.id),
    householdId: Value(a.householdId),
    ownerUserId: Value(a.ownerUserId),
    name: Value(a.name),
    accountType: Value(a.accountType.dbValue),
    institution: Value(a.institution),
    lastFour: Value(a.lastFour),
    currency: Value(a.currency),
    startingBalance: Value(a.startingBalance),
    currentBalance: Value(a.currentBalance),
    creditLimit: Value(a.creditLimit),
    isActive: Value(a.isActive),
    color: Value(a.color),
    interestRate: Value(a.interestRate),
    createdAt: Value(a.createdAt.toUtc()),
    updatedAt: Value(a.updatedAt.toUtc()),
    cachedAt: Value(DateTime.now().toUtc()),
  );
}

/// Inverse of [_toCompanion] — converts a cached row back into an
/// Account model. The `account_type` lookup is linear over
/// AccountType.values; the enum is tiny and this happens once per
/// row, not per byte.
Account _fromCacheRow(AccountsCacheRow r) {
  return Account(
    id: r.id,
    householdId: r.householdId,
    ownerUserId: r.ownerUserId,
    name: r.name,
    accountType: AccountType.values.firstWhere(
      (t) => t.dbValue == r.accountType,
      // Fallback for a row written by a newer version of the app
      // (added an enum variant) being read by an older version.
      // Picking 'cash' rather than throwing keeps the UI usable.
      orElse: () => AccountType.cash,
    ),
    institution: r.institution,
    lastFour: r.lastFour,
    currency: r.currency,
    startingBalance: r.startingBalance,
    currentBalance: r.currentBalance,
    creditLimit: r.creditLimit,
    isActive: r.isActive,
    color: r.color,
    interestRate: r.interestRate,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}
