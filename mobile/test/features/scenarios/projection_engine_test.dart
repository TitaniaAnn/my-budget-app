// Pure-function tests for the scenario projection engine.
//
// Two functions sit behind the scenarioDetailProvider: the RRULE
// expander (which date(s) does this event hit?) and the forward
// walk (apply each delta day-by-day, sample weekly for the chart).
// Both are private to the implementation but exposed via
// @visibleForTesting so the math can be pinned without the
// Riverpod plumbing or a real Supabase fixture.
//
// Contracts pinned here:
//   * non-recurring events return their single date, dropped when
//     past the window end (no past-event back-projection);
//   * each FREQ generates the right cadence + preserves day-of-
//     month / month-of-year as appropriate;
//   * COUNT bounds the recurrence; UNTIL clamps against the
//     window end (whichever lands first);
//   * malformed RRULE (unknown FREQ) doesn't crash — silently
//     yields only the start date;
//   * buildProjection accumulates running balance correctly, with
//     past-dated events effectively dropped (the iteration range
//     starts at `from`);
//   * weekly sampling lands on day 0, 7, 14, ... + always
//     includes the final day.
//
// Tests are pure Dart — no Supabase, no widget tree.
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/scenarios/models/scenario_event.dart';
import 'package:mybudget/features/scenarios/providers/scenarios_provider.dart';

ScenarioEvent _event({
  required EventType type,
  required DateTime date,
  required int amount,
  bool isRecurring = false,
  String? rrule,
  String id = 'e',
  String label = 'Test event',
}) {
  return ScenarioEvent(
    id: id,
    scenarioId: 's',
    eventType: type,
    label: label,
    eventDate: date,
    amount: amount,
    isRecurring: isRecurring,
    recurrenceRule: rrule,
    sortOrder: 0,
  );
}

void main() {
  group('expandRecurrenceDates', () {
    final windowEnd = DateTime(2026, 12, 31);

    test('non-recurring event returns its single date', () {
      final e = _event(
        type: EventType.expense,
        date: DateTime(2026, 6, 15),
        amount: 5000,
      );
      expect(expandRecurrenceDates(e, windowEnd), [DateTime(2026, 6, 15)]);
    });

    test('non-recurring event past the window returns empty', () {
      // A car-purchase event scheduled for 2030 in a window that
      // ends 2026 must not get applied — otherwise the projection
      // shows a phantom transaction that the user can't see on the
      // chart.
      final e = _event(
        type: EventType.purchase,
        date: DateTime(2030, 1, 1),
        amount: 5000000,
      );
      expect(expandRecurrenceDates(e, windowEnd), isEmpty);
    });

    test('recurring with no rrule string falls back to single-date '
        'behaviour', () {
      // isRecurring=true + recurrenceRule=null is a data
      // inconsistency the UI should prevent, but the engine must
      // not crash on it. Treat it as non-recurring.
      final e = _event(
        type: EventType.income,
        date: DateTime(2026, 3, 1),
        amount: 1000,
        isRecurring: true,
      );
      expect(expandRecurrenceDates(e, windowEnd), [DateTime(2026, 3, 1)]);
    });

    test('DAILY freq yields one date per day from start through windowEnd', () {
      final e = _event(
        type: EventType.expense,
        date: DateTime(2026, 6, 1),
        amount: 1000,
        isRecurring: true,
        rrule: 'FREQ=DAILY;COUNT=4',
      );
      expect(expandRecurrenceDates(e, windowEnd), [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 2),
        DateTime(2026, 6, 3),
        DateTime(2026, 6, 4),
      ]);
    });

    test('WEEKLY freq yields one date every 7 days', () {
      final e = _event(
        type: EventType.income,
        date: DateTime(2026, 6, 1),
        amount: 200000,
        isRecurring: true,
        rrule: 'FREQ=WEEKLY;COUNT=3',
      );
      expect(expandRecurrenceDates(e, windowEnd), [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 8),
        DateTime(2026, 6, 15),
      ]);
    });

    test('MONTHLY freq preserves day-of-month across month boundaries', () {
      final e = _event(
        type: EventType.expense,
        date: DateTime(2026, 1, 15),
        amount: 50000,
        isRecurring: true,
        rrule: 'FREQ=MONTHLY;COUNT=6',
      );
      expect(expandRecurrenceDates(e, windowEnd), [
        DateTime(2026, 1, 15),
        DateTime(2026, 2, 15),
        DateTime(2026, 3, 15),
        DateTime(2026, 4, 15),
        DateTime(2026, 5, 15),
        DateTime(2026, 6, 15),
      ]);
    });

    test('YEARLY freq preserves month + day across years', () {
      // Need a wider window than the group's default 2026-12-31 to
      // let three yearly occurrences land. The COUNT cap stops the
      // loop, but the window check happens first.
      final e = _event(
        type: EventType.income,
        date: DateTime(2026, 4, 15),
        amount: 100000,
        isRecurring: true,
        rrule: 'FREQ=YEARLY;COUNT=3',
      );
      expect(expandRecurrenceDates(e, DateTime(2030, 1, 1)), [
        DateTime(2026, 4, 15),
        DateTime(2027, 4, 15),
        DateTime(2028, 4, 15),
      ]);
    });

    test('COUNT bounds the output even when the window would allow more', () {
      // 100-week window but COUNT=2 → only 2 dates.
      final e = _event(
        type: EventType.expense,
        date: DateTime(2026, 6, 1),
        amount: 1000,
        isRecurring: true,
        rrule: 'FREQ=WEEKLY;COUNT=2',
      );
      expect(expandRecurrenceDates(e, windowEnd), [
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 8),
      ]);
    });

    test('UNTIL clamps to its date when earlier than windowEnd', () {
      // RRULE UNTIL is YYYYMMDD (no separator) in the parser's
      // current format. windowEnd is 2026-12-31, UNTIL is
      // 2026-06-30 → stops after the June occurrence.
      final e = _event(
        type: EventType.income,
        date: DateTime(2026, 4, 1),
        amount: 200000,
        isRecurring: true,
        rrule: 'FREQ=MONTHLY;UNTIL=20260630',
      );
      expect(expandRecurrenceDates(e, windowEnd), [
        DateTime(2026, 4, 1),
        DateTime(2026, 5, 1),
        DateTime(2026, 6, 1),
      ]);
    });

    test('windowEnd clamps the recurrence when no UNTIL is set', () {
      // Short window: 6 days. WEEKLY recurrence yields only the
      // start date (next occurrence at +7 days is past windowEnd).
      final e = _event(
        type: EventType.expense,
        date: DateTime(2026, 6, 1),
        amount: 1000,
        isRecurring: true,
        rrule: 'FREQ=WEEKLY',
      );
      expect(expandRecurrenceDates(e, DateTime(2026, 6, 6)), [
        DateTime(2026, 6, 1),
      ]);
    });

    test('malformed RRULE (unknown FREQ) yields only the start date', () {
      // The parser defaults the next-step transition to
      // `effectiveEnd + 1 day`, which terminates the loop after
      // the start. So a typo'd FREQ doesn't generate a wrong
      // cadence — it degrades to a single-shot event.
      final e = _event(
        type: EventType.expense,
        date: DateTime(2026, 6, 1),
        amount: 1000,
        isRecurring: true,
        rrule: 'FREQ=HOURLY;COUNT=5',
      );
      expect(expandRecurrenceDates(e, windowEnd), [DateTime(2026, 6, 1)]);
    });
  });

  group('buildProjection', () {
    final from = DateTime(2026, 6, 1);

    test('no events keeps the balance flat across the window', () {
      final result = buildProjection(
        startingBalance: 1000000,
        events: const [],
        from: from,
        windowDays: 14,
      );
      // Weekly sampling: day 0, 7, 14 — three points. All at 1M.
      expect(result.map((p) => p.balanceCents), [1000000, 1000000, 1000000]);
    });

    test('single positive event applies on its day', () {
      // Income event +$100 at day 5. The day-0 sample is before
      // the event; the day-7 sample is after — balance should
      // have ticked up by 10000 cents.
      final result = buildProjection(
        startingBalance: 0,
        events: [
          _event(
            type: EventType.income,
            date: from.add(const Duration(days: 5)),
            amount: 10000,
          ),
        ],
        from: from,
        windowDays: 14,
      );
      expect(result[0].balanceCents, 0);
      expect(result[1].balanceCents, 10000);
      expect(result[2].balanceCents, 10000);
    });

    test('negative event types subtract', () {
      // Expense event applies as -amount even though the model
      // stores amount as positive (sign is in eventType).
      final result = buildProjection(
        startingBalance: 100000,
        events: [
          _event(
            type: EventType.expense,
            date: from.add(const Duration(days: 5)),
            amount: 30000,
          ),
        ],
        from: from,
        windowDays: 14,
      );
      expect(result.last.balanceCents, 70000);
    });

    test('multiple events on the same day sum', () {
      // Three events landing on day 3 — all should apply before
      // the day-7 sample.
      final result = buildProjection(
        startingBalance: 0,
        events: [
          _event(
            id: 'a',
            type: EventType.income,
            date: from.add(const Duration(days: 3)),
            amount: 10000,
          ),
          _event(
            id: 'b',
            type: EventType.income,
            date: from.add(const Duration(days: 3)),
            amount: 5000,
          ),
          _event(
            id: 'c',
            type: EventType.expense,
            date: from.add(const Duration(days: 3)),
            amount: 2000,
          ),
        ],
        from: from,
        windowDays: 14,
      );
      // 10000 + 5000 - 2000 = 13000 by day 7.
      expect(result[1].balanceCents, 13000);
    });

    test('past-dated event is silently dropped (no back-projection)', () {
      // The iteration starts at `from`; a delta keyed to a date
      // before `from` is never looked up, so the past event has
      // no effect on the series.
      final result = buildProjection(
        startingBalance: 50000,
        events: [
          _event(
            type: EventType.income,
            date: from.subtract(const Duration(days: 30)),
            amount: 999999,
          ),
        ],
        from: from,
        windowDays: 14,
      );
      expect(
        result.every((p) => p.balanceCents == 50000),
        isTrue,
        reason:
            'past-dated events must not retroactively bump the '
            'starting balance — the projection is forward-only.',
      );
    });

    test('weekly sampling: day 0, 7, 14 plus the final day when not a '
        'multiple of 7', () {
      // windowDays=10 — samples at i=0, 7, AND the final i=10
      // (even though 10 is not a multiple of 7) so the last
      // chart point lines up with the projection end.
      final result = buildProjection(
        startingBalance: 0,
        events: const [],
        from: from,
        windowDays: 10,
      );
      expect(result.map((p) => p.date), [
        from,
        from.add(const Duration(days: 7)),
        from.add(const Duration(days: 10)),
      ]);
    });

    test('recurring event accumulates each occurrence into the balance', () {
      // Monthly $1k expense, 3 occurrences. Window 95 days
      // (~3.1 months). Final balance: starting - 3 × 100000.
      final result = buildProjection(
        startingBalance: 500000,
        events: [
          _event(
            type: EventType.expense,
            date: from,
            amount: 100000,
            isRecurring: true,
            rrule: 'FREQ=MONTHLY;COUNT=3',
          ),
        ],
        from: from,
        windowDays: 95,
      );
      expect(result.last.balanceCents, 500000 - 300000);
    });
  });
}
