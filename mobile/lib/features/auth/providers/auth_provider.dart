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
@riverpod
Stream<AuthState> authState(AuthStateRef ref) async* {
  final initial = supabase.auth.currentSession;
  if (initial != null) {
    yield AuthState(AuthChangeEvent.initialSession, initial);
  }
  yield* supabase.auth.onAuthStateChange;
}

/// Derives the current [User] from the latest [AuthState].
///
/// Falls back to [supabase.auth.currentUser] before any auth event has fired
/// so a persisted session is recognised on cold start.
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateProvider).valueOrNull?.session?.user ??
      supabase.auth.currentUser;
}
