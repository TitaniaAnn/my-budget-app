// Local SQLite database (drift) backing the offline read cache.
//
// Audit L1 — Phase 1. Each table here mirrors a Supabase table 1:1
// in column shape (snake_case, same primitive types) so a server
// row JSON-decodes directly into a Companion. The cache is per-
// install (not per-household) and lives in the app's documents
// directory: `<docs>/mybudget_cache.sqlite`.
//
// Phase 1 surface:
//   * Accounts table only (validation of the pipeline before we
//     scale to N tables).
//   * `cached_at` column stamps when the row was last refreshed
//     from the server — feeds the "last updated X ago" indicator
//     in Phase 2 and the stale-eviction policy if we add one.
//   * `upsertAccount` / `upsertAccounts` / `clearAccountsForHousehold`
//     / `loadAccountsForHousehold` — the surface
//     AccountsRepository needs for cache-through reads.
//
// What this DB is NOT:
//   * NOT the source of truth — Postgres is. On any conflict, the
//     server wins (the cache-through write order is "network
//     succeeds, THEN cache; if cache write fails it's logged but
//     not surfaced — we already have the data in memory").
//   * NOT a place to put user state that isn't on the server. App
//     prefs, last-fired notification map, etc. stay in
//     SharedPreferences.
//   * NOT a write queue. Mutations still hit the network directly
//     in Phase 1; Phase 3 adds a `pending_writes` table for the
//     offline-write case.
//
// Schema migrations: drift's `MigrationStrategy` is the home for
// schema bumps. The schemaVersion field on AppDatabase is the
// authoritative version; bump it AND add an `onUpgrade` branch
// whenever a column is added/dropped.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Mirror of the Supabase `accounts` table.
///
/// Column names + types match the server 1:1 (snake_case, integer
/// cents for money) so the JSON returned by `supabase.from('accounts')
/// .select()` maps directly into [AccountsCacheCompanion]. The one
/// drift-only column is [cachedAt] — the wall-clock moment we
/// last refreshed this row from the server.
@DataClassName('AccountsCacheRow')
class AccountsCache extends Table {
  // Postgres UUIDs stored as TEXT — drift has no native UUID type
  // and the comparison semantics on TEXT match what we need.
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get ownerUserId => text()();
  TextColumn get name => text()();

  /// Stores the dbValue of [AccountType] (e.g. 'checking',
  /// 'credit_card'). The Dart-side AccountType.values lookup is in
  /// the repository's row→Account mapper.
  TextColumn get accountType => text()();

  TextColumn get institution => text().nullable()();
  TextColumn get lastFour => text().nullable()();
  TextColumn get currency => text()();
  IntColumn get startingBalance => integer().withDefault(const Constant(0))();
  IntColumn get currentBalance => integer()();
  IntColumn get creditLimit => integer().nullable()();
  BoolColumn get isActive => boolean()();
  TextColumn get color => text().nullable()();
  RealColumn get interestRate => real().nullable()();

  /// Server-side timestamps. Drift stores DateTime as Unix epoch
  /// seconds in UTC by default, which round-trips cleanly with
  /// Postgres TIMESTAMPTZ via `.toUtc()`.
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Drift-only: when we last pulled this row from the server.
  /// Phase 2 surfaces this as "last updated X minutes ago" on the
  /// accounts screen; Phase 4+ uses it for stale-eviction.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror of the Supabase `categories` table.
///
/// System categories (seeded by migration 002) have `householdId
/// IS NULL` and are visible to every user; household-specific
/// categories have a non-null householdId. RLS already enforces
/// visibility on the server side — the cache mirrors what the
/// caller's `fetchCategories()` returned, which already filters
/// to "categories I can see," so no household scoping is needed
/// here.
@DataClassName('CategoriesCacheRow')
class CategoriesCache extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get isIncome => boolean()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror of the Supabase `transactions` table.
///
/// The cache is queried with the same shape as the server-side
/// fetchTransactions (householdId required, account/category/
/// date/search filters optional). Joins with [CategoriesCache]
/// on read so the `category` field on Transaction can be
/// populated for the UI.
///
/// One index — (household_id, transaction_date DESC) — matches
/// the dashboard's hot query path. Other drill-down columns
/// (account_id, category_id) are still queryable but pay the
/// full-scan-within-household cost; acceptable for a per-install
/// cache that's small (typically <50K rows).
@DataClassName('TransactionsCacheRow')
class TransactionsCache extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get accountId => text()();

  /// Signed cents. Negative = expense, positive = income.
  IntColumn get amount => integer()();
  TextColumn get currency => text()();
  TextColumn get description => text()();
  TextColumn get merchant => text().nullable()();
  TextColumn get categoryId => text().nullable()();

  /// Stored as a UTC DateTime even though the server column is
  /// DATE. Drift's dateTime() round-trips fine — the time
  /// component is always 00:00 UTC.
  DateTimeColumn get transactionDate => dateTime()();
  DateTimeColumn get postedDate => dateTime().nullable()();
  BoolColumn get pending => boolean()();

  /// Stores the raw enum string ('manual', 'import', 'plaid',
  /// 'recurring') verbatim. Repository maps to/from Transaction.
  TextColumn get source => text()();

  TextColumn get enteredBy => text().nullable()();
  TextColumn get receiptId => text().nullable()();
  TextColumn get rateId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get externalId => text().nullable()();
  TextColumn get transferId => text().nullable()();
  IntColumn get mlModelConfidence => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [AccountsCache, CategoriesCache, TransactionsCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor — passes an explicit executor so tests
  /// can open an in-memory database (`NativeDatabase.memory()`)
  /// and avoid touching the real filesystem.
  AppDatabase.withExecutor(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2: added CategoriesCache + TransactionsCache for
      // Phase 2 of the offline cache rollout. The accounts cache
      // table from v1 is unchanged.
      if (from < 2) {
        await m.createTable(categoriesCache);
        await m.createTable(transactionsCache);
      }
    },
  );

  // ── Accounts cache surface ──────────────────────────────────

  /// Insert-or-replace a single account row. Drift's
  /// `InsertMode.replace` matches Postgres' `INSERT … ON CONFLICT
  /// (id) DO UPDATE` semantics, which is what we want — the server
  /// is the source of truth and the freshest row wins.
  Future<void> upsertAccount(AccountsCacheCompanion row) {
    return into(accountsCache).insert(row, mode: InsertMode.replace);
  }

  /// Bulk variant. Wrapped in a transaction so a partial failure
  /// (extremely unlikely on local SQLite but possible on disk-full)
  /// rolls back to the prior state cleanly rather than leaving the
  /// cache half-written.
  Future<void> upsertAccounts(List<AccountsCacheCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(accountsCache, rows, mode: InsertMode.replace);
    });
  }

  /// Replace all cached rows for a household with [rows]. Used after
  /// a successful list fetch so the cache exactly mirrors the
  /// server's view (any server-side soft-delete drops out of the
  /// cache, matching the `is_active=true` filter on the query).
  ///
  /// Atomic via transaction — the delete and re-insert succeed or
  /// fail together; we never end up with an empty cache because of
  /// a mid-write crash.
  Future<void> replaceAccountsForHousehold(
    String householdId,
    List<AccountsCacheCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(
        accountsCache,
      )..where((t) => t.householdId.equals(householdId))).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(accountsCache, rows, mode: InsertMode.replace);
        });
      }
    });
  }

  /// Read all cached accounts for a household, filtering on
  /// is_active and sorting newest-first to match the server's
  /// AccountsRepository.fetchAccounts contract. Returns an empty
  /// list when nothing is cached.
  Future<List<AccountsCacheRow>> loadAccountsForHousehold(
    String householdId,
  ) {
    return (select(accountsCache)
          ..where((t) => t.householdId.equals(householdId) & t.isActive)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Delete a single cached row by id. Called after a successful
  /// server-side delete so the cache doesn't show a row the user
  /// just removed.
  Future<void> deleteAccount(String id) {
    return (delete(accountsCache)..where((t) => t.id.equals(id))).go();
  }

  // ── Categories cache surface ────────────────────────────────

  /// Replace every cached category row with [rows]. Categories
  /// are loaded all-at-once (`fetchCategories()` has no filter
  /// shape), so the cache is a single set rather than per-
  /// household — system categories and every household's custom
  /// categories live side-by-side, matching what the server
  /// returns.
  Future<void> replaceCategories(List<CategoriesCacheCompanion> rows) async {
    await transaction(() async {
      await delete(categoriesCache).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(categoriesCache, rows, mode: InsertMode.replace);
        });
      }
    });
  }

  /// Insert-or-replace a single category row. Called after a
  /// server-side create.
  Future<void> upsertCategory(CategoriesCacheCompanion row) {
    return into(categoriesCache).insert(row, mode: InsertMode.replace);
  }

  Future<void> deleteCategory(String id) {
    return (delete(categoriesCache)..where((t) => t.id.equals(id))).go();
  }

  /// Load every cached category ordered (sortOrder ASC, name
  /// ASC) — matches the server-side fetchCategories contract.
  Future<List<CategoriesCacheRow>> loadCategories() {
    return (select(categoriesCache)..orderBy([
          (t) => OrderingTerm.asc(t.sortOrder),
          (t) => OrderingTerm.asc(t.name),
        ]))
        .get();
  }

  // ── Transactions cache surface ──────────────────────────────

  /// Insert-or-replace a single transaction row. Called after a
  /// server-side create/update returns the row.
  Future<void> upsertTransaction(TransactionsCacheCompanion row) {
    return into(transactionsCache).insert(row, mode: InsertMode.replace);
  }

  /// Bulk variant for the result of fetchTransactions. Wrapped in
  /// a batch so a partial failure rolls back.
  Future<void> upsertTransactions(
    List<TransactionsCacheCompanion> rows,
  ) async {
    if (rows.isEmpty) return;
    await batch((b) {
      b.insertAll(transactionsCache, rows, mode: InsertMode.replace);
    });
  }

  Future<void> deleteTransaction(String id) {
    return (delete(transactionsCache)..where((t) => t.id.equals(id))).go();
  }

  /// Delete a set of transactions by id — used to mirror the
  /// server-side `delete().inFilter('id', ids)` of bulk-delete.
  /// Returns the number of rows removed.
  Future<int> deleteTransactionsByIds(List<String> ids) async {
    if (ids.isEmpty) return 0;
    return (delete(transactionsCache)..where((t) => t.id.isIn(ids))).go();
  }

  /// Filtered transactions read for the cache-fallback path.
  ///
  /// Mirrors fetchTransactions' filter shape with one omission:
  /// the [search] term is applied as a SQLite LIKE (case-
  /// insensitive for ASCII) over description OR merchant. No tag
  /// filter — the tag-assignment tables are a Phase 2b mirror;
  /// callers that pass tagFilteredIds via [idsFilter] get those
  /// pre-filtered rows.
  ///
  /// Joins [CategoriesCache] LEFT OUTER so the result rows carry
  /// the joined Category for the Transaction model to populate.
  Future<List<TransactionWithCategoryRow>> loadTransactionsForHousehold({
    required String householdId,
    String? accountId,
    String? categoryId,
    DateTime? from,
    DateTime? to,
    String? search,
    List<String>? idsFilter,
    int limit = 1000,
    int offset = 0,
  }) async {
    // Optimisation: an empty idsFilter (set by a tag with no
    // assignments) short-circuits to an empty result without
    // touching the table. Matches the server-side early-return.
    if (idsFilter != null && idsFilter.isEmpty) {
      return const [];
    }

    final query = select(transactionsCache).join([
      leftOuterJoin(
        categoriesCache,
        categoriesCache.id.equalsExp(transactionsCache.categoryId),
      ),
    ]);

    final tx = transactionsCache;
    query.where(tx.householdId.equals(householdId));
    if (accountId != null) query.where(tx.accountId.equals(accountId));
    if (categoryId != null) query.where(tx.categoryId.equals(categoryId));
    if (from != null) query.where(tx.transactionDate.isBiggerOrEqualValue(from));
    if (to != null) query.where(tx.transactionDate.isSmallerOrEqualValue(to));
    if (idsFilter != null) query.where(tx.id.isIn(idsFilter));
    if (search != null && search.isNotEmpty) {
      // SQLite LIKE is case-insensitive for ASCII by default —
      // no `.ilike()` needed. We do NOT escape `%`/`_` here: a
      // proper ESCAPE clause would require dropping to a raw
      // expression, and the cost of an over-broad cache result
      // on an unusual search input is small (a few extra rows
      // returned offline). The server-side query handles escape
      // correctly when online.
      final term = '%$search%';
      query.where(tx.description.like(term) | tx.merchant.like(term));
    }

    query.orderBy([
      OrderingTerm.desc(tx.transactionDate),
      OrderingTerm.desc(tx.createdAt),
    ]);
    query.limit(limit, offset: offset);

    final result = await query.get();
    return result.map((row) {
      return TransactionWithCategoryRow(
        transaction: row.readTable(transactionsCache),
        category: row.readTableOrNull(categoriesCache),
      );
    }).toList();
  }
}

/// Single row of the transactions-with-joined-category query.
/// Keeps the join result types out of the consuming repository's
/// signature; the repo maps this into the Transaction freezed
/// model with the category embedded.
class TransactionWithCategoryRow {
  const TransactionWithCategoryRow({
    required this.transaction,
    required this.category,
  });
  final TransactionsCacheRow transaction;
  final CategoriesCacheRow? category;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'mybudget_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
