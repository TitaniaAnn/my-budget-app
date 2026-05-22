// Unit tests for the pure payoff-plan simulator.
//
// Two functions under test:
//   * simulatePayoff — forward walk, applying interest then payment
//     each month until balance hits zero (or maxMonths exhausted);
//   * requiredMonthlyPayment — inverse, "given a target horizon
//     what payment pays this off?".
//
// Spot-check arithmetic against the standard amortisation formula:
//   * 0% APR degenerates to balance / months (or the ceiling
//     thereof);
//   * 12% APR gives 1% monthly compound, easy to hand-check on a
//     2-month payoff;
//   * insufficient-payment short-circuits rather than looping to
//     the cap (matters because the UI calls this on every keystroke).

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/scenarios/services/payoff_simulator.dart';

void main() {
  final start = DateTime(2026, 1, 15);

  group('simulatePayoff', () {
    test('0% APR pays off in balance/payment months, no interest', () {
      // $1000 balance, $200/month, 0% APR → exactly 5 months.
      final sim = simulatePayoff(
        startingBalanceCents: 100000,
        monthlyPaymentCents: 20000,
        aprBps: 0,
        startDate: start,
      );
      expect(sim.paidOff, isTrue);
      expect(sim.monthCount, 5);
      expect(sim.totalInterestCents, 0);
      expect(sim.totalPaidCents, 100000);
      expect(sim.months.last.balanceCents, 0);
    });

    test('last-month payment is clipped so we never overpay past zero', () {
      // $250 balance, $100/month, 0% APR → 3 months, last
      // payment is $50 (not $100). Total paid == starting
      // balance.
      final sim = simulatePayoff(
        startingBalanceCents: 25000,
        monthlyPaymentCents: 10000,
        aprBps: 0,
        startDate: start,
      );
      expect(sim.monthCount, 3);
      expect(sim.months[0].paymentCents, 10000);
      expect(sim.months[1].paymentCents, 10000);
      expect(
        sim.months[2].paymentCents,
        5000,
        reason: 'final payment clipped to remaining balance',
      );
      expect(sim.totalPaidCents, 25000);
    });

    test(
      'starting balance of zero returns an empty schedule, paidOff=true',
      () {
        final sim = simulatePayoff(
          startingBalanceCents: 0,
          monthlyPaymentCents: 10000,
          aprBps: 0,
          startDate: start,
        );
        expect(sim.months, isEmpty);
        expect(sim.paidOff, isTrue);
        expect(sim.payoffDate, isNull);
      },
    );

    test('compound interest at 12% APR (1% monthly) accrues correctly '
        'on month 1', () {
      // $10,000 balance @ 12% APR. Month 1 interest =
      // 10000 * 0.01 = $100 (10000 cents). Pay $500 → balance
      // before pmt = $10100, after = $9600 (960000 cents).
      final sim = simulatePayoff(
        startingBalanceCents: 1000000,
        monthlyPaymentCents: 50000,
        aprBps: 1200,
        startDate: start,
      );
      expect(sim.months.first.interestCents, 10000);
      expect(sim.months.first.balanceCents, 960000);
      expect(sim.paidOff, isTrue);
    });

    test('insufficient payment short-circuits with paidOff=false rather '
        'than running to maxMonths', () {
      // $5000 @ 24% APR (2% monthly) → month 1 interest = $100.
      // A $50/month payment can't cover interest; the loop must
      // detect and abort.
      final sim = simulatePayoff(
        startingBalanceCents: 500000,
        monthlyPaymentCents: 5000,
        aprBps: 2400,
        startDate: start,
      );
      expect(sim.paidOff, isFalse);
      expect(
        sim.months,
        isEmpty,
        reason:
            'the abort fires before any month is emitted — '
            "we don't want to display growing-balance rows in the UI",
      );
    });

    test('maxMonths caps the loop on borderline-but-positive amortisation', () {
      // A payment that DOES cover interest but only barely — the
      // simulator should run for at most maxMonths and report
      // paidOff=false if the cap hits first. Use a tight cap so
      // the test is fast: $10k @ 12% APR, $101/month → ~$1
      // beyond interest, payoff in ~13900 months in reality;
      // maxMonths=24 caps it.
      final sim = simulatePayoff(
        startingBalanceCents: 1000000,
        monthlyPaymentCents: 10100,
        aprBps: 1200,
        startDate: start,
        maxMonths: 24,
      );
      expect(sim.paidOff, isFalse);
      expect(sim.monthCount, 24);
      // Balance should still be significant — definitely not 0.
      expect(sim.months.last.balanceCents, greaterThan(900000));
    });

    test('monthEnd advances by one calendar month per step', () {
      // January start → Jan-31, Feb-28, Mar-31, Apr-30, May-31.
      final sim = simulatePayoff(
        startingBalanceCents: 100000,
        monthlyPaymentCents: 20000,
        aprBps: 0,
        startDate: DateTime(2026, 1, 15),
      );
      expect(sim.months.map((m) => m.monthEnd), [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
        DateTime(2026, 5, 31),
      ]);
    });

    test('totalInterest equals sum of per-month interest figures', () {
      // Light correctness check: invariant that simply re-derives
      // totalInterest from the per-row data. Catches a regression
      // where the accumulator drifts from the row values.
      final sim = simulatePayoff(
        startingBalanceCents: 500000,
        monthlyPaymentCents: 50000,
        aprBps: 1800,
        startDate: start,
      );
      final summedRows = sim.months.fold<int>(
        0,
        (acc, m) => acc + m.interestCents,
      );
      expect(sim.totalInterestCents, summedRows);
      expect(sim.totalPaidCents, summedRows + 500000);
    });
  });

  group('requiredMonthlyPayment', () {
    test('0% APR → ceiling division', () {
      // $1000 paid off in 3 months at 0% → ceil(100000/3) = 33334.
      expect(
        requiredMonthlyPayment(
          startingBalanceCents: 100000,
          aprBps: 0,
          months: 3,
        ),
        33334,
      );
    });

    test(
      'simulating the recommended payment finishes in ≤ the target months',
      () {
        // Closed loop: compute P, feed it back to simulatePayoff,
        // confirm the schedule hits zero by the requested month.
        // Use a non-trivial rate to exercise the amortisation
        // formula.
        final p = requiredMonthlyPayment(
          startingBalanceCents: 1000000,
          aprBps: 1500,
          months: 24,
        )!;
        final sim = simulatePayoff(
          startingBalanceCents: 1000000,
          monthlyPaymentCents: p,
          aprBps: 1500,
          startDate: start,
        );
        expect(sim.paidOff, isTrue);
        expect(
          sim.monthCount,
          lessThanOrEqualTo(24),
          reason:
              'the .ceil() in requiredMonthlyPayment should ensure '
              'we never need a 25th month for a 24-month plan',
        );
      },
    );

    test('zero or negative inputs return null', () {
      expect(
        requiredMonthlyPayment(
          startingBalanceCents: 0,
          aprBps: 1500,
          months: 24,
        ),
        isNull,
      );
      expect(
        requiredMonthlyPayment(
          startingBalanceCents: 100000,
          aprBps: 1500,
          months: 0,
        ),
        isNull,
      );
      expect(
        requiredMonthlyPayment(
          startingBalanceCents: -100,
          aprBps: 1500,
          months: 24,
        ),
        isNull,
      );
    });

    test('for a high APR the required payment is materially higher than '
        'plain balance/months', () {
      // Sanity: 24% APR (2% monthly) on $10k over 24 months should
      // be noticeably above $10000/24 = $416/month.
      final plain = 1000000 ~/ 24;
      final actual = requiredMonthlyPayment(
        startingBalanceCents: 1000000,
        aprBps: 2400,
        months: 24,
      )!;
      expect(
        actual,
        greaterThan(plain + 5000),
        reason:
            'at 24% APR the interest premium over 24 months is '
            'tens of dollars per month; if the result is within '
            '\$50 of the plain divide, the formula is broken',
      );
    });
  });
}
