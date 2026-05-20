// TargetAllocation — mirrors the `target_allocations` table
// (migration 035). One row per (household, asset_class) sets the
// household's target weight as basis points.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'holding.dart';

part 'target_allocation.freezed.dart';
part 'target_allocation.g.dart';

@freezed
class TargetAllocation with _$TargetAllocation {
  const factory TargetAllocation({
    required String householdId,
    required AssetClass assetClass,

    /// Target weight in basis points (0–10000). The setter UI gates
    /// the full household sum to 100% before saving; individual rows
    /// don't carry that invariant — a partial set (stocks + bonds
    /// defined, no cash row) is valid and treated as 0% for the
    /// undefined classes.
    required int targetPctBp,
    String? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TargetAllocation;

  factory TargetAllocation.fromJson(Map<String, dynamic> json) =>
      _$TargetAllocationFromJson(json);
}
