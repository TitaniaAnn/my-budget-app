// Helpers and extensions for showing modal bottom sheets and SnackBars
// with the app's standard styling. Saves widgets from copy-pasting the
// same `showModalBottomSheet(context, isScrollControlled: true, shape: …)`
// block in a dozen places.
import 'package:flutter/material.dart';

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
  void showErrorSnackBar(Object error) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Theme.of(this).colorScheme.error,
      ),
    );
  }

  /// Shows a neutral informational message.
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
