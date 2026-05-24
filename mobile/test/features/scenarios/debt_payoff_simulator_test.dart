// Unit tests for the multi-debt amortisation simulator.
//
// Coverage targets:
//   * Strategy correctness — avalanche routes extras to highest APR;
//     snowball routes to smallest balance; custom honours declared
//     per-debt extras in order.
//   * Boundary conditions — empty debts list, all-zero principals,
//     insufficient budget, last-payment clipping, all-paid early
//     exit, runaway-guard cap.
//   * Bookkeeping — totals match per-month sums; startingPrincipals
//     snapshot is faithful; payoffDates land on the right month.
//   * Helper — recommendedMinPayment hits floor, scales, never
//     exceeds principal.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/scenarios/models/scenario.dart';
import 'package:mybudget/features/scenarios/services/debt_payoff_simulator.dart';

DebtPayoffTarget _t(
  String accountId, {
  required int minPaymentCents,
  required int aprBps,
  int? extraPaymentCents,
}) => DebtPayoffTarget(
  accountId: accountId,
  minPaymentCents: minPaymentCents,
  aprBps: aprBps,
  extraPaymentCents: extraPaymentCents,
);

void main() {
  final start = DateTime(2026, 1, 15);

  group('simulateMultiDebtPayoff — degenerate inputs', () {
    test('empty targets list returns allPaidOff=true, no months', () {
      final r = simulateMultiDebtPayoff(
        targets: const [],
        startingPrincipals: const {},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 50000,
        startDate: start,
      );
      expect(r.allPaidOff, isTrue);
      expect(r.months, isEmpty);
      expect(r.totalInterestCents, 0);
      expect(r.totalPaidCents, 0);
      expect(r.payoffDates, isEmpty);
      expect(r.startingPrincipals, isEmpty);
      expect(r.debtFreeDate, isNull);
    });

    test('targets with zero starting principal are silently dropped', () {
      final r = simulateMultiDebtPayoff(
        targets: [_t('a', minPaymentCents: 10000, aprBps: 1500)],
        startingPrincipals: const {'a': 0},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 50000,
        startDate: start,
      );
      // Same observable shape as empty input — nothing to simulate.
      expect(r.allPaidOff, isTrue);
      expect(r.months, isEmpty);
      expect(r.startingPrincipals, isEmpty);
    });

    test('insufficient budget (mins exceed budget) bails immediately', () {
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('a', minPaymentCents: 30000, aprBps: 1500),
          _t('b', minPaymentCents: 30000, aprBps: 2000),
        ],
        startingPrincipals: const {'a': 500000, 'b': 300000},
        strategy: DebtPayoffStrategy.avalanche,
        // Sum of mins is $600 but we offer $400 — can't even cover
        // minimums, so balances would grow. The simulator must bail
        // rather than emit climbing-debt months.
        monthlyBudgetCents: 40000,
        startDate: start,
      );
      expect(r.allPaidOff, isFalse);
      expect(r.months, isEmpty);
      expect(r.totalInterestCents, 0);
      expect(r.totalPaidCents, 0);
      expect(r.payoffDates, {'a': null, 'b': null});
      expect(r.startingPrincipals, {'a': 500000, 'b': 300000});
    });
  });

  group('simulateMultiDebtPayoff — single-debt equivalence', () {
    test('one debt, 0% APR, exact payoff in 5 months', () {
      // $1000 balance, $200/month, 0% APR — same as the single-debt
      // simulator's first test, but routed through the multi-debt
      // path with one target.
      final r = simulateMultiDebtPayoff(
        targets: [_t('a', minPaymentCents: 20000, aprBps: 0)],
        startingPrincipals: const {'a': 100000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 20000,
        startDate: start,
      );
      expect(r.allPaidOff, isTrue);
      expect(r.months.length, 5);
      expect(r.totalInterestCents, 0);
      expect(r.totalPaidCents, 100000);
      expect(r.months.last.balances['a'], 0);
      expect(r.payoffDates['a'], DateTime(2026, 5, 31));
      expect(r.debtFreeDate, DateTime(2026, 5, 31));
      expect(r.startingPrincipals, {'a': 100000});
    });

    test('last-month payment clips so we never overpay past zero', () {
      // $250 balance, $100 min + $0 extra (budget = min) → 3 months,
      // last payment $50.
      final r = simulateMultiDebtPayoff(
        targets: [_t('a', minPaymentCents: 10000, aprBps: 0)],
        startingPrincipals: const {'a': 25000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10000,
        startDate: start,
      );
      expect(r.months.length, 3);
      expect(r.months[0].payments['a'], 10000);
      expect(r.months[1].payments['a'], 10000);
      expect(
        r.months[2].payments['a'],
        5000,
        reason: 'final payment clipped to remaining balance',
      );
      expect(r.totalPaidCents, 25000);
    });
  });

  group('simulateMultiDebtPayoff — avalanche', () {
    test('extras flow to the highest-APR debt first', () {
      // Two debts: A is bigger but cheap (5%), B is smaller but
      // expensive (24%). Budget = $50 mins + $400 extra. Avalanche
      // should push the entire extra to B every month until B
      // clears, then redirect to A.
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 2500, aprBps: 500),
          _t('B', minPaymentCents: 2500, aprBps: 2400),
        ],
        startingPrincipals: const {'A': 500000, 'B': 100000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 45000,
        startDate: start,
      );
      // First month: A gets its $25 min only. B gets $25 min +
      // ~$400 extra.
      expect(r.months.first.payments['A'], 2500);
      expect(
        r.months.first.payments['B']!,
        greaterThan(40000),
        reason: 'avalanche routes all extra to the highest APR',
      );
      expect(r.allPaidOff, isTrue);
      // B should clear well before A.
      expect(
        r.payoffDates['B']!.isBefore(r.payoffDates['A']!),
        isTrue,
        reason: 'targeted debt finishes first',
      );
    });
  });

  group('simulateMultiDebtPayoff — snowball', () {
    test('extras flow to the smallest-balance debt first', () {
      // Same two debts but flipped intent: A is small + cheap, B is
      // huge + expensive. Snowball ignores APR and pushes extra to A
      // because it has the smallest balance.
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 2500, aprBps: 500),
          _t('B', minPaymentCents: 2500, aprBps: 2400),
        ],
        startingPrincipals: const {'A': 50000, 'B': 500000},
        strategy: DebtPayoffStrategy.snowball,
        monthlyBudgetCents: 45000,
        startDate: start,
      );
      expect(
        r.months.first.payments['A']!,
        greaterThan(40000),
        reason: 'snowball routes extra to smallest balance',
      );
      expect(r.months.first.payments['B'], 2500);
      expect(r.allPaidOff, isTrue);
      expect(r.payoffDates['A']!.isBefore(r.payoffDates['B']!), isTrue);
    });
  });

  group('simulateMultiDebtPayoff — custom', () {
    test('per-debt extras honoured in declared order', () {
      // Three debts each with $25 min. Custom extras: A=$100, B=$50,
      // C=$0. Budget = $75 mins + $150 extras = $225. Confirm month
      // 1 payments match the declared extras exactly.
      final r = simulateMultiDebtPayoff(
        targets: [
          _t(
            'A',
            minPaymentCents: 2500,
            aprBps: 1000,
            extraPaymentCents: 10000,
          ),
          _t('B', minPaymentCents: 2500, aprBps: 1500, extraPaymentCents: 5000),
          _t('C', minPaymentCents: 2500, aprBps: 2000),
        ],
        startingPrincipals: const {'A': 500000, 'B': 500000, 'C': 500000},
        strategy: DebtPayoffStrategy.custom,
        monthlyBudgetCents: 22500,
        startDate: start,
        maxMonths: 6, // we only inspect the first month
      );
      final m0 = r.months.first;
      expect(m0.payments['A'], 12500); // 2500 min + 10000 extra
      expect(m0.payments['B'], 7500); // 2500 min + 5000 extra
      expect(m0.payments['C'], 2500); // min only
    });

    test('custom with extras exceeding budget gives later debts nothing', () {
      // Budget is just $75 ≥ mins, plus only $30 of headroom. A's
      // extra is $50 — A consumes the entire $30 (clipped), B's
      // $50 extra gets nothing.
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 2500, aprBps: 1000, extraPaymentCents: 5000),
          _t('B', minPaymentCents: 2500, aprBps: 1500, extraPaymentCents: 5000),
        ],
        startingPrincipals: const {'A': 500000, 'B': 500000},
        strategy: DebtPayoffStrategy.custom,
        monthlyBudgetCents: 8000, // 5000 mins + 3000 extra headroom
        startDate: start,
        maxMonths: 6,
      );
      final m0 = r.months.first;
      expect(m0.payments['A'], 5500); // 2500 min + 3000 clipped extra
      expect(m0.payments['B'], 2500); // min only — budget exhausted
    });
  });

  group('simulateMultiDebtPayoff — bookkeeping invariants', () {
    test('totalInterest and totalPaid equal the sum of per-month rows', () {
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 5000, aprBps: 1800),
          _t('B', minPaymentCents: 3000, aprBps: 1200),
        ],
        startingPrincipals: const {'A': 200000, 'B': 150000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 20000,
        startDate: start,
      );
      var summedInterest = 0;
      var summedPayments = 0;
      for (final m in r.months) {
        for (final v in m.interest.values) {
          summedInterest += v;
        }
        for (final v in m.payments.values) {
          summedPayments += v;
        }
      }
      expect(r.totalInterestCents, summedInterest);
      expect(r.totalPaidCents, summedPayments);
      // Sanity: total paid = original principal + interest.
      expect(r.totalPaidCents, 200000 + 150000 + r.totalInterestCents);
    });

    test('startingPrincipals snapshot is exactly the input balances', () {
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 5000, aprBps: 1800),
          _t('B', minPaymentCents: 3000, aprBps: 1200),
        ],
        startingPrincipals: const {'A': 200000, 'B': 150000},
        strategy: DebtPayoffStrategy.snowball,
        monthlyBudgetCents: 20000,
        startDate: start,
      );
      expect(r.startingPrincipals, {'A': 200000, 'B': 150000});
    });

    test('debtFreeDate is the latest payoffDate across all debts', () {
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 5000, aprBps: 0),
          _t('B', minPaymentCents: 3000, aprBps: 0),
        ],
        // A pays off in 2 months (5000+5000=10000); B in 3 months
        // under snowball routing (extras flow to A first since
        // smaller? A and B same starting? Use different sizes).
        startingPrincipals: const {'A': 10000, 'B': 30000},
        strategy: DebtPayoffStrategy.custom, // no extras → pure mins
        monthlyBudgetCents: 8000,
        startDate: start,
      );
      expect(r.allPaidOff, isTrue);
      // B has the later payoff (30000 / 3000 = 10 months vs A's
      // 2 months).
      expect(r.debtFreeDate, r.payoffDates['B']);
    });

    test('all-paid early exit returns before maxMonths', () {
      // Generous budget on small debts → loop exits in ~3 months,
      // not 600.
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 5000, aprBps: 0),
          _t('B', minPaymentCents: 5000, aprBps: 0),
        ],
        startingPrincipals: const {'A': 5000, 'B': 5000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10000,
        startDate: start,
        maxMonths: 600,
      );
      expect(r.allPaidOff, isTrue);
      expect(
        r.months.length,
        lessThan(5),
        reason: 'early exit fires the month every debt clears',
      );
    });

    test('runaway-guard cap returns allPaidOff=false with months filled', () {
      // Budget exactly covers minimums but mins barely beat interest
      // on a high-APR balance → never finishes within the cap.
      final r = simulateMultiDebtPayoff(
        targets: [_t('A', minPaymentCents: 10100, aprBps: 1200)],
        startingPrincipals: const {'A': 1000000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10100,
        startDate: start,
        maxMonths: 12,
      );
      expect(r.allPaidOff, isFalse);
      expect(r.months.length, 12);
      expect(
        r.months.last.balances['A']!,
        greaterThan(900000),
        reason: 'barely-amortising payment leaves most balance after a year',
      );
    });
  });

  group('simulateMultiDebtPayoff — one-off payments', () {
    test('untargeted lump-sum joins that month\'s extra budget', () {
      // Two debts, avalanche, $50 extra/month base budget. A $200
      // untargeted lump-sum in month 2 should land on the highest-
      // APR debt (B) on top of the normal extra. Compare to a
      // baseline run with no lump-sum.
      final base = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 2500, aprBps: 500),
          _t('B', minPaymentCents: 2500, aprBps: 2400),
        ],
        startingPrincipals: const {'A': 200000, 'B': 200000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10000, // $50 mins + $50 extra
        startDate: start,
        maxMonths: 6,
      );
      final withLump = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 2500, aprBps: 500),
          _t('B', minPaymentCents: 2500, aprBps: 2400),
        ],
        startingPrincipals: const {'A': 200000, 'B': 200000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10000,
        startDate: start,
        oneOffPayments: [
          OneOffPaymentInput(
            // Month 2 of the simulation = February 2026.
            date: DateTime(2026, 2, 15),
            amountCents: 20000,
          ),
        ],
        maxMonths: 6,
      );
      // Month 2 (index 1) of withLump should pay ~$200 more on B
      // than the baseline did.
      expect(
        withLump.months[1].payments['B']! - base.months[1].payments['B']!,
        20000,
      );
      expect(withLump.months[1].payments['A'], base.months[1].payments['A']);
    });

    test('targeted lump-sum pre-pays its debt regardless of strategy', () {
      // Avalanche would route extra to B (24% APR). A targeted
      // lump-sum on A should land on A anyway — strategy bypassed
      // for that payment.
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 2500, aprBps: 500),
          _t('B', minPaymentCents: 2500, aprBps: 2400),
        ],
        startingPrincipals: const {'A': 200000, 'B': 200000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10000,
        startDate: start,
        oneOffPayments: [
          OneOffPaymentInput(
            date: DateTime(2026, 2, 15),
            amountCents: 20000,
            accountId: 'A',
          ),
        ],
        maxMonths: 6,
      );
      // Month 2 payment on A = $25 min + $200 targeted = $225.
      expect(r.months[1].payments['A'], 22500);
      // Strategy still routes the $50 leftover extra to B.
      expect(r.months[1].payments['B'], 7500);
    });

    test('targeted lump-sum clips against remaining principal', () {
      // A $5000 lump-sum on a $200 debt overpays by far. The
      // simulator must clip the payment to the principal and not
      // drive the balance negative.
      final r = simulateMultiDebtPayoff(
        targets: [
          _t('A', minPaymentCents: 2500, aprBps: 0),
          _t('B', minPaymentCents: 2500, aprBps: 2400),
        ],
        startingPrincipals: const {'A': 20000, 'B': 200000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10000,
        startDate: start,
        oneOffPayments: [
          OneOffPaymentInput(
            date: DateTime(2026, 2, 15),
            amountCents: 500000,
            accountId: 'A',
          ),
        ],
        maxMonths: 6,
      );
      // After month 1 min, A is at $175. The lump-sum pays the
      // remaining $175 and stops — no negative balance, no
      // overflow to B.
      expect(r.months[1].balances['A'], 0);
      expect(r.payoffDates['A'], DateTime(2026, 2, 28));
    });

    test('targeted lump-sum on already-paid debt is a graceful no-op', () {
      // A clears in 4 months on its own; the lump-sum is scheduled
      // for month 10. The simulator must not crash, not reflow the
      // amount into the budget, and not mutate anything.
      final r = simulateMultiDebtPayoff(
        targets: [_t('A', minPaymentCents: 10000, aprBps: 0)],
        startingPrincipals: const {'A': 40000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10000,
        startDate: start,
        oneOffPayments: [
          OneOffPaymentInput(
            date: DateTime(2026, 10, 15),
            amountCents: 50000,
            accountId: 'A',
          ),
        ],
        maxMonths: 12,
      );
      // A clears in 4 months under its own steam; sim early-exits
      // before October.
      expect(r.allPaidOff, isTrue);
      expect(r.months.length, 4);
      expect(r.totalPaidCents, 40000);
    });

    test('zero or negative amount is ignored', () {
      // Defensive — a stale form state could submit a zero. Sim
      // should produce the same result as no lump-sum at all.
      final base = simulateMultiDebtPayoff(
        targets: [_t('A', minPaymentCents: 10000, aprBps: 0)],
        startingPrincipals: const {'A': 50000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10000,
        startDate: start,
      );
      final withZero = simulateMultiDebtPayoff(
        targets: [_t('A', minPaymentCents: 10000, aprBps: 0)],
        startingPrincipals: const {'A': 50000},
        strategy: DebtPayoffStrategy.avalanche,
        monthlyBudgetCents: 10000,
        startDate: start,
        oneOffPayments: [
          OneOffPaymentInput(date: DateTime(2026, 3, 1), amountCents: 0),
        ],
      );
      expect(withZero.totalPaidCents, base.totalPaidCents);
      expect(withZero.months.length, base.months.length);
    });
  });

  group('recommendedMinPayment', () {
    test('zero principal returns 0', () {
      expect(recommendedMinPayment(principalCents: 0, aprBps: 2000), 0);
    });

    test('floors at \$25 for tiny balances', () {
      // $100 @ 20% APR → monthly interest ≈ $1.67, 1% principal = $1
      // → raw ≈ $2.67. Floor kicks in to $25.
      expect(recommendedMinPayment(principalCents: 10000, aprBps: 2000), 2500);
    });

    test('floor never exceeds the remaining principal — a debt under \$25 '
        'tops out at the principal itself', () {
      // $10 balance: even the $25 floor would overpay. Floor is
      // clipped to principal so we recommend $10, not $25.
      expect(recommendedMinPayment(principalCents: 1000, aprBps: 2000), 1000);
    });

    test('industry formula at \$10k @ 18% APR', () {
      // monthly interest = 10000_00 * 0.18 / 12 = 15000c
      // 1% of principal = 10000c
      // raw = 25000c, well above the $25 floor.
      expect(
        recommendedMinPayment(principalCents: 1000000, aprBps: 1800),
        25000,
      );
    });
  });
}
