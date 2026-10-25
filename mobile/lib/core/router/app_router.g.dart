// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Builds and returns the [GoRouter] instance.
///
/// The [redirect] callback runs on every navigation event and enforces:
/// - Unauthenticated users → /login
/// - Authenticated users on auth routes → /dashboard (prevents back-nav to login)

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Builds and returns the [GoRouter] instance.
///
/// The [redirect] callback runs on every navigation event and enforces:
/// - Unauthenticated users → /login
/// - Authenticated users on auth routes → /dashboard (prevents back-nav to login)

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Builds and returns the [GoRouter] instance.
  ///
  /// The [redirect] callback runs on every navigation event and enforces:
  /// - Unauthenticated users → /login
  /// - Authenticated users on auth routes → /dashboard (prevents back-nav to login)
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'62eff8bcd37c7bac8ac995589df0c3b84c3d9d7c';
