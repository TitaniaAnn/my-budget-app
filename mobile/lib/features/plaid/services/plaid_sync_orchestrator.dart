// Drives `plaid-transactions-sync` for every active Item in the
// household. Aggregates per-item results so the dashboard can
// surface a single toast ("synced N transactions across M
// accounts") and surface re-auth state for the items that
// failed.
//
// Pure-business-logic so the per-item dispatch order, error
// handling, and aggregation can be unit-tested without the
// Edge Function tier. The repository is injected; tests pass
// a stub.

import '../models/plaid_item.dart';
import '../models/plaid_link_result.dart';
import '../repositories/plaid_repository.dart';

/// Aggregated outcome from `syncAll` — one tuple per call,
/// computed across every Item the user has linked.
class PlaidSyncSummary {
  const PlaidSyncSummary({
    required this.items,
    required this.totalAdded,
    required this.totalModified,
    required this.totalRemoved,
    required this.totalMerged,
    required this.itemsRequiringReauth,
    required this.failedItems,
    required this.itemsWithPartialFailure,
  });

  /// Items the orchestrator touched (whether or not the sync
  /// succeeded).
  final List<PlaidItem> items;

  /// Across all items.
  final int totalAdded;
  final int totalModified;
  final int totalRemoved;
  final int totalMerged;

  /// Items whose sync returned `requires_reauth: true`. The
  /// ReauthPrompt watches this set and shows one tile per item.
  final List<PlaidItem> itemsRequiringReauth;

  /// Items whose sync threw — distinct from re-auth (which is a
  /// soft failure surfaced via flag). UI usually shows these as
  /// a generic "couldn't sync $institution, will retry next
  /// load" banner.
  final List<PlaidItem> failedItems;

  /// Items whose sync returned `partial_failure: true` — at
  /// least one per-account RPC errored inside the Edge Function
  /// but the rest succeeded. The Edge Function held the cursor
  /// at the old value so the next sync retries automatically;
  /// the orchestrator surfaces these distinctly from
  /// [failedItems] (which threw completely) so the UI can say
  /// "1 account in $institution didn't update — we'll retry
  /// next time."
  final List<PlaidItem> itemsWithPartialFailure;

  bool get hasChanges =>
      totalAdded + totalModified + totalRemoved + totalMerged > 0;

  /// True when ANY item needs attention (re-auth OR full
  /// failure OR partial failure). Drives whether the caller
  /// should invalidate the sync-trigger keepAlive provider to
  /// force a retry on the next dashboard load.
  bool get hasUnhealthyItems =>
      itemsRequiringReauth.isNotEmpty ||
      failedItems.isNotEmpty ||
      itemsWithPartialFailure.isNotEmpty;
}

class PlaidSyncOrchestrator {
  PlaidSyncOrchestrator({required this.repository});

  final PlaidRepository repository;

  /// Pulls the active Items, fires one sync per item in
  /// sequence, aggregates the results. Sequential rather than
  /// parallel so a slow Plaid response on Item A doesn't
  /// hammer the user's connection while Items B-D wait — for
  /// family scale (≤10 Items) the wall-clock difference is
  /// negligible and the simpler sequential code wins.
  Future<PlaidSyncSummary> syncAll() async {
    final items = await repository.fetchActiveItems();
    var totalAdded = 0;
    var totalModified = 0;
    var totalRemoved = 0;
    var totalMerged = 0;
    final reauth = <PlaidItem>[];
    final failed = <PlaidItem>[];
    final partial = <PlaidItem>[];

    for (final item in items) {
      try {
        final result = await repository.sync(item.id);
        totalAdded += result.added;
        totalModified += result.modified;
        totalRemoved += result.removed;
        totalMerged += result.merged;
        if (result.requiresReauth) reauth.add(item);
        if (result.partialFailure) partial.add(item);
      } catch (_) {
        // Don't let one bad Item kill the rest of the batch.
        // The thrown error is already logged in the Edge
        // Function; the UI surfaces "failed" without details.
        failed.add(item);
      }
    }

    return PlaidSyncSummary(
      items: items,
      totalAdded: totalAdded,
      totalModified: totalModified,
      totalRemoved: totalRemoved,
      totalMerged: totalMerged,
      itemsWithPartialFailure: partial,
      itemsRequiringReauth: reauth,
      failedItems: failed,
    );
  }

  /// Sync a single Item. Used by the post-exchange "initial
  /// pull" path and the re-auth-success retry path. Mirrors
  /// the per-item portion of [syncAll] but returns the raw
  /// [PlaidSyncResult] (callers want the counts more than the
  /// aggregated summary).
  Future<PlaidSyncResult> syncOne(String plaidItemRowId) {
    return repository.sync(plaidItemRowId);
  }
}
