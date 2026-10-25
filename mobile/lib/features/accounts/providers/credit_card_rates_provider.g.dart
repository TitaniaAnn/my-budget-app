// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_rates_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(creditCardRates)
final creditCardRatesProvider = CreditCardRatesFamily._();

final class CreditCardRatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CreditCardRate>>,
          List<CreditCardRate>,
          FutureOr<List<CreditCardRate>>
        >
    with
        $FutureModifier<List<CreditCardRate>>,
        $FutureProvider<List<CreditCardRate>> {
  CreditCardRatesProvider._({
    required CreditCardRatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'creditCardRatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$creditCardRatesHash();

  @override
  String toString() {
    return r'creditCardRatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CreditCardRate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CreditCardRate>> create(Ref ref) {
    final argument = this.argument as String;
    return creditCardRates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CreditCardRatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$creditCardRatesHash() => r'83454d72be751361eed77b013b4aa8e03ce1dc7d';

final class CreditCardRatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<CreditCardRate>>, String> {
  CreditCardRatesFamily._()
    : super(
        retry: null,
        name: r'creditCardRatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CreditCardRatesProvider call(String accountId) =>
      CreditCardRatesProvider._(argument: accountId, from: this);

  @override
  String toString() => r'creditCardRatesProvider';
}
