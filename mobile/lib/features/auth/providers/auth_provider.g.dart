// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authStateHash() => r'f0677f3c98f70ade260a12aa9fcdc96005efd474';

/// Streams [AuthState] changes from Supabase (login, logout, token refresh).
/// The router watches this to redirect unauthenticated users to /login.
///
/// On cold start the stream's first event can take a moment to arrive, so
/// we yield a synthetic event from the persisted session immediately.
/// Without this seed the router briefly sees `loading` (treated as logged-out)
/// and redirects already-authenticated users to /login before bouncing back.
///
/// Copied from [authState].
@ProviderFor(authState)
final authStateProvider = AutoDisposeStreamProvider<AuthState>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateRef = AutoDisposeStreamProviderRef<AuthState>;
String _$currentUserHash() => r'e6425e68907078f22f8f7b5d76884c81293abd61';

/// Derives the current [User] from the latest [AuthState].
///
/// Falls back to [supabase.auth.currentUser] before any auth event has fired
/// so a persisted session is recognised on cold start.
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeProviderRef<User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
