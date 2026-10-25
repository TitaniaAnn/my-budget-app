// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_log_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificationLogRepository)
final notificationLogRepositoryProvider = NotificationLogRepositoryProvider._();

final class NotificationLogRepositoryProvider
    extends
        $FunctionalProvider<
          NotificationLogRepository,
          NotificationLogRepository,
          NotificationLogRepository
        >
    with $Provider<NotificationLogRepository> {
  NotificationLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationLogRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationLogRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationLogRepository create(Ref ref) {
    return notificationLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationLogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationLogRepository>(value),
    );
  }
}

String _$notificationLogRepositoryHash() =>
    r'05cebce6a656a7c6150f49e17d148dcc55712a60';
