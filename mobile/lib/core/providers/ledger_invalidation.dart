// Shared "the ledger changed" invalidation helper.
//
// Every transaction-write path (create, edit, delete, transfer, bulk
// import, line-item edit) needs to invalidate the same set of
// downstream providers so the dashboard / accounts / transactions /
// budget surfaces all refresh together. Before this helper each
// write site invalidated some-but-not-all of them by hand — most
// commonly accountsProvider + transactionsProvider while forgetting
// budgetDataProvider, leaving the user looking at stale budget bars
// after adding a grocery expense. (Audit C2.)
//
// Use this whenever a transaction write commits — the cost of a
// few extra invalidations on a write is far smaller than the cost of
// a single stale surface in front of the user.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/providers/accounts_provider.dart';
import '../../features/budget/providers/budget_provider.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/transactions/providers/transactions_provider.dart';

/// Invalidate every provider whose data is derived from the
/// transactions ledger. Call this after a successful transaction
/// write (create / update / delete / transfer leg / bulk import /
/// line-item edit that shifts category spend).
///
/// Invalidation is cheap — autoDispose providers re-derive on the
/// next watch, and any currently-mounted screen sees fresh data on
/// the next frame. Forgetting one of these is the bug pattern this
/// helper exists to prevent.
void invalidateLedger(WidgetRef ref) {
  ref.invalidate(accountsProvider);
  ref.invalidate(transactionsProvider);
  ref.invalidate(budgetDataProvider);
  // The dashboard provider doesn't `ref.watch(transactionsProvider)`
  // — it goes through repos directly — so without this line a write
  // from the dashboard FAB leaves the dashboard cards stale until
  // the user navigates away (autoDispose) or hits the refresh button.
  ref.invalidate(dashboardDataProvider);
}
