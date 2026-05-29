// Manual sync entry point. Audit L1 Phase 5b.
//
// Three places trigger a sync today:
//   1. App lifecycle resume (≥1 min away)   — `invalidateLedger`
//   2. Connectivity false→true edge          — drain + invalidate
//   3. User pulls-to-refresh on any screen   — this coordinator
//
// Before this provider each pull-to-refresh path called
// `ref.refresh(someSpecificProvider.future)` — that re-fetched
// that one provider's data but skipped draining the offline
// queue. Result: a user who edited a transaction while offline,
// reconnected, and pulled to refresh, would see their queued
// edit fire on the next connectivity tick instead of right now.
//
// SyncCoordinator.pullToRefresh runs both halves in the right
// order — drain first (so the server has the user's writes),
// then invalidate (so the re-fetch reads the server-canonical
// state including those writes). Surfaces drain failures via
// the returned `SyncResult`; callers can show a snackbar.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/ledger_invalidation.dart';
import 'pending_writes_queue.dart';

part 'sync_coordinator.g.dart';

/// What happened during a manual sync. Both numbers may be 0
/// (nothing was queued; the refresh was a pure re-fetch).
class SyncResult {
  const SyncResult({required this.drainAttempted, required this.drainFailed});
  final int drainAttempted;
  final int drainFailed;
}

@Riverpod(keepAlive: true)
SyncCoordinator syncCoordinator(SyncCoordinatorRef ref) {
  return SyncCoordinator(queue: ref.watch(pendingWritesQueueProvider));
}

class SyncCoordinator {
  SyncCoordinator({required this.queue});
  final PendingWritesQueue queue;

  /// Drain the offline write queue + invalidate the ledger.
  /// Call from pull-to-refresh handlers. The [ref] parameter is
  /// the calling widget's WidgetRef so invalidateLedger can
  /// target the same provider scope.
  Future<SyncResult> pullToRefresh(WidgetRef ref) async {
    final drainResult = await queue.drain();
    invalidateLedger(ref);
    return SyncResult(
      drainAttempted: drainResult.attempted,
      drainFailed: drainResult.failed,
    );
  }
}
