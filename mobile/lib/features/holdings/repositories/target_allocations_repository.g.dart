// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_allocations_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(targetAllocationsRepository)
final targetAllocationsRepositoryProvider =
    TargetAllocationsRepositoryProvider._();

final class TargetAllocationsRepositoryProvider
    extends
        $FunctionalProvider<
          TargetAllocationsRepository,
          TargetAllocationsRepository,
          TargetAllocationsRepository
        >
    with $Provider<TargetAllocationsRepository> {
  TargetAllocationsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'targetAllocationsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$targetAllocationsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TargetAllocationsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TargetAllocationsRepository create(Ref ref) {
    return targetAllocationsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TargetAllocationsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TargetAllocationsRepository>(value),
    );
  }
}

String _$targetAllocationsRepositoryHash() =>
    r'8e6701b1db3c410dd2ddae423541a442f0cbbe11';
