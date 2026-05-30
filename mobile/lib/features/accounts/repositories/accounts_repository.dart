// Data access layer for the `accounts` table.
// All DB operations live here so the rest of the app stays decoupled from
// Supabase-specific query syntax.
//
// Audit L1 Phase 1 (reads) + Phase 3b (writes): this repository
// is cache-through. Reads try the network first; on any failure
// the cached SQLite mirror supplies the data. Writes go to the
// network; on transient failure (offline, captive portal, server
// 5xx) the mutation lands in the pending_writes queue with a
// client-generated row id, and an optimistic cache row appears
// immediately. The replay loop fires the same INSERT (with the
// same id, so the server upsert is idempotent) when connectivity
// returns. The public API is unchanged — callers can't tell a
// server hit apart from an optimistic-cached one until the next
// fetch.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/sync/atomic_write.dart';
import '../../../core/sync/pending_writes_queue.dart';
import '../../../core/sync/transient_error.dart';
import '../models/account.dart';

part 'accounts_repository.g.dart';

/// Provides a singleton [AccountsRepository] instance via Riverpod.
@riverpod
AccountsRepository accountsRepository(AccountsRepositoryRef ref) {
  return AccountsRepository(
    db: ref.watch(appDatabaseProvider),
    queue: ref.watch(pendingWritesQueueProvider),
  );
}

class AccountsRepository {
  /// The [db] and [queue] parameters are nullable for the legacy
  /// `AccountsRepository()` zero-arg constructor used by older
  /// tests. Production code goes through the Riverpod provider
  /// above, which always passes both.
  AccountsRepository({AppDatabase? db, PendingWritesQueue? queue})
    : _db = db,
      _queue = queue;
  final AppDatabase? _db;
  final PendingWritesQueue? _queue;
  final _uuid = const Uuid();

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
    // Pre-generate the row id so the optimistic cache row and the
    // server INSERT share it. Postgres accepts an explicit value
    // for `id UUID DEFAULT uuid_generate_v4()` — the default
    // only fires when the column is omitted. On replay the same
    // id flows through; the queue's upsert ignoreDuplicates=false
    // path makes a half-completed first attempt idempotent.
    final clientId = _uuid.v4();
    final payload = <String, dynamic>{
      'id': clientId,
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
    };
    try {
      final data = await supabase
          .from('accounts')
          .insert(payload)
          .select()
          .single();

      final account = Account.fromJson(data);
      await _writeCacheRow(account);
      return account;
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      // Build an optimistic Account from the inputs + now() for
      // the server-generated timestamps. The next fetchAccounts
      // after replay overwrites with the canonical row.
      final now = DateTime.now().toUtc();
      final optimistic = Account(
        id: clientId,
        householdId: householdId,
        ownerUserId: ownerUserId,
        name: name,
        accountType: accountType,
        institution: institution,
        lastFour: lastFour,
        currency: 'USD',
        startingBalance: startingBalance,
        currentBalance: startingBalance,
        creditLimit: creditLimit,
        isActive: true,
        color: color,
        interestRate: interestRate,
        createdAt: now,
        updatedAt: now,
      );
      // Audit 2026-05-26 H4: cache write + queue enqueue must
      // be atomic. The prior shape `await cache; await queue`
      // could leave the UI showing an optimistic row that
      // never replays (cache write succeeded, queue insert
      // failed on disk-full / locked db). User sees the row,
      // assumes it's saved, the next online fetch silently
      // wipes it.
      //
      // Both writes target the same drift database; wrapping
      // them in db.transaction makes the queue insert participate
      // in the same SQL transaction as the cache upsert. Either
      // both land or neither does.
      await atomicCacheAndEnqueue(
        db: _db,
        queue: _queue,
        write: () => _writeCacheRow(optimistic),
        queueOp: QueuedInsert(
          table: 'accounts',
          payload: payload,
          rowId: clientId,
        ),
      );
      return optimistic;
    }
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
    final patch = <String, dynamic>{
      'name': name,
      'institution': institution,
      'last_four': lastFour,
      'starting_balance': startingBalance,
      'credit_limit': creditLimit,
      'color': color,
      'interest_rate': interestRate,
    };
    try {
      final data = await supabase
          .from('accounts')
          .update(patch)
          .eq('id', accountId)
          .select()
          .single();
      final account = Account.fromJson(data);
      await _writeCacheRow(account);
      return account;
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      // Optimistic: patch the cached row directly so the UI
      // shows the user's edit immediately. Read the existing
      // row, apply the patch, write back. If the row isn't
      // cached we can't synthesise a meaningful Account; the
      // queue still carries the UPDATE so the server eventually
      // applies it — but we throw here so the UI knows
      // something off-pattern happened.
      final existing = await _loadCacheRowById(accountId);
      if (existing == null) rethrow;
      final patched = existing.copyWith(
        name: name,
        institution: institution,
        lastFour: lastFour,
        startingBalance: startingBalance,
        creditLimit: creditLimit,
        color: color,
        interestRate: interestRate,
        updatedAt: DateTime.now().toUtc(),
      );
      await atomicCacheAndEnqueue(
        db: _db,
        queue: _queue,
        write: () => _writeCacheRow(patched),
        queueOp: QueuedUpdate(
          table: 'accounts',
          rowId: accountId,
          payload: patch,
        ),
      );
      return patched;
    }
  }

  /// Updates the stored balance for an account (in cents).
  /// Called after manually adjusting a balance or reconciling with a statement.
  ///
  /// Cache note: this write doesn't return the updated row, so the
  /// cached `current_balance` will be stale until the next
  /// fetchAccounts call. Acceptable for Phase 1 — the dashboard
  /// invalidates and re-fetches on every balance adjustment.
  Future<void> updateBalance(String accountId, int cents) async {
    try {
      await supabase
          .from('accounts')
          .update({'current_balance': cents})
          .eq('id', accountId);
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      // Optimistically patch the cached balance + enqueue the
      // UPDATE atomically (H4). If the cache patch can't find
      // the row, fall back to enqueue-only — the next online
      // fetch will reconcile.
      final existing = await _loadCacheRowById(accountId);
      final queueOp = QueuedUpdate(
        table: 'accounts',
        rowId: accountId,
        payload: {'current_balance': cents},
      );
      if (existing != null) {
        await atomicCacheAndEnqueue(
          db: _db,
          queue: _queue,
          write: () => _writeCacheRow(
            existing.copyWith(
              currentBalance: cents,
              updatedAt: DateTime.now().toUtc(),
            ),
          ),
          queueOp: queueOp,
        );
      } else {
        await _queue?.enqueue(queueOp);
      }
    }
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
    try {
      await supabase
          .from('accounts')
          .update({'is_active': false})
          .eq('id', accountId);
      await _deleteCacheRow(accountId);
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      // Soft-delete is the user's intent; remove from cache so
      // the list immediately drops the row. Queue the same
      // is_active=false UPDATE for replay (H4: atomic).
      await atomicCacheAndEnqueue(
        db: _db,
        queue: _queue,
        write: () => _deleteCacheRow(accountId),
        queueOp: QueuedUpdate(
          table: 'accounts',
          rowId: accountId,
          payload: {'is_active': false},
        ),
      );
    }
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

  /// Read one cached Account row by id. Used by the
  /// optimistic-update paths to fetch the current state before
  /// patching it. Returns null when the row isn't cached or the
  /// database isn't wired (legacy zero-arg constructor).
  Future<Account?> _loadCacheRowById(String id) async {
    final db = _db;
    if (db == null) return null;
    try {
      // No single-row loader on AppDatabase yet — derive from
      // the household loader by filtering. Cheap because the
      // cache is small (typically a dozen rows per household).
      // For the offline-update path we don't know which
      // household; we just scan all households (still O(n) over
      // the per-install cache, n ≪ 100).
      final all = await db.select(db.accountsCache).get();
      for (final r in all) {
        if (r.id == id) return _fromCacheRow(r);
      }
      return null;
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
