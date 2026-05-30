// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_upload_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$storageUploadQueueHash() =>
    r'dad27339c5759e54077191dd4fe981a4216ca9db';

/// See also [storageUploadQueue].
@ProviderFor(storageUploadQueue)
final storageUploadQueueProvider = Provider<StorageUploadQueue>.internal(
  storageUploadQueue,
  name: r'storageUploadQueueProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$storageUploadQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StorageUploadQueueRef = ProviderRef<StorageUploadQueue>;
String _$storageUploadAutoDrainHash() =>
    r'8590bfef81b2f22a464357d59802a6f68cdcbd20';

/// Side-effect provider: drains the storage queue on the
/// false→true connectivity edge. keepAlive so the listener
/// subscription is process-lifetime. Same pattern as
/// PendingWritesAutoDrain.
///
/// Copied from [StorageUploadAutoDrain].
@ProviderFor(StorageUploadAutoDrain)
final storageUploadAutoDrainProvider =
    NotifierProvider<StorageUploadAutoDrain, void>.internal(
      StorageUploadAutoDrain.new,
      name: r'storageUploadAutoDrainProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$storageUploadAutoDrainHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StorageUploadAutoDrain = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
