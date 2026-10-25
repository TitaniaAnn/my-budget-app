// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncCoordinator)
final syncCoordinatorProvider = SyncCoordinatorProvider._();

final class SyncCoordinatorProvider
    extends
        $FunctionalProvider<SyncCoordinator, SyncCoordinator, SyncCoordinator>
    with $Provider<SyncCoordinator> {
  SyncCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncCoordinatorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncCoordinatorHash();

  @$internal
  @override
  $ProviderElement<SyncCoordinator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncCoordinator create(Ref ref) {
    return syncCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncCoordinator>(value),
    );
  }
}

String _$syncCoordinatorHash() => r'479d6768807c154efc7166a50e89c1c58591be7c';
