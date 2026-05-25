// Shared card container — the surface-bg + divider-border + 12px-
// radius shape that ~49 sites across the app spell out by hand.
//
// Audit R2 flagged the repetition. Beyond the ergonomic win
// (one widget instead of nine lines of decoration), centralising
// the shape gives us one place to retune card styling — a global
// shadow tweak or border-radius bump becomes a single-file diff
// instead of a 49-site find-and-replace.
//
// Two variants share one widget:
//   * default — surface bg + divider border (the dashboard cards,
//     account summary tiles, settings rows, etc.);
//   * accent — alpha-tinted bg + alpha-tinted border in the same
//     hue (the "selected" / "highlighted" card style used by the
//     scenarios advisor surface and a few warning banners).
//
// The widget is intentionally minimal: padding, margin, child,
// optional accent, optional onTap. Anything fancier (gradient,
// shadow, custom shape) stays at the call site as a bespoke
// Container — premature generalisation is its own cost.

import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.accent,
    this.onTap,
    required this.child,
  });

  /// Inner padding around [child]. Defaults to 16-all because the
  /// dashboard and account list cards both use that; sites that
  /// want a tighter pack (12, or asymmetric) override explicitly.
  final EdgeInsetsGeometry padding;

  /// Outer margin around the card. Null = no margin; callers in
  /// a Column with their own SizedBox spacers leave this default.
  final EdgeInsetsGeometry? margin;

  /// When set, the card uses an alpha-tinted background + matching
  /// border in this hue. Used for "this card is the highlighted /
  /// selected one" surfaces (advisor cards, banners).
  final Color? accent;

  /// Tap callback. When non-null the card becomes an InkWell so
  /// the tap is visually acknowledged. Use for cards that drill
  /// into a detail screen.
  final VoidCallback? onTap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = accent != null ? accent!.withValues(alpha: 0.08) : cs.surface;
    final borderColor = accent != null
        ? accent!.withValues(alpha: 0.4)
        : theme.dividerColor;

    final body = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: body,
      ),
    );
  }
}
