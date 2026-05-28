// Riverpod providers for the Plaid feature.
//
// Split into three layers:
//
//   plaidItemsProvider  — autoDispose Future over the active
//                         plaid_items rows. The connect-bank
//                         screen + dashboard reauth banner both
//                         watch this. Invalidated after exchange
//                         and after sync (since sync writes
//                         last_sync_error / last_sync_at).
//
//   plaidSyncOrchestratorProvider — keepAlive (one orchestrator
//                         per app process; cheap to construct
//                         either way, kept stable so its internal
//                         repository ref is stable).
//
//   plaidSyncTriggerProvider — fires syncAll() at most once per
//                         app session UNLESS the user pulls to
//                         refresh. Same shape as
//                         runRecurringSchedulerProvider — the
//                         dashboard fires it via `ref.read(...future)`
//                         to kick off the work without blocking the
//                         dashboard's own data fetch on the
//                         Plaid round-trip.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/plaid_item.dart';
import '../repositories/plaid_repository.dart';
import '../services/plaid_sync_orchestrator.dart';

part 'plaid_providers.g.dart';

@riverpod
Future<List<PlaidItem>> plaidItems(PlaidItemsRef ref) async {
  final repo = ref.watch(plaidRepositoryProvider);
  return repo.fetchActiveItems();
}

@Riverpod(keepAlive: true)
PlaidSyncOrchestrator plaidSyncOrchestrator(PlaidSyncOrchestratorRef ref) {
  return PlaidSyncOrchestrator(repository: ref.watch(plaidRepositoryProvider));
}

/// Fires syncAll() once per app process. Same pattern as
/// runRecurringSchedulerProvider — keepAlive so a subsequent
/// dashboard load doesn't re-fire, and a pull-to-refresh
/// invalidates this provider to force another run.
///
/// Returns the [PlaidSyncSummary] so callers can show a
/// post-sync toast or banner; null when there are no items
/// (don't bother dispatching).
@Riverpod(keepAlive: true)
Future<PlaidSyncSummary?> plaidSyncTrigger(PlaidSyncTriggerRef ref) async {
  final orchestrator = ref.watch(plaidSyncOrchestratorProvider);
  final summary = await orchestrator.syncAll();
  // Any sync that wrote rows means the cached items + cached
  // ledger reads are stale. Invalidate the items provider so
  // last_sync_at / last_sync_error refresh; the dashboard
  // ledger providers are invalidated by the broader
  // invalidateLedger pattern in the call site, not here, to
  // avoid coupling Plaid to every ledger surface.
  if (summary.items.isNotEmpty) {
    ref.invalidate(plaidItemsProvider);
  }
  return summary.items.isEmpty ? null : summary;
}
