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

/// Mirror of the Supabase `budgets` table.
///
/// One row per (household, category, period) — the budgets UI
/// shows the row joined with its category. Cached with the
/// drift-only `cachedAt` to support a "last synced" indicator.
@DataClassName('BudgetsCacheRow')
class BudgetsCache extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get categoryId => text()();
  IntColumn get amount => integer()();
  TextColumn get currency => text().withDefault(const Constant('USD'))();

  /// Stores the BudgetPeriod dbValue verbatim ('weekly',
  /// 'monthly', etc.). Repository maps to/from the enum.
  TextColumn get period => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get createdBy => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror of the Supabase `fx_rates` table.
///
/// Composite primary key matches the server side:
/// (household_id, from_currency, to_currency, as_of_date). The
/// "latest rate at or before X" hot query is supported by
/// loadLatestRate, which mirrors the server's
/// `.order(as_of_date DESC).limit(1)` shape.
@DataClassName('FxRatesCacheRow')
class FxRatesCache extends Table {
  TextColumn get householdId => text()();
  TextColumn get fromCurrency => text()();
  TextColumn get toCurrency => text()();
  DateTimeColumn get asOfDate => dateTime()();

  /// Drift's `real()` is a double. The server stores
  /// NUMERIC(18,8); the JSON-wire-coerce in FxRate.fromJson
  /// already handles the string-to-double bridge.
  RealColumn get rate => real()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey =>
      {householdId, fromCurrency, toCurrency, asOfDate};
}

/// Mirror of the Supabase `receipts` table.
///
/// One row per uploaded receipt. `ocrRaw` is stored as a JSON
/// TEXT column — drift has no native JSON type and the column is
/// rarely read (only the OCR retry surface looks at it). The
/// repository's mapper handles the jsonEncode / jsonDecode.
@DataClassName('ReceiptsCacheRow')
class ReceiptsCache extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get uploadedBy => text()();
  TextColumn get storagePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get merchantName => text().nullable()();
  DateTimeColumn get receiptDate => dateTime().nullable()();
  IntColumn get totalAmount => integer().nullable()();

  /// Stores the OcrStatus dbValue verbatim ('pending', etc.).
  TextColumn get ocrStatus => text()();

  /// JSON-encoded `Map<String, dynamic>`. Null when OCR hasn't
  /// run or returned nothing.
  TextColumn get ocrRawJson => text().nullable()();
  DateTimeColumn get uploadedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror of the Supabase `receipt_line_items` table.
///
/// Loaded per receipt, sorted by sort_order ASC. The cache uses
/// the receiptId as a filter (no need for a composite index — a
/// typical receipt has tens of line items, not thousands).
@DataClassName('ReceiptLineItemsCacheRow')
class ReceiptLineItemsCache extends Table {
  TextColumn get id => text()();
  TextColumn get receiptId => text()();
  TextColumn get description => text()();
  IntColumn get amount => integer()();
  RealColumn get quantity => real().nullable()();
  IntColumn get unitPrice => integer().nullable()();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isTax => boolean()();
  BoolColumn get isTip => boolean()();
  BoolColumn get isDiscount => boolean()();
  IntColumn get sortOrder => integer()();
  IntColumn get ocrConfidenceBp => integer().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror of the Supabase `holdings` table (migration 027).
@DataClassName('HoldingsCacheRow')
class HoldingsCache extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get accountId => text()();
  TextColumn get symbol => text()();
  TextColumn get description => text().nullable()();
  RealColumn get quantity => real()();
  IntColumn get costBasis => integer().nullable()();
  IntColumn get currentValue => integer()();

  /// Stores AssetClass dbValue verbatim ('us_equity', etc.).
  /// Null is meaningful — "asset class not yet classified."
  TextColumn get assetClass => text().nullable()();
  DateTimeColumn get lastPricedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror of the Supabase `recurring_transactions` table
/// (migration 031). The scheduler emission path lands in the
/// transactions cache (already mirrored), not here.
@DataClassName('RecurringTransactionsCacheRow')
class RecurringTransactionsCache extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get accountId => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text()();
  TextColumn get description => text()();
  TextColumn get merchant => text().nullable()();
  TextColumn get categoryId => text().nullable()();

  /// Stores RecurrenceCadence dbValue ('weekly', 'monthly', etc.).
  TextColumn get cadence => text()();
  DateTimeColumn get nextOccurrenceDate => dateTime()();
  DateTimeColumn get lastEmittedAt => dateTime().nullable()();
  DateTimeColumn get skippedUntilDate => dateTime().nullable()();
  BoolColumn get isActive => boolean()();
  TextColumn get createdBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror of the Supabase `transaction_tags` table (migration 020).
/// The dictionary side — assignment tables are below.
@DataClassName('TransactionTagsCacheRow')
class TransactionTagsCache extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror of `transaction_tag_assignments`. Composite PK
/// (transaction_id, tag_id) — at most one assignment per pair.
@DataClassName('TransactionTagAssignmentsCacheRow')
class TransactionTagAssignmentsCache extends Table {
  TextColumn get transactionId => text()();
  TextColumn get tagId => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}

/// Mirror of `receipt_line_item_tag_assignments`. Composite PK
/// (line_item_id, tag_id).
@DataClassName('ReceiptLineItemTagAssignmentsCacheRow')
class ReceiptLineItemTagAssignmentsCache extends Table {
  TextColumn get lineItemId => text()();
  TextColumn get tagId => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {lineItemId, tagId};
}

/// Offline mutation queue. Each row represents one Supabase
/// write that was attempted while offline (or failed mid-flight
/// with a transient error). Replayed in created_at order on
/// reconnect.
///
/// Stored OUT-of-band from the table-cache mirrors above:
///   * Cache tables answer "what does the user see?"
///   * pending_writes answers "what does the user still owe the
///     server?"
///
/// On a successful replay the row is DELETE'd; the cache row
/// (which already has the optimistic write) is overwritten by
/// the next fetch with the server-canonical version including
/// any server-generated timestamps.
@DataClassName('PendingWritesRow')
class PendingWrites extends Table {
  /// Client-generated UUID — keeps the queue self-contained
  /// without depending on the network.
  TextColumn get id => text()();

  /// One of 'insert', 'update', 'delete', 'rpc'. The dispatcher
  /// in PendingWritesQueue.drain branches on this.
  TextColumn get opType => text()();

  /// For table-level ops ('insert', 'update', 'delete'): the
  /// Supabase table name. Null when opType == 'rpc'. Named
  /// `targetTable` (not `tableName`) so it doesn't clash with
  /// drift's `Table.tableName` getter.
  TextColumn get targetTable => text().nullable()();

  /// For 'rpc' ops only. The Postgres function name to invoke.
  TextColumn get rpcName => text().nullable()();

  /// The affected row's primary key. Required for 'update' and
  /// 'delete'; optional for 'insert' (some inserts let the
  /// server pick the id) and unused for 'rpc'.
  TextColumn get rowId => text().nullable()();

  /// JSON-encoded payload. For insert/update: the column map.
  /// For delete: usually empty `{}`. For rpc: the params map.
  TextColumn get payloadJson => text()();

  DateTimeColumn get createdAt => dateTime()();

  /// Increments each time drain attempts to execute this row.
  /// Lets future telemetry distinguish "tried once and works"
  /// from "tried many times, keeps failing".
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();

  /// Stringified error message from the last failed attempt.
  /// Null when the row hasn't been tried yet OR the last attempt
  /// succeeded (in which case the row would be deleted).
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending receipt uploads. Audit L1 Phase 4b.
///
/// Storage uploads can't ride on `pending_writes` because the
/// image bytes (typically 500KB-1.5MB) would balloon the
/// payload_json column. Instead, the bytes are persisted to
/// `<docs>/pending_uploads/<id>.jpg` and a row here tracks the
/// metadata + receipt INSERT shape so the drain can play
/// everything back in order:
///   1. Read the local file.
///   2. Upload to Supabase Storage at targetStoragePath.
///   3. Optionally upload thumbnailLocalPath bytes to
///      targetThumbnailPath.
///   4. INSERT into receipts with receiptMetadataJson.
///   5. Delete the local file(s).
///   6. Delete this row.
///
/// Failures mid-sequence keep the row + attemptCount bumps so
/// the next drain pass retries. Step 4 is idempotent at the
/// id level (receiptMetadataJson carries the row id), so a
/// half-completed prior attempt becomes a no-op via upsert
/// on conflict.
@DataClassName('PendingStorageUploadsRow')
class PendingStorageUploads extends Table {
  TextColumn get id => text()();
  TextColumn get localFilePath => text()();
  TextColumn get thumbnailLocalPath => text().nullable()();
  TextColumn get targetBucket => text()();
  TextColumn get targetStoragePath => text()();
  TextColumn get targetThumbnailPath => text().nullable()();
  TextColumn get contentType => text().withDefault(const Constant('image/jpeg'))();
  TextColumn get receiptMetadataJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    AccountsCache,
    CategoriesCache,
    TransactionsCache,
    BudgetsCache,
    FxRatesCache,
    ReceiptsCache,
    ReceiptLineItemsCache,
    HoldingsCache,
    RecurringTransactionsCache,
    TransactionTagsCache,
    TransactionTagAssignmentsCache,
    ReceiptLineItemTagAssignmentsCache,
    PendingWrites,
    PendingStorageUploads,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor — passes an explicit executor so tests
  /// can open an in-memory database (`NativeDatabase.memory()`)
  /// and avoid touching the real filesystem.
  AppDatabase.withExecutor(super.e);

  /// Store DateTime columns as ISO 8601 TEXT instead of the
  /// default Unix-epoch INT. The int encoding round-trips through
  /// the device's local timezone — a UTC midnight value written
  /// in a UTC+0 zone reads back as the same wall-clock UTC
  /// midnight in a UTC-5 zone, silently shifting transaction/
  /// budget/rate calendar days by a day. Text encoding preserves
  /// the original instant as an ISO string with the `Z` suffix,
  /// matching what Postgres returns over the wire.
  ///
  /// Changing this is a one-way decision: rows written under the
  /// other encoding can't be transparently read back. The
  /// schemaVersion bump + onUpgrade drop-and-recreate below
  /// handles the v3 → v4 transition.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 → v2: added CategoriesCache + TransactionsCache for
      // Phase 2a of the offline cache rollout. The accounts cache
      // table from v1 is unchanged.
      if (from < 2) {
        await m.createTable(categoriesCache);
        await m.createTable(transactionsCache);
      }
      // v2 → v3: added BudgetsCache + FxRatesCache for Phase 2b.
      if (from < 3) {
        await m.createTable(budgetsCache);
        await m.createTable(fxRatesCache);
      }
      // v3 → v4: switched DateTime storage from epoch INT to ISO
      // TEXT (see [options] above). Existing INT-encoded values
      // can't be read back as TEXT, so drop and recreate every
      // cache table. Cost: the user pays one re-fetch on first
      // app open after upgrade — acceptable for an offline cache
      // (we never lost source-of-truth data).
      if (from < 4) {
        await customStatement('DROP TABLE IF EXISTS accounts_cache');
        await customStatement('DROP TABLE IF EXISTS categories_cache');
        await customStatement('DROP TABLE IF EXISTS transactions_cache');
        await customStatement('DROP TABLE IF EXISTS budgets_cache');
        await customStatement('DROP TABLE IF EXISTS fx_rates_cache');
        await m.createAll();
      }
      // v4 → v5: added ReceiptsCache + ReceiptLineItemsCache for
      // Phase 2c.
      if (from < 5) {
        await m.createTable(receiptsCache);
        await m.createTable(receiptLineItemsCache);
      }
      // v5 → v6: Phase 2d. Holdings, recurring transactions, and
      // the tags trio (dictionary + 2 assignment tables).
      if (from < 6) {
        await m.createTable(holdingsCache);
        await m.createTable(recurringTransactionsCache);
        await m.createTable(transactionTagsCache);
        await m.createTable(transactionTagAssignmentsCache);
        await m.createTable(receiptLineItemTagAssignmentsCache);
      }
      // v6 → v7: Phase 3a. The offline write queue.
      if (from < 7) {
        await m.createTable(pendingWrites);
      }
      // v7 → v8: Phase 4b. Storage upload queue for receipt
      // image bytes.
      if (from < 8) {
        await m.createTable(pendingStorageUploads);
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

  // ── Budgets cache surface ───────────────────────────────────

  /// Replace the cached budget set for a household. Mirrors the
  /// server query (`fetchBudgets(householdId)`) which always
  /// returns the full set for that household; we don't have a
  /// "delta" of which budgets changed, so the safest mirror is
  /// "throw away the old, write the new" inside one transaction.
  Future<void> replaceBudgetsForHousehold(
    String householdId,
    List<BudgetsCacheCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(
        budgetsCache,
      )..where((t) => t.householdId.equals(householdId))).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(budgetsCache, rows, mode: InsertMode.replace);
        });
      }
    });
  }

  Future<void> upsertBudget(BudgetsCacheCompanion row) {
    return into(budgetsCache).insert(row, mode: InsertMode.replace);
  }

  Future<void> deleteBudget(String id) {
    return (delete(budgetsCache)..where((t) => t.id.equals(id))).go();
  }

  /// Read all cached budgets for a household, sorted by
  /// start_date ASC — matches the server fetchBudgets contract.
  Future<List<BudgetsCacheRow>> loadBudgetsForHousehold(String householdId) {
    return (select(budgetsCache)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
        .get();
  }

  // ── FX rates cache surface ──────────────────────────────────

  /// Replace the cached rate set for a household. Same shape as
  /// budgets — fxRatesRepository.fetchAll returns the full set,
  /// so we mirror "purge then insert" for atomic refresh.
  Future<void> replaceFxRatesForHousehold(
    String householdId,
    List<FxRatesCacheCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(
        fxRatesCache,
      )..where((t) => t.householdId.equals(householdId))).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(fxRatesCache, rows, mode: InsertMode.replace);
        });
      }
    });
  }

  Future<void> upsertFxRate(FxRatesCacheCompanion row) {
    return into(fxRatesCache).insert(row, mode: InsertMode.replace);
  }

  Future<void> deleteFxRate({
    required String householdId,
    required String fromCurrency,
    required String toCurrency,
    required DateTime asOfDate,
  }) {
    return (delete(fxRatesCache)..where(
          (t) =>
              t.householdId.equals(householdId) &
              t.fromCurrency.equals(fromCurrency) &
              t.toCurrency.equals(toCurrency) &
              t.asOfDate.equals(asOfDate),
        ))
        .go();
  }

  /// Load all cached rates for a household, newest first (matches
  /// fetchAll's `order(as_of_date DESC)` contract).
  Future<List<FxRatesCacheRow>> loadFxRatesForHousehold(String householdId) {
    return (select(fxRatesCache)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([(t) => OrderingTerm.desc(t.asOfDate)]))
        .get();
  }

  /// Latest cached rate for (from, to) at or before [asOf]. Same
  /// shape as FxRatesRepository.latestRate's network query.
  /// Returns null when nothing is cached for that pair.
  Future<FxRatesCacheRow?> loadLatestFxRate({
    required String householdId,
    required String fromCurrency,
    required String toCurrency,
    DateTime? asOf,
  }) {
    final cutoff = (asOf ?? DateTime.now().toUtc());
    return (select(fxRatesCache)
          ..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.fromCurrency.equals(fromCurrency) &
                t.toCurrency.equals(toCurrency) &
                t.asOfDate.isSmallerOrEqualValue(cutoff),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.asOfDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  // ── Receipts cache surface ──────────────────────────────────

  /// Replace the cached receipt set for a household. Mirrors
  /// fetchReceipts(householdId)'s return.
  Future<void> replaceReceiptsForHousehold(
    String householdId,
    List<ReceiptsCacheCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(
        receiptsCache,
      )..where((t) => t.householdId.equals(householdId))).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(receiptsCache, rows, mode: InsertMode.replace);
        });
      }
    });
  }

  Future<void> upsertReceipt(ReceiptsCacheCompanion row) {
    return into(receiptsCache).insert(row, mode: InsertMode.replace);
  }

  Future<void> deleteReceipt(String id) {
    return (delete(receiptsCache)..where((t) => t.id.equals(id))).go();
  }

  /// Read all cached receipts for a household, sorted by
  /// uploaded_at DESC (matches the server fetchReceipts contract).
  Future<List<ReceiptsCacheRow>> loadReceiptsForHousehold(String householdId) {
    return (select(receiptsCache)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([(t) => OrderingTerm.desc(t.uploadedAt)]))
        .get();
  }

  /// Read a single cached receipt by id, or null. Mirrors
  /// fetchReceipt(receiptId).
  Future<ReceiptsCacheRow?> loadReceiptById(String id) {
    return (select(receiptsCache)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ── Receipt line items cache surface ────────────────────────

  /// Replace every cached line item for a receipt. The server
  /// saveLineItems RPC (migration 028) atomically replaces — we
  /// mirror the same shape here so the cache stays in sync.
  Future<void> replaceLineItemsForReceipt(
    String receiptId,
    List<ReceiptLineItemsCacheCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(
        receiptLineItemsCache,
      )..where((t) => t.receiptId.equals(receiptId))).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(receiptLineItemsCache, rows, mode: InsertMode.replace);
        });
      }
    });
  }

  Future<void> upsertLineItem(ReceiptLineItemsCacheCompanion row) {
    return into(receiptLineItemsCache).insert(row, mode: InsertMode.replace);
  }

  /// Read all cached line items for a receipt, sorted by
  /// sort_order ASC to match the server contract.
  Future<List<ReceiptLineItemsCacheRow>> loadLineItemsForReceipt(
    String receiptId,
  ) {
    return (select(receiptLineItemsCache)
          ..where((t) => t.receiptId.equals(receiptId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  /// Batch variant — load every cached line item belonging to
  /// any of [receiptIds]. Used by the offline category-spending
  /// calculator (Phase 4a). Returns rows interleaved, sorted by
  /// receipt_id then sort_order; the caller groups by
  /// receipt_id.
  Future<List<ReceiptLineItemsCacheRow>> loadLineItemsForReceipts(
    List<String> receiptIds,
  ) {
    if (receiptIds.isEmpty) {
      return Future.value(const []);
    }
    return (select(receiptLineItemsCache)
          ..where((t) => t.receiptId.isIn(receiptIds))
          ..orderBy([
            (t) => OrderingTerm.asc(t.receiptId),
            (t) => OrderingTerm.asc(t.sortOrder),
          ]))
        .get();
  }

  // ── Holdings cache surface ──────────────────────────────────

  Future<void> replaceHoldingsForHousehold(
    String householdId,
    List<HoldingsCacheCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(
        holdingsCache,
      )..where((t) => t.householdId.equals(householdId))).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(holdingsCache, rows, mode: InsertMode.replace);
        });
      }
    });
  }

  Future<void> upsertHolding(HoldingsCacheCompanion row) {
    return into(holdingsCache).insert(row, mode: InsertMode.replace);
  }

  Future<void> deleteHolding(String id) {
    return (delete(holdingsCache)..where((t) => t.id.equals(id))).go();
  }

  /// All cached holdings for a household, sorted symbol ASC
  /// (case-insensitive via LOWER) to match the server contract.
  Future<List<HoldingsCacheRow>> loadHoldingsForHousehold(String householdId) {
    return (select(holdingsCache)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([(t) => OrderingTerm.asc(t.symbol)]))
        .get();
  }

  /// All cached holdings inside one account, sorted symbol ASC.
  Future<List<HoldingsCacheRow>> loadHoldingsForAccount(String accountId) {
    return (select(holdingsCache)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([(t) => OrderingTerm.asc(t.symbol)]))
        .get();
  }

  // ── Recurring transactions cache surface ────────────────────

  Future<void> replaceRecurringForHousehold(
    String householdId,
    List<RecurringTransactionsCacheCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(
        recurringTransactionsCache,
      )..where((t) => t.householdId.equals(householdId))).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            recurringTransactionsCache,
            rows,
            mode: InsertMode.replace,
          );
        });
      }
    });
  }

  Future<void> upsertRecurring(RecurringTransactionsCacheCompanion row) {
    return into(
      recurringTransactionsCache,
    ).insert(row, mode: InsertMode.replace);
  }

  Future<void> deleteRecurring(String id) {
    return (delete(
      recurringTransactionsCache,
    )..where((t) => t.id.equals(id))).go();
  }

  /// All cached recurring rules for a household, sorted by
  /// next_occurrence_date ASC (matches the server contract).
  Future<List<RecurringTransactionsCacheRow>> loadRecurringForHousehold(
    String householdId,
  ) {
    return (select(recurringTransactionsCache)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([(t) => OrderingTerm.asc(t.nextOccurrenceDate)]))
        .get();
  }

  // ── Tags dictionary cache surface ───────────────────────────

  Future<void> replaceTagsForHousehold(
    String householdId,
    List<TransactionTagsCacheCompanion> rows,
  ) async {
    await transaction(() async {
      await (delete(
        transactionTagsCache,
      )..where((t) => t.householdId.equals(householdId))).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(transactionTagsCache, rows, mode: InsertMode.replace);
        });
      }
    });
  }

  Future<void> upsertTag(TransactionTagsCacheCompanion row) {
    return into(transactionTagsCache).insert(row, mode: InsertMode.replace);
  }

  Future<void> deleteTag(String id) {
    return (delete(transactionTagsCache)..where((t) => t.id.equals(id))).go();
  }

  /// All cached tags for a household, sorted name ASC. Matches
  /// the server-side fetchTags contract.
  Future<List<TransactionTagsCacheRow>> loadTagsForHousehold(
    String householdId,
  ) {
    return (select(transactionTagsCache)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  // ── Transaction tag assignments cache ──────────────────────
  //
  // Full-replace shape for fetchAllAssignments — the network
  // call returns every assignment the caller can see, so we
  // mirror by purging and re-inserting in one transaction.

  Future<void> replaceAllTransactionTagAssignments(
    List<TransactionTagAssignmentsCacheCompanion> rows,
  ) async {
    await transaction(() async {
      await delete(transactionTagAssignmentsCache).go();
      if (rows.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            transactionTagAssignmentsCache,
            rows,
            mode: InsertMode.replace,
          );
        });
      }
    });
  }

  /// Mirrors replaceAssignments(transactionId, tagIds): delete
  /// every assignment for the transaction, then insert one row
  /// per tag.
  Future<void> replaceTransactionTagAssignments({
    required String transactionId,
    required List<String> tagIds,
  }) async {
    await transaction(() async {
      await (delete(transactionTagAssignmentsCache)
            ..where((t) => t.transactionId.equals(transactionId)))
          .go();
      if (tagIds.isNotEmpty) {
        final now = DateTime.now().toUtc();
        await batch((b) {
          b.insertAll(
            transactionTagAssignmentsCache,
            tagIds.map(
              (tagId) => TransactionTagAssignmentsCacheCompanion(
                transactionId: Value(transactionId),
                tagId: Value(tagId),
                cachedAt: Value(now),
              ),
            ),
            mode: InsertMode.replace,
          );
        });
      }
    });
  }

  /// Load all transaction tag assignments, returned as
  /// `Map<transaction_id, Set<tag_id>>` to match the server-side
  /// fetchAllAssignments contract.
  Future<Map<String, Set<String>>> loadAllTransactionTagAssignments() async {
    final rows = await select(transactionTagAssignmentsCache).get();
    final result = <String, Set<String>>{};
    for (final r in rows) {
      (result[r.transactionId] ??= <String>{}).add(r.tagId);
    }
    return result;
  }

  /// Tag-filter shape: which transactions carry [tagId]?
  Future<List<String>> loadTransactionIdsForTag(String tagId) async {
    final rows = await (select(transactionTagAssignmentsCache)
          ..where((t) => t.tagId.equals(tagId)))
        .get();
    return rows.map((r) => r.transactionId).toList();
  }

  /// Tag ids assigned to one transaction. Derived from the same
  /// cache table; lets fetchAssignedTagIds(transactionId) fall
  /// back to the cache without an extra query shape.
  Future<List<String>> loadAssignedTagIds(String transactionId) async {
    final rows = await (select(transactionTagAssignmentsCache)
          ..where((t) => t.transactionId.equals(transactionId)))
        .get();
    return rows.map((r) => r.tagId).toList();
  }

  /// Delete every cached assignment for [transactionId]s. Used
  /// when the server-side delete removes a whole transaction or
  /// in a bulk-untag flow.
  Future<int> deleteTransactionTagAssignmentsByTransactionIds(
    List<String> transactionIds,
  ) async {
    if (transactionIds.isEmpty) return 0;
    return (delete(transactionTagAssignmentsCache)
          ..where((t) => t.transactionId.isIn(transactionIds)))
        .go();
  }

  // ── Receipt line item tag assignments cache ────────────────

  Future<void> replaceReceiptLineItemTagAssignments({
    required String lineItemId,
    required List<String> tagIds,
  }) async {
    await transaction(() async {
      await (delete(receiptLineItemTagAssignmentsCache)
            ..where((t) => t.lineItemId.equals(lineItemId)))
          .go();
      if (tagIds.isNotEmpty) {
        final now = DateTime.now().toUtc();
        await batch((b) {
          b.insertAll(
            receiptLineItemTagAssignmentsCache,
            tagIds.map(
              (tagId) => ReceiptLineItemTagAssignmentsCacheCompanion(
                lineItemId: Value(lineItemId),
                tagId: Value(tagId),
                cachedAt: Value(now),
              ),
            ),
            mode: InsertMode.replace,
          );
        });
      }
    });
  }

  Future<List<String>> loadAssignedTagIdsForLineItem(
    String lineItemId,
  ) async {
    final rows = await (select(receiptLineItemTagAssignmentsCache)
          ..where((t) => t.lineItemId.equals(lineItemId)))
        .get();
    return rows.map((r) => r.tagId).toList();
  }

  // ── Pending writes surface ──────────────────────────────────

  /// Insert a pending write. Always `InsertMode.insert` (not
  /// replace) — every enqueue creates a fresh row with a unique
  /// id even when the user repeats the same logical op, because
  /// each repeat is its own attempt to replay.
  Future<void> enqueuePendingWrite(PendingWritesCompanion row) {
    return into(pendingWrites).insert(row);
  }

  /// Read pending writes in FIFO order. The drain loop reads
  /// this once, attempts each row, and records success/failure
  /// per-row.
  Future<List<PendingWritesRow>> loadPendingWrites() {
    return (select(pendingWrites)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deletePendingWrite(String id) {
    return (delete(pendingWrites)..where((t) => t.id.equals(id))).go();
  }

  /// Record a failed replay attempt: bump attemptCount, store
  /// the error string. The row stays in the queue for the next
  /// drain pass. Raw SQL because drift's typed-update doesn't
  /// support self-referencing `col + 1` cleanly.
  Future<void> markPendingWriteFailed({
    required String id,
    required String error,
  }) async {
    await customUpdate(
      'UPDATE pending_writes '
      'SET attempt_count = attempt_count + 1, last_error = ? '
      'WHERE id = ?',
      variables: [Variable.withString(error), Variable.withString(id)],
      updates: {pendingWrites},
    );
  }

  /// Count of pending writes — surfaces in the Settings sync
  /// status indicator. Cheap (no row body read).
  Future<int> pendingWritesCount() {
    return (selectOnly(pendingWrites)..addColumns([pendingWrites.id.count()]))
        .map((row) => row.read<int>(pendingWrites.id.count()) ?? 0)
        .getSingle();
  }

  // ── Pending storage uploads surface (Phase 4b) ──────────────

  Future<void> enqueuePendingStorageUpload(
    PendingStorageUploadsCompanion row,
  ) {
    return into(pendingStorageUploads).insert(row);
  }

  /// FIFO load of every pending storage upload. The drain loop
  /// reads this once per pass.
  Future<List<PendingStorageUploadsRow>> loadPendingStorageUploads() {
    return (select(pendingStorageUploads)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deletePendingStorageUpload(String id) {
    return (delete(pendingStorageUploads)..where((t) => t.id.equals(id))).go();
  }

  /// Raw-SQL atomic increment of attemptCount + error stamp.
  /// Same shape as markPendingWriteFailed.
  Future<void> markPendingStorageUploadFailed({
    required String id,
    required String error,
  }) async {
    await customUpdate(
      'UPDATE pending_storage_uploads '
      'SET attempt_count = attempt_count + 1, last_error = ? '
      'WHERE id = ?',
      variables: [Variable.withString(error), Variable.withString(id)],
      updates: {pendingStorageUploads},
    );
  }

  /// Count for the Settings sync indicator (Phase 5c-style).
  Future<int> pendingStorageUploadsCount() {
    return (selectOnly(pendingStorageUploads)
          ..addColumns([pendingStorageUploads.id.count()]))
        .map(
          (row) => row.read<int>(pendingStorageUploads.id.count()) ?? 0,
        )
        .getSingle();
  }

  /// Wipe every cached row + every queued write. Called on
  /// sign-out (Audit 2026-05-26 C1) so the next user signing
  /// in on the same device doesn't see the previous user's
  /// data, and queued writes can't replay against the wrong
  /// session.
  ///
  /// Runs every delete inside one transaction so a mid-clear
  /// crash leaves the database either fully populated (rollback)
  /// or fully empty (commit) — never half-cleared with one
  /// table's rows still around.
  ///
  /// The categories table is included even though it's not
  /// per-household (system categories are shared) — household-
  /// specific custom categories from the prior user need to go,
  /// and the rest will re-populate on the next fetch.
  Future<void> clearAllCachesForSignOut() async {
    await transaction(() async {
      await delete(accountsCache).go();
      await delete(categoriesCache).go();
      await delete(transactionsCache).go();
      await delete(budgetsCache).go();
      await delete(fxRatesCache).go();
      await delete(receiptsCache).go();
      await delete(receiptLineItemsCache).go();
      await delete(holdingsCache).go();
      await delete(recurringTransactionsCache).go();
      await delete(transactionTagsCache).go();
      await delete(transactionTagAssignmentsCache).go();
      await delete(receiptLineItemTagAssignmentsCache).go();
      // Queued writes from the previous session must die too —
      // replaying them as the new user would either fail RLS
      // (best case) or, in a write-queue bug, hit Supabase with
      // the new user's JWT but the old user's payload.
      await delete(pendingWrites).go();
    });
  }

  /// Maximum `cached_at` timestamp across every cache table
  /// that has one. Used by the offline banner (Phase 5a) to
  /// surface "showing data from X minutes ago" — a single
  /// scalar that approximates "when did we last hear from the
  /// server about any data?". Returns null when no cache table
  /// has any rows (fresh install offline).
  ///
  /// Implementation note: a single UNION ALL would also work
  /// but the per-table SELECT MAX() reads only the index, so
  /// the cost is constant in the number of cached rows. The
  /// tag-assignment tables are excluded — they don't carry
  /// user-visible data on their own and their cachedAt is
  /// dominated by the dictionary fetch anyway.
  Future<DateTime?> latestCacheTimestamp() async {
    final result = await customSelect(
      '''
      SELECT MAX(ts) AS ts FROM (
        SELECT MAX(cached_at) AS ts FROM accounts_cache
        UNION ALL SELECT MAX(cached_at) FROM categories_cache
        UNION ALL SELECT MAX(cached_at) FROM transactions_cache
        UNION ALL SELECT MAX(cached_at) FROM budgets_cache
        UNION ALL SELECT MAX(cached_at) FROM fx_rates_cache
        UNION ALL SELECT MAX(cached_at) FROM receipts_cache
        UNION ALL SELECT MAX(cached_at) FROM receipt_line_items_cache
        UNION ALL SELECT MAX(cached_at) FROM holdings_cache
        UNION ALL SELECT MAX(cached_at) FROM recurring_transactions_cache
        UNION ALL SELECT MAX(cached_at) FROM transaction_tags_cache
      )
      ''',
    ).getSingle();
    final raw = result.data['ts'] as String?;
    if (raw == null) return null;
    return DateTime.parse(raw);
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
