// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_rates_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(creditCardRatesRepository)
final creditCardRatesRepositoryProvider = CreditCardRatesRepositoryProvider._();

final class CreditCardRatesRepositoryProvider
    extends
        $FunctionalProvider<
          CreditCardRatesRepository,
          CreditCardRatesRepository,
          CreditCardRatesRepository
        >
    with $Provider<CreditCardRatesRepository> {
  CreditCardRatesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creditCardRatesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creditCardRatesRepositoryHash();

  @$internal
  @override
  $ProviderElement<CreditCardRatesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CreditCardRatesRepository create(Ref ref) {
    return creditCardRatesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreditCardRatesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreditCardRatesRepository>(value),
    );
  }
}

String _$creditCardRatesRepositoryHash() =>
    r'cb6058ebd7e4b09993bc610a6f64ce86b7614244';
