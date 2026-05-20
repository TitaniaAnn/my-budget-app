// Integration tests for FxRatesRepository (migration 036).
//
// Pinned:
//   * setRate upserts on the composite PK (household, from, to,
//     as_of_date) — re-saving the same date overwrites;
//   * latestRate returns the most recent row at or before the
//     cutoff (the "what's the rate for today" lookup);
//   * latestRate returns null when no rate exists for the pair
//     in the time window;
//   * deleteRate removes only the matched row;
//   * the DB CHECK rejects rate <= 0 (negative or zero
//     multipliers would make every conversion nonsense);
//   * the DB CHECK rejects from == to (identity rates are
//     handled by the no-op short-circuit in the conversion math).

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/currency/repositories/fx_rates_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('FxRatesRepository (integration)', () {
    late Harness harness;
    late FxRatesRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'fx-rates');
      repo = FxRatesRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    setUp(() async {
      if (reason != null) return;
      await harness.client
          .from('fx_rates')
          .delete()
          .eq('household_id', harness.householdId);
    });

    test(
      'setRate inserts on first call, upserts on re-save with same date',
      () async {
        await repo.setRate(
          householdId: harness.householdId,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.0573,
          asOfDate: DateTime.utc(2026, 5, 1),
          createdBy: harness.userId,
        );
        var rows = await repo.fetchAll(harness.householdId);
        expect(rows, hasLength(1));
        expect(rows.single.rate, 1.0573);

        // Re-save the same (from, to, date) with a corrected rate
        // — composite PK upsert overwrites in place.
        await repo.setRate(
          householdId: harness.householdId,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.0700,
          asOfDate: DateTime.utc(2026, 5, 1),
          createdBy: harness.userId,
        );
        rows = await repo.fetchAll(harness.householdId);
        expect(rows, hasLength(1));
        expect(rows.single.rate, 1.0700);
      },
      skip: reason,
    );

    test(
      'latestRate returns the most recent row at or before the cutoff',
      () async {
        // Three rates for the same pair across three dates. The
        // lookup must pick the one closest to (but not after)
        // the cutoff.
        for (final entry in {
          DateTime.utc(2026, 5, 1): 1.05,
          DateTime.utc(2026, 5, 5): 1.07,
          DateTime.utc(2026, 5, 10): 1.10,
        }.entries) {
          await repo.setRate(
            householdId: harness.householdId,
            fromCurrency: 'EUR',
            toCurrency: 'USD',
            rate: entry.value,
            asOfDate: entry.key,
            createdBy: harness.userId,
          );
        }

        // Cutoff between May 5 and May 10 → picks May 5.
        final rate = await repo.latestRate(
          householdId: harness.householdId,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          asOf: DateTime.utc(2026, 5, 8),
        );
        expect(rate, isNotNull);
        expect(rate!.rate, 1.07);
        expect(
          rate.asOfDate.toIso8601String().substring(0, 10),
          '2026-05-05',
        );
      },
      skip: reason,
    );

    test(
      'latestRate returns null when no rate exists for the pair',
      () async {
        // Set EUR→USD; query for GBP→USD → no match, null.
        await repo.setRate(
          householdId: harness.householdId,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.05,
          asOfDate: DateTime.utc(2026, 5, 1),
          createdBy: harness.userId,
        );
        final rate = await repo.latestRate(
          householdId: harness.householdId,
          fromCurrency: 'GBP',
          toCurrency: 'USD',
        );
        expect(
          rate,
          isNull,
          reason: 'a household with no GBP rate set must get null '
              'back — the dashboard surfaces that as a missing-rate '
              'warning, not a silent fall-through.',
        );
      },
      skip: reason,
    );

    test(
      'latestRate returns null when every rate is AFTER the cutoff',
      () async {
        // Rate dated May 10; query for cutoff May 1 → too early,
        // no rate available yet for that historical date.
        await repo.setRate(
          householdId: harness.householdId,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.05,
          asOfDate: DateTime.utc(2026, 5, 10),
          createdBy: harness.userId,
        );
        final rate = await repo.latestRate(
          householdId: harness.householdId,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          asOf: DateTime.utc(2026, 5, 1),
        );
        expect(rate, isNull);
      },
      skip: reason,
    );

    test(
      'deleteRate removes only the matched (pair, date) row',
      () async {
        await repo.setRate(
          householdId: harness.householdId,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.05,
          asOfDate: DateTime.utc(2026, 5, 1),
          createdBy: harness.userId,
        );
        await repo.setRate(
          householdId: harness.householdId,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          rate: 1.10,
          asOfDate: DateTime.utc(2026, 5, 10),
          createdBy: harness.userId,
        );

        await repo.deleteRate(
          householdId: harness.householdId,
          fromCurrency: 'EUR',
          toCurrency: 'USD',
          asOfDate: DateTime.utc(2026, 5, 1),
        );

        final rows = await repo.fetchAll(harness.householdId);
        expect(rows, hasLength(1));
        expect(
          rows.single.asOfDate.toIso8601String().substring(0, 10),
          '2026-05-10',
        );
      },
      skip: reason,
    );

    test(
      'DB CHECK rejects rate <= 0 and from == to',
      () async {
        // Zero rate would make every conversion zero; negative
        // rate would flip signs nonsensically. The CHECK rejects
        // both. from == to is also rejected because identity
        // rates are handled by the no-op short-circuit.
        await expectLater(
          repo.setRate(
            householdId: harness.householdId,
            fromCurrency: 'EUR',
            toCurrency: 'USD',
            rate: 0,
            asOfDate: DateTime.utc(2026, 5, 1),
            createdBy: harness.userId,
          ),
          throwsA(anything),
        );
        await expectLater(
          repo.setRate(
            householdId: harness.householdId,
            fromCurrency: 'EUR',
            toCurrency: 'USD',
            rate: -1.05,
            asOfDate: DateTime.utc(2026, 5, 1),
            createdBy: harness.userId,
          ),
          throwsA(anything),
        );
        await expectLater(
          repo.setRate(
            householdId: harness.householdId,
            fromCurrency: 'USD',
            toCurrency: 'USD',
            rate: 1.0,
            asOfDate: DateTime.utc(2026, 5, 1),
            createdBy: harness.userId,
          ),
          throwsA(anything),
        );
      },
      skip: reason,
    );
  });
}
