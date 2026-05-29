// Persistent shell around all authenticated screens.
// Provides the bottom NavigationBar and maps tab taps to go_router routes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/connectivity/connectivity_provider.dart';
import '../../core/sync/last_synced_provider.dart';
import '../../core/theme/app_theme.dart';

/// Wraps an authenticated screen in the app's bottom navigation bar.
/// Used as the [ShellRoute] builder in app_router.dart so the nav bar
/// persists across tab switches without rebuilding.
class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  // Tab definitions in display order. Path must match a GoRoute path.
  static const _tabs = [
    _TabItem(
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
      path: '/dashboard',
    ),
    _TabItem(
      icon: Icons.account_balance_outlined,
      label: 'Accounts',
      path: '/accounts',
    ),
    _TabItem(
      icon: Icons.receipt_long_outlined,
      label: 'Transactions',
      path: '/transactions',
    ),
    _TabItem(
      icon: Icons.photo_camera_outlined,
      label: 'Receipts',
      path: '/receipts',
    ),
    _TabItem(icon: Icons.pie_chart_outline, label: 'Budget', path: '/budget'),
    _TabItem(
      icon: Icons.trending_up_outlined,
      label: 'Scenarios',
      path: '/scenarios',
    ),
    _TabItem(
      icon: Icons.settings_outlined,
      label: 'Settings',
      path: '/settings',
    ),
  ];

  /// Derives the selected tab index from the current route location.
  /// Falls back to 0 (Dashboard) for any unmatched route.
  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = _selectedIndex(context);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      // Column wraps the offline banner above the routed child so the
      // banner sits inside the safe area and above the bottom nav bar
      // without overlapping either. Audit L1 Phase 1.
      body: Column(
        children: [
          if (!isOnline) const _OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.appColors.surfaceDeep,
        // Subtle highlight behind the selected tab icon
        indicatorColor: BrandColors.primary.withValues(alpha: 0.2),
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon, color: context.cs.outline),
                selectedIcon: Icon(t.icon, color: BrandColors.primary),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Thin status strip rendered at the top of [MainScaffold] when the
/// platform reports no connectivity. Audit L1 Phase 1 + 5a.
///
/// Visually subdued (warning tone, single-line, ~32px tall) — the
/// goal is "user notices something is up" not "the offline state
/// dominates the screen." Cache-through repositories still serve
/// whatever data they have, so most screens stay usable; the
/// banner explains why a fresh fetch might fail AND surfaces the
/// last-synced timestamp so the user knows how stale the cached
/// data is.
class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    // AsyncValue from the lastSyncedAtProvider — render
    // optimistically: while the timestamp is loading, hide
    // the trailing label and just show the offline message.
    final lastSynced = ref.watch(lastSyncedAtProvider).valueOrNull;
    final captionStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: colors.textMuted,
    );
    return SafeArea(
      bottom: false,
      child: Material(
        color: BrandColors.warning.withValues(alpha: 0.15),
        child: SizedBox(
          height: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 16, color: colors.textMuted),
              const SizedBox(width: 8),
              Text("You're offline", style: captionStyle),
              if (lastSynced != null) ...[
                Text(' · synced ', style: captionStyle),
                LastSyncedLabel(
                  lastSyncedAt: lastSynced,
                  style: captionStyle,
                ),
              ],
            ],
          ),
        ),
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
