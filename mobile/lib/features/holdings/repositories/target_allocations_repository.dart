// Data access for household target allocations (migration 035).
//
// Mostly upsert + delete. The setter screen reads every row for
// the household at once, edits in memory, then writes back the
// full set so partial / 100%-summing constraints stay consistent.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../models/holding.dart';
import '../models/target_allocation.dart';

part 'target_allocations_repository.g.dart';

@riverpod
TargetAllocationsRepository targetAllocationsRepository(
  TargetAllocationsRepositoryRef ref,
) {
  return TargetAllocationsRepository();
}

class TargetAllocationsRepository {
  /// Lists every target row for the household. Empty list when no
  /// targets are set — the rebalance math treats missing classes
  /// as 0%, so an unconfigured household just sees "every class is
  /// overweight by its current weight."
  Future<List<TargetAllocation>> fetchAll(String householdId) async {
    final data = await supabase
        .from('target_allocations')
        .select()
        .eq('household_id', householdId);
    return data.map<TargetAllocation>(TargetAllocation.fromJson).toList();
  }

  /// Upserts one (household, asset_class) row. Replaces target if
  /// it already exists for this class — that's the only update path
  /// the UI needs.
  Future<void> setTarget({
    required String householdId,
    required AssetClass assetClass,
    required int targetPctBp,
    required String createdBy,
  }) async {
    await supabase
        .from('target_allocations')
        .upsert(
          {
            'household_id': householdId,
            'asset_class': assetClass.dbValue,
            'target_pct_bp': targetPctBp,
            'created_by': createdBy,
          },
          onConflict: 'household_id,asset_class',
        );
  }

  /// Removes a single (household, asset_class) row. Distinct from
  /// "set to 0%" — a row with target 0 says "I've explicitly
  /// decided not to hold this," whereas absent is "I haven't
  /// thought about this class." The rebalance math treats both the
  /// same, but the UI shows them differently (explicit zero vs
  /// blank).
  Future<void> deleteTarget({
    required String householdId,
    required AssetClass assetClass,
  }) async {
    await supabase
        .from('target_allocations')
        .delete()
        .eq('household_id', householdId)
        .eq('asset_class', assetClass.dbValue);
  }
}
