// App-wide routing using go_router with Riverpod-powered auth redirect.
//
// The router is itself a Riverpod provider so it can watch [authStateProvider]
// and reactively redirect unauthenticated users to /login without needing a
// separate stream listener in the widget tree.
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/receipts/screens/receipts_screen.dart';
import '../../features/receipts/screens/receipt_detail_screen.dart';
import '../../features/budget/screens/budget_screen.dart';
import '../../features/scenarios/screens/scenarios_screen.dart';
import '../../features/scenarios/screens/scenario_detail_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

part 'app_router.g.dart';

/// Builds and returns the [GoRouter] instance.
///
/// The [redirect] callback runs on every navigation event and enforces:
/// - Unauthenticated users → /login
/// - Authenticated users on auth routes → /dashboard (prevents back-nav to login)
@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null; // no redirect needed
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      // ShellRoute wraps all authenticated screens in MainScaffold (bottom nav).
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/accounts', builder: (_, _) => const AccountsScreen()),
          GoRoute(path: '/transactions', builder: (_, _) => const TransactionsScreen()),
          GoRoute(
            path: '/receipts',
            builder: (_, _) => const ReceiptsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => ReceiptDetailScreen(
                  receiptId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(path: '/budget', builder: (_, _) => const BudgetScreen()),
          GoRoute(
            path: '/scenarios',
            builder: (_, _) => const ScenariosScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => ScenarioDetailScreen(
                  scenarioId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
}
