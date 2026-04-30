// Submit button that swaps its child for a small spinner while the action
// it triggers is in flight. Replaces the
//   `_loading ? SizedBox(20×20, CircularProgressIndicator) : Text(label)`
// snippet that was hand-rolled inside every form sheet.
import 'package:flutter/material.dart';

enum _ButtonStyle { elevated, filled }

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.child,
  }) : _style = _ButtonStyle.elevated;

  /// FilledButton variant — used by the `add_*` sheets that previously
  /// reached for FilledButton directly.
  const LoadingButton.filled({
    super.key,
    required this.loading,
    required this.onPressed,
    required this.child,
  }) : _style = _ButtonStyle.filled;

  final bool loading;
  final VoidCallback? onPressed;
  final Widget child;
  final _ButtonStyle _style;

  @override
  Widget build(BuildContext context) {
    final body = loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
        : child;
    final tap = loading ? null : onPressed;
    return switch (_style) {
      _ButtonStyle.elevated => ElevatedButton(onPressed: tap, child: body),
      _ButtonStyle.filled => FilledButton(onPressed: tap, child: body),
    };
  }
}
