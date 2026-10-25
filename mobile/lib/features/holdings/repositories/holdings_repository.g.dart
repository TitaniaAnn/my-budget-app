// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holdings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(holdingsRepository)
final holdingsRepositoryProvider = HoldingsRepositoryProvider._();

final class HoldingsRepositoryProvider
    extends
        $FunctionalProvider<
          HoldingsRepository,
          HoldingsRepository,
          HoldingsRepository
        >
    with $Provider<HoldingsRepository> {
  HoldingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'holdingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$holdingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<HoldingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HoldingsRepository create(Ref ref) {
    return holdingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HoldingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HoldingsRepository>(value),
    );
  }
}

String _$holdingsRepositoryHash() =>
    r'd1e40b68c50ad3fa9b636f29d6391d834ea2dbb3';
