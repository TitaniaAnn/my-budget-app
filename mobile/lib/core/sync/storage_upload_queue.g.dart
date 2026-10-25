// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_upload_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(storageUploadQueue)
final storageUploadQueueProvider = StorageUploadQueueProvider._();

final class StorageUploadQueueProvider
    extends
        $FunctionalProvider<
          StorageUploadQueue,
          StorageUploadQueue,
          StorageUploadQueue
        >
    with $Provider<StorageUploadQueue> {
  StorageUploadQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageUploadQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageUploadQueueHash();

  @$internal
  @override
  $ProviderElement<StorageUploadQueue> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StorageUploadQueue create(Ref ref) {
    return storageUploadQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageUploadQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageUploadQueue>(value),
    );
  }
}

String _$storageUploadQueueHash() =>
    r'18085ff4e727867f0485c36c3032c45485072b7c';

/// Side-effect provider: drains the storage queue on the
/// false→true connectivity edge. keepAlive so the listener
/// subscription is process-lifetime. Same pattern as
/// PendingWritesAutoDrain.

@ProviderFor(StorageUploadAutoDrain)
final storageUploadAutoDrainProvider = StorageUploadAutoDrainProvider._();

/// Side-effect provider: drains the storage queue on the
/// false→true connectivity edge. keepAlive so the listener
/// subscription is process-lifetime. Same pattern as
/// PendingWritesAutoDrain.
final class StorageUploadAutoDrainProvider
    extends $NotifierProvider<StorageUploadAutoDrain, void> {
  /// Side-effect provider: drains the storage queue on the
  /// false→true connectivity edge. keepAlive so the listener
  /// subscription is process-lifetime. Same pattern as
  /// PendingWritesAutoDrain.
  StorageUploadAutoDrainProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageUploadAutoDrainProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageUploadAutoDrainHash();

  @$internal
  @override
  StorageUploadAutoDrain create() => StorageUploadAutoDrain();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$storageUploadAutoDrainHash() =>
    r'8590bfef81b2f22a464357d59802a6f68cdcbd20';

/// Side-effect provider: drains the storage queue on the
/// false→true connectivity edge. keepAlive so the listener
/// subscription is process-lifetime. Same pattern as
/// PendingWritesAutoDrain.

abstract class _$StorageUploadAutoDrain extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
