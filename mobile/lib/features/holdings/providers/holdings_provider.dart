// Riverpod providers for holdings. Two surfaces:
//   - per-account list (HoldingsScreen)
//   - household-wide rollup keyed by asset class (dashboard donut)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../models/holding.dart';
import '../repositories/holdings_repository.dart';

part 'holdings_provider.g.dart';

/// All holdings inside [accountId]. Family-keyed so navigating
/// between two investment accounts gets each its own cache slot.
@riverpod
Future<List<Holding>> holdingsForAccount(
  HoldingsForAccountRef ref,
  String accountId,
) async {
  final repo = ref.watch(holdingsRepositoryProvider);
  return repo.fetchForAccount(accountId);
}

/// Every holding across every investment account in the current
/// household. Powers the dashboard's asset-allocation donut.
@riverpod
Future<List<Holding>> householdHoldings(HouseholdHoldingsRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return const [];
  final repo = ref.watch(holdingsRepositoryProvider);
  return repo.fetchForHousehold(householdId);
}

/// Total current value (cents) per [AssetClass], computed from
/// [householdHoldingsProvider]. Holdings with no asset_class are
/// bucketed under [AssetClass.other] so the donut never has an
/// unlabelled slice. Returned as a sorted list (largest slice
/// first) — that's the convention the donut renders against.
@riverpod
Future<List<({AssetClass assetClass, int totalCents})>> assetAllocation(
  AssetAllocationRef ref,
) async {
  final holdings = await ref.watch(householdHoldingsProvider.future);
  final totals = <AssetClass, int>{};
  for (final h in holdings) {
    final cls = h.assetClass ?? AssetClass.other;
    totals[cls] = (totals[cls] ?? 0) + h.currentValue;
  }
  final entries =
      totals.entries
          .map((e) => (assetClass: e.key, totalCents: e.value))
          .toList()
        ..sort((a, b) => b.totalCents.compareTo(a.totalCents));
  return entries;
}
