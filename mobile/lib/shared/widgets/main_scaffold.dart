// Persistent shell around all authenticated screens.
// Provides the bottom NavigationBar and maps tab taps to go_router routes.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Wraps an authenticated screen in the app's bottom navigation bar.
/// Used as the [ShellRoute] builder in app_router.dart so the nav bar
/// persists across tab switches without rebuilding.
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  // Tab definitions in display order. Path must match a GoRoute path.
  static const _tabs = [
    _TabItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: '/dashboard'),
    _TabItem(icon: Icons.account_balance_outlined, label: 'Accounts', path: '/accounts'),
    _TabItem(icon: Icons.receipt_long_outlined, label: 'Transactions', path: '/transactions'),
    _TabItem(icon: Icons.photo_camera_outlined, label: 'Receipts', path: '/receipts'),
    _TabItem(icon: Icons.pie_chart_outline, label: 'Budget', path: '/budget'),
    _TabItem(icon: Icons.trending_up_outlined, label: 'Scenarios', path: '/scenarios'),
    _TabItem(icon: Icons.settings_outlined, label: 'Settings', path: '/settings'),
  ];

  /// Derives the selected tab index from the current route location.
  /// Falls back to 0 (Dashboard) for any unmatched route.
  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.appColors.surfaceDeep,
        // Subtle highlight behind the selected tab icon
        indicatorColor: BrandColors.primary.withValues(alpha: 0.2),
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon, color: context.cs.outline),
                  selectedIcon:
                      Icon(t.icon, color: BrandColors.primary),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

/// Data class holding the metadata for a single bottom-nav tab.
class _TabItem {
  final IconData icon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.label, required this.path});
}
