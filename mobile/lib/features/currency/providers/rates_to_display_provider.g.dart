// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rates_to_display_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// {from-currency → rate} where rate converts INTO the household's
/// display currency. Picks the most recent rate per (from, display)
/// pair — `fetchAll` orders newest-first by `as_of_date`, so
/// `putIfAbsent` latches onto the latest row.
///
/// Empty map for USD-only households (no fx_rates rows OR every
/// rate's `to_currency` doesn't match display). Callers treat
/// missing entries as "exclude this currency, don't lie at rate=1"
/// per the project-wide multi-currency contract.

@ProviderFor(ratesToDisplay)
final ratesToDisplayProvider = RatesToDisplayProvider._();

/// {from-currency → rate} where rate converts INTO the household's
/// display currency. Picks the most recent rate per (from, display)
/// pair — `fetchAll` orders newest-first by `as_of_date`, so
/// `putIfAbsent` latches onto the latest row.
///
/// Empty map for USD-only households (no fx_rates rows OR every
/// rate's `to_currency` doesn't match display). Callers treat
/// missing entries as "exclude this currency, don't lie at rate=1"
/// per the project-wide multi-currency contract.

final class RatesToDisplayProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, double>>,
          Map<String, double>,
          FutureOr<Map<String, double>>
        >
    with
        $FutureModifier<Map<String, double>>,
        $FutureProvider<Map<String, double>> {
  /// {from-currency → rate} where rate converts INTO the household's
  /// display currency. Picks the most recent rate per (from, display)
  /// pair — `fetchAll` orders newest-first by `as_of_date`, so
  /// `putIfAbsent` latches onto the latest row.
  ///
  /// Empty map for USD-only households (no fx_rates rows OR every
  /// rate's `to_currency` doesn't match display). Callers treat
  /// missing entries as "exclude this currency, don't lie at rate=1"
  /// per the project-wide multi-currency contract.
  RatesToDisplayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ratesToDisplayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ratesToDisplayHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, double>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, double>> create(Ref ref) {
    return ratesToDisplay(ref);
  }
}

String _$ratesToDisplayHash() => r'655d3e6d42fd33a30695165ac4e98287cdb1e953';
