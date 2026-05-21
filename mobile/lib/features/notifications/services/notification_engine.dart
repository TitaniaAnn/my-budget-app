// Pure function that decides which notifications to fire on the
// next pass. No platform calls, no SharedPreferences, no Riverpod
// — just (state in) → (list of PendingNotification out). Lets the
// trigger logic be unit-tested without the widget tree or a real
// notifications plugin.
//
// Caller responsibilities:
//   * persist `lastFiredByKey` between passes (SharedPreferences in
//     production; an in-memory map in tests);
//   * actually show each PendingNotification via the platform
//     wrapper;
//   * after showing, write the new key → now() entries back into
//     the persisted map so subsequent passes skip them.
//
// Dedup keys are namespaced and include enough context that a NEW
// instance of the same kind of event (next budget period, new
// transaction id) gets a fresh key and fires again.

import '../../budget/providers/budget_provider.dart';
import '../../transactions/models/transaction.dart';
import '../models/notification_settings.dart';

/// Threshold past which a budget over-spend is worth notifying
/// about. A budget that runs $0.01 over from a rounding-edge
/// refund situation would spam the user; the $1 floor keeps
/// notifications meaningful.
const _budgetOverFloorCents = 100;

/// Window for "this is a new transaction we should notify about."
/// Older rows are assumed already-seen on whatever device imported
/// them — without this gate a fresh install would fire a flood of
/// notifications for months of history on the first dashboard load.
const _recentTransactionWindow = Duration(hours: 24);

List<PendingNotification> evaluateNotifications({
  required NotificationSettings settings,
  required List<BudgetWithSpending> budgets,
  required List<Transaction> recentTransactions,
  required Map<String, DateTime> lastFiredByKey,
  required DateTime now,
}) {
  if (!settings.enabled) return const [];
  final pending = <PendingNotification>[];

  // ── Budget actually-over ──────────────────────────────────────────
  if (settings.budgetOverEnabled) {
    for (final b in budgets) {
      if (!b.isOverBudget) continue;
      // Both sides in the household's display currency — capCents
      // is the budget amount converted via FX (slice 3 of the
      // multi-currency arc), spentCents is what the RPC returned.
      final overBy = b.spentCents - b.capCents;
      if (overBy < _budgetOverFloorCents) continue;

      // Period-scoped key so a fresh cycle of the same budget can
      // fire again. Stable YYYY-MM-DD prefix avoids subtle timezone
      // drift in the dedup key.
      final periodKey = b.periodFrom.toIso8601String().substring(0, 10);
      final key = 'budget_over:${b.budget.id}:$periodKey';
      if (lastFiredByKey.containsKey(key)) continue;

      pending.add(
        PendingNotification(
          key: key,
          title: 'Over budget: ${b.categoryName}',
          body:
              '\$${(overBy / 100).toStringAsFixed(2)} over the '
              '\$${(b.capCents / 100).toStringAsFixed(2)} '
              '${b.budget.period.label.toLowerCase()} cap.',
        ),
      );
    }
  }

  // ── Large transaction ─────────────────────────────────────────────
  if (settings.largeTxEnabled) {
    for (final t in recentTransactions) {
      if (t.amount.abs() < settings.largeTxThresholdCents) continue;
      // Transfer legs are pure cash movement between household
      // accounts; notifying on them would scare a user moving money
      // they intended to move.
      if (t.transferId != null) continue;
      // Only fresh rows. Once an existing row is older than the
      // recent window we treat it as already-seen.
      if (now.difference(t.createdAt) > _recentTransactionWindow) continue;

      final key = 'large_tx:${t.id}';
      if (lastFiredByKey.containsKey(key)) continue;

      final sign = t.amount < 0 ? '-' : '+';
      pending.add(
        PendingNotification(
          key: key,
          title: 'Large transaction',
          body:
              '$sign\$${(t.amount.abs() / 100).toStringAsFixed(2)} — '
              '${t.merchant ?? t.description}',
        ),
      );
    }
  }

  return pending;
}
