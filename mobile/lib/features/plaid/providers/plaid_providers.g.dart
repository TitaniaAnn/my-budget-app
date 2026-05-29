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
String _$plaidSyncTriggerHash() => r'b1af6faa237ea8a0d434d151b9746bef1a376800';

/// Fires syncAll() once per app process. Same pattern as
/// runRecurringSchedulerProvider — keepAlive so a subsequent
/// dashboard load doesn't re-fire, and a pull-to-refresh
/// invalidates this provider to force another run.
///
/// Returns the [PlaidSyncSummary] so callers can show a
/// post-sync toast or banner; null when there are no items
/// (don't bother dispatching).
///
/// When the summary reports unhealthy items (re-auth needed,
/// hard failure, or partial-failure on the cursor-gated path
/// — review fix #2), this provider self-invalidates after a
/// short delay so the NEXT dashboard load re-attempts the sync.
/// Without this, a transient partial-failure (RLS hiccup, pool
/// exhaustion) would stay cached for the rest of the app
/// session and the cursor-held deltas would only retry on a
/// full app restart.
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
