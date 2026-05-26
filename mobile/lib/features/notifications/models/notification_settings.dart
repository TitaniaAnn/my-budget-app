// User-controlled toggles + threshold for the local-notifications
// engine. Plain immutable data; the SharedPreferences-backed
// provider in `providers/notification_settings_provider.dart` is
// what loads / persists.
//
// All flags default OFF so a fresh install doesn't surprise the
// user with notifications they never asked for. The settings screen
// requests OS permission the first time the master toggle is
// flipped on.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings.freezed.dart';

/// Audit T2: was a hand-rolled value class with `copyWith` but no
/// `==` / `hashCode`. `state = state.copyWith(enabled: true)`
/// produced fresh identity even when the value didn't change. No
/// observable bug today (nobody uses `.select`), but the moment
/// someone does, the selector would misfire on every prefs save.
/// Converted to `@freezed` per project convention.
@freezed
class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    /// Master switch. When false, the engine returns no notifications
    /// regardless of the per-trigger toggles. Lets the user silence
    /// everything in one tap without losing their other preferences.
    @Default(false) bool enabled,

    /// Fire when a category budget's actual spend exceeds the cap.
    @Default(true) bool budgetOverEnabled,

    /// Fire when a transaction's |amount| crosses [largeTxThresholdCents].
    @Default(true) bool largeTxEnabled,

    /// Magnitude in cents at or above which a transaction triggers a
    /// large-transaction notification. Default $200; the settings
    /// screen lets the user adjust.
    @Default(20000) int largeTxThresholdCents,
  }) = _NotificationSettings;
}

/// Output of the evaluation pass — a notification the engine wants
/// to fire. The platform service turns this into an OS notification;
/// [key] is what the engine writes to the last-fired map for dedup.
class PendingNotification {
  const PendingNotification({
    required this.key,
    required this.title,
    required this.body,
  });

  /// Stable identifier for the underlying event. Keys are namespaced
  /// (e.g. `budget_over:<budget_id>:<period_from>`) so the same kind
  /// of event in a fresh period or on a fresh row gets a distinct
  /// entry.
  final String key;

  final String title;
  final String body;
}
