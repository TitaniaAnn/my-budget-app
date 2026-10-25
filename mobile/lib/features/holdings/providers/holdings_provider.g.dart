// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holdings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All holdings inside [accountId]. Family-keyed so navigating
/// between two investment accounts gets each its own cache slot.

@ProviderFor(holdingsForAccount)
final holdingsForAccountProvider = HoldingsForAccountFamily._();

/// All holdings inside [accountId]. Family-keyed so navigating
/// between two investment accounts gets each its own cache slot.

final class HoldingsForAccountProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Holding>>,
          List<Holding>,
          FutureOr<List<Holding>>
        >
    with $FutureModifier<List<Holding>>, $FutureProvider<List<Holding>> {
  /// All holdings inside [accountId]. Family-keyed so navigating
  /// between two investment accounts gets each its own cache slot.
  HoldingsForAccountProvider._({
    required HoldingsForAccountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'holdingsForAccountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$holdingsForAccountHash();

  @override
  String toString() {
    return r'holdingsForAccountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Holding>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Holding>> create(Ref ref) {
    final argument = this.argument as String;
    return holdingsForAccount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HoldingsForAccountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$holdingsForAccountHash() =>
    r'3a8369a904ed69505dfff0feee463d32b8eb85f9';

/// All holdings inside [accountId]. Family-keyed so navigating
/// between two investment accounts gets each its own cache slot.

final class HoldingsForAccountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Holding>>, String> {
  HoldingsForAccountFamily._()
    : super(
        retry: null,
        name: r'holdingsForAccountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// All holdings inside [accountId]. Family-keyed so navigating
  /// between two investment accounts gets each its own cache slot.

  HoldingsForAccountProvider call(String accountId) =>
      HoldingsForAccountProvider._(argument: accountId, from: this);

  @override
  String toString() => r'holdingsForAccountProvider';
}

/// Every holding across every investment account in the current
/// household. Powers the dashboard's asset-allocation donut.

@ProviderFor(householdHoldings)
final householdHoldingsProvider = HouseholdHoldingsProvider._();

/// Every holding across every investment account in the current
/// household. Powers the dashboard's asset-allocation donut.

final class HouseholdHoldingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Holding>>,
          List<Holding>,
          FutureOr<List<Holding>>
        >
    with $FutureModifier<List<Holding>>, $FutureProvider<List<Holding>> {
  /// Every holding across every investment account in the current
  /// household. Powers the dashboard's asset-allocation donut.
  HouseholdHoldingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdHoldingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdHoldingsHash();

  @$internal
  @override
  $FutureProviderElement<List<Holding>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Holding>> create(Ref ref) {
    return householdHoldings(ref);
  }
}

String _$householdHoldingsHash() => r'4781bf5d346b1df31576e59071e743be999f7b51';

/// Total current value (cents) per [AssetClass], computed from
/// [householdHoldingsProvider]. Holdings with no asset_class are
/// bucketed under [AssetClass.other] so the donut never has an
/// unlabelled slice. Returned as a sorted list (largest slice
/// first) — that's the convention the donut renders against.

@ProviderFor(assetAllocation)
final assetAllocationProvider = AssetAllocationProvider._();

/// Total current value (cents) per [AssetClass], computed from
/// [householdHoldingsProvider]. Holdings with no asset_class are
/// bucketed under [AssetClass.other] so the donut never has an
/// unlabelled slice. Returned as a sorted list (largest slice
/// first) — that's the convention the donut renders against.

final class AssetAllocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<({AssetClass assetClass, int totalCents})>>,
          List<({AssetClass assetClass, int totalCents})>,
          FutureOr<List<({AssetClass assetClass, int totalCents})>>
        >
    with
        $FutureModifier<List<({AssetClass assetClass, int totalCents})>>,
        $FutureProvider<List<({AssetClass assetClass, int totalCents})>> {
  /// Total current value (cents) per [AssetClass], computed from
  /// [householdHoldingsProvider]. Holdings with no asset_class are
  /// bucketed under [AssetClass.other] so the donut never has an
  /// unlabelled slice. Returned as a sorted list (largest slice
  /// first) — that's the convention the donut renders against.
  AssetAllocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assetAllocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assetAllocationHash();

  @$internal
  @override
  $FutureProviderElement<List<({AssetClass assetClass, int totalCents})>>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<({AssetClass assetClass, int totalCents})>> create(Ref ref) {
    return assetAllocation(ref);
  }
}

String _$assetAllocationHash() => r'fc8181a66525b8cb1a8637060b2eabbaf450712e';
