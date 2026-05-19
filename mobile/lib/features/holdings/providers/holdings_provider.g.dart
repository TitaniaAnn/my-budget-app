// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holdings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$holdingsForAccountHash() =>
    r'4c9ea4c5db844aaa94704282860c632dd7a2fc62';

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

/// All holdings inside [accountId]. Family-keyed so navigating
/// between two investment accounts gets each its own cache slot.
///
/// Copied from [holdingsForAccount].
@ProviderFor(holdingsForAccount)
const holdingsForAccountProvider = HoldingsForAccountFamily();

/// All holdings inside [accountId]. Family-keyed so navigating
/// between two investment accounts gets each its own cache slot.
///
/// Copied from [holdingsForAccount].
class HoldingsForAccountFamily extends Family<AsyncValue<List<Holding>>> {
  /// All holdings inside [accountId]. Family-keyed so navigating
  /// between two investment accounts gets each its own cache slot.
  ///
  /// Copied from [holdingsForAccount].
  const HoldingsForAccountFamily();

  /// All holdings inside [accountId]. Family-keyed so navigating
  /// between two investment accounts gets each its own cache slot.
  ///
  /// Copied from [holdingsForAccount].
  HoldingsForAccountProvider call(String accountId) {
    return HoldingsForAccountProvider(accountId);
  }

  @override
  HoldingsForAccountProvider getProviderOverride(
    covariant HoldingsForAccountProvider provider,
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
  String? get name => r'holdingsForAccountProvider';
}

/// All holdings inside [accountId]. Family-keyed so navigating
/// between two investment accounts gets each its own cache slot.
///
/// Copied from [holdingsForAccount].
class HoldingsForAccountProvider
    extends AutoDisposeFutureProvider<List<Holding>> {
  /// All holdings inside [accountId]. Family-keyed so navigating
  /// between two investment accounts gets each its own cache slot.
  ///
  /// Copied from [holdingsForAccount].
  HoldingsForAccountProvider(String accountId)
    : this._internal(
        (ref) => holdingsForAccount(ref as HoldingsForAccountRef, accountId),
        from: holdingsForAccountProvider,
        name: r'holdingsForAccountProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$holdingsForAccountHash,
        dependencies: HoldingsForAccountFamily._dependencies,
        allTransitiveDependencies:
            HoldingsForAccountFamily._allTransitiveDependencies,
        accountId: accountId,
      );

  HoldingsForAccountProvider._internal(
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
    FutureOr<List<Holding>> Function(HoldingsForAccountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HoldingsForAccountProvider._internal(
        (ref) => create(ref as HoldingsForAccountRef),
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
  AutoDisposeFutureProviderElement<List<Holding>> createElement() {
    return _HoldingsForAccountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HoldingsForAccountProvider && other.accountId == accountId;
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
mixin HoldingsForAccountRef on AutoDisposeFutureProviderRef<List<Holding>> {
  /// The parameter `accountId` of this provider.
  String get accountId;
}

class _HoldingsForAccountProviderElement
    extends AutoDisposeFutureProviderElement<List<Holding>>
    with HoldingsForAccountRef {
  _HoldingsForAccountProviderElement(super.provider);

  @override
  String get accountId => (origin as HoldingsForAccountProvider).accountId;
}

String _$householdHoldingsHash() => r'c3238dacc39755389bf0caa6c2f402fbeb24bf2a';

/// Every holding across every investment account in the current
/// household. Powers the dashboard's asset-allocation donut.
///
/// Copied from [householdHoldings].
@ProviderFor(householdHoldings)
final householdHoldingsProvider =
    AutoDisposeFutureProvider<List<Holding>>.internal(
      householdHoldings,
      name: r'householdHoldingsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$householdHoldingsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HouseholdHoldingsRef = AutoDisposeFutureProviderRef<List<Holding>>;
String _$assetAllocationHash() => r'd5351d07e423dd30a4a30240bed433dc3805bb66';

/// Total current value (cents) per [AssetClass], computed from
/// [householdHoldingsProvider]. Holdings with no asset_class are
/// bucketed under [AssetClass.other] so the donut never has an
/// unlabelled slice. Returned as a sorted list (largest slice
/// first) — that's the convention the donut renders against.
///
/// Copied from [assetAllocation].
@ProviderFor(assetAllocation)
final assetAllocationProvider =
    AutoDisposeFutureProvider<
      List<({AssetClass assetClass, int totalCents})>
    >.internal(
      assetAllocation,
      name: r'assetAllocationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$assetAllocationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AssetAllocationRef =
    AutoDisposeFutureProviderRef<
      List<({AssetClass assetClass, int totalCents})>
    >;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
