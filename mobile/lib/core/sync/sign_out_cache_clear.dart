// On sign-out, nuke every drift cache row + the pending-writes
// queue. Audit 2026-05-26 C1.
//
// Three concrete leaks this closes:
//   1. Cross-user: User A signs out, User B signs in on the
//      same device. Without the wipe, B sees A's transactions,
//      account names, categories, tag assignments, and budget
//      caps offline until the first online fetch — and even
//      then, only the tables that re-fetch on read get
//      reconciled. Tag assignments are full-replace-on-fetch
//      only; categories are also single-set; both would still
//      leak A's data for B until those specific surfaces
//      reload.
//   2. Queue-replay confusion: a write A queued while offline
//      would replay against B's session. RLS rejects (B doesn't
//      own A's household_id) and the row marks-failed-forever,
//      but only after attempting — and the attempt itself is a
//      meaningless write to A's data using B's credentials.
//   3. Disk forensics is partially mitigated: a rooted device
//      / ADB pull / iCloud backup of a signed-out account
//      reveals less. Full encryption is a separate item
//      (sqlcipher + Keychain/Keystore).
//
// Listener wiring: subscribes to Supabase auth state at
// provider build time. Keep-alive so the subscription is
// process-lifetime — sign-out can happen from any screen, the
// listener has to be live throughout.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../supabase/supabase_client.dart';

part 'sign_out_cache_clear.g.dart';

@Riverpod(keepAlive: true)
class SignOutCacheClear extends _$SignOutCacheClear {
  StreamSubscription<AuthState>? _sub;

  @override
  void build() {
    final db = ref.watch(appDatabaseProvider);
    _sub = supabase.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        // Fire-and-forget. Sign-out completes synchronously
        // from the user's POV; the cache clear races with the
        // router's redirect to /login, which is fine because
        // /login renders no cached data.
        // ignore: discarded_futures
        _clearWithErrorHandling(db);
      }
    });
    ref.onDispose(() {
      // ignore: discarded_futures
      _sub?.cancel();
    });
  }

  Future<void> _clearWithErrorHandling(AppDatabase db) async {
    try {
      await db.clearAllCachesForSignOut();
    } catch (e) {
      // Failure here is non-fatal — the new user will still see
      // fresh data via the cache-through repositories' network
      // path on next online fetch. Logging the error gives a
      // signal in stderr without crashing the sign-out flow.
      // ignore: avoid_print
      print('[SignOutCacheClear] failed to clear caches: $e');
    }
  }
}

