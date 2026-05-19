// Unit tests for [aggregateMonthEndNetWorth]. Pure Dart — no
// Supabase, no widget tree. The aggregator is the math layer
// between reconstructHistoricalNetWorth's daily series and the
// rule's month-grained expectations.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/dashboard/services/month_end_aggregator.dart';

void main() {
  group('aggregateMonthEndNetWorth', () {
    test('empty input returns a single point at the current month', () {
      // Brand-new household: no transaction history, but we still
      // know today's balance from the accounts table. The single
      // point lets the dashboard render a value even without
      // history; trajectory rules stay silent until they get
      // enough months to compare.
      final result = aggregateMonthEndNetWorth(
        const [],
        now: DateTime(2026, 5, 19),
        currentBalanceCents: 150000,
      );
      expect(result, hasLength(1));
      expect(result.first.balanceCents, 150000);
      // monthEnd in the empty-input case is "today" — see the
      // aggregator's docstring rationale.
      expect(result.first.monthEnd, DateTime(2026, 5, 19));
    });

    test('emits one point per calendar month, carrying forward gaps', () {
      // Two transaction dates with a month of nothing between them.
      // Aggregator must emit a point for the gap month using the
      // most-recent prior balance (between transactions, balance
      // doesn't move).
      final daily = [
        (date: DateTime(2026, 1, 15), balanceCents: 100000),
        // No February activity.
        (date: DateTime(2026, 3, 10), balanceCents: 130000),
      ];
      final result = aggregateMonthEndNetWorth(
        daily,
        now: DateTime(2026, 5, 19),
        currentBalanceCents: 200000,
      );
      expect(result.map((p) => p.monthEnd.month).toList(), [1, 2, 3, 4, 5]);
      // Jan: only point so far is Jan 15 at 100000.
      expect(result[0].balanceCents, 100000);
      // Feb: no activity, carry forward.
      expect(result[1].balanceCents, 100000);
      // Mar: balance moved to 130000 on the 10th.
      expect(result[2].balanceCents, 130000);
      // Apr: no activity, carry.
      expect(result[3].balanceCents, 130000);
      // May (current month): use currentBalanceCents verbatim.
      expect(result[4].balanceCents, 200000);
    });

    test(
      'current month always uses currentBalanceCents and now as monthEnd',
      () {
        // The current month's "month end" is the future on any
        // mid-month call. The aggregator must use `now` instead so
        // the dashboard surface stays meaningful.
        final daily = [
          (date: DateTime(2026, 5, 1), balanceCents: 100000),
          (date: DateTime(2026, 5, 10), balanceCents: 110000),
        ];
        final result = aggregateMonthEndNetWorth(
          daily,
          now: DateTime(2026, 5, 19),
          currentBalanceCents: 175000,
        );
        // Single month in the range, but the value comes from the
        // override, not the latest daily point.
        expect(result, hasLength(1));
        expect(result.single.monthEnd, DateTime(2026, 5, 19));
        expect(result.single.balanceCents, 175000);
      },
    );

    test('uses latest in-month balance when picking the month-end value', () {
      // Multiple transactions in the same month — the aggregator
      // should reflect end-of-month, which is the latest in-month
      // point. (For non-current months only; current month uses
      // currentBalanceCents.)
      final daily = [
        (date: DateTime(2026, 1, 5), balanceCents: 100000),
        (date: DateTime(2026, 1, 20), balanceCents: 95000),
        (date: DateTime(2026, 1, 28), balanceCents: 110000),
      ];
      final result = aggregateMonthEndNetWorth(
        daily,
        now: DateTime(2026, 3, 1),
        currentBalanceCents: 110000,
      );
      // Jan: latest in-month value (110000).
      expect(result.first.balanceCents, 110000);
    });
  });
}
