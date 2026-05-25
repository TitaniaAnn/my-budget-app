// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_runner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationDispatcherHash() =>
    r'af970aa6229148807d13e6273b849a0f5d271df9';

/// Indirection so tests can swap in a fake dispatcher. Production
/// returns the real flutter_local_notifications-backed singleton.
///
/// Copied from [notificationDispatcher].
@ProviderFor(notificationDispatcher)
final notificationDispatcherProvider =
    AutoDisposeProvider<LocalNotificationDispatcher>.internal(
      notificationDispatcher,
      name: r'notificationDispatcherProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationDispatcherHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationDispatcherRef =
    AutoDisposeProviderRef<LocalNotificationDispatcher>;
String _$runNotificationsHash() => r'00964f9ca59c13aabe19602367125f1f9f13ca70';

/// See also [runNotifications].
@ProviderFor(runNotifications)
final runNotificationsProvider = FutureProvider<int>.internal(
  runNotifications,
  name: r'runNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$runNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RunNotificationsRef = FutureProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
