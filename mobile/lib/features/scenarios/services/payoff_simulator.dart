// Pure-Dart payoff-plan math. No Riverpod, no Supabase, no
// DateTime.now() — easy to unit test against amortisation tables.
//
// The simulator walks forward month by month: each step accrues
// interest on the remaining balance, then applies the user's
// monthly payment. The loop exits when the balance hits zero OR
// when [maxMonths] is reached (the "insufficient payment" guard —
// without a cap, a too-low payment that doesn't outpace interest
// would loop until the heat death of the simulator).
//
// All money in integer cents (project convention). APR in basis
// points so the doubles only live inside the local rate math, not
// in the persisted contract.

import 'dart:math' as math;

/// One row of the projected amortisation table.
class PayoffMonth {
  const PayoffMonth({
    required this.monthEnd,
    required this.interestCents,
    required this.paymentCents,
    required this.balanceCents,
  });

  /// Last day of the simulated month. The simulator advances
  /// month-by-month from the caller-supplied start, so a January
  /// start emits January-31, February-{28,29}, March-31, …
  final DateTime monthEnd;

  /// Interest that accrued THIS month, before the payment was
  /// applied. Always >= 0.
  final int interestCents;

  /// Payment APPLIED this month. Equals the requested monthly
  /// payment except for the final month, where it's clipped to
  /// `balance_before_payment + interest` so we don't overpay past
  /// zero.
  final int paymentCents;

  /// Remaining principal AFTER this month's payment. The last
  /// emitted row of a successful payoff has `balanceCents == 0`.
  final int balanceCents;
}

class PayoffSimulation {
  const PayoffSimulation({
    required this.months,
    required this.paidOff,
    required this.totalInterestCents,
    required this.totalPaidCents,
    required this.startingBalanceCents,
  });

  final List<PayoffMonth> months;

  /// True when the balance reached zero within the simulator's
  /// horizon. False when [maxMonths] capped the loop — meaning the
  /// monthly payment is too small to outpace interest, or the user
  /// chose a horizon shorter than the math allows.
  final bool paidOff;
  final int totalInterestCents;

  /// Sum of every payment applied. For a successful payoff this is
  /// `startingBalance + totalInterest`. For a capped sim it's the
  /// running total at the cap.
  final int totalPaidCents;

  /// What the caller passed in — useful for the UI's "$X paid off
  /// in N months" caption without round-tripping.
  final int startingBalanceCents;

  /// Convenience: total months simulated. Zero when starting
  /// balance was already zero.
  int get monthCount => months.length;

  /// Convenience: payoff date — last row's monthEnd, or null if
  /// nothing simulated.
  DateTime? get payoffDate => months.isEmpty ? null : months.last.monthEnd;
}

/// Walks the amortisation forward from [startingBalanceCents] at
/// the given APR, applying [monthlyPaymentCents] each month until
/// the balance hits zero or [maxMonths] is reached.
///
/// [startingBalanceCents] must be the positive magnitude of the
/// debt (the caller normalises — accounts store credit-card debt
/// as negative cents per project convention, but the simulator
/// works in unsigned principal).
///
/// [aprBps]: APR in basis points. 10000 = 100%. 1799 ≈ 17.99% APR.
/// Monthly rate = APR / 12.
///
/// [startDate]: any DateTime. The simulator emits month-end
/// snapshots advancing forward; the day-of-month is normalised to
/// the last day of each month.
///
/// [maxMonths]: simulation horizon (default 480 = 40 years). Stops
/// the loop when payment is insufficient to outpace interest, so
/// the function always terminates.
PayoffSimulation simulatePayoff({
  required int startingBalanceCents,
  required int monthlyPaymentCents,
  required int aprBps,
  required DateTime startDate,
  int maxMonths = 480,
}) {
  // Normalise pathological inputs to a clean "nothing to simulate"
  // shape rather than throwing — the UI calls this on every form
  // keystroke and we'd rather it just render an empty schedule.
  if (startingBalanceCents <= 0) {
    return PayoffSimulation(
      months: const [],
      paidOff: true,
      totalInterestCents: 0,
      totalPaidCents: 0,
      startingBalanceCents: math.max(0, startingBalanceCents),
    );
  }

  final monthlyRate = aprBps / 10000.0 / 12.0;
  var balance = startingBalanceCents;
  var totalInterest = 0;
  var totalPaid = 0;
  final months = <PayoffMonth>[];

  // Iterate by adding one to the calendar month each step. Using
  // last-day-of-month for the snapshot ([year, month+1, 0] in
  // DateTime convention) keeps Feb's 28/29 right without us doing
  // calendar math.
  for (var i = 1; i <= maxMonths; i++) {
    final interest = (balance * monthlyRate).round();
    // If the requested payment can't cover even the interest, the
    // balance grows — abort the loop and signal "insufficient
    // payment" via paidOff=false. Without this guard the loop
    // would run to maxMonths emitting ever-growing balances; we'd
    // rather short-circuit so the UI can label the input clearly.
    if (monthlyPaymentCents <= interest) {
      return PayoffSimulation(
        months: months,
        paidOff: false,
        totalInterestCents: totalInterest,
        totalPaidCents: totalPaid,
        startingBalanceCents: startingBalanceCents,
      );
    }

    // Last-payment clip: don't overpay past zero. The final month
    // pays exactly balance + interest (sometimes less than the
    // requested monthlyPaymentCents).
    final beforePayment = balance + interest;
    final payment = math.min(monthlyPaymentCents, beforePayment);
    balance = beforePayment - payment;

    totalInterest += interest;
    totalPaid += payment;

    final monthEnd = DateTime(startDate.year, startDate.month + i, 0);
    months.add(
      PayoffMonth(
        monthEnd: monthEnd,
        interestCents: interest,
        paymentCents: payment,
        balanceCents: balance,
      ),
    );

    if (balance <= 0) {
      return PayoffSimulation(
        months: months,
        paidOff: true,
        totalInterestCents: totalInterest,
        totalPaidCents: totalPaid,
        startingBalanceCents: startingBalanceCents,
      );
    }
  }

  // Hit the cap before zero — same shape as insufficient payment,
  // but with a non-empty `months` list. The UI distinguishes via
  // paidOff=false.
  return PayoffSimulation(
    months: months,
    paidOff: false,
    totalInterestCents: totalInterest,
    totalPaidCents: totalPaid,
    startingBalanceCents: startingBalanceCents,
  );
}

/// Inverse: what monthly payment pays [startingBalanceCents] off
/// in exactly [months] months at the given [aprBps]? Used by the
/// AddEventSheet's "target-date → payment" toggle.
///
/// Returns null when [months] <= 0 or [startingBalanceCents] <= 0.
/// For [aprBps] == 0 the math degenerates to plain principal /
/// months; otherwise it uses the standard amortisation formula:
///
///   P = balance × r × (1+r)^n / ((1+r)^n − 1)
///
/// Result is rounded UP to the nearest cent — paying down to
/// exactly zero at the final month requires the payment cover any
/// fractional cent rounding the simulator's own .round() leaves
/// behind. Underpaying by a cent would push the payoff into a
/// 481st month.
int? requiredMonthlyPayment({
  required int startingBalanceCents,
  required int aprBps,
  required int months,
}) {
  if (months <= 0 || startingBalanceCents <= 0) return null;
  if (aprBps == 0) {
    // Ceiling division: payment * months ≥ balance.
    return (startingBalanceCents + months - 1) ~/ months;
  }
  final r = aprBps / 10000.0 / 12.0;
  final pow = math.pow(1 + r, months);
  final payment = startingBalanceCents * r * pow / (pow - 1);
  return payment.ceil();
}
