// Online/offline awareness. Audit L1 Phase 1.
//
// Exposes a single boolean Riverpod state — `isOnline` — sourced
// from connectivity_plus. The state updates whenever the platform
// reports a connectivity change (Wi-Fi drop, airplane mode toggle,
// VPN reconnect, etc.) and is read by:
//   * MainScaffold's offline banner.
//   * The cache-through repositories' "should I even try the
//     network call?" decision (Phase 2+).
//
// Optimistic default: the initial state before the first platform
// check resolves is `true` (online). This avoids briefly flashing
// the offline banner on cold start when the platform check is
// still in flight. A false-positive "online" for the first
// hundred milliseconds is harmless — the network call either
// succeeds (great) or fails normally (the repository falls back
// to cache).
//
// NOT a network *reachability* check. Platform-level connectivity
// reports "I have a Wi-Fi association" but says nothing about
// whether the supabase URL is reachable. A captive-portal Wi-Fi
// connection reports online but every HTTP call hangs. Treat this
// as a hint, not a guarantee — the cache-through pattern's
// "network throws, fall back to cache" behavior covers the
// captive-portal case regardless of what this provider says.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Wraps connectivity_plus in a Riverpod state. keepAlive so the
/// subscription survives provider scope changes — connectivity
/// state is app-global, not per-screen.
@Riverpod(keepAlive: true)
class IsOnline extends _$IsOnline {
  @override
  bool build() {
    final connectivity = Connectivity();

    // Subscribe to platform updates. Cancelled on provider dispose.
    final sub = connectivity.onConnectivityChanged.listen((results) {
      state = _isOnline(results);
    });
    ref.onDispose(sub.cancel);

    // Kick off the initial check. The optimistic `true` returned
    // below is the value until this future resolves (typically
    // <100 ms on a real device).
    //
    // ignore: discarded_futures
    connectivity.checkConnectivity().then((results) {
      state = _isOnline(results);
    });

    return true;
  }
}

/// True when at least one ConnectivityResult in [results] is
/// something other than `none`. The platform reports a list (not a
/// single value) because a device can have multiple active
/// interfaces — e.g. Wi-Fi + VPN simultaneously. Any non-none
/// interface means we have a path to the internet, even if some
/// of the listed interfaces are themselves down.
bool _isOnline(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}
