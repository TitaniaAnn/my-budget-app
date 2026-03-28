// Riverpod providers that expose Supabase auth state to the rest of the app.
//
// [authStateProvider] is watched by the router to trigger redirects, and by
// any widget that needs to react to login/logout events.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

part 'auth_provider.g.dart';

/// Streams [AuthState] changes from Supabase (login, logout, token refresh).
/// The router watches this to redirect unauthenticated users to /login.
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return supabase.auth.onAuthStateChange;
}

/// Derives the current [User] from the latest [AuthState].
/// Returns null when no session is active (user is logged out).
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateProvider).valueOrNull?.session?.user;
}
