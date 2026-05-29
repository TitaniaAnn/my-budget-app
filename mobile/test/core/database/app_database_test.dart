// Drift round-trip tests for the offline cache. Audit L1 Phase 1.
//
// In-memory SQLite via NativeDatabase.memory() — no file system,
// no platform plugins, runs under plain `flutter test`. Each test
// opens a fresh database so state doesn't leak between cases.
//
// What's covered:
//   * upsertAccount: insert + replace-on-conflict
//   * upsertAccounts: bulk variant transactional
//   * loadAccountsForHousehold: filters by householdId AND
//     is_active, sorts createdAt DESC (matches the server query)
//   * replaceAccountsForHousehold: prior set is purged before new
//     set lands (no leftover ghost rows)
//   * deleteAccount: removes a single row by id
//   * Cross-household isolation: a row for household A is not
//     returned for household B
//
// What's NOT covered here (defer to Phase 2 + integration):
//   * AccountsRepository's network-fail-fall-back-to-cache path
//     (needs a mock supabase client)
//   * The drift ↔ Account model mapper round-trip via the
//     repository's private helpers
//   * Connectivity transitions firing ledger invalidation

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  AccountsCacheCompanion sampleRow({
    required String id,
    String householdId = 'hh-1',
    String name = 'Checking',
    String accountType = 'checking',
    int currentBalance = 100000,
    bool isActive = true,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.utc(2026, 5, 28, 12);
    return AccountsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      ownerUserId: const Value('user-1'),
      name: Value(name),
      accountType: Value(accountType),
      institution: const Value('Chase'),
      lastFour: const Value('1234'),
      currency: const Value('USD'),
      startingBalance: const Value(0),
      currentBalance: Value(currentBalance),
      creditLimit: const Value(null),
      isActive: Value(isActive),
      color: const Value(null),
      interestRate: const Value(null),
      createdAt: Value(now),
      updatedAt: Value(now),
      cachedAt: Value(DateTime.utc(2026, 5, 28, 12, 1)),
    );
  }

  group('AppDatabase.upsertAccount', () {
    test('inserts a new row', () async {
      await db.upsertAccount(sampleRow(id: 'a-1'));
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'a-1');
      expect(rows.first.name, 'Checking');
      expect(rows.first.currentBalance, 100000);
    });

    test('replaces an existing row on id conflict', () async {
      await db.upsertAccount(sampleRow(id: 'a-1', currentBalance: 100000));
      await db.upsertAccount(
        sampleRow(id: 'a-1', name: 'Renamed', currentBalance: 250000),
      );
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows, hasLength(1));
      expect(rows.first.name, 'Renamed');
      expect(rows.first.currentBalance, 250000);
    });
  });

  group('AppDatabase.upsertAccounts', () {
    test('empty list is a no-op', () async {
      await db.upsertAccounts(const []);
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows, isEmpty);
    });

    test('inserts multiple rows in one batch', () async {
      await db.upsertAccounts([
        sampleRow(id: 'a-1', name: 'A'),
        sampleRow(id: 'a-2', name: 'B'),
        sampleRow(id: 'a-3', name: 'C'),
      ]);
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows.map((r) => r.id).toSet(), {'a-1', 'a-2', 'a-3'});
    });
  });

  group('AppDatabase.loadAccountsForHousehold', () {
    test('returns empty list when nothing is cached', () async {
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows, isEmpty);
    });

    test('filters out is_active=false rows', () async {
      await db.upsertAccounts([
        sampleRow(id: 'a-active', isActive: true),
        sampleRow(id: 'a-inactive', isActive: false),
      ]);
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'a-active');
    });

    test('sorts createdAt descending (newest first)', () async {
      await db.upsertAccounts([
        sampleRow(id: 'old', createdAt: DateTime.utc(2026, 1, 1)),
        sampleRow(id: 'new', createdAt: DateTime.utc(2026, 5, 1)),
        sampleRow(id: 'middle', createdAt: DateTime.utc(2026, 3, 1)),
      ]);
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows.map((r) => r.id).toList(), ['new', 'middle', 'old']);
    });

    test('is household-scoped — does not leak across households', () async {
      await db.upsertAccounts([
        sampleRow(id: 'a-hh1', householdId: 'hh-1'),
        sampleRow(id: 'a-hh2', householdId: 'hh-2'),
      ]);
      final hh1 = await db.loadAccountsForHousehold('hh-1');
      final hh2 = await db.loadAccountsForHousehold('hh-2');
      expect(hh1.map((r) => r.id), ['a-hh1']);
      expect(hh2.map((r) => r.id), ['a-hh2']);
    });
  });

  group('AppDatabase.replaceAccountsForHousehold', () {
    test('purges prior rows for the household before inserting', () async {
      await db.upsertAccounts([
        sampleRow(id: 'old-1'),
        sampleRow(id: 'old-2'),
      ]);
      await db.replaceAccountsForHousehold('hh-1', [
        sampleRow(id: 'fresh-1'),
      ]);
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['fresh-1']);
    });

    test('leaves other households untouched', () async {
      await db.upsertAccounts([
        sampleRow(id: 'a-hh1', householdId: 'hh-1'),
        sampleRow(id: 'a-hh2', householdId: 'hh-2'),
      ]);
      await db.replaceAccountsForHousehold('hh-1', [
        sampleRow(id: 'fresh-hh1', householdId: 'hh-1'),
      ]);
      final hh2 = await db.loadAccountsForHousehold('hh-2');
      expect(hh2.map((r) => r.id), ['a-hh2']);
    });

    test('empty replacement set leaves the household empty', () async {
      await db.upsertAccounts([sampleRow(id: 'a-1')]);
      await db.replaceAccountsForHousehold('hh-1', const []);
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows, isEmpty);
    });
  });

  group('AppDatabase.deleteAccount', () {
    test('removes a single row by id', () async {
      await db.upsertAccounts([
        sampleRow(id: 'a-1'),
        sampleRow(id: 'a-2'),
      ]);
      await db.deleteAccount('a-1');
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['a-2']);
    });

    test('no-op for an id that does not exist', () async {
      await db.upsertAccounts([sampleRow(id: 'a-1')]);
      await db.deleteAccount('does-not-exist');
      final rows = await db.loadAccountsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['a-1']);
    });
  });
}
