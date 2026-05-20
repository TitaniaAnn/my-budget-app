// Glue between the pure engine, the SharedPreferences-backed
// last-fired map, and the platform service. Runs once per app
// process (Riverpod keepAlive) on dashboard load, after the
// recurring scheduler has materialised any due rules.
//
// The eval-then-show-then-persist sequence has to be in this
// order: persisting before showing would risk dedup-ing a
// notification we then failed to display.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../budget/providers/budget_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../services/notification_engine.dart';
import 'notification_settings_provider.dart';
import '../services/notification_service.dart';

part 'notification_runner_provider.g.dart';

@Riverpod(keepAlive: true)
Future<int> runNotifications(RunNotificationsRef ref) async {
  // Awaits both data sources the engine needs. Watching (not just
  // reading) so a settings flip or a budget refresh re-fires the
  // pass — Riverpod caches subsequent calls to the same input
  // shape, so this isn't expensive.
  final settings = ref.watch(notificationSettingsNotifierProvider);
  if (!settings.enabled) return 0;

  final dashboard = await ref.watch(dashboardDataProvider.future);
  final budgets = await ref.watch(budgetDataProvider.future);

  final lastFired = await loadLastFired();
  final now = DateTime.now();
  final pending = evaluateNotifications(
    settings: settings,
    budgets: budgets,
    recentTransactions: dashboard.recentTransactions90d,
    lastFiredByKey: lastFired,
    now: now,
  );
  if (pending.isEmpty) return 0;

  final service = NotificationService.instance;
  await service.ensureInitialized();
  for (final n in pending) {
    await service.show(tag: n.key, title: n.title, body: n.body);
  }
  await recordFired(
    existing: lastFired,
    newKeys: pending.map((n) => n.key),
    now: now,
  );
  return pending.length;
}
