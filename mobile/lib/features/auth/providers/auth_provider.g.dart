// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Streams [AuthState] changes from Supabase (login, logout, token refresh).
/// The router watches this to redirect unauthenticated users to /login.
///
/// On cold start the stream's first event can take a moment to arrive, so
/// we yield a synthetic event from the persisted session immediately.
/// Without this seed the router briefly sees `loading` (treated as logged-out)
/// and redirects already-authenticated users to /login before bouncing back.
///
/// `onAuthStateChange` itself emits `initialSession` once it warms up, so
/// the router can see two `initialSession` events on cold start. The router
/// redirect is idempotent (it only navigates when the destination differs
/// from the current location), so the duplicate is harmless — keeping the
/// manual yield avoids the cold-start race that the duplicate would
/// otherwise paper over.

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// Streams [AuthState] changes from Supabase (login, logout, token refresh).
/// The router watches this to redirect unauthenticated users to /login.
///
/// On cold start the stream's first event can take a moment to arrive, so
/// we yield a synthetic event from the persisted session immediately.
/// Without this seed the router briefly sees `loading` (treated as logged-out)
/// and redirects already-authenticated users to /login before bouncing back.
///
/// `onAuthStateChange` itself emits `initialSession` once it warms up, so
/// the router can see two `initialSession` events on cold start. The router
/// redirect is idempotent (it only navigates when the destination differs
/// from the current location), so the duplicate is harmless — keeping the
/// manual yield avoids the cold-start race that the duplicate would
/// otherwise paper over.

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  /// Streams [AuthState] changes from Supabase (login, logout, token refresh).
  /// The router watches this to redirect unauthenticated users to /login.
  ///
  /// On cold start the stream's first event can take a moment to arrive, so
  /// we yield a synthetic event from the persisted session immediately.
  /// Without this seed the router briefly sees `loading` (treated as logged-out)
  /// and redirects already-authenticated users to /login before bouncing back.
  ///
  /// `onAuthStateChange` itself emits `initialSession` once it warms up, so
  /// the router can see two `initialSession` events on cold start. The router
  /// redirect is idempotent (it only navigates when the destination differs
  /// from the current location), so the duplicate is harmless — keeping the
  /// manual yield avoids the cold-start race that the duplicate would
  /// otherwise paper over.
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'277d81412bb1c39d85e3db1218681920fa45b699';

/// Derives the current [User] from the latest [AuthState].
///
/// Falls back to [supabase.auth.currentUser] before any auth event has fired
/// so a persisted session is recognised on cold start.

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// Derives the current [User] from the latest [AuthState].
///
/// Falls back to [supabase.auth.currentUser] before any auth event has fired
/// so a persisted session is recognised on cold start.

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
  /// Derives the current [User] from the latest [AuthState].
  ///
  /// Falls back to [supabase.auth.currentUser] before any auth event has fired
  /// so a persisted session is recognised on cold start.
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  User? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$currentUserHash() => r'9568ce43c0fe0a28f4bf3aeaffbecfa735cfb8a5';
