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

import 'dart:async';

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
///
/// When the summary reports unhealthy items (re-auth needed,
/// hard failure, or partial-failure on the cursor-gated path
/// — review fix #2), this provider self-invalidates after a
/// short delay so the NEXT dashboard load re-attempts the sync.
/// Without this, a transient partial-failure (RLS hiccup, pool
/// exhaustion) would stay cached for the rest of the app
/// session and the cursor-held deltas would only retry on a
/// full app restart.
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
  // Self-invalidate the keepAlive cache when an item is
  // unhealthy so a follow-up dashboard load gets a fresh sync
  // attempt instead of returning the cached partial-failure
  // summary. Done out-of-band via Timer so this resolves
  // first; otherwise the listener that just consumed `summary`
  // would re-fire immediately and the user would see the
  // sync spinner ping-pong.
  if (summary.hasUnhealthyItems) {
    // Riverpod's Ref doesn't expose a `mounted` flag the way
    // WidgetRef does. Use onDispose to cancel the timer when the
    // provider gets invalidated some other way (e.g. user
    // pull-to-refresh) so we don't double-invalidate.
    final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return summary.items.isEmpty ? null : summary;
}
