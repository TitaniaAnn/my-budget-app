// Unit tests for runNotifications — the glue between the pure
// engine, the SharedPreferences-backed last-fired map, the shared
// notification_log, and the platform service.
//
// Contracts pinned here are the ones the runner's narrative
// comment claims:
//
//   * disabled master toggle short-circuits to 0;
//   * server-fired keys (recentKeys lookup) are merged into the
//     local lastFiredByKey BEFORE the engine evaluates, so the
//     in-app surface respects what the dispatcher already pushed;
//   * claim ordering — only the keys notification_log accepts
//     (didn't already exist) get shown; the rest silently drop;
//   * recordFired persists the actually-shown keys, not the
//     evaluated ones;
//   * prune is fire-and-forget after show.
//
// The runner depends on the platform service and SharedPreferences,
// neither of which work in the test VM. The dispatcher is
// overridden via the new notificationDispatcherProvider; prefs are
// faked via SharedPreferences.setMockInitialValues.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/providers/household_provider.dart';
import 'package:mybudget/features/budget/providers/budget_provider.dart';
import 'package:mybudget/features/currency/providers/rates_to_display_provider.dart';
import 'package:mybudget/features/dashboard/providers/dashboard_provider.dart';
import 'package:mybudget/features/notifications/models/notification_settings.dart';
import 'package:mybudget/features/notifications/providers/notification_runner_provider.dart';
import 'package:mybudget/features/notifications/providers/notification_settings_provider.dart';
import 'package:mybudget/features/notifications/repositories/notification_log_repository.dart';
import 'package:mybudget/features/notifications/services/notification_service.dart';
import 'package:mybudget/features/settings/providers/settings_provider.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingDispatcher implements LocalNotificationDispatcher {
  final List<({String tag, String title, String body})> shown = [];
  bool initialised = false;

  @override
  Future<void> ensureInitialized() async {
    initialised = true;
  }

  @override
  Future<void> show({
    required String tag,
    required String title,
    required String body,
  }) async {
    shown.add((tag: tag, title: title, body: body));
  }
}

class _FakeNotificationLogRepository extends NotificationLogRepository {
  _FakeNotificationLogRepository({
    Set<String> serverKeys = const {},
    Set<String> alreadyClaimed = const {},
  }) : _serverKeys = serverKeys,
       _alreadyClaimed = alreadyClaimed;

  final Set<String> _serverKeys;

  /// Keys the LOG will report as already-claimed (returning empty
  /// for those from claimKeys). Lets a test simulate a server pass
  /// winning the race for a subset of evaluated keys.
  final Set<String> _alreadyClaimed;

  final List<String> claimCalls = [];
  final List<String> pruneCalls = [];

  @override
  Future<Set<String>> recentKeys({
    required String householdId,
    required DateTime since,
  }) async {
    return _serverKeys;
  }

  @override
  Future<Set<String>> claimKeys({
    required String householdId,
    required Iterable<String> keys,
  }) async {
    final list = keys.toList();
    claimCalls.addAll(list);
    return list.where((k) => !_alreadyClaimed.contains(k)).toSet();
  }

  @override
  Future<int> pruneOlderThan({
    required String householdId,
    Duration retention = const Duration(days: 90),
  }) async {
    pruneCalls.add(householdId);
    return 0;
  }

  @override
  Future<void> clearAll({required String householdId}) async {}
}

DashboardData _dashboardData(List<Transaction> recent90d) {
  return DashboardData(
    accounts: const [],
    recentTransactions90d: recent90d,
    recentTransactions: recent90d,
  );
}

Transaction _tx({
  required int amount,
  required String id,
  DateTime? createdAt,
  String currency = 'USD',
  String? transferId,
}) {
  final ts = createdAt ?? DateTime.now();
  return Transaction(
    id: id,
    householdId: 'h',
    accountId: 'a',
    amount: amount,
    currency: currency,
    description: 'desc',
    merchant: 'Costco',
    transactionDate: ts,
    pending: false,
    source: 'manual',
    createdAt: ts,
    updatedAt: ts,
    transferId: transferId,
  );
}

HouseholdInfo _householdInfo() {
  return const HouseholdInfo(
    householdId: 'h',
    householdName: 'Test household',
    isOwner: true,
    members: [],
    displayCurrency: 'USD',
  );
}

/// Builds a ProviderContainer with every dependency the runner
/// touches overridden. Defaults yield a "settings enabled, no
/// transactions, no budgets, no server keys" world — the
/// happy-path baseline that should produce zero notifications.
ProviderContainer _buildContainer({
  NotificationSettings settings = const NotificationSettings(enabled: true),
  List<Transaction> recentTransactions = const [],
  List<BudgetWithSpending> budgets = const [],
  required _RecordingDispatcher dispatcher,
  required _FakeNotificationLogRepository logRepo,
  String? householdId = 'h',
}) {
  return ProviderContainer(
    overrides: [
      // Settings: use a notifier override so the runner's
      // ref.watch sees the value we want.
      notificationSettingsNotifierProvider.overrideWith(
        () => _StubSettingsNotifier(settings),
      ),
      householdIdProvider.overrideWith((_) async => householdId),
      householdInfoProvider.overrideWith((_) async => _householdInfo()),
      ratesToDisplayProvider.overrideWith(
        (_) async => const <String, double>{},
      ),
      dashboardDataProvider.overrideWith(
        (_) async => _dashboardData(recentTransactions),
      ),
      budgetDataProvider.overrideWith((_) async => budgets),
      notificationLogRepositoryProvider.overrideWithValue(logRepo),
      notificationDispatcherProvider.overrideWithValue(dispatcher),
    ],
  );
}

class _StubSettingsNotifier extends NotificationSettingsNotifier {
  _StubSettingsNotifier(this._initial);
  final NotificationSettings _initial;

  @override
  NotificationSettings build() => _initial;
}

void main() {
  setUp(() async {
    // Empty prefs by default — loadLastFired returns {}.
    SharedPreferences.setMockInitialValues({});
  });

  test('disabled master toggle short-circuits to 0', () async {
    final dispatcher = _RecordingDispatcher();
    final logRepo = _FakeNotificationLogRepository();
    final container = _buildContainer(
      settings: const NotificationSettings(enabled: false),
      // Even with data that would otherwise fire, disabled wins.
      recentTransactions: [
        _tx(amount: -50000, id: 't1', createdAt: DateTime.now()),
      ],
      dispatcher: dispatcher,
      logRepo: logRepo,
    );
    addTearDown(container.dispose);

    final result = await container.read(runNotificationsProvider.future);
    expect(result, 0);
    expect(
      dispatcher.shown,
      isEmpty,
      reason:
          'disabled toggle must not initialize the platform service '
          'or show anything — that is the "silence in one tap" promise.',
    );
    expect(
      logRepo.claimCalls,
      isEmpty,
      reason:
          'with the toggle off, the engine is never called and '
          'there is nothing to claim.',
    );
  });

  test('returns 0 when there is no household', () async {
    final dispatcher = _RecordingDispatcher();
    final logRepo = _FakeNotificationLogRepository();
    final container = _buildContainer(
      householdId: null,
      dispatcher: dispatcher,
      logRepo: logRepo,
    );
    addTearDown(container.dispose);

    expect(await container.read(runNotificationsProvider.future), 0);
    expect(dispatcher.shown, isEmpty);
  });

  test(
    'server-fired keys merged into lastFired BEFORE evaluation so '
    'the in-app surface respects pushes the dispatcher already sent',
    () async {
      final dispatcher = _RecordingDispatcher();
      // Server already pushed the large-tx alert for transaction t1.
      // The recentKeys lookup returns it, the merge step writes it
      // into lastFiredByKey, and the engine's dedup branch then
      // skips t1.
      final logRepo = _FakeNotificationLogRepository(
        serverKeys: {'large_tx:t1'},
      );
      final container = _buildContainer(
        settings: const NotificationSettings(
          enabled: true,
          largeTxThresholdCents: 20000,
        ),
        recentTransactions: [
          _tx(amount: -50000, id: 't1', createdAt: DateTime.now()),
        ],
        dispatcher: dispatcher,
        logRepo: logRepo,
      );
      addTearDown(container.dispose);

      final result = await container.read(runNotificationsProvider.future);
      expect(
        result,
        0,
        reason:
            'large_tx:t1 was already in the server log — the runner '
            'must merge that into lastFired so the engine dedup skips it.',
      );
      expect(dispatcher.shown, isEmpty);
    },
  );

  test('only keys that claim returns ACTUALLY get shown', () async {
    // Two large-tx events evaluate. The server already claimed one
    // between our recentKeys read and our claimKeys call — that key
    // comes back in alreadyClaimed and the runner must drop it.
    final dispatcher = _RecordingDispatcher();
    final logRepo = _FakeNotificationLogRepository(
      // No server keys at recentKeys time, but the claim step
      // (later, separate round-trip) reports t2 as already claimed.
      // That's the race the dedup contract protects against.
      alreadyClaimed: {'large_tx:t2'},
    );
    final container = _buildContainer(
      settings: const NotificationSettings(
        enabled: true,
        largeTxThresholdCents: 20000,
      ),
      recentTransactions: [
        _tx(amount: -25000, id: 't1', createdAt: DateTime.now()),
        _tx(amount: -30000, id: 't2', createdAt: DateTime.now()),
      ],
      dispatcher: dispatcher,
      logRepo: logRepo,
    );
    addTearDown(container.dispose);

    final result = await container.read(runNotificationsProvider.future);
    expect(result, 1);
    // Only t1 — the engine evaluated both but the claim returned
    // just t1 because t2 was already in the log.
    expect(dispatcher.shown.map((s) => s.tag), ['large_tx:t1']);
    // Both keys were submitted to claimKeys — the filter happens
    // on the response, not preemptively.
    expect(logRepo.claimCalls.toSet(), {'large_tx:t1', 'large_tx:t2'});
  });

  test('when nothing is pending the runner returns 0 without touching '
      'the dispatcher or the log', () async {
    // No transactions, no budgets → engine returns empty.
    final dispatcher = _RecordingDispatcher();
    final logRepo = _FakeNotificationLogRepository();
    final container = _buildContainer(dispatcher: dispatcher, logRepo: logRepo);
    addTearDown(container.dispose);

    expect(await container.read(runNotificationsProvider.future), 0);
    expect(dispatcher.initialised, isFalse);
    expect(dispatcher.shown, isEmpty);
    expect(
      logRepo.claimCalls,
      isEmpty,
      reason:
          'no point hitting notification_log when nothing was '
          'pending — saves a round-trip on every empty pass.',
    );
    expect(
      logRepo.pruneCalls,
      isEmpty,
      reason:
          'prune only fires after at least one notification — a '
          'genuinely idle pass shouldn\'t cause writes.',
    );
  });

  test('recordFired persists shown keys + prune is fire-and-forget', () async {
    // One legitimate large-tx event. After it shows:
    //   * the local lastFired map must record the key (so a
    //     subsequent pass in the same session doesn't re-fire)
    //   * prune must be called for cleanup
    final dispatcher = _RecordingDispatcher();
    final logRepo = _FakeNotificationLogRepository();
    final container = _buildContainer(
      settings: const NotificationSettings(
        enabled: true,
        largeTxThresholdCents: 20000,
      ),
      recentTransactions: [
        _tx(amount: -50000, id: 't1', createdAt: DateTime.now()),
      ],
      dispatcher: dispatcher,
      logRepo: logRepo,
    );
    addTearDown(container.dispose);

    final result = await container.read(runNotificationsProvider.future);
    expect(result, 1);
    expect(dispatcher.shown, hasLength(1));
    expect(
      logRepo.pruneCalls,
      ['h'],
      reason:
          'prune must be called once for the household after '
          'showing — it is the cleanup hook for the 90-day cap.',
    );

    // Local map must now contain the fired key. Use loadLastFired
    // directly to verify the persistence side-effect.
    final persisted = await loadLastFired();
    expect(persisted.keys, contains('large_tx:t1'));
  });
}
