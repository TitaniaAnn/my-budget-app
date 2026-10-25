// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_runner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Indirection so tests can swap in a fake dispatcher. Production
/// returns the real flutter_local_notifications-backed singleton.

@ProviderFor(notificationDispatcher)
final notificationDispatcherProvider = NotificationDispatcherProvider._();

/// Indirection so tests can swap in a fake dispatcher. Production
/// returns the real flutter_local_notifications-backed singleton.

final class NotificationDispatcherProvider
    extends
        $FunctionalProvider<
          LocalNotificationDispatcher,
          LocalNotificationDispatcher,
          LocalNotificationDispatcher
        >
    with $Provider<LocalNotificationDispatcher> {
  /// Indirection so tests can swap in a fake dispatcher. Production
  /// returns the real flutter_local_notifications-backed singleton.
  NotificationDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationDispatcherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationDispatcherHash();

  @$internal
  @override
  $ProviderElement<LocalNotificationDispatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalNotificationDispatcher create(Ref ref) {
    return notificationDispatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalNotificationDispatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalNotificationDispatcher>(value),
    );
  }
}

String _$notificationDispatcherHash() =>
    r'49b99630b7745ab62e4a96f9b1d78f56cbade679';

@ProviderFor(runNotifications)
final runNotificationsProvider = RunNotificationsProvider._();

final class RunNotificationsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  RunNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runNotificationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runNotificationsHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return runNotifications(ref);
  }
}

String _$runNotificationsHash() => r'9a3f74d29bea1b8591feaebe699f25baaae1de9c';
