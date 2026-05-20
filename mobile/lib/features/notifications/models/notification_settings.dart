// User-controlled toggles + threshold for the local-notifications
// engine. Plain immutable data; the SharedPreferences-backed
// provider in `providers/notification_settings_provider.dart` is
// what loads / persists.
//
// All flags default OFF so a fresh install doesn't surprise the
// user with notifications they never asked for. The settings screen
// requests OS permission the first time the master toggle is
// flipped on.

class NotificationSettings {
  const NotificationSettings({
    this.enabled = false,
    this.budgetOverEnabled = true,
    this.largeTxEnabled = true,
    this.largeTxThresholdCents = 20000,
  });

  /// Master switch. When false, the engine returns no notifications
  /// regardless of the per-trigger toggles. Lets the user silence
  /// everything in one tap without losing their other preferences.
  final bool enabled;

  /// Fire when a category budget's actual spend exceeds the cap.
  final bool budgetOverEnabled;

  /// Fire when a transaction's |amount| crosses [largeTxThresholdCents].
  final bool largeTxEnabled;

  /// Magnitude in cents at or above which a transaction triggers a
  /// large-transaction notification. Default $200; the settings
  /// screen lets the user adjust.
  final int largeTxThresholdCents;

  NotificationSettings copyWith({
    bool? enabled,
    bool? budgetOverEnabled,
    bool? largeTxEnabled,
    int? largeTxThresholdCents,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      budgetOverEnabled: budgetOverEnabled ?? this.budgetOverEnabled,
      largeTxEnabled: largeTxEnabled ?? this.largeTxEnabled,
      largeTxThresholdCents:
          largeTxThresholdCents ?? this.largeTxThresholdCents,
    );
  }
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
