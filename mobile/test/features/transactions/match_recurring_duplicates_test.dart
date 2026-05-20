// Pure-function tests for matchRecurringDuplicates — the matcher
// that decides which scheduler-emitted rows get reconciled when a
// statement import lands.
//
// Contracts pinned:
//   * exact amount equality (signed cents) — a -$9.99 charge and
//     a +$9.99 refund are different events and must NOT match;
//   * ±1-day default tolerance for bank posting lag, with anything
//     outside the window left alone;
//   * each scheduler row is claimed at most once per import — two
//     import rows for the same recurring rule (unusual CSV) only
//     dedup one of them;
//   * closest-date wins on tie-breaking so a same-day match beats
//     a 1-day-shifted match;
//   * malformed rows (missing amount or date) silently skip
//     without crashing.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/repositories/transactions_repository.dart';

({String id, DateTime date, int amount}) _r({
  required String id,
  required int amount,
  required DateTime date,
}) => (id: id, date: date, amount: amount);

Map<String, dynamic> _imp({
  required int amount,
  required DateTime date,
}) => {
  'amount': amount,
  'transaction_date': date.toIso8601String().substring(0, 10),
};

void main() {
  group('matchRecurringDuplicates', () {
    test('matches same-amount same-date as the obvious case', () {
      final matches = matchRecurringDuplicates(
        importRows: [
          _imp(amount: -999, date: DateTime.utc(2026, 6, 1)),
        ],
        recurringRows: [
          _r(id: 'spotify', amount: -999, date: DateTime.utc(2026, 6, 1)),
        ],
      );
      expect(matches, hasLength(1));
      expect(matches.single.importRowIndex, 0);
      expect(matches.single.scheduledTransactionId, 'spotify');
    });

    test('1-day bank-posting lag still matches; 2 days does NOT', () {
      final matches = matchRecurringDuplicates(
        importRows: [
          _imp(amount: -999, date: DateTime.utc(2026, 6, 2)),
          _imp(amount: -1500, date: DateTime.utc(2026, 6, 3)),
        ],
        recurringRows: [
          // 1 day off — matches.
          _r(id: 'a', amount: -999, date: DateTime.utc(2026, 6, 1)),
          // 2 days off — out of window.
          _r(id: 'b', amount: -1500, date: DateTime.utc(2026, 6, 1)),
        ],
      );
      final byImportIdx = {for (final m in matches) m.importRowIndex: m};
      expect(byImportIdx[0]?.scheduledTransactionId, 'a');
      expect(
        byImportIdx.containsKey(1),
        isFalse,
        reason: 'a 2-day gap is outside the default ±1-day tolerance; '
            'matching it would risk reconciling unrelated charges.',
      );
    });

    test('refund and charge of the same magnitude do NOT match', () {
      // A -$9.99 scheduler emission and a +$9.99 refund import are
      // structurally different events even though |amount| matches.
      final matches = matchRecurringDuplicates(
        importRows: [
          _imp(amount: 999, date: DateTime.utc(2026, 6, 1)),
        ],
        recurringRows: [
          _r(id: 'charge', amount: -999, date: DateTime.utc(2026, 6, 1)),
        ],
      );
      expect(matches, isEmpty);
    });

    test('each scheduler row is claimed at most once', () {
      // Two identical-looking import rows; only one can dedup the
      // single matching scheduler row, the other is left alone (will
      // land as a fresh insert via the upsert path).
      final matches = matchRecurringDuplicates(
        importRows: [
          _imp(amount: -999, date: DateTime.utc(2026, 6, 1)),
          _imp(amount: -999, date: DateTime.utc(2026, 6, 1)),
        ],
        recurringRows: [
          _r(id: 'only-one', amount: -999, date: DateTime.utc(2026, 6, 1)),
        ],
      );
      expect(matches, hasLength(1));
      expect(matches.single.importRowIndex, 0);
    });

    test('closest-date scheduler row wins on tie-break', () {
      // Two scheduler rows of the same amount, one same-day and one
      // 1-day-off relative to the import row. The same-day one wins;
      // the 1-day-off one is left for a potential later import row.
      final matches = matchRecurringDuplicates(
        importRows: [
          _imp(amount: -999, date: DateTime.utc(2026, 6, 2)),
        ],
        recurringRows: [
          _r(id: 'one-day-off', amount: -999, date: DateTime.utc(2026, 6, 1)),
          _r(id: 'same-day', amount: -999, date: DateTime.utc(2026, 6, 2)),
        ],
      );
      expect(matches.single.scheduledTransactionId, 'same-day');
    });

    test('malformed import rows (missing amount or date) are skipped', () {
      final matches = matchRecurringDuplicates(
        importRows: [
          {'amount': null, 'transaction_date': '2026-06-01'},
          {'amount': -999, 'transaction_date': null},
          _imp(amount: -999, date: DateTime.utc(2026, 6, 1)),
        ],
        recurringRows: [
          _r(id: 'r', amount: -999, date: DateTime.utc(2026, 6, 1)),
        ],
      );
      // The third row matches; the first two are silently dropped.
      expect(matches, hasLength(1));
      expect(matches.single.importRowIndex, 2);
    });

    test('custom tolerance widens the match window', () {
      final matches = matchRecurringDuplicates(
        importRows: [
          _imp(amount: -999, date: DateTime.utc(2026, 6, 5)),
        ],
        recurringRows: [
          _r(id: 'far', amount: -999, date: DateTime.utc(2026, 6, 1)),
        ],
        // 4-day window catches the otherwise-out-of-tolerance match.
        dateTolerance: const Duration(days: 4),
      );
      expect(matches, hasLength(1));
    });
  });
}
