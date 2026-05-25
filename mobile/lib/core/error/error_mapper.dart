// Centralised mapping from low-level exceptions to user-facing
// SnackBar messages.
//
// Pre-fix every `catch (e) { context.showErrorSnackBar(e) }` in the
// app printed the raw `e.toString()` — a household member would see
// "PostgrestException(message: JSON object requested, multiple (or
// no) rows returned, code: PGRST116, …)" when a simple lookup
// returned zero rows. A 401 from an expired JWT looked identical to
// a CHECK violation. (Audit C5.)
//
// Worse, no path anywhere bounced the user back to /login when the
// session expired — RLS just returned empty arrays and the user
// stared at a blank dashboard with no explanation. (Audit C6.)
//
// This mapper closes both: it returns a [MappedError] with a clean
// user-facing message + a [requiresReauth] flag. [showErrorSnackBar]
// in `app_sheet.dart` is wired through it; when reauth is required,
// it triggers `supabase.auth.signOut()` whose stream the router
// already watches → automatic redirect to /login.

import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of mapping a raw exception to user-facing copy.
class MappedError {
  const MappedError({
    required this.userMessage,
    this.requiresReauth = false,
  });

  /// Short, copy-ready message to display in a SnackBar. Never
  /// contains stack traces, error codes, or framework jargon.
  final String userMessage;

  /// True when the error indicates the user's session is no longer
  /// valid (expired JWT, server-side revocation). Callers should
  /// trigger sign-out so the router redirects to /login.
  final bool requiresReauth;
}

/// Maps a raw exception to a [MappedError]. Unknown error shapes
/// fall through to a generic "Something went wrong" — never the
/// raw `toString()`, which leaks framework internals.
///
/// The raw exception is intentionally NOT included in the user
/// message. Callers that want to log it for debugging should do so
/// at the catch site before calling this mapper.
MappedError mapError(Object error) {
  // ── Postgrest data-layer ──────────────────────────────────────
  if (error is PostgrestException) {
    switch (error.code) {
      case 'PGRST301':
        // JWT expired — Postgrest rejected the token. Bounce.
        return const MappedError(
          userMessage: 'Your session expired — please sign in again.',
          requiresReauth: true,
        );
      case '42501':
        // RLS / insufficient_privilege. The row exists but the
        // caller's claims don't grant access. Most user-facing
        // path: stale household membership, foreign-account write.
        return const MappedError(
          userMessage: "You don't have access to this.",
        );
      case 'PGRST116':
        // "JSON object requested, multiple (or no) rows returned" —
        // usually `.single()` against an empty/over-filtered query.
        // The user just sees "not found"; the dev sees raw stack.
        return const MappedError(
          userMessage: "We couldn't find what you were looking for.",
        );
      case '23505':
        // unique_violation — surfaces on duplicate inserts (e.g.
        // re-creating an invite for an already-invited email).
        return const MappedError(
          userMessage: 'That already exists.',
        );
      case '23503':
        // foreign_key_violation — usually a stale id in a write.
        return const MappedError(
          userMessage: "That reference no longer exists. Try refreshing.",
        );
      case '23502':
        // not_null_violation — a required field was missing.
        return const MappedError(
          userMessage: 'Something required was missing.',
        );
    }
    return const MappedError(userMessage: 'Something went wrong.');
  }

  // ── Auth layer ────────────────────────────────────────────────
  if (error is AuthException) {
    // Subclass-based reauth signals — when the SDK itself flagged
    // the session as no good, trust it.
    if (error is AuthSessionMissingException ||
        error is AuthInvalidJwtException) {
      return const MappedError(
        userMessage: 'Your session expired — please sign in again.',
        requiresReauth: true,
      );
    }
    // Code-based reauth signal (matches Supabase's documented
    // error codes — see gotrue error_code.dart).
    if (error.code == 'invalid_jwt') {
      return const MappedError(
        userMessage: 'Your session expired — please sign in again.',
        requiresReauth: true,
      );
    }
    // Other AuthException — typically a login-time failure with a
    // useful `.message` ("Invalid login credentials", "Email not
    // confirmed", etc). Surface that verbatim; the login screen is
    // already the right place for it.
    return MappedError(userMessage: error.message);
  }

  // ── Network ───────────────────────────────────────────────────
  if (error is SocketException || error is TimeoutException) {
    return const MappedError(
      userMessage: "Couldn't reach the server. Check your connection.",
    );
  }

  // ── Plain strings ─────────────────────────────────────────────
  // Several call sites pass `e.message` (a String) directly. Pass
  // those through — the caller already chose user-facing copy.
  if (error is String) {
    return MappedError(userMessage: error);
  }

  // ── Unknown ───────────────────────────────────────────────────
  return const MappedError(userMessage: 'Something went wrong.');
}
