// Reusable dialog helpers. Currently the only one is the destructive-action
// confirmation, which was previously copy-pasted into every screen that
// needed a delete/archive confirm.
import 'package:flutter/material.dart';

/// Shows a Cancel / red-FilledButton confirmation dialog and resolves to
/// `true` when the user confirms, `false` otherwise (including dismiss).
///
/// [confirmLabel] defaults to "Delete"; pass "Archive", "Remove", etc. when
/// the action isn't a literal delete.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogCtx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogCtx).colorScheme.error,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
