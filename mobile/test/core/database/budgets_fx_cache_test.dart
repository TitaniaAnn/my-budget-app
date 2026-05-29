// Drift round-trip tests for the budgets + fx_rates caches
// added in L1 Phase 2b. Same in-memory pattern as the prior
// cache tests — no Supabase, runs under plain `flutter test`.

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

  BudgetsCacheCompanion sampleBudget({
    required String id,
    String householdId = 'hh-1',
    String categoryId = 'cat-1',
    int amount = 50000,
    String currency = 'USD',
    String period = 'monthly',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BudgetsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      categoryId: Value(categoryId),
      amount: Value(amount),
      currency: Value(currency),
      period: Value(period),
      startDate: Value(startDate ?? DateTime.utc(2026, 5, 1)),
      endDate: Value(endDate),
      createdBy: const Value('user-1'),
      cachedAt: Value(DateTime.utc(2026, 5, 28, 12)),
    );
  }

  FxRatesCacheCompanion sampleFx({
    String householdId = 'hh-1',
    String fromCurrency = 'EUR',
    String toCurrency = 'USD',
    DateTime? asOfDate,
    double rate = 1.08,
  }) {
    final date = asOfDate ?? DateTime.utc(2026, 5, 1);
    return FxRatesCacheCompanion(
      householdId: Value(householdId),
      fromCurrency: Value(fromCurrency),
      toCurrency: Value(toCurrency),
      asOfDate: Value(date),
      rate: Value(rate),
      createdBy: const Value('user-1'),
      createdAt: Value(date),
      updatedAt: Value(date),
      cachedAt: Value(DateTime.utc(2026, 5, 28, 12)),
    );
  }

  group('AppDatabase.replaceBudgetsForHousehold', () {
    test('purges prior budgets for the household before inserting', () async {
      await db.upsertBudget(sampleBudget(id: 'b-old-1'));
      await db.upsertBudget(sampleBudget(id: 'b-old-2'));
      await db.replaceBudgetsForHousehold('hh-1', [
        sampleBudget(id: 'b-new'),
      ]);
      final rows = await db.loadBudgetsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['b-new']);
    });

    test('leaves other households untouched', () async {
      await db.upsertBudget(sampleBudget(id: 'b-hh1', householdId: 'hh-1'));
      await db.upsertBudget(sampleBudget(id: 'b-hh2', householdId: 'hh-2'));
      await db.replaceBudgetsForHousehold('hh-1', [
        sampleBudget(id: 'b-fresh-hh1', householdId: 'hh-1'),
      ]);
      final hh2 = await db.loadBudgetsForHousehold('hh-2');
      expect(hh2.map((r) => r.id), ['b-hh2']);
    });

    test('empty replacement set leaves the household empty', () async {
      await db.upsertBudget(sampleBudget(id: 'b-1'));
      await db.replaceBudgetsForHousehold('hh-1', const []);
      expect(await db.loadBudgetsForHousehold('hh-1'), isEmpty);
    });
  });

  group('AppDatabase budget surface', () {
    test('upsertBudget replaces on id conflict', () async {
      await db.upsertBudget(sampleBudget(id: 'b-1', amount: 50000));
      await db.upsertBudget(sampleBudget(id: 'b-1', amount: 75000));
      final rows = await db.loadBudgetsForHousehold('hh-1');
      expect(rows.single.amount, 75000);
    });

    test('deleteBudget removes one row by id', () async {
      await db.upsertBudget(sampleBudget(id: 'b-1'));
      await db.upsertBudget(sampleBudget(id: 'b-2'));
      await db.deleteBudget('b-1');
      final rows = await db.loadBudgetsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['b-2']);
    });

    test('loadBudgetsForHousehold sorts by start_date ASC', () async {
      await db.upsertBudget(
        sampleBudget(id: 'b-late', startDate: DateTime.utc(2026, 5, 1)),
      );
      await db.upsertBudget(
        sampleBudget(id: 'b-early', startDate: DateTime.utc(2026, 1, 1)),
      );
      await db.upsertBudget(
        sampleBudget(id: 'b-mid', startDate: DateTime.utc(2026, 3, 1)),
      );
      final rows = await db.loadBudgetsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['b-early', 'b-mid', 'b-late']);
    });
  });

  group('AppDatabase.replaceFxRatesForHousehold', () {
    test('purges prior rates for the household before inserting', () async {
      await db.upsertFxRate(sampleFx(asOfDate: DateTime.utc(2026, 1, 1)));
      await db.upsertFxRate(sampleFx(asOfDate: DateTime.utc(2026, 2, 1)));
      await db.replaceFxRatesForHousehold('hh-1', [
        sampleFx(asOfDate: DateTime.utc(2026, 5, 1)),
      ]);
      final rows = await db.loadFxRatesForHousehold('hh-1');
      expect(rows.map((r) => r.asOfDate), [DateTime.utc(2026, 5, 1)]);
    });

    test('leaves other households untouched', () async {
      await db.upsertFxRate(sampleFx(householdId: 'hh-1'));
      await db.upsertFxRate(sampleFx(householdId: 'hh-2'));
      await db.replaceFxRatesForHousehold('hh-1', [
        sampleFx(
          householdId: 'hh-1',
          asOfDate: DateTime.utc(2026, 5, 5),
        ),
      ]);
      final hh2 = await db.loadFxRatesForHousehold('hh-2');
      expect(hh2, hasLength(1));
    });
  });

  group('AppDatabase.loadLatestFxRate', () {
    test('returns the most recent rate at or before [asOf]', () async {
      await db.upsertFxRate(sampleFx(
        asOfDate: DateTime.utc(2026, 1, 15),
        rate: 1.05,
      ));
      await db.upsertFxRate(sampleFx(
        asOfDate: DateTime.utc(2026, 3, 15),
        rate: 1.08,
      ));
      await db.upsertFxRate(sampleFx(
        asOfDate: DateTime.utc(2026, 5, 15),
        rate: 1.12,
      ));
      final result = await db.loadLatestFxRate(
        householdId: 'hh-1',
        fromCurrency: 'EUR',
        toCurrency: 'USD',
        asOf: DateTime.utc(2026, 4, 1),
      );
      expect(result?.rate, 1.08);
      expect(result?.asOfDate, DateTime.utc(2026, 3, 15));
    });

    test('returns null when no rate exists for the pair', () async {
      await db.upsertFxRate(sampleFx(
        fromCurrency: 'EUR',
        toCurrency: 'USD',
      ));
      final result = await db.loadLatestFxRate(
        householdId: 'hh-1',
        fromCurrency: 'GBP',
        toCurrency: 'USD',
        asOf: DateTime.utc(2026, 5, 28),
      );
      expect(result, isNull);
    });

    test('respects (fromCurrency, toCurrency) directionality', () async {
      // Symmetry isn't assumed — storing EUR→USD doesn't imply USD→EUR.
      await db.upsertFxRate(sampleFx(
        fromCurrency: 'EUR',
        toCurrency: 'USD',
        rate: 1.08,
      ));
      final reverse = await db.loadLatestFxRate(
        householdId: 'hh-1',
        fromCurrency: 'USD',
        toCurrency: 'EUR',
        asOf: DateTime.utc(2026, 5, 28),
      );
      expect(reverse, isNull);
    });

    test('respects household scoping', () async {
      await db.upsertFxRate(sampleFx(householdId: 'hh-1', rate: 1.08));
      await db.upsertFxRate(sampleFx(householdId: 'hh-2', rate: 1.12));
      final hh1Rate = await db.loadLatestFxRate(
        householdId: 'hh-1',
        fromCurrency: 'EUR',
        toCurrency: 'USD',
      );
      final hh2Rate = await db.loadLatestFxRate(
        householdId: 'hh-2',
        fromCurrency: 'EUR',
        toCurrency: 'USD',
      );
      expect(hh1Rate?.rate, 1.08);
      expect(hh2Rate?.rate, 1.12);
    });

    test('defaults asOf to now() — picks the most recent rate', () async {
      await db.upsertFxRate(sampleFx(
        asOfDate: DateTime.utc(2026, 1, 1),
        rate: 1.05,
      ));
      await db.upsertFxRate(sampleFx(
        asOfDate: DateTime.utc(2026, 4, 1),
        rate: 1.08,
      ));
      final result = await db.loadLatestFxRate(
        householdId: 'hh-1',
        fromCurrency: 'EUR',
        toCurrency: 'USD',
      );
      expect(result?.rate, 1.08);
    });
  });

  group('AppDatabase fx surface', () {
    test('loadFxRatesForHousehold sorts by as_of_date DESC', () async {
      await db.upsertFxRate(sampleFx(asOfDate: DateTime.utc(2026, 1, 1)));
      await db.upsertFxRate(sampleFx(
        asOfDate: DateTime.utc(2026, 5, 1),
        fromCurrency: 'GBP',
      ));
      await db.upsertFxRate(sampleFx(
        asOfDate: DateTime.utc(2026, 3, 1),
        fromCurrency: 'CAD',
      ));
      final rows = await db.loadFxRatesForHousehold('hh-1');
      expect(
        rows.map((r) => r.asOfDate).toList(),
        [
          DateTime.utc(2026, 5, 1),
          DateTime.utc(2026, 3, 1),
          DateTime.utc(2026, 1, 1),
        ],
      );
    });

    test('upsertFxRate replaces on composite PK conflict', () async {
      await db.upsertFxRate(sampleFx(rate: 1.05));
      await db.upsertFxRate(sampleFx(rate: 1.08));
      final rows = await db.loadFxRatesForHousehold('hh-1');
      expect(rows, hasLength(1));
      expect(rows.single.rate, 1.08);
    });

    test('deleteFxRate removes the matching row only', () async {
      await db.upsertFxRate(sampleFx(asOfDate: DateTime.utc(2026, 1, 1)));
      await db.upsertFxRate(sampleFx(asOfDate: DateTime.utc(2026, 5, 1)));
      await db.deleteFxRate(
        householdId: 'hh-1',
        fromCurrency: 'EUR',
        toCurrency: 'USD',
        asOfDate: DateTime.utc(2026, 1, 1),
      );
      final rows = await db.loadFxRatesForHousehold('hh-1');
      expect(rows.map((r) => r.asOfDate), [DateTime.utc(2026, 5, 1)]);
    });
  });
}
