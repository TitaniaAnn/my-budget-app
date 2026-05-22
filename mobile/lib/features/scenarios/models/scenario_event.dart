// ScenarioEvent model — mirrors the `scenario_events` table.
// Each event represents a one-off or recurring cash flow applied on top of
// the current net worth when projecting a scenario forward in time.
//
// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scenario_event.freezed.dart';
part 'scenario_event.g.dart';

/// The broad category of a scenario event, used for icons and grouping.
enum EventType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
  @JsonValue('transfer')
  transfer,
  @JsonValue('purchase')
  purchase,
  @JsonValue('debt')
  debt,
  @JsonValue('savings')
  savings,

  /// Pay-down-a-debt plan. `accountId` references the debt
  /// account; `amount` is the monthly payment in cents;
  /// `paymentAprBps` is the APR in basis points. The projection
  /// engine expands a payoff event into a synthetic month-by-month
  /// stream of principal payments and interest accruals until the
  /// remaining balance hits zero (or never, if the payment is too
  /// small to outpace interest).
  @JsonValue('payoff')
  payoff;

  String get label => switch (this) {
    EventType.income => 'Income',
    EventType.expense => 'Expense',
    EventType.transfer => 'Transfer',
    EventType.purchase => 'Purchase',
    EventType.debt => 'Debt',
    EventType.savings => 'Savings',
    EventType.payoff => 'Payoff plan',
  };

  /// Positive event types add to net worth; negative ones subtract.
  ///
  /// Payoff isn't in either bucket — its monthly payment subtracts
  /// from cash, but the loan balance ticks UP toward zero, which
  /// nets to (approximately) zero impact on net worth each month.
  /// The projection engine handles payoff events specially; this
  /// flag is just for the generic event types.
  bool get isPositive =>
      this == EventType.income ||
      this == EventType.savings ||
      this == EventType.transfer;
}

/// One financial event in a scenario (e.g. "Buy a car", "Get a raise").
///
/// [amount] is always stored as a positive number of cents. Whether it
/// increases or decreases net worth is determined by [eventType.isPositive].
///
/// Recurring events use iCal RRULE syntax in [recurrenceRule], e.g.
/// "FREQ=MONTHLY;COUNT=12" for 12 monthly payments.
@freezed
class ScenarioEvent with _$ScenarioEvent {
  const factory ScenarioEvent({
    required String id,
    required String scenarioId,
    required EventType eventType,
    required String label,
    required DateTime eventDate,

    /// Amount in cents (always positive; direction set by [eventType]).
    required int amount,
    String? accountId,
    required bool isRecurring,

    /// iCal RRULE string when [isRecurring] is true (e.g. "FREQ=MONTHLY").
    String? recurrenceRule,

    /// Free-form JSON for extra parameters (unused for now, future-proofing).
    Map<String, dynamic>? parameters,
    required int sortOrder,

    /// APR in basis points (10000 = 100%) for payoff-plan events.
    /// Null for all other event types. Set at create time from the
    /// debt account's `interestRate` — capturing it on the event
    /// keeps the plan stable if the user updates the account's APR
    /// later. Migration 041.
    @JsonKey(name: 'payoff_apr_bps') int? paymentAprBps,
  }) = _ScenarioEvent;

  factory ScenarioEvent.fromJson(Map<String, dynamic> json) =>
      _$ScenarioEventFromJson(json);
}
