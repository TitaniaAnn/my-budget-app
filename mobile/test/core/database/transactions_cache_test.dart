// Drift round-trip tests for the transactions + categories
// caches added in L1 Phase 2a. In-memory SQLite via
// NativeDatabase.memory() — no Supabase, runs under plain
// `flutter test`. Each test opens a fresh database so state
// doesn't leak.
//
// What's covered:
//   * categories: replace-all + load preserves sort_order ASC,
//     name ASC ordering (matches server contract)
//   * categories: upsertCategory replaces on id conflict
//   * categories: deleteCategory removes one row
//   * transactions: upsert single + bulk
//   * transactions: deleteTransaction + deleteTransactionsByIds
//   * loadTransactionsForHousehold filters:
//       - householdId scoping (no cross-household leak)
//       - accountId + categoryId narrow the result
//       - date range (from / to inclusive)
//       - search LIKE on description OR merchant
//       - idsFilter empty short-circuits to []
//       - idsFilter narrows
//       - limit + offset paginate
//   * left-join with categories populates the category field
//     when present, leaves null when not
//
// What's NOT covered here (defer to Phase 3 integration):
//   * TransactionsRepository's network-fail-fall-back-to-cache
//     wiring (needs a fake supabase client)
//   * Transaction ↔ Companion mapper round-trips at the
//     repository layer

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

  CategoriesCacheCompanion sampleCategory({
    required String id,
    String? householdId,
    String name = 'Groceries',
    bool isIncome = false,
    int sortOrder = 100,
  }) {
    return CategoriesCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      parentId: const Value(null),
      icon: const Value('shopping_cart'),
      color: const Value('#22C55E'),
      isIncome: Value(isIncome),
      sortOrder: Value(sortOrder),
      cachedAt: Value(DateTime.utc(2026, 5, 28, 12)),
    );
  }

  TransactionsCacheCompanion sampleTransaction({
    required String id,
    String householdId = 'hh-1',
    String accountId = 'acct-1',
    int amount = -2500,
    String description = 'Coffee',
    String? merchant,
    String? categoryId,
    DateTime? transactionDate,
    String source = 'manual',
  }) {
    final date = transactionDate ?? DateTime.utc(2026, 5, 1);
    return TransactionsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      accountId: Value(accountId),
      amount: Value(amount),
      currency: const Value('USD'),
      description: Value(description),
      merchant: Value(merchant),
      categoryId: Value(categoryId),
      transactionDate: Value(date),
      postedDate: const Value(null),
      pending: const Value(false),
      source: Value(source),
      enteredBy: const Value('user-1'),
      receiptId: const Value(null),
      rateId: const Value(null),
      notes: const Value(null),
      externalId: const Value(null),
      transferId: const Value(null),
      mlModelConfidence: const Value(null),
      createdAt: Value(date),
      updatedAt: Value(date),
      cachedAt: Value(DateTime.utc(2026, 5, 28, 12)),
    );
  }

  group('AppDatabase.replaceCategories', () {
    test('replaces the entire category set on each call', () async {
      await db.replaceCategories([
        sampleCategory(id: 'c-1'),
        sampleCategory(id: 'c-2'),
      ]);
      await db.replaceCategories([sampleCategory(id: 'c-3')]);
      final rows = await db.loadCategories();
      expect(rows.map((r) => r.id), ['c-3']);
    });

    test('empty list purges the cache', () async {
      await db.replaceCategories([sampleCategory(id: 'c-1')]);
      await db.replaceCategories(const []);
      expect(await db.loadCategories(), isEmpty);
    });

    test('preserves sort_order ASC, name ASC ordering', () async {
      await db.replaceCategories([
        sampleCategory(id: 'c-z', name: 'Zebra', sortOrder: 100),
        sampleCategory(id: 'c-a', name: 'Alpha', sortOrder: 100),
        sampleCategory(id: 'c-early', name: 'Anything', sortOrder: 10),
      ]);
      final rows = await db.loadCategories();
      expect(rows.map((r) => r.id), ['c-early', 'c-a', 'c-z']);
    });
  });

  group('AppDatabase.upsertCategory / deleteCategory', () {
    test('upsert inserts then replaces on id conflict', () async {
      await db.upsertCategory(sampleCategory(id: 'c-1', name: 'Original'));
      await db.upsertCategory(sampleCategory(id: 'c-1', name: 'Renamed'));
      final rows = await db.loadCategories();
      expect(rows.single.name, 'Renamed');
    });

    test('deleteCategory removes one row', () async {
      await db.replaceCategories([
        sampleCategory(id: 'c-1'),
        sampleCategory(id: 'c-2'),
      ]);
      await db.deleteCategory('c-1');
      final rows = await db.loadCategories();
      expect(rows.map((r) => r.id), ['c-2']);
    });
  });

  group('AppDatabase transactions surface', () {
    test('upsertTransaction round-trips a single row', () async {
      await db.upsertTransaction(sampleTransaction(id: 't-1'));
      final rows = await db.loadTransactionsForHousehold(householdId: 'hh-1');
      expect(rows, hasLength(1));
      expect(rows.first.transaction.id, 't-1');
      expect(rows.first.transaction.description, 'Coffee');
    });

    test('upsertTransactions bulk-inserts', () async {
      await db.upsertTransactions([
        sampleTransaction(id: 't-1'),
        sampleTransaction(id: 't-2'),
        sampleTransaction(id: 't-3'),
      ]);
      final rows = await db.loadTransactionsForHousehold(householdId: 'hh-1');
      expect(rows.map((r) => r.transaction.id).toSet(), {'t-1', 't-2', 't-3'});
    });

    test('empty upsertTransactions is a no-op', () async {
      await db.upsertTransactions(const []);
      final rows = await db.loadTransactionsForHousehold(householdId: 'hh-1');
      expect(rows, isEmpty);
    });

    test('deleteTransaction removes one row', () async {
      await db.upsertTransactions([
        sampleTransaction(id: 't-1'),
        sampleTransaction(id: 't-2'),
      ]);
      await db.deleteTransaction('t-1');
      final rows = await db.loadTransactionsForHousehold(householdId: 'hh-1');
      expect(rows.map((r) => r.transaction.id), ['t-2']);
    });

    test('deleteTransactionsByIds removes a batch', () async {
      await db.upsertTransactions([
        sampleTransaction(id: 't-1'),
        sampleTransaction(id: 't-2'),
        sampleTransaction(id: 't-3'),
      ]);
      final removed = await db.deleteTransactionsByIds(['t-1', 't-3']);
      expect(removed, 2);
      final rows = await db.loadTransactionsForHousehold(householdId: 'hh-1');
      expect(rows.map((r) => r.transaction.id), ['t-2']);
    });

    test('deleteTransactionsByIds with empty list is a no-op', () async {
      await db.upsertTransactions([sampleTransaction(id: 't-1')]);
      final removed = await db.deleteTransactionsByIds(const []);
      expect(removed, 0);
      final rows = await db.loadTransactionsForHousehold(householdId: 'hh-1');
      expect(rows, hasLength(1));
    });
  });

  group('AppDatabase.loadTransactionsForHousehold filters', () {
    test('householdId scoping — no cross-household leak', () async {
      await db.upsertTransactions([
        sampleTransaction(id: 't-hh1', householdId: 'hh-1'),
        sampleTransaction(id: 't-hh2', householdId: 'hh-2'),
      ]);
      final hh1 = await db.loadTransactionsForHousehold(householdId: 'hh-1');
      final hh2 = await db.loadTransactionsForHousehold(householdId: 'hh-2');
      expect(hh1.map((r) => r.transaction.id), ['t-hh1']);
      expect(hh2.map((r) => r.transaction.id), ['t-hh2']);
    });

    test('accountId narrows the result', () async {
      await db.upsertTransactions([
        sampleTransaction(id: 't-a', accountId: 'acct-a'),
        sampleTransaction(id: 't-b', accountId: 'acct-b'),
      ]);
      final rows = await db.loadTransactionsForHousehold(
        householdId: 'hh-1',
        accountId: 'acct-a',
      );
      expect(rows.map((r) => r.transaction.id), ['t-a']);
    });

    test('categoryId narrows the result', () async {
      await db.upsertTransactions([
        sampleTransaction(id: 't-cat1', categoryId: 'cat-1'),
        sampleTransaction(id: 't-cat2', categoryId: 'cat-2'),
        sampleTransaction(id: 't-uncat', categoryId: null),
      ]);
      final rows = await db.loadTransactionsForHousehold(
        householdId: 'hh-1',
        categoryId: 'cat-1',
      );
      expect(rows.map((r) => r.transaction.id), ['t-cat1']);
    });

    test('date range from/to is inclusive at both ends', () async {
      await db.upsertTransactions([
        sampleTransaction(
          id: 't-early',
          transactionDate: DateTime.utc(2026, 4, 15),
        ),
        sampleTransaction(
          id: 't-edge-start',
          transactionDate: DateTime.utc(2026, 5, 1),
        ),
        sampleTransaction(
          id: 't-middle',
          transactionDate: DateTime.utc(2026, 5, 15),
        ),
        sampleTransaction(
          id: 't-edge-end',
          transactionDate: DateTime.utc(2026, 5, 31),
        ),
        sampleTransaction(
          id: 't-late',
          transactionDate: DateTime.utc(2026, 6, 5),
        ),
      ]);
      final rows = await db.loadTransactionsForHousehold(
        householdId: 'hh-1',
        from: DateTime.utc(2026, 5, 1),
        to: DateTime.utc(2026, 5, 31),
      );
      expect(rows.map((r) => r.transaction.id).toSet(), {
        't-edge-start',
        't-middle',
        't-edge-end',
      });
    });

    test('search matches description LIKE (case-insensitive)', () async {
      await db.upsertTransactions([
        sampleTransaction(id: 't-1', description: 'Starbucks #4842'),
        sampleTransaction(id: 't-2', description: 'Whole Foods Market'),
        sampleTransaction(id: 't-3', description: 'BLUE BOTTLE COFFEE'),
      ]);
      final rows = await db.loadTransactionsForHousehold(
        householdId: 'hh-1',
        search: 'coffee',
      );
      expect(rows.map((r) => r.transaction.id), ['t-3']);
    });

    test('search matches merchant column as fallback', () async {
      await db.upsertTransactions([
        sampleTransaction(
          id: 't-1',
          description: 'PAYMENT 4842',
          merchant: 'Starbucks',
        ),
        sampleTransaction(
          id: 't-2',
          description: 'Whole Foods Market',
          merchant: null,
        ),
      ]);
      final rows = await db.loadTransactionsForHousehold(
        householdId: 'hh-1',
        search: 'starbucks',
      );
      expect(rows.map((r) => r.transaction.id), ['t-1']);
    });

    test('idsFilter empty short-circuits to empty result', () async {
      await db.upsertTransactions([
        sampleTransaction(id: 't-1'),
        sampleTransaction(id: 't-2'),
      ]);
      final rows = await db.loadTransactionsForHousehold(
        householdId: 'hh-1',
        idsFilter: const [],
      );
      expect(rows, isEmpty);
    });

    test('idsFilter narrows to the provided ids', () async {
      await db.upsertTransactions([
        sampleTransaction(id: 't-1'),
        sampleTransaction(id: 't-2'),
        sampleTransaction(id: 't-3'),
      ]);
      final rows = await db.loadTransactionsForHousehold(
        householdId: 'hh-1',
        idsFilter: const ['t-1', 't-3'],
      );
      expect(rows.map((r) => r.transaction.id).toSet(), {'t-1', 't-3'});
    });

    test('limit + offset paginate, newest-first', () async {
      // Five rows on consecutive dates — newest first by
      // transaction_date DESC.
      for (var i = 1; i <= 5; i++) {
        await db.upsertTransaction(
          sampleTransaction(
            id: 't-$i',
            transactionDate: DateTime.utc(2026, 5, i),
          ),
        );
      }
      final page1 = await db.loadTransactionsForHousehold(
        householdId: 'hh-1',
        limit: 2,
        offset: 0,
      );
      final page2 = await db.loadTransactionsForHousehold(
        householdId: 'hh-1',
        limit: 2,
        offset: 2,
      );
      expect(page1.map((r) => r.transaction.id), ['t-5', 't-4']);
      expect(page2.map((r) => r.transaction.id), ['t-3', 't-2']);
    });

    test('left-join populates category when present', () async {
      await db.replaceCategories([
        sampleCategory(id: 'cat-1', name: 'Coffee Shops'),
      ]);
      await db.upsertTransactions([
        sampleTransaction(id: 't-joined', categoryId: 'cat-1'),
        sampleTransaction(id: 't-orphan', categoryId: 'cat-missing'),
        sampleTransaction(id: 't-null', categoryId: null),
      ]);
      final rows = await db.loadTransactionsForHousehold(householdId: 'hh-1');
      final byId = {for (final r in rows) r.transaction.id: r};
      expect(byId['t-joined']!.category?.name, 'Coffee Shops');
      // category_id references a category that isn't in the cache
      // — left-join returns null on the category side. The
      // repository surfaces this as "uncategorized in cache."
      expect(byId['t-orphan']!.category, isNull);
      expect(byId['t-null']!.category, isNull);
    });
  });
}
