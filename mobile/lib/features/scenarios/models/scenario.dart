// Scenario model — mirrors the `scenarios` table.
// A scenario is a named what-if financial plan. When [isGoal] is true it also
// carries a [targetAmount] and [targetDate] so progress can be tracked.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'scenario.freezed.dart';
part 'scenario.g.dart';

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
  }) = _Scenario;

  factory Scenario.fromJson(Map<String, dynamic> json) =>
      _$ScenarioFromJson(json);
}
