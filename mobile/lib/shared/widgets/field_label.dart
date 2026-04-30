// Small muted label rendered above each form field. Used inside add/edit
// sheets to keep field captions visually consistent across the app.
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.bottomPadding = 6});

  final String text;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.appColors.textMuted,
        ),
      ),
    );
  }
}
