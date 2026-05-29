// Audit 2026-05-26 C1 — verifies the sign-out cache wipe
// truly clears every cache table + the pending-writes queue
// in one atomic transaction. In-memory drift; no auth, no
// Supabase.

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

  Future<void> seedEveryTable() async {
    final now = DateTime.utc(2026, 5, 28, 12);

    await db.upsertAccount(
      AccountsCacheCompanion(
        id: const Value('a-1'),
        householdId: const Value('hh-1'),
        ownerUserId: const Value('user-1'),
        name: const Value('Checking'),
        accountType: const Value('checking'),
        currency: const Value('USD'),
        currentBalance: const Value(100000),
        isActive: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
        cachedAt: Value(now),
      ),
    );
    await db.upsertCategory(
      CategoriesCacheCompanion(
        id: const Value('c-1'),
        name: const Value('Groceries'),
        isIncome: const Value(false),
        sortOrder: const Value(100),
        cachedAt: Value(now),
      ),
    );
    await db.upsertTransaction(
      TransactionsCacheCompanion(
        id: const Value('t-1'),
        householdId: const Value('hh-1'),
        accountId: const Value('a-1'),
        amount: const Value(-2500),
        currency: const Value('USD'),
        description: const Value('Coffee'),
        transactionDate: Value(now),
        pending: const Value(false),
        source: const Value('manual'),
        createdAt: Value(now),
        updatedAt: Value(now),
        cachedAt: Value(now),
      ),
    );
    await db.upsertBudget(
      BudgetsCacheCompanion(
        id: const Value('b-1'),
        householdId: const Value('hh-1'),
        categoryId: const Value('c-1'),
        amount: const Value(50000),
        period: const Value('monthly'),
        startDate: Value(now),
        createdBy: const Value('user-1'),
        cachedAt: Value(now),
      ),
    );
    await db.upsertFxRate(
      FxRatesCacheCompanion(
        householdId: const Value('hh-1'),
        fromCurrency: const Value('EUR'),
        toCurrency: const Value('USD'),
        asOfDate: Value(now),
        rate: const Value(1.08),
        createdAt: Value(now),
        updatedAt: Value(now),
        cachedAt: Value(now),
      ),
    );
    await db.upsertReceipt(
      ReceiptsCacheCompanion(
        id: const Value('r-1'),
        householdId: const Value('hh-1'),
        uploadedBy: const Value('user-1'),
        storagePath: const Value('hh-1/r-1.jpg'),
        ocrStatus: const Value('complete'),
        uploadedAt: Value(now),
        cachedAt: Value(now),
      ),
    );
    await db.upsertLineItem(
      ReceiptLineItemsCacheCompanion(
        id: const Value('li-1'),
        receiptId: const Value('r-1'),
        description: const Value('Bananas'),
        amount: const Value(199),
        isTax: const Value(false),
        isTip: const Value(false),
        isDiscount: const Value(false),
        sortOrder: const Value(0),
        cachedAt: Value(now),
      ),
    );
    await db.upsertHolding(
      HoldingsCacheCompanion(
        id: const Value('h-1'),
        householdId: const Value('hh-1'),
        accountId: const Value('a-1'),
        symbol: const Value('VOO'),
        quantity: const Value(10.0),
        currentValue: const Value(450000),
        createdAt: Value(now),
        updatedAt: Value(now),
        cachedAt: Value(now),
      ),
    );
    await db.upsertRecurring(
      RecurringTransactionsCacheCompanion(
        id: const Value('rec-1'),
        householdId: const Value('hh-1'),
        accountId: const Value('a-1'),
        amountCents: const Value(-999),
        currency: const Value('USD'),
        description: const Value('Spotify'),
        cadence: const Value('monthly'),
        nextOccurrenceDate: Value(now),
        isActive: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
        cachedAt: Value(now),
      ),
    );
    await db.upsertTag(
      TransactionTagsCacheCompanion(
        id: const Value('tag-1'),
        householdId: const Value('hh-1'),
        name: const Value('contractor'),
        createdAt: Value(now),
        cachedAt: Value(now),
      ),
    );
    await db.replaceTransactionTagAssignments(
      transactionId: 't-1',
      tagIds: const ['tag-1'],
    );
    await db.replaceReceiptLineItemTagAssignments(
      lineItemId: 'li-1',
      tagIds: const ['tag-1'],
    );
    await db.enqueuePendingWrite(
      PendingWritesCompanion(
        id: const Value('pw-1'),
        opType: const Value('delete'),
        targetTable: const Value('transactions'),
        rowId: const Value('t-1'),
        payloadJson: const Value('{}'),
        createdAt: Value(now),
      ),
    );
  }

  group('AppDatabase.clearAllCachesForSignOut', () {
    test('wipes every cache table + pending_writes', () async {
      await seedEveryTable();

      // Verify the seed actually populated (catches a future
      // schema regression where the wipe runs against an empty
      // DB and silently passes).
      expect(await db.loadAccountsForHousehold('hh-1'), hasLength(1));
      expect(await db.loadCategories(), hasLength(1));
      expect(await db.pendingWritesCount(), 1);

      await db.clearAllCachesForSignOut();

      expect(await db.loadAccountsForHousehold('hh-1'), isEmpty);
      expect(await db.loadCategories(), isEmpty);
      expect(
        await db.loadTransactionsForHousehold(householdId: 'hh-1'),
        isEmpty,
      );
      expect(await db.loadBudgetsForHousehold('hh-1'), isEmpty);
      expect(await db.loadFxRatesForHousehold('hh-1'), isEmpty);
      expect(await db.loadReceiptsForHousehold('hh-1'), isEmpty);
      expect(await db.loadLineItemsForReceipt('r-1'), isEmpty);
      expect(await db.loadHoldingsForHousehold('hh-1'), isEmpty);
      expect(await db.loadRecurringForHousehold('hh-1'), isEmpty);
      expect(await db.loadTagsForHousehold('hh-1'), isEmpty);
      expect(await db.loadAllTransactionTagAssignments(), isEmpty);
      expect(await db.loadAssignedTagIdsForLineItem('li-1'), isEmpty);
      expect(await db.pendingWritesCount(), 0);
    });

    test('is a no-op on an already-empty database', () async {
      await db.clearAllCachesForSignOut();
      expect(await db.pendingWritesCount(), 0);
    });

    test('subsequent inserts work after a clear', () async {
      await seedEveryTable();
      await db.clearAllCachesForSignOut();
      // New user signs in and the cache refills via the
      // cache-through pattern. Smoke-test by re-seeding accounts.
      await db.upsertAccount(
        AccountsCacheCompanion(
          id: const Value('a-2'),
          householdId: const Value('hh-2'),
          ownerUserId: const Value('user-2'),
          name: const Value('Savings'),
          accountType: const Value('savings'),
          currency: const Value('USD'),
          currentBalance: const Value(0),
          isActive: const Value(true),
          createdAt: Value(DateTime.utc(2026, 5, 29)),
          updatedAt: Value(DateTime.utc(2026, 5, 29)),
          cachedAt: Value(DateTime.utc(2026, 5, 29)),
        ),
      );
      final rows = await db.loadAccountsForHousehold('hh-2');
      expect(rows.single.id, 'a-2');
      expect(await db.loadAccountsForHousehold('hh-1'), isEmpty);
    });
  });
}
