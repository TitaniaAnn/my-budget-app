// Dashboard screen — the home view shown after login.
// Displays net worth, this month's spending vs income, top spending categories,
// and the 5 most recent transactions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/money.dart';
import '../providers/dashboard_provider.dart';
import '../../transactions/widgets/transaction_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Manual refresh in case Realtime hasn't pushed an update yet.
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(dashboardDataProvider),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 12),
              Text(e.toString(),
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardDataProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) => _DashboardBody(data: data),
      ),
    );
  }
}

/// The scrollable body shown when data has loaded successfully.
class _DashboardBody extends StatelessWidget {
  final DashboardData data;
  const _DashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM').format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Net Worth ─────────────────────────────────────────────────────
        _NetWorthCard(netWorthCents: data.netWorth),
        const SizedBox(height: 16),

        // ── Monthly Summary ───────────────────────────────────────────────
        _SectionHeader(title: '$monthName Summary'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'Spent',
                cents: data.monthlySpending,
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: 'Income',
                cents: data.monthlyIncome,
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFF22C55E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Top Categories ────────────────────────────────────────────────
        if (data.topCategories.isNotEmpty) ...[
          _SectionHeader(
            title: 'Top Spending',
            actionLabel: 'See budget',
            onAction: (ctx) => ctx.go('/budget'),
          ),
          const SizedBox(height: 10),
          _TopCategoriesCard(
            categories: data.topCategories,
            totalSpending: data.monthlySpending,
          ),
          const SizedBox(height: 24),
        ],

        // ── Recent Transactions ───────────────────────────────────────────
        if (data.recentTransactions.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent Transactions',
            actionLabel: 'See all',
            onAction: (ctx) => ctx.go('/transactions'),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: data.recentTransactions
                  .map((tx) => TransactionCard(transaction: tx))
                  .toList(),
            ),
          ),
        ],

        // ── Empty state when there are no accounts yet ─────────────────────
        if (data.accounts.isEmpty)
          _EmptyState(
            icon: Icons.account_balance_outlined,
            title: 'No accounts yet',
            subtitle: 'Add accounts to start tracking your finances',
            buttonLabel: 'Add Account',
            onTap: (ctx) => ctx.go('/accounts'),
          ),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

/// Large gradient card showing total net worth in dollars.
class _NetWorthCard extends StatelessWidget {
  final int netWorthCents;
  const _NetWorthCard({required this.netWorthCents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Net Worth',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          const SizedBox(height: 6),
          Text(
            formatCurrency(netWorthCents),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              // Red if the user is net-negative (more debt than assets).
              color: netWorthCents >= 0
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small card showing a single monetary total (spent or income).
class _SummaryTile extends StatelessWidget {
  final String label;
  final int cents;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.cents,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(cents),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal bar chart of top spending categories for the month.
class _TopCategoriesCard extends StatelessWidget {
  final List<({String name, String? color, int totalCents})> categories;
  final int totalSpending;

  const _TopCategoriesCard({
    required this.categories,
    required this.totalSpending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: categories.map((cat) {
          // Fraction of total spending this category represents.
          final fraction =
              totalSpending > 0 ? cat.totalCents / totalSpending : 0.0;

          Color barColor = const Color(0xFF3B82F6);
          if (cat.color != null) {
            barColor = Color(int.parse(
                'FF${cat.color!.replaceAll('#', '')}',
                radix: 16));
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(cat.name,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      formatCurrency(cat.totalCents),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 6),
                    // Percentage of total spending this month
                    Text(
                      '${(fraction * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Section header with an optional right-side action link.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  // Receives BuildContext so the callback can call context.go() without
  // needing a BuildContext closure in the parent's build method.
  final void Function(BuildContext)? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: () => onAction?.call(context),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}

/// Placeholder shown when the household has no accounts yet.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final void Function(BuildContext) onTap;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFF334155)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(color: Color(0xFF475569)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => onTap(context),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
