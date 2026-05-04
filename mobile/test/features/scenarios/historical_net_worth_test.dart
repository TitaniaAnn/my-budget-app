// Regression tests for reconstructHistoricalNetWorth.
//
// Pins the end-of-day balance contract:
//   B_today = currentNetWorth
//   B_d     = B_{prev} - D_{prev}     (prev is the next-newer emitted date)
//
// These tests previously caught an off-by-one where the function subtracted
// `D_d` instead of `D_{prev}`, leaving every historical point off by one
// day's worth of transactions.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/scenarios/repositories/scenarios_repository.dart';

void main() {
  group('reconstructHistoricalNetWorth', () {
    final today = DateTime(2026, 5, 3);
    DateTime d(int daysAgo) => today.subtract(Duration(days: daysAgo));

    test('today-only anchor when there are no historical deltas', () {
      final points = reconstructHistoricalNetWorth(
        currentNetWorth: 100000,
        deltasByDate: const {},
        today: today,
      );
      expect(points, hasLength(1));
      expect(points.single.date, today);
      expect(points.single.balanceCents, 100000);
    });

    test('end-of-yesterday = currentNetWorth - todayDelta', () {
      final points = reconstructHistoricalNetWorth(
        currentNetWorth: 100000,
        deltasByDate: {
          today: -5000, // spent $50 today
          d(1): -10000, // spent $100 yesterday
        },
        today: today,
      );
      // Oldest first.
      expect(points.map((p) => p.date).toList(), [d(1), today]);
      // End-of-today = 100000.
      expect(points.last.balanceCents, 100000);
      // End-of-yesterday = 100000 - (-5000) = 105000  (undo today's delta,
      // NOT yesterday's — that was the off-by-one bug).
      expect(points.first.balanceCents, 105000);
    });

    test('chains correctly across three transaction days', () {
      // today: spent $50, yesterday: spent $100, day-before: spent $30.
      final points = reconstructHistoricalNetWorth(
        currentNetWorth: 100000,
        deltasByDate: {today: -5000, d(1): -10000, d(2): -3000},
        today: today,
      );
      // Expected end-of-day balances:
      //   today      = 100000
      //   yesterday  = 100000 - (-5000)   = 105000
      //   day-before = 105000 - (-10000)  = 115000
      expect(points.map((p) => p.balanceCents).toList(), [
        115000,
        105000,
        100000,
      ]);
    });

    test('skips days with no transactions correctly', () {
      // Gap between yesterday and 5d-ago: no transactions in between,
      // so end-of-yesterday equals end-of-5d-ago + delta(yesterday).
      // Wait — let's trace: today $50 spent, yesterday $100 spent, 5d-ago
      // $200 deposit. Output dates: [5d-ago, yesterday, today].
      //   today      = 100000
      //   yesterday  = 100000 - (-5000)   = 105000   (undo today)
      //   5d-ago     = 105000 - (-10000)  = 115000   (undo yesterday;
      //                                               days 2-4 have zero
      //                                               delta so nothing else
      //                                               to subtract)
      final points = reconstructHistoricalNetWorth(
        currentNetWorth: 100000,
        deltasByDate: {today: -5000, d(1): -10000, d(5): 20000},
        today: today,
      );
      expect(points.map((p) => p.date).toList(), [d(5), d(1), today]);
      expect(points.map((p) => p.balanceCents).toList(), [
        115000,
        105000,
        100000,
      ]);
    });

    test('today as the only delta-bearing day', () {
      // currentNetWorth already includes today's $50 spend; end-of-yesterday
      // should be $50 higher.
      final points = reconstructHistoricalNetWorth(
        currentNetWorth: 100000,
        deltasByDate: {today: -5000, d(3): 0}, // d(3) explicitly zero
        today: today,
      );
      expect(points.map((p) => p.date).toList(), [d(3), today]);
      // End-of-3d-ago undoes today's $50 spend AND a zero delta on yesterday/
      // day-before-yesterday → 105000.
      expect(points.first.balanceCents, 105000);
      expect(points.last.balanceCents, 100000);
    });

    test('drops misdated future entries', () {
      final points = reconstructHistoricalNetWorth(
        currentNetWorth: 100000,
        deltasByDate: {
          today.add(const Duration(days: 7)): -99999, // bogus future row
          today: -5000,
          d(1): -10000,
        },
        today: today,
      );
      // Future row is ignored; result identical to the two-day test above.
      expect(points.map((p) => p.date).toList(), [d(1), today]);
      expect(points.map((p) => p.balanceCents).toList(), [105000, 100000]);
    });

    test('positive deltas (income) reduce the historical balance', () {
      // currentNetWorth includes a $200 deposit today; end-of-yesterday
      // should be $200 lower.
      final points = reconstructHistoricalNetWorth(
        currentNetWorth: 100000,
        deltasByDate: {today: 20000, d(1): 5000, d(2): 3000},
        today: today,
      );
      // End-of-today = 100000.
      // End-of-yesterday   = 100000 - 20000 = 80000   (undo today)
      // End-of-day-before  = 80000  - 5000  = 75000   (undo yesterday)
      expect(points.map((p) => p.balanceCents).toList(), [
        75000,
        80000,
        100000,
      ]);
    });
  });
}
