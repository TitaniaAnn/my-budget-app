// RecurringTransaction model — mirrors the `recurring_transactions`
// table (migration 031).
//
// A recurring rule describes "this transaction repeats." A future
// scheduler will materialise actual `transactions` rows from these
// when due; this model is the vocabulary the rest of the app uses
// to read and edit the rules themselves.
//
// `amountCents` is signed the same way as Transaction.amount —
// negative for outflows (Spotify), positive for inflows (paycheck,
// dividend, allowance). The CHECK constraint at the DB level
// rejects zero amounts so they can't get into the table.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_transaction.freezed.dart';
part 'recurring_transaction.g.dart';

/// Maps to the `recurrence_cadence` Postgres enum. Deliberately
/// distinct from `budget_period`: budgets do semiannual cycles
/// (H1/H2) which essentially never describe a real subscription,
/// and recurring rules cover `quarterly` (insurance premiums,
/// quarterly taxes) which budgets don't.
///
/// Audit L8 (known leap-year quirk): the scheduler's
/// `advance_recurrence_date` SQL helper uses Postgres
/// `+ INTERVAL '1 year'`, which clamps Feb 29 → Feb 28 in
/// non-leap years. Once a Feb-29 annual rule emits on Feb-28 in a
/// non-leap year, every subsequent `+ INTERVAL '1 year'` lands on
/// Feb-28 again (Feb-28 + 1 year = Feb-28, even in a leap year).
/// Net effect: a "Feb 29" annual rule permanently shifts to Feb 28
/// after its first non-leap-year emission. Documented rather than
/// fixed because (a) it affects only the leap-day case, (b) the
/// alternative (round forward to Mar 1 OR re-snap to Feb 29 in
/// leap years) silently changes the spend's date — neither is
/// clearly better — and (c) the user can edit `next_occurrence_date`
/// directly if Feb 29 specifically matters to them.
enum RecurrenceCadence {
  @JsonValue('weekly')
  weekly,
  @JsonValue('biweekly')
  biweekly,
  @JsonValue('monthly')
  monthly,
  @JsonValue('quarterly')
  quarterly,
  @JsonValue('annual')
  annual;

  /// User-facing label shown in the UI.
  String get displayName => switch (this) {
    RecurrenceCadence.weekly => 'Weekly',
    RecurrenceCadence.biweekly => 'Every 2 weeks',
    RecurrenceCadence.monthly => 'Monthly',
    RecurrenceCadence.quarterly => 'Quarterly',
    RecurrenceCadence.annual => 'Annual',
  };

  /// Exact string stored in the Postgres enum. Used when building
  /// INSERT / UPDATE payloads manually (the @JsonValue annotation
  /// handles the read path but not the write path).
  String get dbValue => switch (this) {
    RecurrenceCadence.weekly => 'weekly',
    RecurrenceCadence.biweekly => 'biweekly',
    RecurrenceCadence.monthly => 'monthly',
    RecurrenceCadence.quarterly => 'quarterly',
    RecurrenceCadence.annual => 'annual',
  };
}

@freezed
class RecurringTransaction with _$RecurringTransaction {
  const factory RecurringTransaction({
    required String id,
    required String householdId,
    required String accountId,

    /// Signed cents. Negative = outflow, positive = inflow.
    /// Zero is rejected by the DB CHECK constraint.
    required int amountCents,
    required String currency,
    required String description,
    String? merchant,
    String? categoryId,
    required RecurrenceCadence cadence,

    /// Next date the scheduler should emit a transaction. Updated
    /// by the (future) scheduler after each emission.
    required DateTime nextOccurrenceDate,

    /// Wall-clock of the last scheduler emission. Null until the
    /// first emission — distinct from [nextOccurrenceDate] because
    /// the scheduler may sit dormant for days and the audit trail
    /// remains useful even then.
    DateTime? lastEmittedAt,

    /// When set, the scheduler skips any occurrence whose date is
    /// on or before this. Pauses a subscription without deleting
    /// the rule. Null = no skip in effect.
    DateTime? skippedUntilDate,

    /// Whether the scheduler should consider this row at all.
    /// Easier than deleting when the user wants to keep history
    /// of "we used to have this subscription."
    required bool isActive,
    String? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RecurringTransaction;

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionFromJson(json);
}
