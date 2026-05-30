// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_synced_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$lastSyncedAtHash() => r'becf985286ddbdd95f04ae89ed5a51b72f4e4a49';

/// See also [lastSyncedAt].
@ProviderFor(lastSyncedAt)
final lastSyncedAtProvider = AutoDisposeFutureProvider<DateTime?>.internal(
  lastSyncedAt,
  name: r'lastSyncedAtProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lastSyncedAtHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LastSyncedAtRef = AutoDisposeFutureProviderRef<DateTime?>;
String _$pendingWritesCountValueHash() =>
    r'cfc997ee9425049fe2d1cedf0244c0f846a48a6d';

/// Pending-writes count for the Settings sync surface (Phase 5c).
/// Plain (not keepAlive) so each settings open gets a fresh read.
///
/// Copied from [pendingWritesCountValue].
@ProviderFor(pendingWritesCountValue)
final pendingWritesCountValueProvider = AutoDisposeFutureProvider<int>.internal(
  pendingWritesCountValue,
  name: r'pendingWritesCountValueProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingWritesCountValueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingWritesCountValueRef = AutoDisposeFutureProviderRef<int>;
String _$pendingStorageUploadsCountValueHash() =>
    r'1aa0acf78645dcd3b1801d54f5bef7a7e36e87c3';

/// Pending storage-upload count for the Settings sync surface
/// (Phase 4b polish). Mirrors pendingWritesCountValue for the
/// receipt-image queue.
///
/// Copied from [pendingStorageUploadsCountValue].
@ProviderFor(pendingStorageUploadsCountValue)
final pendingStorageUploadsCountValueProvider =
    AutoDisposeFutureProvider<int>.internal(
      pendingStorageUploadsCountValue,
      name: r'pendingStorageUploadsCountValueProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingStorageUploadsCountValueHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingStorageUploadsCountValueRef = AutoDisposeFutureProviderRef<int>;
String _$pendingStorageUploadIdsHash() =>
    r'64d4e9159c4aeeecad3163d117b5a0c5678c1216';

/// Set of receipt ids currently sitting in the storage upload
/// queue (Phase 4b polish). Powers the "pending upload" badge on
/// the receipts grid. Plain (not keepAlive) so each grid render
/// gets a fresh read; the result is a tiny set (typically zero or
/// single-digit rows) so the read is cheap.
///
/// Copied from [pendingStorageUploadIds].
@ProviderFor(pendingStorageUploadIds)
final pendingStorageUploadIdsProvider =
    AutoDisposeFutureProvider<Set<String>>.internal(
      pendingStorageUploadIds,
      name: r'pendingStorageUploadIdsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingStorageUploadIdsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingStorageUploadIdsRef = AutoDisposeFutureProviderRef<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
