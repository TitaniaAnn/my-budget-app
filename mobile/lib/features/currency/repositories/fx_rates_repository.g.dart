// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fx_rates_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fxRatesRepository)
final fxRatesRepositoryProvider = FxRatesRepositoryProvider._();

final class FxRatesRepositoryProvider
    extends
        $FunctionalProvider<
          FxRatesRepository,
          FxRatesRepository,
          FxRatesRepository
        >
    with $Provider<FxRatesRepository> {
  FxRatesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fxRatesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fxRatesRepositoryHash();

  @$internal
  @override
  $ProviderElement<FxRatesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FxRatesRepository create(Ref ref) {
    return fxRatesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FxRatesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FxRatesRepository>(value),
    );
  }
}

String _$fxRatesRepositoryHash() => r'6b7d446c693279681eb205ef2da8fc25903b4c93';
