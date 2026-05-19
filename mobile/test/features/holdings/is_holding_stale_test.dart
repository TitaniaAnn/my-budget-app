// Pure-function tests for isHoldingStale — the rule behind the
// "Stale · Xd" / "Never priced" chip on each HoldingCard.
//
// These pin two contracts the chip's correctness depends on:
//   1. A null timestamp (the row was created without a price hint,
//      e.g. a backfilled position) ALWAYS flags as stale. The chip
//      renders "Never priced" in that branch, so the boolean has to
//      agree.
//   2. The threshold is strictly "older than" — sitting exactly on
//      the boundary (the day the threshold ticks over) still reads
//      as fresh, so a daily-update cadence wouldn't see the chip
//      flickering on/off across the midnight boundary.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/holdings/widgets/holding_card.dart';

void main() {
  group('isHoldingStale', () {
    // Fixed reference so the math is deterministic — the production
    // function defaults to DateTime.now(), but every test below
    // pins `now` explicitly.
    final now = DateTime.utc(2026, 6, 1, 12);

    test('null timestamp is always stale (never-priced positions)', () {
      // Backfilled rows enter the table without a price; the chip
      // must surface so the user knows the figure they typed has
      // no recorded date.
      expect(isHoldingStale(null, now: now), isTrue);
      expect(
        isHoldingStale(null, staleAfterDays: 365, now: now),
        isTrue,
        reason:
            'the never-priced shortcut must short-circuit even when '
            'the threshold is set very high — null means "no data", '
            'and no threshold makes a missing date acceptable.',
      );
    });

    test('priced today is fresh', () {
      expect(isHoldingStale(now, now: now), isFalse);
    });

    test('priced exactly at the threshold boundary is fresh', () {
      // 30 days ago to the second. inDays floors, so the diff is
      // exactly 30 days — and the production rule is "strictly
      // greater than", so this side of the boundary stays fresh.
      final at = now.subtract(const Duration(days: 30));
      expect(
        isHoldingStale(at, now: now),
        isFalse,
        reason:
            'the boundary is exclusive — "older than 30 days" must '
            'mean ≥ 31 days, otherwise a daily-update cadence sees '
            'the chip blink off and on at the threshold.',
      );
    });

    test('one day past the threshold is stale', () {
      final at = now.subtract(const Duration(days: 31));
      expect(isHoldingStale(at, now: now), isTrue);
    });

    test('custom threshold respected', () {
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      expect(isHoldingStale(twoDaysAgo, staleAfterDays: 7, now: now), isFalse);
      expect(isHoldingStale(twoDaysAgo, staleAfterDays: 1, now: now), isTrue);
    });
  });
}
