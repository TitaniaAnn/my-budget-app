// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_rates_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$creditCardRatesHash() => r'509a4ea81f861698f2fdecc4b722322acba36a13';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [creditCardRates].
@ProviderFor(creditCardRates)
const creditCardRatesProvider = CreditCardRatesFamily();

/// See also [creditCardRates].
class CreditCardRatesFamily extends Family<AsyncValue<List<CreditCardRate>>> {
  /// See also [creditCardRates].
  const CreditCardRatesFamily();

  /// See also [creditCardRates].
  CreditCardRatesProvider call(String accountId) {
    return CreditCardRatesProvider(accountId);
  }

  @override
  CreditCardRatesProvider getProviderOverride(
    covariant CreditCardRatesProvider provider,
  ) {
    return call(provider.accountId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'creditCardRatesProvider';
}

/// See also [creditCardRates].
class CreditCardRatesProvider
    extends AutoDisposeFutureProvider<List<CreditCardRate>> {
  /// See also [creditCardRates].
  CreditCardRatesProvider(String accountId)
    : this._internal(
        (ref) => creditCardRates(ref as CreditCardRatesRef, accountId),
        from: creditCardRatesProvider,
        name: r'creditCardRatesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$creditCardRatesHash,
        dependencies: CreditCardRatesFamily._dependencies,
        allTransitiveDependencies:
            CreditCardRatesFamily._allTransitiveDependencies,
        accountId: accountId,
      );

  CreditCardRatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.accountId,
  }) : super.internal();

  final String accountId;

  @override
  Override overrideWith(
    FutureOr<List<CreditCardRate>> Function(CreditCardRatesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CreditCardRatesProvider._internal(
        (ref) => create(ref as CreditCardRatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        accountId: accountId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<CreditCardRate>> createElement() {
    return _CreditCardRatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreditCardRatesProvider && other.accountId == accountId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, accountId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CreditCardRatesRef on AutoDisposeFutureProviderRef<List<CreditCardRate>> {
  /// The parameter `accountId` of this provider.
  String get accountId;
}

class _CreditCardRatesProviderElement
    extends AutoDisposeFutureProviderElement<List<CreditCardRate>>
    with CreditCardRatesRef {
  _CreditCardRatesProviderElement(super.provider);

  @override
  String get accountId => (origin as CreditCardRatesProvider).accountId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
