// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rates_to_display_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ratesToDisplayHash() => r'c35f1ec73734d3a152ac16e505e7c02367b16e16';

/// {from-currency → rate} where rate converts INTO the household's
/// display currency. Picks the most recent rate per (from, display)
/// pair — `fetchAll` orders newest-first by `as_of_date`, so
/// `putIfAbsent` latches onto the latest row.
///
/// Empty map for USD-only households (no fx_rates rows OR every
/// rate's `to_currency` doesn't match display). Callers treat
/// missing entries as "exclude this currency, don't lie at rate=1"
/// per the project-wide multi-currency contract.
///
/// Copied from [ratesToDisplay].
@ProviderFor(ratesToDisplay)
final ratesToDisplayProvider =
    AutoDisposeFutureProvider<Map<String, double>>.internal(
      ratesToDisplay,
      name: r'ratesToDisplayProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$ratesToDisplayHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RatesToDisplayRef = AutoDisposeFutureProviderRef<Map<String, double>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
