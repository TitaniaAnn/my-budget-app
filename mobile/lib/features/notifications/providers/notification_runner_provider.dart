// Glue between the pure engine, the SharedPreferences-backed
// last-fired map, the shared notification_log (migration 039), and
// the platform service. Runs once per app process (Riverpod
// keepAlive) on dashboard load, after the recurring scheduler has
// materialised any due rules.
//
// The eval → claim → show → persist sequence has to be in this
// order:
//   * persisting before showing would risk dedup-ing a notification
//     we then failed to display
//   * claiming the dedup_key in notification_log BEFORE showing
//     means a concurrent server-side push for the same key sees
//     our row and skips the FCM send (and vice versa). Both sides
//     racing on the same key resolves to exactly one delivery.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/household_provider.dart';
import '../../budget/providers/budget_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../repositories/notification_log_repository.dart';
import '../services/notification_engine.dart';
import 'notification_settings_provider.dart';
import '../services/notification_service.dart';

part 'notification_runner_provider.g.dart';

/// How far back to read the server-side dedup log when merging into
/// the in-app last-fired map. Matches the local 90-day retention so
/// nothing falls between the cracks.
const _serverLogLookback = Duration(days: 90);

@Riverpod(keepAlive: true)
Future<int> runNotifications(RunNotificationsRef ref) async {
  // Awaits both data sources the engine needs. Watching (not just
  // reading) so a settings flip or a budget refresh re-fires the
  // pass — Riverpod caches subsequent calls to the same input
  // shape, so this isn't expensive.
  final settings = ref.watch(notificationSettingsNotifierProvider);
  if (!settings.enabled) return 0;

  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return 0;

  final dashboard = await ref.watch(dashboardDataProvider.future);
  final budgets = await ref.watch(budgetDataProvider.future);

  final localLastFired = await loadLastFired();
  final now = DateTime.now();
  final logRepo = ref.read(notificationLogRepositoryProvider);

  // Merge server-fired keys into the dedup map so the in-app
  // engine respects pushes the dispatcher already sent.
  final serverKeys = await logRepo.recentKeys(
    householdId: householdId,
    since: now.subtract(_serverLogLookback),
  );
  final mergedLastFired = <String, DateTime>{
    ...localLastFired,
    // Server fires don't carry a precise timestamp here — `now`
    // is good enough because the dedup contract is "key present
    // means already fired", not "exact time of fire."
    for (final k in serverKeys) k: now,
  };

  final pending = evaluateNotifications(
    settings: settings,
    budgets: budgets,
    recentTransactions: dashboard.recentTransactions90d,
    lastFiredByKey: mergedLastFired,
    now: now,
  );
  if (pending.isEmpty) return 0;

  // Atomically claim each key in notification_log. The set that
  // comes back is what we can show — anything missing was claimed
  // by a concurrent server pass between our `recentKeys` read and
  // here.
  final claimed = await logRepo.claimKeys(
    householdId: householdId,
    keys: pending.map((n) => n.key),
  );
  final toShow = pending.where((n) => claimed.contains(n.key)).toList();
  if (toShow.isEmpty) return 0;

  final service = NotificationService.instance;
  await service.ensureInitialized();
  for (final n in toShow) {
    await service.show(tag: n.key, title: n.title, body: n.body);
  }
  await recordFired(
    existing: localLastFired,
    newKeys: toShow.map((n) => n.key),
    now: now,
  );
  return toShow.length;
}
