// Drift round-trip tests for the holdings, recurring, and tags
// caches (plus assignments) added in L1 Phase 2d.

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

  HoldingsCacheCompanion sampleHolding({
    required String id,
    String householdId = 'hh-1',
    String accountId = 'acct-1',
    String symbol = 'VOO',
    String? assetClass = 'us_equity',
  }) {
    return HoldingsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      accountId: Value(accountId),
      symbol: Value(symbol),
      description: const Value('Vanguard S&P 500'),
      quantity: const Value(10.5),
      costBasis: const Value(380000),
      currentValue: const Value(450000),
      assetClass: Value(assetClass),
      lastPricedAt: Value(DateTime.utc(2026, 5, 1)),
      createdAt: Value(DateTime.utc(2026, 1, 1)),
      updatedAt: Value(DateTime.utc(2026, 5, 1)),
      cachedAt: Value(DateTime.utc(2026, 5, 28)),
    );
  }

  RecurringTransactionsCacheCompanion sampleRecurring({
    required String id,
    String householdId = 'hh-1',
    String cadence = 'monthly',
    DateTime? nextOccurrenceDate,
    bool isActive = true,
  }) {
    final next = nextOccurrenceDate ?? DateTime.utc(2026, 6, 1);
    return RecurringTransactionsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      accountId: const Value('acct-1'),
      amountCents: const Value(-999),
      currency: const Value('USD'),
      description: const Value('Spotify'),
      merchant: const Value(null),
      categoryId: const Value(null),
      cadence: Value(cadence),
      nextOccurrenceDate: Value(next),
      lastEmittedAt: const Value(null),
      skippedUntilDate: const Value(null),
      isActive: Value(isActive),
      createdBy: const Value('user-1'),
      createdAt: Value(DateTime.utc(2026, 1, 1)),
      updatedAt: Value(DateTime.utc(2026, 1, 1)),
      cachedAt: Value(DateTime.utc(2026, 5, 28)),
    );
  }

  TransactionTagsCacheCompanion sampleTag({
    required String id,
    String householdId = 'hh-1',
    String name = 'contractor',
  }) {
    return TransactionTagsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      color: const Value('#22C55E'),
      createdAt: Value(DateTime.utc(2026, 1, 1)),
      cachedAt: Value(DateTime.utc(2026, 5, 28)),
    );
  }

  group('AppDatabase holdings surface', () {
    test('replaceHoldingsForHousehold purges + reinserts', () async {
      await db.upsertHolding(sampleHolding(id: 'h-old'));
      await db.replaceHoldingsForHousehold('hh-1', [
        sampleHolding(id: 'h-new'),
      ]);
      final rows = await db.loadHoldingsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['h-new']);
    });

    test('loadHoldingsForHousehold sorts symbol ASC', () async {
      await db.upsertHolding(sampleHolding(id: 'h-z', symbol: 'ZNGA'));
      await db.upsertHolding(sampleHolding(id: 'h-a', symbol: 'AAPL'));
      await db.upsertHolding(sampleHolding(id: 'h-m', symbol: 'MSFT'));
      final rows = await db.loadHoldingsForHousehold('hh-1');
      expect(rows.map((r) => r.symbol), ['AAPL', 'MSFT', 'ZNGA']);
    });

    test('loadHoldingsForAccount filters to one account', () async {
      await db.upsertHolding(
        sampleHolding(id: 'h-a1', accountId: 'acct-1', symbol: 'VOO'),
      );
      await db.upsertHolding(
        sampleHolding(id: 'h-a2', accountId: 'acct-2', symbol: 'BND'),
      );
      final rows = await db.loadHoldingsForAccount('acct-1');
      expect(rows.map((r) => r.id), ['h-a1']);
    });

    test('deleteHolding removes one row', () async {
      await db.upsertHolding(sampleHolding(id: 'h-1'));
      await db.upsertHolding(sampleHolding(id: 'h-2', symbol: 'VTI'));
      await db.deleteHolding('h-1');
      final rows = await db.loadHoldingsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['h-2']);
    });

    test('nullable assetClass round-trips', () async {
      await db.upsertHolding(sampleHolding(id: 'h-null', assetClass: null));
      final rows = await db.loadHoldingsForHousehold('hh-1');
      expect(rows.single.assetClass, isNull);
    });
  });

  group('AppDatabase recurring surface', () {
    test('replaceRecurringForHousehold purges + reinserts', () async {
      await db.upsertRecurring(sampleRecurring(id: 'r-old'));
      await db.replaceRecurringForHousehold('hh-1', [
        sampleRecurring(id: 'r-new'),
      ]);
      final rows = await db.loadRecurringForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['r-new']);
    });

    test('loadRecurringForHousehold sorts next_occurrence_date ASC', () async {
      await db.upsertRecurring(sampleRecurring(
        id: 'r-late',
        nextOccurrenceDate: DateTime.utc(2026, 7, 1),
      ));
      await db.upsertRecurring(sampleRecurring(
        id: 'r-early',
        nextOccurrenceDate: DateTime.utc(2026, 6, 1),
      ));
      await db.upsertRecurring(sampleRecurring(
        id: 'r-mid',
        nextOccurrenceDate: DateTime.utc(2026, 6, 15),
      ));
      final rows = await db.loadRecurringForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['r-early', 'r-mid', 'r-late']);
    });

    test('includes inactive rules — callers filter in Dart', () async {
      await db.upsertRecurring(sampleRecurring(id: 'r-on', isActive: true));
      await db.upsertRecurring(sampleRecurring(id: 'r-off', isActive: false));
      final rows = await db.loadRecurringForHousehold('hh-1');
      expect(rows.map((r) => r.id).toSet(), {'r-on', 'r-off'});
    });

    test('deleteRecurring removes one row', () async {
      await db.upsertRecurring(sampleRecurring(id: 'r-1'));
      await db.upsertRecurring(sampleRecurring(id: 'r-2'));
      await db.deleteRecurring('r-1');
      final rows = await db.loadRecurringForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['r-2']);
    });
  });

  group('AppDatabase tags dictionary surface', () {
    test('replaceTagsForHousehold purges + reinserts', () async {
      await db.upsertTag(sampleTag(id: 't-old'));
      await db.replaceTagsForHousehold('hh-1', [
        sampleTag(id: 't-new'),
      ]);
      final rows = await db.loadTagsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['t-new']);
    });

    test('loadTagsForHousehold sorts name ASC', () async {
      await db.upsertTag(sampleTag(id: 't-z', name: 'zebra'));
      await db.upsertTag(sampleTag(id: 't-a', name: 'alpha'));
      await db.upsertTag(sampleTag(id: 't-m', name: 'middle'));
      final rows = await db.loadTagsForHousehold('hh-1');
      expect(rows.map((r) => r.name), ['alpha', 'middle', 'zebra']);
    });

    test('deleteTag removes one row', () async {
      await db.upsertTag(sampleTag(id: 't-1', name: 'one'));
      await db.upsertTag(sampleTag(id: 't-2', name: 'two'));
      await db.deleteTag('t-1');
      final rows = await db.loadTagsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['t-2']);
    });
  });

  group('AppDatabase transaction tag assignments', () {
    test('replaceAll purges + rebuilds the full set', () async {
      await db.replaceAllTransactionTagAssignments([
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-1'),
          tagId: const Value('tag-a'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-1'),
          tagId: const Value('tag-b'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-2'),
          tagId: const Value('tag-a'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
      ]);
      final map = await db.loadAllTransactionTagAssignments();
      expect(map['tx-1'], {'tag-a', 'tag-b'});
      expect(map['tx-2'], {'tag-a'});
    });

    test('replaceTransactionTagAssignments swaps a transaction set', () async {
      await db.replaceAllTransactionTagAssignments([
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-1'),
          tagId: const Value('tag-a'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-1'),
          tagId: const Value('tag-b'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
      ]);
      await db.replaceTransactionTagAssignments(
        transactionId: 'tx-1',
        tagIds: const ['tag-c'],
      );
      final tags = await db.loadAssignedTagIds('tx-1');
      expect(tags, ['tag-c']);
    });

    test('replaceTransactionTagAssignments empty clears the set', () async {
      await db.replaceAllTransactionTagAssignments([
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-1'),
          tagId: const Value('tag-a'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
      ]);
      await db.replaceTransactionTagAssignments(
        transactionId: 'tx-1',
        tagIds: const [],
      );
      final tags = await db.loadAssignedTagIds('tx-1');
      expect(tags, isEmpty);
    });

    test('loadTransactionIdsForTag returns matching transactions', () async {
      await db.replaceAllTransactionTagAssignments([
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-a1'),
          tagId: const Value('tag-x'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-a2'),
          tagId: const Value('tag-x'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-b'),
          tagId: const Value('tag-y'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
      ]);
      final ids = await db.loadTransactionIdsForTag('tag-x');
      expect(ids.toSet(), {'tx-a1', 'tx-a2'});
    });

    test('deleteTransactionTagAssignmentsByTransactionIds removes multiple',
        () async {
      await db.replaceAllTransactionTagAssignments([
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-1'),
          tagId: const Value('tag-a'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-2'),
          tagId: const Value('tag-a'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
        TransactionTagAssignmentsCacheCompanion(
          transactionId: const Value('tx-3'),
          tagId: const Value('tag-a'),
          cachedAt: Value(DateTime.utc(2026, 5, 28)),
        ),
      ]);
      final removed = await db
          .deleteTransactionTagAssignmentsByTransactionIds(['tx-1', 'tx-3']);
      expect(removed, 2);
      final remaining = await db.loadAllTransactionTagAssignments();
      expect(remaining.keys.toSet(), {'tx-2'});
    });
  });

  group('AppDatabase receipt line item tag assignments', () {
    test('replace swaps the per-line-item set', () async {
      await db.replaceReceiptLineItemTagAssignments(
        lineItemId: 'li-1',
        tagIds: const ['tag-a', 'tag-b'],
      );
      await db.replaceReceiptLineItemTagAssignments(
        lineItemId: 'li-1',
        tagIds: const ['tag-c'],
      );
      final tags = await db.loadAssignedTagIdsForLineItem('li-1');
      expect(tags, ['tag-c']);
    });

    test('replace with empty list clears the set', () async {
      await db.replaceReceiptLineItemTagAssignments(
        lineItemId: 'li-1',
        tagIds: const ['tag-a'],
      );
      await db.replaceReceiptLineItemTagAssignments(
        lineItemId: 'li-1',
        tagIds: const [],
      );
      final tags = await db.loadAssignedTagIdsForLineItem('li-1');
      expect(tags, isEmpty);
    });

    test('per-line-item scoping — other line items untouched', () async {
      await db.replaceReceiptLineItemTagAssignments(
        lineItemId: 'li-1',
        tagIds: const ['tag-a'],
      );
      await db.replaceReceiptLineItemTagAssignments(
        lineItemId: 'li-2',
        tagIds: const ['tag-b'],
      );
      final li1 = await db.loadAssignedTagIdsForLineItem('li-1');
      final li2 = await db.loadAssignedTagIdsForLineItem('li-2');
      expect(li1, ['tag-a']);
      expect(li2, ['tag-b']);
    });
  });
}
