// Shared classifier for "is this error worth queueing for
// replay?" Audit L1 Phase 3b. Same shape as
// [core/utils/retry.dart]'s `_isTransient` (read-side retries),
// extracted here so write paths can share the classification
// without depending on the read-side helper.
//
// Returns true for the network shapes that almost always recover
// on retry (SocketException, TimeoutException, ClientException
// from package:http, PostgrestException with PGRST5xx codes).
// Returns false for auth, RLS, CHECK violations, and other
// shapes where a retry won't help — these should bubble to the
// user as a real error.

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

bool isTransientWriteError(Object error) {
  if (error is SocketException || error is TimeoutException) return true;
  // ClientException from package:http is the "connection closed
  // mid-request" shape. Matched by runtimeType string so we
  // don't take a direct dependency on package:http.
  final type = error.runtimeType.toString();
  if (type == 'ClientException') return true;
  if (error is PostgrestException) {
    final code = error.code;
    if (code != null && code.startsWith('PGRST5')) return true;
  }
  return false;
}
