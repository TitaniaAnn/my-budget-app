// Transient-failure retry helper for read-only fetches.
//
// Audit L3: a single dropped packet during a dashboard load
// dumped the user into the error view, even though a retry would
// almost always succeed. Wrapping the dashboard's fetch chain in
// [retryTransient] turns those one-off blips into invisible
// retries.
//
// Only safe for READ-only operations. Writes are NOT idempotent
// in the general case (an INSERT that fails between "row written"
// and "ack received" would land twice on retry); callers must not
// pass mutating closures.

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps [body] with up to [maxAttempts] tries, sleeping with
/// exponential backoff between failures. Only retries when the
/// thrown error looks transient — network blips and PostgREST
/// 5xx-shaped responses. Auth, RLS, and CHECK violations bubble
/// out on the first attempt (retrying won't help).
///
/// Default backoff: 200 ms, 800 ms, then fail. Total worst-case
/// added latency on a true-failure call is 1 second — small
/// enough that the user can't visually distinguish a "blip then
/// recovered" from a "slow connection."
Future<T> retryTransient<T>(
  Future<T> Function() body, {
  int maxAttempts = 3,
  Duration initialBackoff = const Duration(milliseconds: 200),
}) async {
  var attempt = 0;
  var delay = initialBackoff;
  while (true) {
    attempt += 1;
    try {
      return await body();
    } catch (e) {
      if (attempt >= maxAttempts || !_isTransient(e)) rethrow;
      await Future<void>.delayed(delay);
      delay *= 4;
    }
  }
}

/// True when the exception looks worth retrying. Network-layer
/// shapes (SocketException, TimeoutException, ClientException) are
/// always transient; PostgREST exceptions with a code in the 5xx
/// range mean the upstream had a transient hiccup; everything else
/// — RLS denials, CHECK violations, expired JWTs — won't change on
/// a retry and should fail through immediately.
bool _isTransient(Object error) {
  if (error is SocketException || error is TimeoutException) return true;
  // ClientException from package:http is the "connection closed"
  // shape that wraps mid-request transport failures.
  final type = error.runtimeType.toString();
  if (type == 'ClientException') return true;
  if (error is PostgrestException) {
    // PostgREST codes prefixed with 'PGRST5' are server-side
    // transient: PGRST500/503/504. Pre-fix the whole error view
    // surfaced on a single 503; the retry usually wins.
    final code = error.code;
    if (code != null && code.startsWith('PGRST5')) return true;
  }
  return false;
}
