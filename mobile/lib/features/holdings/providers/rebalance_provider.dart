// Riverpod glue for the rebalance surface. Combines holdings +
// target allocations into a RebalanceReport the dashboard card
// can read directly.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/household_provider.dart';
import '../repositories/target_allocations_repository.dart';
import '../services/rebalance.dart';
import 'holdings_provider.dart';

part 'rebalance_provider.g.dart';

@riverpod
Future<RebalanceReport> rebalanceReport(RebalanceReportRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) {
    return const RebalanceReport(totalCents: 0, rows: []);
  }
  final holdings = await ref.watch(householdHoldingsProvider.future);
  final targets = await ref
      .read(targetAllocationsRepositoryProvider)
      .fetchAll(householdId);
  return evaluateRebalance(holdings: holdings, targets: targets);
}
