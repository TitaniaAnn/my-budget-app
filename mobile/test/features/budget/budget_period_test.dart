import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/budget/models/budget.dart';

void main() {
  group('BudgetPeriod.currentRange', () {
    group('weekly', () {
      test('Wednesday → Monday..Sunday of that week', () {
        // 2026-04-29 is a Wednesday.
        final (from, to) = BudgetPeriod.weekly
            .currentRange(now: DateTime(2026, 4, 29));
        expect(from, DateTime(2026, 4, 27)); // Monday
        expect(to, DateTime(2026, 5, 3)); // Sunday
      });

      test('Sunday is treated as the END of the current week', () {
        // ISO weeks start on Monday; Sunday weekday=7 → subtract 6 days.
        final (from, to) = BudgetPeriod.weekly
            .currentRange(now: DateTime(2026, 5, 3));
        expect(from, DateTime(2026, 4, 27));
        expect(to, DateTime(2026, 5, 3));
      });

      test('Monday is the start of its own week', () {
        final (from, to) = BudgetPeriod.weekly
            .currentRange(now: DateTime(2026, 4, 27));
        expect(from, DateTime(2026, 4, 27));
        expect(to, DateTime(2026, 5, 3));
      });
    });

    group('biweekly', () {
      test('returns a 14-day window anchored to a Monday', () {
        final (from, to) = BudgetPeriod.biweekly
            .currentRange(now: DateTime(2026, 4, 29));
        expect(to.difference(from).inDays, 13);
        expect(from.weekday, DateTime.monday);
      });

      test('the previous biweekly block is consistent with the current one', () {
        // Two consecutive Wednesdays a week apart should land in the same
        // or adjacent blocks; either way the start dates are 0 or 14 apart.
        final (a, _) = BudgetPeriod.biweekly
            .currentRange(now: DateTime(2026, 4, 29));
        final (b, _) = BudgetPeriod.biweekly
            .currentRange(now: DateTime(2026, 5, 6));
        final delta = b.difference(a).inDays.abs();
        expect(delta, anyOf(0, 14));
      });
    });

    group('monthly', () {
      test('mid-month → 1st through last day of that month', () {
        final (from, to) = BudgetPeriod.monthly
            .currentRange(now: DateTime(2026, 4, 15));
        expect(from, DateTime(2026, 4, 1));
        expect(to, DateTime(2026, 4, 30));
      });

      test('handles February (28 days)', () {
        final (from, to) = BudgetPeriod.monthly
            .currentRange(now: DateTime(2026, 2, 10));
        expect(from, DateTime(2026, 2, 1));
        expect(to, DateTime(2026, 2, 28));
      });

      test('handles February in a leap year (29 days)', () {
        final (from, to) = BudgetPeriod.monthly
            .currentRange(now: DateTime(2024, 2, 10));
        expect(to, DateTime(2024, 2, 29));
      });

      test('handles December (year-end)', () {
        final (from, to) = BudgetPeriod.monthly
            .currentRange(now: DateTime(2026, 12, 15));
        expect(from, DateTime(2026, 12, 1));
        expect(to, DateTime(2026, 12, 31));
      });
    });

    group('semiannual', () {
      test('April → H1 (Jan 1 – Jun 30)', () {
        final (from, to) = BudgetPeriod.semiannual
            .currentRange(now: DateTime(2026, 4, 29));
        expect(from, DateTime(2026, 1, 1));
        expect(to, DateTime(2026, 6, 30));
      });

      test('June 30 is the last day of H1', () {
        final (_, to) = BudgetPeriod.semiannual
            .currentRange(now: DateTime(2026, 6, 30));
        expect(to, DateTime(2026, 6, 30));
      });

      test('July 1 → H2 (Jul 1 – Dec 31)', () {
        final (from, to) = BudgetPeriod.semiannual
            .currentRange(now: DateTime(2026, 7, 1));
        expect(from, DateTime(2026, 7, 1));
        expect(to, DateTime(2026, 12, 31));
      });
    });

    group('annual', () {
      test('returns Jan 1 .. Dec 31 of the current year', () {
        final (from, to) = BudgetPeriod.annual
            .currentRange(now: DateTime(2026, 4, 29));
        expect(from, DateTime(2026, 1, 1));
        expect(to, DateTime(2026, 12, 31));
      });
    });
  });
}
