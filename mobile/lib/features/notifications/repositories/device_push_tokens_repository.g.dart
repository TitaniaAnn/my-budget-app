// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_push_tokens_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(devicePushTokensRepository)
final devicePushTokensRepositoryProvider =
    DevicePushTokensRepositoryProvider._();

final class DevicePushTokensRepositoryProvider
    extends
        $FunctionalProvider<
          DevicePushTokensRepository,
          DevicePushTokensRepository,
          DevicePushTokensRepository
        >
    with $Provider<DevicePushTokensRepository> {
  DevicePushTokensRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'devicePushTokensRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$devicePushTokensRepositoryHash();

  @$internal
  @override
  $ProviderElement<DevicePushTokensRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DevicePushTokensRepository create(Ref ref) {
    return devicePushTokensRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DevicePushTokensRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DevicePushTokensRepository>(value),
    );
  }
}

String _$devicePushTokensRepositoryHash() =>
    r'10714a61159e17cf546f2d18972462e6389b3d34';
