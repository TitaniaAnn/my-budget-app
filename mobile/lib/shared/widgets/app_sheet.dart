// Helpers and extensions for showing modal bottom sheets and SnackBars
// with the app's standard styling. Saves widgets from copy-pasting the
// same `showModalBottomSheet(context, isScrollControlled: true, shape: …)`
// block in a dozen places.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/error/error_mapper.dart';
import '../../core/supabase/supabase_client.dart';

/// Shows [child] in a modal bottom sheet styled to match the rest of the app:
/// rounded top corners, scroll-controlled height, surface background color.
///
/// Returns the value passed to `Navigator.pop` from inside the sheet, or null
/// if the sheet was dismissed without a result.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required Widget child,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => child,
  );
}

/// Convenience extensions for showing the app's standard SnackBars.
extension SnackBarContext on BuildContext {
  /// Shows an error message styled with the theme's error color.
  ///
  /// Routes the raw exception through [mapError] (audit C5) so the
  /// user sees clean copy ("Your session expired", "You don't have
  /// access to this") rather than the raw
  /// `PostgrestException(message: …, code: …)` toString. When the
  /// mapping indicates a session-expiry shape (audit C6), also
  /// fires [supabase.auth.signOut] — the router's auth-stream
  /// listener picks up the signedOut event and redirects to /login
  /// automatically, no manual `context.go('/login')` needed at the
  /// catch site.
  void showErrorSnackBar(Object error) {
    final mapped = mapError(error);
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(mapped.userMessage),
        backgroundColor: Theme.of(this).colorScheme.error,
      ),
    );
    if (mapped.requiresReauth) {
      // Fire-and-forget. The snackbar shows synchronously; the
      // signOut roundtrip resolves shortly after and the router
      // moves the user to /login.
      unawaited(supabase.auth.signOut());
    }
  }

  /// Shows a neutral informational message.
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
