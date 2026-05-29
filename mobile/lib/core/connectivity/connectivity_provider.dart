// Online/offline awareness. Audit L1 Phase 1 + 2026-05-26 H10.
//
// Exposes a single boolean Riverpod state — `isOnline` — sourced
// from connectivity_plus (link-layer signal) AND a periodic
// reachability probe (HEAD against Supabase). The state updates
// whenever the platform reports a connectivity change (Wi-Fi
// drop, airplane mode toggle, VPN reconnect, etc.) AND whenever
// the probe transitions a hung captive-portal Wi-Fi from "looks
// online but every call hangs" to "actually online".
//
// Optimistic default: the initial state before the first probe
// resolves is `true` (online). This avoids briefly flashing the
// offline banner on cold start. A false-positive for the first
// hundred milliseconds is harmless — the network call either
// succeeds (great) or fails normally (the repository falls back
// to cache).
//
// H10 — periodic probe. Without it, captive-portal Wi-Fi (user
// on hotel network, hasn't tapped through the portal yet)
// reports `isOnline=true` from connectivity_plus, so the offline
// banner is hidden AND the false→true reconnect edge never
// fires when the portal sign-in completes (because we were
// already "online"). The probe runs every 2 min while the
// platform says we're online; when the probe fails twice in a
// row we flip to offline; when a subsequent probe succeeds we
// flip back, triggering the queue drain + ledger invalidation
// that key off the false→true edge.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../supabase/supabase_client.dart';

part 'connectivity_provider.g.dart';

/// Wraps connectivity_plus in a Riverpod state. keepAlive so the
/// subscription survives provider scope changes — connectivity
/// state is app-global, not per-screen.
@Riverpod(keepAlive: true)
class IsOnline extends _$IsOnline {
  /// How often to actively probe Supabase reachability while
  /// connectivity_plus thinks we're online. Tuned to balance
  /// "catches captive-portal sign-in within a couple minutes"
  /// against "doesn't burn battery polling needlessly". A
  /// failed probe doesn't immediately flip — we wait for two
  /// in a row to avoid a single transient blip thrashing the
  /// banner.
  static const _probeInterval = Duration(minutes: 2);

  /// Per-probe HTTP timeout. Generous because the goal is to
  /// distinguish "hung" from "slow"; an actual reachable host
  /// resolves in <1s.
  static const _probeTimeout = Duration(seconds: 5);

  int _consecutiveProbeFailures = 0;

  @override
  bool build() {
    final connectivity = Connectivity();

    // Subscribe to platform updates. Cancelled on provider dispose.
    final sub = connectivity.onConnectivityChanged.listen((results) {
      final platformOnline = _isOnline(results);
      // A link-layer DOWN unambiguously flips us offline.
      // A link-layer UP starts the optimistic path — we trust
      // it until the probe says otherwise.
      if (!platformOnline) {
        _consecutiveProbeFailures = 0;
        state = false;
      } else {
        // Platform link came back; probe immediately to validate
        // reachability before flipping back to online.
        // ignore: discarded_futures
        _runProbe();
      }
    });
    ref.onDispose(sub.cancel);

    // Initial platform check + probe schedule.
    // ignore: discarded_futures
    connectivity.checkConnectivity().then((results) {
      if (!_isOnline(results)) {
        state = false;
      } else {
        // ignore: discarded_futures
        _runProbe();
      }
    });
    final timer = Timer.periodic(_probeInterval, (_) {
      // ignore: discarded_futures
      _runProbe();
    });
    ref.onDispose(timer.cancel);

    return true;
  }

  /// Cheap SELECT against a table that always exists. Proves
  /// DNS + TLS + PostgREST are all reachable. RLS may deny
  /// rows (returns empty) but the round-trip itself succeeds;
  /// only a transport error (SocketException, TimeoutException,
  /// captive-portal-style hang past _probeTimeout) trips the
  /// failure counter.
  ///
  /// Two consecutive failures flip us offline; one success
  /// flips back. The single-failure tolerance keeps a transient
  /// blip from thrashing the banner.
  Future<void> _runProbe() async {
    try {
      await supabase
          .from('households')
          .select('id')
          .limit(1)
          .timeout(_probeTimeout);
      _consecutiveProbeFailures = 0;
      if (state == false) state = true;
    } catch (_) {
      _consecutiveProbeFailures++;
      if (_consecutiveProbeFailures >= 2 && state == true) {
        state = false;
      }
    }
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
