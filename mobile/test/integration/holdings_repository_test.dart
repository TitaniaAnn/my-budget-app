// Integration tests for HoldingsRepository.
//
// Pins the contract the holdings UI relies on:
//   * fetchForAccount returns rows for that account only, ordered
//     by symbol ASC (postgrest defaults to DESC — same gotcha as
//     the prior .order() audit)
//   * createHolding round-trips quantity precision (NUMERIC(20,8))
//   * updateHolding refreshes last_priced_at iff current_value
//     was passed — the stale-price indicator depends on it
//   * deleteHolding clears the row
//
// Skipped when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY env
// vars aren't set.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/holdings/models/holding.dart';
import 'package:mybudget/features/holdings/repositories/holdings_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('HoldingsRepository (integration)', () {
    late Harness harness;
    late HoldingsRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'holdings-repo');
      repo = HoldingsRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    // ── fetchForAccount ─────────────────────────────────────────────────

    test('fetchForAccount returns rows ordered by symbol ASC', () async {
      // Insert deliberately out of alphabetical order. The implicit
      // postgrest `.order()` would put 'Z…' first; the repo asks
      // explicitly for ASC.
      await repo.createHolding(
        householdId: harness.householdId,
        accountId: harness.accountId,
        symbol: 'ZTSAX',
        quantity: 1,
        currentValue: 10000,
      );
      await repo.createHolding(
        householdId: harness.householdId,
        accountId: harness.accountId,
        symbol: 'AAPL',
        quantity: 1,
        currentValue: 10000,
      );
      await repo.createHolding(
        householdId: harness.householdId,
        accountId: harness.accountId,
        symbol: 'MSFT',
        quantity: 1,
        currentValue: 10000,
      );

      final result = await repo.fetchForAccount(harness.accountId);
      final symbols = result.map((h) => h.symbol).toList();
      // Other tests in this group may add rows too; assert relative
      // order rather than exact length.
      final aIdx = symbols.indexOf('AAPL');
      final mIdx = symbols.indexOf('MSFT');
      final zIdx = symbols.indexOf('ZTSAX');
      expect(
        aIdx < mIdx && mIdx < zIdx,
        isTrue,
        reason:
            'fetchForAccount must order by symbol ASC. '
            'Found order: AAPL=$aIdx MSFT=$mIdx ZTSAX=$zIdx in $symbols.',
      );
    }, skip: reason);

    // ── createHolding ───────────────────────────────────────────────────

    test(
      'createHolding round-trips fractional quantity at 8 decimals',
      () async {
        // NUMERIC(20,8) is what crypto positions need. Verify the
        // wire format preserves the precision rather than rounding
        // to int or losing precision past 4 places.
        final h = await repo.createHolding(
          householdId: harness.householdId,
          accountId: harness.accountId,
          symbol: 'BTC-FRACTION',
          quantity: 0.12345678,
          currentValue: 500000,
          assetClass: AssetClass.crypto,
        );
        expect(h.quantity, closeTo(0.12345678, 1e-9));
        expect(h.assetClass, AssetClass.crypto);
      },
      skip: reason,
    );

    test(
      'createHolding accepts null cost_basis (backfilled positions)',
      () async {
        // Existing position without purchase history — common case
        // when a user backfills an old brokerage account.
        final h = await repo.createHolding(
          householdId: harness.householdId,
          accountId: harness.accountId,
          symbol: 'NO-BASIS',
          quantity: 10,
          currentValue: 200000,
          // costBasis omitted intentionally.
        );
        expect(h.costBasis, isNull);
      },
      skip: reason,
    );

    // ── updateHolding ───────────────────────────────────────────────────

    test(
      'updateHolding refreshes last_priced_at when currentValue moves',
      () async {
        // Re-marking the value should bump the timestamp. A pure
        // metadata edit (description only) must NOT touch it.
        final created = await repo.createHolding(
          householdId: harness.householdId,
          accountId: harness.accountId,
          symbol: 'STALE',
          quantity: 1,
          currentValue: 10000,
          lastPricedAt: DateTime.utc(2025, 1, 1),
        );

        // Description-only update: timestamp must stay put.
        final descOnly = await repo.updateHolding(
          holdingId: created.id,
          description: 'New name',
        );
        expect(descOnly.lastPricedAt, created.lastPricedAt);

        // Value update: timestamp must move to now.
        final priced = await repo.updateHolding(
          holdingId: created.id,
          currentValue: 12000,
        );
        expect(priced.currentValue, 12000);
        expect(priced.lastPricedAt, isNotNull);
        final skew = DateTime.now()
            .toUtc()
            .difference(priced.lastPricedAt!.toUtc())
            .abs();
        expect(
          skew.inMinutes < 5,
          isTrue,
          reason:
              'updateHolding must refresh last_priced_at to "now" when '
              'currentValue is passed. Skew=$skew.',
        );
      },
      skip: reason,
    );

    // ── deleteHolding ───────────────────────────────────────────────────

    test('deleteHolding removes the row', () async {
      final h = await repo.createHolding(
        householdId: harness.householdId,
        accountId: harness.accountId,
        symbol: 'TO-DELETE',
        quantity: 1,
        currentValue: 100,
      );
      await repo.deleteHolding(h.id);

      final remaining = await repo.fetchForAccount(harness.accountId);
      expect(remaining.any((r) => r.id == h.id), isFalse);
    }, skip: reason);
  });
}
