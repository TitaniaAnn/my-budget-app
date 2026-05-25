// SharedPreferences-backed Riverpod provider for the user's
// notification preferences + the last-fired dedup map.
//
// Two things share this provider's lifecycle:
//   * NotificationSettings (which triggers, what threshold)
//   * last-fired map (keyed by PendingNotification.key → DateTime)
//
// They're stored under separate prefs keys but exposed together so
// the engine pass can read both at once. The map is intentionally
// trimmed to the last 90 days on each save — without bounding it,
// a long-running install would accrete an ever-growing JSON blob
// in shared_preferences for transactions that no longer matter.

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_settings.dart';

part 'notification_settings_provider.g.dart';

const _kEnabledKey = 'notifications.enabled';
const _kBudgetOverKey = 'notifications.budget_over_enabled';
const _kLargeTxKey = 'notifications.large_tx_enabled';
const _kLargeTxThresholdKey = 'notifications.large_tx_threshold_cents';
const _kLastFiredKey = 'notifications.last_fired';

/// Default threshold ($200) for the large-transaction trigger.
/// Mirrors the constant in [NotificationSettings] so a fresh load
/// before the user has saved anything matches the model's default.
const _kDefaultLargeTxThreshold = 20000;

/// Cap on how long entries stay in the last-fired map. After this
/// long the underlying event (transaction, budget period) is
/// almost certainly outside any future eval window — keeping the
/// key around is dead weight.
const _kLastFiredRetention = Duration(days: 90);

@Riverpod(keepAlive: true)
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  @override
  NotificationSettings build() {
    _load();
    // Initial value before async load lands — must match the model's
    // defaults so the UI doesn't flash a different state on cold start.
    return const NotificationSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      enabled: prefs.getBool(_kEnabledKey) ?? false,
      budgetOverEnabled: prefs.getBool(_kBudgetOverKey) ?? true,
      largeTxEnabled: prefs.getBool(_kLargeTxKey) ?? true,
      largeTxThresholdCents:
          prefs.getInt(_kLargeTxThresholdKey) ?? _kDefaultLargeTxThreshold,
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }

  Future<void> setBudgetOverEnabled(bool value) async {
    state = state.copyWith(budgetOverEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBudgetOverKey, value);
  }

  Future<void> setLargeTxEnabled(bool value) async {
    state = state.copyWith(largeTxEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLargeTxKey, value);
  }

  Future<void> setLargeTxThresholdCents(int value) async {
    state = state.copyWith(largeTxThresholdCents: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLargeTxThresholdKey, value);
  }
}

/// Last-fired dedup map. Read by the engine to skip already-fired
/// keys; updated by the engine wrapper after the platform service
/// shows each notification.
///
/// Not a Riverpod state holder because the map is monotonically
/// growing and changes every dashboard load — a notifier would
/// re-render dependent widgets needlessly. Stays as plain async
/// reads + writes.
Future<Map<String, DateTime>> loadLastFired() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kLastFiredKey);
  if (raw == null || raw.isEmpty) return <String, DateTime>{};
  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        entry.key: DateTime.parse(entry.value as String),
    };
  } catch (_) {
    // Corrupted store — start fresh rather than wedge the engine.
    return <String, DateTime>{};
  }
}

/// Wipes the persisted last-fired map. Paired with
/// `NotificationLogRepository.clearAll` for the "Reset notification
/// history" affordance — without clearing both, the runner's merge
/// step would repopulate the local map from the server-side log on
/// the next pass.
Future<void> clearLastFired() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kLastFiredKey);
}

/// Appends [newlyFired] (key → now) to the persisted last-fired map
/// and prunes anything older than the retention window so the JSON
/// blob doesn't grow unbounded.
Future<void> recordFired({
  required Map<String, DateTime> existing,
  required Iterable<String> newKeys,
  required DateTime now,
}) async {
  final cutoff = now.subtract(_kLastFiredRetention);
  final merged = <String, DateTime>{
    for (final entry in existing.entries)
      if (entry.value.isAfter(cutoff)) entry.key: entry.value,
    for (final k in newKeys) k: now,
  };
  // .toUtc() so the stored ISO 8601 string is timezone-naive only in
  // the trailing 'Z' sense, not in the "wrong instant" sense. Bare
  // toIso8601String() on a local-zone DateTime emits the local wall
  // time as if it were UTC; if the dedup map ever syncs across
  // devices (or the host's timezone changes between writes and
  // reads), the prune cutoff comparison drifts by the offset. Same
  // bug class CLAUDE.md calls out for TIMESTAMPTZ writes.
  final encoded = jsonEncode({
    for (final entry in merged.entries)
      entry.key: entry.value.toUtc().toIso8601String(),
  });
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLastFiredKey, encoded);
}
