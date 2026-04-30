// Standard inner scaffolding for a bottom sheet body:
//   • Symmetric horizontal padding plus extra bottom padding that respects
//     the on-screen keyboard (MediaQuery.viewInsets.bottom).
//   • A header row with the sheet title and a close (X) icon button.
//
// The sheet itself is presented via `showAppSheet`; this widget is what
// the sheet's `child:` builder returns. It replaces the
//   `Padding(...) → Column(... Row(Title, Spacer, IconButton(close))...)`
// boilerplate that was duplicated in every add/edit sheet.
import 'package:flutter/material.dart';

class AppSheetScaffold extends StatelessWidget {
  const AppSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.scrollable = false,
    this.formKey,
  });

  final String title;
  final Widget child;

  /// Extra icon buttons rendered to the left of the close button (e.g.
  /// the delete icon shown in edit-mode sheets).
  final List<Widget> actions;

  /// Wrap the child in a [SingleChildScrollView] so long forms scroll
  /// instead of overflowing when the keyboard is open.
  final bool scrollable;

  /// When provided, wraps the child in a [Form] using this key.
  final GlobalKey<FormState>? formKey;

  @override
  Widget build(BuildContext context) {
    Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            ...actions,
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );

    if (scrollable) body = SingleChildScrollView(child: body);
    if (formKey != null) body = Form(key: formKey, child: body);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: body,
    );
  }
}
