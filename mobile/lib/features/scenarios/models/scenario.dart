// Scenario model — mirrors the `scenarios` table.
// A scenario is a named what-if financial plan. When [isGoal] is true it also
// carries a [targetAmount] and [targetDate] so progress can be tracked.
//
// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scenario.freezed.dart';
part 'scenario.g.dart';

/// Which "kind" of scenario this row represents. General scenarios
/// have an events timeline; debt-payoff scenarios instead carry a
/// list of [DebtPayoffTarget]s, a strategy, and a monthly budget,
/// and project the multi-debt amortisation rather than an events
/// stream. Migration 042 added the column with a 'general' default
/// so existing rows are correct without a backfill.
enum ScenarioKind {
  @JsonValue('general')
  general,
  @JsonValue('debt_payoff')
  debtPayoff,
}

/// Strategy for allocating the user's monthly debt-payoff budget
/// across multiple debts.
enum DebtPayoffStrategy {
  /// Pay minimums on every debt; extra goes to the highest-APR
  /// debt first (lowest total interest).
  @JsonValue('avalanche')
  avalanche,

  /// Pay minimums on every debt; extra goes to the smallest
  /// balance first (psychological wins, more interest overall).
  @JsonValue('snowball')
  snowball,

  /// User specifies extra-over-minimum per debt. The simulator
  /// honours those amounts verbatim each month.
  @JsonValue('custom')
  custom,
}

/// One debt in a debt-payoff plan. Stored as JSON inside
/// `scenarios.debt_payoff_targets` — short list, read with the
/// scenario, never queried independently.
@freezed
class DebtPayoffTarget with _$DebtPayoffTarget {
  const factory DebtPayoffTarget({
    /// References accounts.id. The simulator snapshots the
    /// account's current_balance at plan-creation time below;
    /// the account_id is kept so the UI can resolve the name +
    /// honour deletes (a target whose account is gone is
    /// silently dropped from the projection).
    @JsonKey(name: 'account_id') required String accountId,

    /// Minimum required payment per month (cents). Auto-computed
    /// at creation time from balance + APR; the user can override
    /// to match their actual statement minimum.
    @JsonKey(name: 'min_payment_cents') required int minPaymentCents,

    /// APR in basis points. Captured per-target so a saved plan
    /// stays stable if the account's interest_rate changes — same
    /// reasoning as scenario_events.payoff_apr_bps.
    @JsonKey(name: 'apr_bps') required int aprBps,

    /// For [DebtPayoffStrategy.custom]: extra-over-minimum to
    /// pay on this debt each month. Null/zero on avalanche or
    /// snowball strategies (the simulator computes extras itself).
    @JsonKey(name: 'extra_payment_cents') int? extraPaymentCents,
  }) = _DebtPayoffTarget;

  factory DebtPayoffTarget.fromJson(Map<String, dynamic> json) =>
      _$DebtPayoffTargetFromJson(json);
}

/// Immutable representation of a row in the `scenarios` table.
///
/// Use [isGoal] to distinguish planning scenarios from saved goals.
/// [color] is a 7-char hex string (e.g. "#6366F1") used to tint the card
/// and the chart line.
@freezed
class Scenario with _$Scenario {
  const factory Scenario({
    required String id,
    required String householdId,
    required String createdBy,

    /// Optional parent scenario this was branched from.
    String? parentId,
    required String name,
    String? description,

    /// The date from which projection starts (usually today or a future date).
    required DateTime baseDate,

    /// True when this scenario represents the unmodified baseline (no events).
    required bool isBaseline,

    /// Hex color for the chart line and card accent (e.g. "#6366F1").
    String? color,

    /// When true this scenario is tracked as a financial goal.
    required bool isGoal,

    /// Target net-worth in cents the user wants to reach (goals only).
    int? targetAmount,

    /// Deadline for hitting [targetAmount] (goals only).
    DateTime? targetDate,
    required DateTime createdAt,
    required DateTime updatedAt,

    /// Which kind of scenario this is. Defaults to general so
    /// existing rows (where the column has the SQL default) decode
    /// cleanly. See [ScenarioKind] for the semantics.
    @Default(ScenarioKind.general) ScenarioKind kind,

    /// Debt-payoff target list. Null for kind=general. The freezed
    /// JSON converter handles the JSONB column directly.
    @JsonKey(name: 'debt_payoff_targets')
    List<DebtPayoffTarget>? debtPayoffTargets,

    /// Strategy for allocating extra-over-minimum payment across
    /// the targets. Null for kind=general.
    @JsonKey(name: 'debt_payoff_strategy')
    DebtPayoffStrategy? debtPayoffStrategy,

    /// Total monthly $ the user is committing across all debts in
    /// the plan (cents). Null for kind=general.
    @JsonKey(name: 'debt_payoff_monthly_budget_cents')
    int? debtPayoffMonthlyBudgetCents,
  }) = _Scenario;

  factory Scenario.fromJson(Map<String, dynamic> json) =>
      _$ScenarioFromJson(json);
}
