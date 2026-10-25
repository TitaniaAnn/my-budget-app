// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_synced_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lastSyncedAt)
final lastSyncedAtProvider = LastSyncedAtProvider._();

final class LastSyncedAtProvider
    extends
        $FunctionalProvider<
          AsyncValue<DateTime?>,
          DateTime?,
          FutureOr<DateTime?>
        >
    with $FutureModifier<DateTime?>, $FutureProvider<DateTime?> {
  LastSyncedAtProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastSyncedAtProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastSyncedAtHash();

  @$internal
  @override
  $FutureProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DateTime?> create(Ref ref) {
    return lastSyncedAt(ref);
  }
}

String _$lastSyncedAtHash() => r'ccf6c4bcbccd1c9db646427107c966e22f10619b';

/// Pending-writes count for the Settings sync surface (Phase 5c).
/// Plain (not keepAlive) so each settings open gets a fresh read.

@ProviderFor(pendingWritesCountValue)
final pendingWritesCountValueProvider = PendingWritesCountValueProvider._();

/// Pending-writes count for the Settings sync surface (Phase 5c).
/// Plain (not keepAlive) so each settings open gets a fresh read.

final class PendingWritesCountValueProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Pending-writes count for the Settings sync surface (Phase 5c).
  /// Plain (not keepAlive) so each settings open gets a fresh read.
  PendingWritesCountValueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingWritesCountValueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingWritesCountValueHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pendingWritesCountValue(ref);
  }
}

String _$pendingWritesCountValueHash() =>
    r'3149ab2b9b04cac7d7fb5b5833f8480cf0e1b30d';

/// Pending storage-upload count for the Settings sync surface
/// (Phase 4b polish). Mirrors pendingWritesCountValue for the
/// receipt-image queue.

@ProviderFor(pendingStorageUploadsCountValue)
final pendingStorageUploadsCountValueProvider =
    PendingStorageUploadsCountValueProvider._();

/// Pending storage-upload count for the Settings sync surface
/// (Phase 4b polish). Mirrors pendingWritesCountValue for the
/// receipt-image queue.

final class PendingStorageUploadsCountValueProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Pending storage-upload count for the Settings sync surface
  /// (Phase 4b polish). Mirrors pendingWritesCountValue for the
  /// receipt-image queue.
  PendingStorageUploadsCountValueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingStorageUploadsCountValueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingStorageUploadsCountValueHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return pendingStorageUploadsCountValue(ref);
  }
}

String _$pendingStorageUploadsCountValueHash() =>
    r'789703a13bfd45f690736e734e8bf1fd346a92c6';

/// Set of receipt ids currently sitting in the storage upload
/// queue (Phase 4b polish). Powers the "pending upload" badge on
/// the receipts grid. Plain (not keepAlive) so each grid render
/// gets a fresh read; the result is a tiny set (typically zero or
/// single-digit rows) so the read is cheap.

@ProviderFor(pendingStorageUploadIds)
final pendingStorageUploadIdsProvider = PendingStorageUploadIdsProvider._();

/// Set of receipt ids currently sitting in the storage upload
/// queue (Phase 4b polish). Powers the "pending upload" badge on
/// the receipts grid. Plain (not keepAlive) so each grid render
/// gets a fresh read; the result is a tiny set (typically zero or
/// single-digit rows) so the read is cheap.

final class PendingStorageUploadIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// Set of receipt ids currently sitting in the storage upload
  /// queue (Phase 4b polish). Powers the "pending upload" badge on
  /// the receipts grid. Plain (not keepAlive) so each grid render
  /// gets a fresh read; the result is a tiny set (typically zero or
  /// single-digit rows) so the read is cheap.
  PendingStorageUploadIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingStorageUploadIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingStorageUploadIdsHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return pendingStorageUploadIds(ref);
  }
}

String _$pendingStorageUploadIdsHash() =>
    r'b5f172bb186d2d0306ad83bcc9944131f543ccd5';
