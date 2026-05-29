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

@DriftDatabase(tables: [AccountsCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor — passes an explicit executor so tests
  /// can open an in-memory database (`NativeDatabase.memory()`)
  /// and avoid touching the real filesystem.
  AppDatabase.withExecutor(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // No upgrades yet — schemaVersion 1 is the initial schema.
      // When we bump to 2, add a `from < 2` branch here.
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File(p.join(docs.path, 'mybudget_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
