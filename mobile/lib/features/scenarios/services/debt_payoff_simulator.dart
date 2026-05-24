// Pure-Dart multi-debt payoff simulator.
//
// Walks month by month across N debts simultaneously: accrues
// interest per debt, applies minimum payments, then distributes the
// remaining monthly budget across debts according to the chosen
// strategy (avalanche / snowball / custom). The loop stops when all
// debts hit zero OR [maxMonths] is reached (the runaway guard —
// without it, an under-budgeted plan that can't outpace interest
// would loop forever).
//
// Companion to payoff_simulator.dart (single-debt). The multi-debt
// version is its own file because the strategy logic + tied-debt
// tracking add enough state that sharing one function would muddle
// both APIs.
//
// All money in integer cents. APR in basis points.

import 'dart:math' as math;

import '../models/scenario.dart';

/// Per-debt monthly snapshot. The simulator emits one
/// [MultiDebtMonth] per simulated cycle; each carries a map keyed
/// by accountId so the UI can render per-debt lines.
class MultiDebtMonth {
  const MultiDebtMonth({
    required this.monthEnd,
    required this.balances,
    required this.interest,
    required this.payments,
  });

  /// Last day of the simulated month (mirrors single-debt
  /// simulator's calendar convention).
  final DateTime monthEnd;

  /// Remaining principal per debt, AFTER this month's payment.
  /// A debt that paid off this month maps to 0.
  final Map<String, int> balances;

  /// Interest accrued per debt THIS month, before any payment.
  final Map<String, int> interest;

  /// Total payment applied per debt this month (min + extra,
  /// clipped to "don't overpay past zero" on the final month).
  final Map<String, int> payments;
}

class MultiDebtPayoffResult {
  const MultiDebtPayoffResult({
    required this.months,
    required this.allPaidOff,
    required this.totalInterestCents,
    required this.totalPaidCents,
    required this.payoffDates,
    required this.startingPrincipals,
  });

  final List<MultiDebtMonth> months;

  /// True iff every debt reached zero before [maxMonths]. False
  /// when the cap interrupted — either the budget can't outpace
  /// interest, or the user picked an unrealistic combination.
  final bool allPaidOff;

  final int totalInterestCents;
  final int totalPaidCents;

  /// Per-debt payoff date. Null entry means that debt was never
  /// paid off within the simulation horizon.
  final Map<String, DateTime?> payoffDates;

  /// Per-debt starting principal — captured so the UI can render
  /// "started at $X" without re-deriving.
  final Map<String, int> startingPrincipals;

  /// Convenience: the latest payoff date across all debts, or
  /// null if any debt didn't clear. This is the "debt-free by"
  /// the summary surface shows.
  DateTime? get debtFreeDate {
    if (!allPaidOff) return null;
    final dates = payoffDates.values.whereType<DateTime>().toList();
    if (dates.isEmpty) return null;
    dates.sort();
    return dates.last;
  }
}

/// One debt as the simulator sees it. The model layer's
/// [DebtPayoffTarget] is augmented with the live `principalCents`
/// (the simulator advances this each month) — kept separate so
/// the persisted target stays immutable while the simulation
/// mutates principal in place.
class _SimDebt {
  _SimDebt({
    required this.accountId,
    required this.principalCents,
    required this.aprBps,
    required this.minPaymentCents,
    required this.extraPaymentCents,
  });

  final String accountId;
  int principalCents;
  final int aprBps;
  final int minPaymentCents;
  final int extraPaymentCents;

  bool get paidOff => principalCents <= 0;
}

/// Multi-debt amortisation. See file header for the algorithm.
///
/// [targets] is the list of debts to pay down — usually populated
/// from `Scenario.debtPayoffTargets`. [startingPrincipals] maps
/// accountId → current outstanding principal (cents, positive
/// magnitude) at simulation start; the caller resolves these from
/// `Account.currentBalance.abs()`.
///
/// [strategy] selects the extra-payment allocator:
///   * avalanche → extra → highest aprBps among live debts
///   * snowball  → extra → smallest principal among live debts
///   * custom    → per-debt `extraPaymentCents` honoured verbatim,
///                 up to the per-month budget.
///
/// [monthlyBudgetCents] is the TOTAL across all debts (mins +
/// extras). When it falls below the sum of minimums the
/// simulator bails with allPaidOff=false rather than emit
/// growing-debt months.
/// One-off lump-sum extra payment landing on a specific calendar
/// month. [accountId] null → joins that month's extra budget and
/// flows through [DebtPayoffStrategy]; set → pre-pays the named
/// debt before strategy allocation. The simulator buckets each
/// one-off by `(date.year, date.month)`.
class OneOffPaymentInput {
  const OneOffPaymentInput({
    required this.date,
    required this.amountCents,
    this.accountId,
  });
  final DateTime date;
  final int amountCents;
  final String? accountId;
}

MultiDebtPayoffResult simulateMultiDebtPayoff({
  required List<DebtPayoffTarget> targets,
  required Map<String, int> startingPrincipals,
  required DebtPayoffStrategy strategy,
  required int monthlyBudgetCents,
  required DateTime startDate,
  List<OneOffPaymentInput> oneOffPayments = const [],
  int maxMonths = 600,
}) {
  // Resolve to mutable sim state, dropping targets whose account
  // has no balance (deleted, or zeroed-out) so the simulator
  // doesn't waste a slot on a no-op.
  final debts = <_SimDebt>[];
  for (final t in targets) {
    final p = startingPrincipals[t.accountId] ?? 0;
    if (p <= 0) continue;
    debts.add(
      _SimDebt(
        accountId: t.accountId,
        principalCents: p,
        aprBps: t.aprBps,
        minPaymentCents: t.minPaymentCents,
        extraPaymentCents: t.extraPaymentCents ?? 0,
      ),
    );
  }

  final startingSnapshot = {
    for (final d in debts) d.accountId: d.principalCents,
  };

  if (debts.isEmpty) {
    return MultiDebtPayoffResult(
      months: const [],
      allPaidOff: true,
      totalInterestCents: 0,
      totalPaidCents: 0,
      payoffDates: const {},
      startingPrincipals: startingSnapshot,
    );
  }

  // Insufficient-budget gate. If the user can't cover even the
  // minimums, every debt grows; bail immediately so the UI shows
  // "increase the budget" rather than 50 years of climbing
  // balances.
  final sumOfMins = debts.fold<int>(0, (a, d) => a + d.minPaymentCents);
  if (monthlyBudgetCents < sumOfMins) {
    return MultiDebtPayoffResult(
      months: const [],
      allPaidOff: false,
      totalInterestCents: 0,
      totalPaidCents: 0,
      payoffDates: {for (final d in debts) d.accountId: null},
      startingPrincipals: startingSnapshot,
    );
  }

  // Bucket one-offs by (year, month) so per-iteration lookup is
  // O(1). Same key encoding as the monthEnd date the simulator
  // emits — `(year, month)` ignores the day, which is the
  // intended contract (a payment dated March 15 lands in the
  // March cycle that ends March 31).
  final oneOffsByMonth = <int, List<OneOffPaymentInput>>{};
  int monthKey(int y, int m) => y * 100 + m;
  for (final o in oneOffPayments) {
    if (o.amountCents <= 0) continue;
    final k = monthKey(o.date.year, o.date.month);
    (oneOffsByMonth[k] ??= []).add(o);
  }

  final months = <MultiDebtMonth>[];
  final payoffDates = <String, DateTime?>{
    for (final d in debts) d.accountId: null,
  };
  var totalInterest = 0;
  var totalPaid = 0;

  for (var i = 1; i <= maxMonths; i++) {
    final monthEnd = DateTime(startDate.year, startDate.month + i, 0);
    final balances = <String, int>{};
    final interestThisMonth = <String, int>{};
    final paymentsThisMonth = <String, int>{};

    // ── Step 1: interest + minimum payment per live debt ───────
    var extraBudget = monthlyBudgetCents;
    for (final d in debts) {
      if (d.paidOff) {
        balances[d.accountId] = 0;
        interestThisMonth[d.accountId] = 0;
        paymentsThisMonth[d.accountId] = 0;
        continue;
      }
      final rate = d.aprBps / 10000.0 / 12.0;
      final interest = (d.principalCents * rate).round();
      // The minimum can never exceed (balance + this month's
      // interest) — clip on the final month so the debt lands at
      // exactly zero, not below.
      final beforeMinAvailable = d.principalCents + interest;
      final minApplied = math.min(d.minPaymentCents, beforeMinAvailable);
      d.principalCents = beforeMinAvailable - minApplied;
      extraBudget -= minApplied;

      interestThisMonth[d.accountId] = interest;
      paymentsThisMonth[d.accountId] = minApplied;
      totalInterest += interest;
      totalPaid += minApplied;
    }

    // ── Step 1b: one-off lump-sums for this month ─────────────
    // Targeted lump-sums pre-pay their specific debt (bypass
    // strategy); untargeted ones fold into extraBudget so they
    // flow through the strategy in step 2.
    final lumps = oneOffsByMonth[monthKey(monthEnd.year, monthEnd.month)];
    if (lumps != null) {
      for (final lump in lumps) {
        if (lump.accountId != null) {
          final d = debts
              .where((d) => d.accountId == lump.accountId && !d.paidOff)
              .firstOrNull;
          if (d == null) {
            // Lump-sum to a debt that's already paid off (or was
            // dropped at sim start) — graceful no-op. The user-
            // entered amount can't help here; we don't reflow it
            // into extraBudget because the user explicitly chose
            // a target.
            continue;
          }
          final pay = math.min(lump.amountCents, d.principalCents);
          d.principalCents -= pay;
          paymentsThisMonth[d.accountId] =
              (paymentsThisMonth[d.accountId] ?? 0) + pay;
          totalPaid += pay;
          if (d.principalCents <= 0 && payoffDates[d.accountId] == null) {
            payoffDates[d.accountId] = monthEnd;
          }
        } else {
          extraBudget += lump.amountCents;
        }
      }
    }

    // ── Step 2: allocate extras per strategy ──────────────────
    if (extraBudget > 0) {
      _applyExtras(
        debts: debts,
        strategy: strategy,
        extraBudget: extraBudget,
        paymentsThisMonth: paymentsThisMonth,
        totalPaidRef: () => totalPaid,
        addToTotalPaid: (n) => totalPaid += n,
      );
    }

    // Snapshot end-of-month balances + record payoff dates.
    for (final d in debts) {
      balances[d.accountId] = d.principalCents;
      if (d.principalCents <= 0 && payoffDates[d.accountId] == null) {
        payoffDates[d.accountId] = monthEnd;
      }
    }

    months.add(
      MultiDebtMonth(
        monthEnd: monthEnd,
        balances: balances,
        interest: interestThisMonth,
        payments: paymentsThisMonth,
      ),
    );

    // Early exit when every debt has cleared.
    if (debts.every((d) => d.paidOff)) {
      return MultiDebtPayoffResult(
        months: months,
        allPaidOff: true,
        totalInterestCents: totalInterest,
        totalPaidCents: totalPaid,
        payoffDates: payoffDates,
        startingPrincipals: startingSnapshot,
      );
    }
  }

  // Cap hit — at least one debt remains. Common cause: budget
  // covers minimums but minimums alone aren't enough to outpace
  // interest on every debt and the extra allocator can only push
  // one debt at a time.
  return MultiDebtPayoffResult(
    months: months,
    allPaidOff: false,
    totalInterestCents: totalInterest,
    totalPaidCents: totalPaid,
    payoffDates: payoffDates,
    startingPrincipals: startingSnapshot,
  );
}

/// Allocates `extraBudget` across live debts per the strategy.
/// Mutates `debts[i].principalCents` and accumulates into
/// `paymentsThisMonth` + the global total.
///
/// Avalanche / snowball pick a single recipient per month and
/// flow the whole extra there until it's paid off (then the
/// allocator naturally re-picks the next month). Custom honours
/// each target's `extraPaymentCents` in declared order, stopping
/// when the budget is exhausted.
void _applyExtras({
  required List<_SimDebt> debts,
  required DebtPayoffStrategy strategy,
  required int extraBudget,
  required Map<String, int> paymentsThisMonth,
  required int Function() totalPaidRef,
  required void Function(int) addToTotalPaid,
}) {
  void payInto(_SimDebt d, int amount) {
    final clipped = math.min(amount, d.principalCents);
    if (clipped <= 0) return;
    d.principalCents -= clipped;
    paymentsThisMonth[d.accountId] =
        (paymentsThisMonth[d.accountId] ?? 0) + clipped;
    addToTotalPaid(clipped);
  }

  final live = debts.where((d) => !d.paidOff).toList();
  if (live.isEmpty) return;

  switch (strategy) {
    case DebtPayoffStrategy.avalanche:
      // Highest APR wins. Tiebreaker: smallest principal (faster
      // clear → frees more budget sooner).
      live.sort((a, b) {
        final byApr = b.aprBps.compareTo(a.aprBps);
        return byApr != 0
            ? byApr
            : a.principalCents.compareTo(b.principalCents);
      });
      payInto(live.first, extraBudget);
    case DebtPayoffStrategy.snowball:
      // Smallest balance wins. Tiebreaker: highest APR.
      live.sort((a, b) {
        final byBalance = a.principalCents.compareTo(b.principalCents);
        return byBalance != 0 ? byBalance : b.aprBps.compareTo(a.aprBps);
      });
      payInto(live.first, extraBudget);
    case DebtPayoffStrategy.custom:
      // Honour each target's per-debt extra in declared order.
      // When the budget runs short, later debts get less or
      // nothing — the user explicitly opted into this layout.
      var remaining = extraBudget;
      for (final d in debts) {
        if (d.paidOff) continue;
        if (d.extraPaymentCents <= 0) continue;
        if (remaining <= 0) break;
        final pay = math.min(d.extraPaymentCents, remaining);
        payInto(d, pay);
        remaining -= pay;
      }
  }
}

/// Suggested minimum payment for a single debt — industry "interest
/// + 1% of principal" rule, floored at $25 to match real-world
/// statement minimums. Used by the UI to auto-fill
/// [DebtPayoffTarget.minPaymentCents] when the user adds a debt.
///
/// Pure function so the form can call it on every keystroke
/// without spinning up Riverpod.
int recommendedMinPayment({required int principalCents, required int aprBps}) {
  if (principalCents <= 0) return 0;
  final monthlyInterest = (principalCents * aprBps / 10000 / 12).round();
  final onePctPrincipal = (principalCents * 0.01).round();
  final raw = monthlyInterest + onePctPrincipal;
  const floorCents = 2500; // $25 — industry-standard statement floor
  return math.max(raw, math.min(principalCents, floorCents));
}
