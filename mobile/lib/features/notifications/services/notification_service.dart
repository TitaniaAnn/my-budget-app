// Thin wrapper around flutter_local_notifications.
//
// The platform plugin needs:
//   * one-time init (channels on Android, presentation options on iOS);
//   * an explicit permission request — iOS always needs it; Android
//     13+ requires the POST_NOTIFICATIONS runtime permission;
//   * a `show(title, body)` shortcut for the engine's pending list.
//
// Kept off the pure side of the engine on purpose: the engine
// decides WHAT to fire and is unit-testable; this wrapper turns
// that decision into platform calls and is mocked out / skipped in
// tests.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Narrow surface the runner provider depends on — just the two
/// methods it actually calls. Exists so a unit test can override
/// the dispatcher without dragging in the real
/// flutter_local_notifications plugin (which crashes outside the
/// platform binding).
abstract class LocalNotificationDispatcher {
  Future<void> ensureInitialized();
  Future<void> show({
    required String tag,
    required String title,
    required String body,
  });
}

class NotificationService implements LocalNotificationDispatcher {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Stable channel id used for every alert this app fires. We don't
  /// split per-trigger because the user-facing controls already let
  /// them toggle each trigger independently — a second axis of
  /// Android channels would just duplicate that.
  static const _channelId = 'mybudget_alerts';
  static const _channelName = 'Budget alerts';
  static const _channelDescription =
      'Budget overruns, large transactions, and other in-app alerts.';

  /// Initialises the platform plugin. Idempotent — repeated calls
  /// are no-ops, so wiring this from multiple cold-start paths is
  /// safe.
  @override
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        // Don't auto-request iOS permission on init — the settings
        // toggle drives that explicitly so the prompt lands at a
        // moment the user expects it.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);

    // Android needs the channel created up front (idempotent).
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.defaultImportance,
      ),
    );
    _initialized = true;
  }

  /// Requests OS-level notification permission. Returns true when
  /// granted. Called from the settings toggle so the user sees the
  /// system prompt at the moment they're asking for it.
  Future<bool> requestPermission() async {
    await ensureInitialized();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      // Android 13+ runtime permission. Older Androids grant
      // implicitly via the manifest — the plugin returns null in
      // that case, which we treat as "granted."
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  /// Shows a notification with [title] and [body]. The notification
  /// id is the [hashCode] of [tag] — same tag fires update-in-place
  /// rather than stacking duplicates if the engine somehow asked
  /// twice in quick succession.
  @override
  Future<void> show({
    required String tag,
    required String title,
    required String body,
  }) async {
    await ensureInitialized();
    await _plugin.show(
      tag.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
