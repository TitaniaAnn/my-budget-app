// Pure-function tests for evaluateRebalance — the math behind the
// dashboard's rebalance card and the future "Settings → Rebalance"
// surface.
//
// Contracts pinned:
//   * portfolio total = SUM(current_value);
//   * current weight per class = current / total, in basis points;
//   * drift = current_bp - target_bp (positive = overweight);
//   * driftCentsAgainst(portfolioTotalCents) = total × drift / 10000;
//   * a missing target row counts as 0% target;
//   * a target row for a class with zero current value still
//     surfaces (so "buy this position from scratch" is reachable);
//   * holdings with null asset_class fall into AssetClass.other;
//   * rows are sorted by absolute drift descending;
//   * empty portfolio doesn't divide-by-zero.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/holdings/models/holding.dart';
import 'package:mybudget/features/holdings/models/target_allocation.dart';
import 'package:mybudget/features/holdings/services/rebalance.dart';

Holding _h({
  required int currentValueCents,
  AssetClass? assetClass,
  String id = 'h',
}) {
  final ts = DateTime(2026, 1, 1);
  return Holding(
    id: id,
    householdId: 'h',
    accountId: 'a',
    symbol: 'XXX',
    quantity: 1,
    currentValue: currentValueCents,
    assetClass: assetClass,
    createdAt: ts,
    updatedAt: ts,
  );
}

TargetAllocation _t(AssetClass cls, int bp) {
  final ts = DateTime(2026, 1, 1);
  return TargetAllocation(
    householdId: 'h',
    assetClass: cls,
    targetPctBp: bp,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  group('evaluateRebalance', () {
    test('on-target portfolio reports zero drift', () {
      // $6k stocks, $4k bonds — 60/40, matching targets.
      final report = evaluateRebalance(
        holdings: [
          _h(currentValueCents: 600000, assetClass: AssetClass.usEquity),
          _h(currentValueCents: 400000, assetClass: AssetClass.bond),
        ],
        targets: [
          _t(AssetClass.usEquity, 6000),
          _t(AssetClass.bond, 4000),
        ],
      );
      expect(report.totalCents, 1000000);
      expect(report.rows.every((r) => r.driftBp == 0), isTrue);
    });

    test('overweight class reports positive drift + sell suggestion', () {
      // $7k stocks, $3k bonds. Targets 60/40 → stocks overweight
      // by 10pp, bonds underweight by 10pp.
      final report = evaluateRebalance(
        holdings: [
          _h(currentValueCents: 700000, assetClass: AssetClass.usEquity),
          _h(currentValueCents: 300000, assetClass: AssetClass.bond),
        ],
        targets: [
          _t(AssetClass.usEquity, 6000),
          _t(AssetClass.bond, 4000),
        ],
      );
      final equity = report.rows.firstWhere(
        (r) => r.assetClass == AssetClass.usEquity,
      );
      final bonds = report.rows.firstWhere(
        (r) => r.assetClass == AssetClass.bond,
      );
      expect(equity.driftBp, 1000);
      expect(bonds.driftBp, -1000);
      // 10pp of a $10k portfolio = $1k to move.
      expect(equity.driftCentsAgainst(report.totalCents), 100000);
      expect(bonds.driftCentsAgainst(report.totalCents), -100000);
    });

    test('a class with no target row is treated as 0% target', () {
      // $5k crypto with no target row → underweight equity 60%,
      // crypto is OVERWEIGHT by 100% of itself.
      final report = evaluateRebalance(
        holdings: [
          _h(currentValueCents: 500000, assetClass: AssetClass.usEquity),
          _h(currentValueCents: 500000, assetClass: AssetClass.crypto),
        ],
        targets: [_t(AssetClass.usEquity, 10000)],
      );
      final crypto = report.rows.firstWhere(
        (r) => r.assetClass == AssetClass.crypto,
      );
      expect(crypto.targetPctBp, 0);
      expect(crypto.currentPctBp, 5000);
      expect(crypto.driftBp, 5000);
    });

    test(
      'a target with no holding still surfaces (build-this-position case)',
      () {
        // Target 30% bonds but no bond holdings — the row must
        // surface so the user has a path to act on it.
        final report = evaluateRebalance(
          holdings: [
            _h(currentValueCents: 500000, assetClass: AssetClass.usEquity),
          ],
          targets: [
            _t(AssetClass.usEquity, 7000),
            _t(AssetClass.bond, 3000),
          ],
        );
        final bonds = report.rows.firstWhere(
          (r) => r.assetClass == AssetClass.bond,
        );
        expect(bonds.currentValueCents, 0);
        expect(bonds.currentPctBp, 0);
        expect(bonds.targetPctBp, 3000);
        expect(bonds.driftBp, -3000);
      },
    );

    test('holdings with null asset_class fall under AssetClass.other', () {
      final report = evaluateRebalance(
        holdings: [
          _h(
            currentValueCents: 250000,
            assetClass: null,
            id: 'unclassified',
          ),
        ],
        targets: const [],
      );
      expect(report.rows, hasLength(1));
      expect(report.rows.single.assetClass, AssetClass.other);
    });

    test('rows are sorted by absolute drift descending', () {
      // Three classes: small / medium / large drift. The biggest
      // drift surfaces first regardless of sign.
      final report = evaluateRebalance(
        holdings: [
          _h(currentValueCents: 200000, assetClass: AssetClass.usEquity),
          _h(currentValueCents: 300000, assetClass: AssetClass.bond),
          _h(currentValueCents: 500000, assetClass: AssetClass.crypto),
        ],
        targets: [
          _t(AssetClass.usEquity, 2500), // 5pp under
          _t(AssetClass.bond, 5000), // 20pp over... wait
          _t(AssetClass.crypto, 2500), // 25pp over
        ],
      );
      // Actual: 20/30/50, targets 25/50/25 → drifts -5 / -20 / +25.
      // |25| > |20| > |5|, so crypto first, bond second, equity third.
      expect(
        report.rows.map((r) => r.assetClass),
        [AssetClass.crypto, AssetClass.bond, AssetClass.usEquity],
      );
    });

    test('empty portfolio with no targets returns empty rows', () {
      final report = evaluateRebalance(holdings: const [], targets: const []);
      expect(report.totalCents, 0);
      expect(report.rows, isEmpty);
    });

    test(
      'empty portfolio with a target still surfaces the target row',
      () {
        // Total is zero, so divide-by-zero is a real risk. The
        // function must NOT crash; current% is 0, target% surfaces.
        final report = evaluateRebalance(
          holdings: const [],
          targets: [_t(AssetClass.usEquity, 6000)],
        );
        expect(report.totalCents, 0);
        expect(report.rows, hasLength(1));
        expect(report.rows.single.currentPctBp, 0);
        expect(report.rows.single.targetPctBp, 6000);
        expect(report.rows.single.driftBp, -6000);
      },
    );

    test('rowsDriftedBy filters rows by absolute threshold', () {
      // Total 300k → each holding is 33.33% (3333bp) actual.
      // Threshold 500bp = 5pp.
      //   * equity target 24%  → drift +9.3pp (above threshold)
      //   * bond   target 25%  → drift +8.3pp (above threshold)
      //   * cash   target 32%  → drift +1.3pp (below threshold, filtered)
      // Three rows, two surviving.
      final report = evaluateRebalance(
        holdings: [
          _h(currentValueCents: 100000, assetClass: AssetClass.usEquity),
          _h(currentValueCents: 100000, assetClass: AssetClass.bond),
          _h(currentValueCents: 100000, assetClass: AssetClass.cash),
        ],
        targets: [
          _t(AssetClass.usEquity, 2400),
          _t(AssetClass.bond, 2500),
          _t(AssetClass.cash, 3200),
        ],
      );
      final drifted = report.rowsDriftedBy(500);
      final classes = drifted.map((r) => r.assetClass).toSet();
      expect(classes, {AssetClass.usEquity, AssetClass.bond});
      expect(
        drifted.any((r) => r.assetClass == AssetClass.cash),
        isFalse,
        reason: 'the 1.3pp cash drift is below the 5pp threshold and '
            'must not surface as a noisy "almost on target" alert.',
      );
    });
  });
}
