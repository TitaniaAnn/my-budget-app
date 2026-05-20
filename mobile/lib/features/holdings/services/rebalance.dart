// Pure rebalance math: given current holdings + target weights,
// return per-class drift (current% − target%) and the dollar
// amount each class would have to move to hit its target.
//
// Two reasons this lives in its own file:
//   * The math is easy to get wrong (basis-point conversions, the
//     "what if total portfolio is zero" edge), so a unit-testable
//     pure function is the right shape;
//   * The dashboard surface and the future "Settings → Rebalance"
//     screen will both want this output; threading the math
//     through a Riverpod provider that calls into both contexts
//     keeps the dependency arrow pointing one way.
//
// Inputs:
//   * holdings — every active holding in the household. The
//     function sums current_value per asset_class (treating null
//     asset_class as AssetClass.other so an unclassified position
//     still gets counted somewhere — otherwise it'd vanish from
//     the portfolio total).
//   * targets — desired weight per class in basis points. Missing
//     classes are treated as 0% target — useful for "I don't want
//     to hold crypto" without forcing the user to create a row.
//
// Outputs: one [RebalanceRow] per class that has either a non-zero
// current value OR a non-zero target. Sorted by absolute drift
// descending so the most out-of-whack class surfaces first.

import '../models/holding.dart';
import '../models/target_allocation.dart';

class RebalanceRow {
  const RebalanceRow({
    required this.assetClass,
    required this.currentValueCents,
    required this.currentPctBp,
    required this.targetPctBp,
  });

  final AssetClass assetClass;
  final int currentValueCents;

  /// Current weight in basis points (currentValueCents /
  /// portfolioTotal × 10000). Zero when the portfolio total is
  /// zero — see [evaluateRebalance] for the edge handling.
  final int currentPctBp;

  /// Target weight in basis points (0 when no row exists).
  final int targetPctBp;

  /// Drift in basis points. Positive = overweight (sell), negative
  /// = underweight (buy). 50bp == 0.5 percentage points.
  int get driftBp => currentPctBp - targetPctBp;

  /// Dollar amount this class would have to move to hit its target,
  /// given the current portfolio total. Positive = needs to shrink;
  /// negative = needs to grow.
  ///
  /// Computed against the CURRENT total (not a hypothetical
  /// rebalanced total), so a sum of all rows' magnitudes won't
  /// quite equal a "deposit plus rebalance" math problem — that
  /// suggestion is a future iteration.
  int driftCentsAgainst(int portfolioTotalCents) =>
      (portfolioTotalCents * driftBp / 10000).round();
}

/// Output of an evaluation pass.
class RebalanceReport {
  const RebalanceReport({
    required this.totalCents,
    required this.rows,
  });

  /// Sum of current_value across all active holdings, regardless
  /// of asset_class. Zero when the household has no holdings — in
  /// that case [rows] is empty too.
  final int totalCents;

  final List<RebalanceRow> rows;

  /// Rows whose drift magnitude exceeds [thresholdBp]. The
  /// dashboard surface filters on this so a 1% drift doesn't
  /// generate dashboard noise.
  List<RebalanceRow> rowsDriftedBy(int thresholdBp) =>
      rows.where((r) => r.driftBp.abs() >= thresholdBp).toList();
}

RebalanceReport evaluateRebalance({
  required List<Holding> holdings,
  required List<TargetAllocation> targets,
}) {
  // Sum current_value per class. Treat null asset_class as `other`
  // so unclassified positions still hit the portfolio total.
  final byClass = <AssetClass, int>{};
  var total = 0;
  for (final h in holdings) {
    final cls = h.assetClass ?? AssetClass.other;
    byClass.update(cls, (v) => v + h.currentValue, ifAbsent: () => h.currentValue);
    total += h.currentValue;
  }

  final targetByClass = {for (final t in targets) t.assetClass: t.targetPctBp};

  // Union of classes appearing in either holdings or targets.
  // Targets-only rows (the user set a target for an asset they
  // don't yet hold) need to surface so they can act on it.
  final classes = {...byClass.keys, ...targetByClass.keys};

  final rows = <RebalanceRow>[];
  for (final cls in classes) {
    final currentValue = byClass[cls] ?? 0;
    // currentPctBp is 0 when the portfolio is empty — same
    // mathematical convention "no portfolio, no weights." A nonzero
    // target in that state still surfaces as "underweight by 100%"
    // which the UI can frame as "build this position from scratch".
    final currentPctBp = total == 0
        ? 0
        : (currentValue * 10000 / total).round();
    final targetPctBp = targetByClass[cls] ?? 0;
    if (currentValue == 0 && targetPctBp == 0) continue;
    rows.add(RebalanceRow(
      assetClass: cls,
      currentValueCents: currentValue,
      currentPctBp: currentPctBp,
      targetPctBp: targetPctBp,
    ));
  }

  rows.sort((a, b) => b.driftBp.abs().compareTo(a.driftBp.abs()));

  return RebalanceReport(totalCents: total, rows: rows);
}
