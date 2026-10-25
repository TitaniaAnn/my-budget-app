// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plaid_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(plaidItems)
final plaidItemsProvider = PlaidItemsProvider._();

final class PlaidItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaidItem>>,
          List<PlaidItem>,
          FutureOr<List<PlaidItem>>
        >
    with $FutureModifier<List<PlaidItem>>, $FutureProvider<List<PlaidItem>> {
  PlaidItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plaidItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plaidItemsHash();

  @$internal
  @override
  $FutureProviderElement<List<PlaidItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlaidItem>> create(Ref ref) {
    return plaidItems(ref);
  }
}

String _$plaidItemsHash() => r'408d263b22530bc422526156c3953acc55542f52';

@ProviderFor(plaidSyncOrchestrator)
final plaidSyncOrchestratorProvider = PlaidSyncOrchestratorProvider._();

final class PlaidSyncOrchestratorProvider
    extends
        $FunctionalProvider<
          PlaidSyncOrchestrator,
          PlaidSyncOrchestrator,
          PlaidSyncOrchestrator
        >
    with $Provider<PlaidSyncOrchestrator> {
  PlaidSyncOrchestratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plaidSyncOrchestratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plaidSyncOrchestratorHash();

  @$internal
  @override
  $ProviderElement<PlaidSyncOrchestrator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlaidSyncOrchestrator create(Ref ref) {
    return plaidSyncOrchestrator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaidSyncOrchestrator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaidSyncOrchestrator>(value),
    );
  }
}

String _$plaidSyncOrchestratorHash() =>
    r'7926662c61310b7976c9d20e54f66abcdc4773f9';

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

@ProviderFor(plaidSyncTrigger)
final plaidSyncTriggerProvider = PlaidSyncTriggerProvider._();

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

final class PlaidSyncTriggerProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlaidSyncSummary?>,
          PlaidSyncSummary?,
          FutureOr<PlaidSyncSummary?>
        >
    with
        $FutureModifier<PlaidSyncSummary?>,
        $FutureProvider<PlaidSyncSummary?> {
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
  PlaidSyncTriggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plaidSyncTriggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plaidSyncTriggerHash();

  @$internal
  @override
  $FutureProviderElement<PlaidSyncSummary?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlaidSyncSummary?> create(Ref ref) {
    return plaidSyncTrigger(ref);
  }
}

String _$plaidSyncTriggerHash() => r'd71f17d1bd029e75b4129ef10f0c791abb2bc45f';
