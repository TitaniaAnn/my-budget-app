// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plaid_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$plaidItemsHash() => r'f2f95148626d8806f37518d35352100e644b32d5';

/// See also [plaidItems].
@ProviderFor(plaidItems)
final plaidItemsProvider = AutoDisposeFutureProvider<List<PlaidItem>>.internal(
  plaidItems,
  name: r'plaidItemsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$plaidItemsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaidItemsRef = AutoDisposeFutureProviderRef<List<PlaidItem>>;
String _$plaidSyncOrchestratorHash() =>
    r'3e4bb3527f9b7dfad46f21705e38ad7a44489334';

/// See also [plaidSyncOrchestrator].
@ProviderFor(plaidSyncOrchestrator)
final plaidSyncOrchestratorProvider = Provider<PlaidSyncOrchestrator>.internal(
  plaidSyncOrchestrator,
  name: r'plaidSyncOrchestratorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$plaidSyncOrchestratorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaidSyncOrchestratorRef = ProviderRef<PlaidSyncOrchestrator>;
String _$plaidSyncTriggerHash() => r'fd83dc562e2985d83bb099353c915fcaee89ce4b';

/// Fires syncAll() once per app process. Same pattern as
/// runRecurringSchedulerProvider — keepAlive so a subsequent
/// dashboard load doesn't re-fire, and a pull-to-refresh
/// invalidates this provider to force another run.
///
/// Returns the [PlaidSyncSummary] so callers can show a
/// post-sync toast or banner; null when there are no items
/// (don't bother dispatching).
///
/// Copied from [plaidSyncTrigger].
@ProviderFor(plaidSyncTrigger)
final plaidSyncTriggerProvider = FutureProvider<PlaidSyncSummary?>.internal(
  plaidSyncTrigger,
  name: r'plaidSyncTriggerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$plaidSyncTriggerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PlaidSyncTriggerRef = FutureProviderRef<PlaidSyncSummary?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
