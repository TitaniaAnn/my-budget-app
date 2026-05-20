// Integration tests for TargetAllocationsRepository (migration 035).
//
// Pinned:
//   * setTarget upserts on (household, asset_class) — repeat-set
//     replaces the previous target_pct_bp;
//   * fetchAll returns every row for the household, no others;
//   * deleteTarget removes the row (not a "set to 0" — the
//     absence has different semantics for the UI);
//   * the DB CHECK rejects out-of-range basis points.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/holdings/models/holding.dart';
import 'package:mybudget/features/holdings/repositories/target_allocations_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('TargetAllocationsRepository (integration)', () {
    late Harness harness;
    late TargetAllocationsRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'target-allocations');
      repo = TargetAllocationsRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    setUp(() async {
      if (reason != null) return;
      // Each test starts with a clean slate so assertions on
      // fetchAll's full output aren't sensitive to sibling tests.
      await harness.client
          .from('target_allocations')
          .delete()
          .eq('household_id', harness.householdId);
    });

    test('setTarget inserts on first call, upserts on second', () async {
      await repo.setTarget(
        householdId: harness.householdId,
        assetClass: AssetClass.usEquity,
        targetPctBp: 6000,
        createdBy: harness.userId,
      );
      var rows = await repo.fetchAll(harness.householdId);
      expect(rows, hasLength(1));
      expect(rows.single.targetPctBp, 6000);

      // Re-set to a different value — must not create a duplicate row.
      await repo.setTarget(
        householdId: harness.householdId,
        assetClass: AssetClass.usEquity,
        targetPctBp: 7000,
        createdBy: harness.userId,
      );
      rows = await repo.fetchAll(harness.householdId);
      expect(rows, hasLength(1));
      expect(rows.single.targetPctBp, 7000);
    }, skip: reason);

    test('fetchAll returns every row for the household', () async {
      // Three classes set.
      for (final entry in {
        AssetClass.usEquity: 5000,
        AssetClass.bond: 3000,
        AssetClass.cash: 2000,
      }.entries) {
        await repo.setTarget(
          householdId: harness.householdId,
          assetClass: entry.key,
          targetPctBp: entry.value,
          createdBy: harness.userId,
        );
      }

      final rows = await repo.fetchAll(harness.householdId);
      final byClass = {for (final r in rows) r.assetClass: r.targetPctBp};
      expect(byClass, {
        AssetClass.usEquity: 5000,
        AssetClass.bond: 3000,
        AssetClass.cash: 2000,
      });
    }, skip: reason);

    test('deleteTarget removes only the specified class', () async {
      await repo.setTarget(
        householdId: harness.householdId,
        assetClass: AssetClass.usEquity,
        targetPctBp: 6000,
        createdBy: harness.userId,
      );
      await repo.setTarget(
        householdId: harness.householdId,
        assetClass: AssetClass.bond,
        targetPctBp: 4000,
        createdBy: harness.userId,
      );

      await repo.deleteTarget(
        householdId: harness.householdId,
        assetClass: AssetClass.usEquity,
      );

      final rows = await repo.fetchAll(harness.householdId);
      expect(rows, hasLength(1));
      expect(rows.single.assetClass, AssetClass.bond);
    }, skip: reason);

    test(
      'DB CHECK rejects basis points outside 0..10000',
      () async {
        // Pin the migration 035 CHECK constraint. A future model
        // change that lets 15000bp through would silently surface
        // a 150% target on the rebalance card.
        await expectLater(
          repo.setTarget(
            householdId: harness.householdId,
            assetClass: AssetClass.usEquity,
            targetPctBp: 15000,
            createdBy: harness.userId,
          ),
          throwsA(anything),
        );
        await expectLater(
          repo.setTarget(
            householdId: harness.householdId,
            assetClass: AssetClass.bond,
            targetPctBp: -100,
            createdBy: harness.userId,
          ),
          throwsA(anything),
        );
      },
      skip: reason,
    );
  });
}
