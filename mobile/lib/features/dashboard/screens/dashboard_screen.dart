// Dashboard screen — net worth, accounts, monthly summary, spending sparkline,
// budget health alerts, top categories, and recent transactions.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/money.dart';
import '../../accounts/models/account.dart';
import '../../budget/providers/budget_provider.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';
import '../../transactions/widgets/transaction_card.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(dashboardDataProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => const AddTransactionSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
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

class _DashboardBody extends ConsumerWidget {
  final DashboardData data;
  const _DashboardBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthName = DateFormat('MMMM').format(DateTime.now());
    final budgetsAsync = ref.watch(budgetDataProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Net Worth ──────────────────────────────────────────────────────
        _NetWorthCard(netWorthCents: data.netWorth),
        const SizedBox(height: 16),

        // ── Accounts ───────────────────────────────────────────────────────
        if (data.accounts.isNotEmpty) ...[
          _SectionHeader(
            title: 'Accounts',
            actionLabel: 'Manage',
            onAction: (ctx) => ctx.go('/accounts'),
          ),
          const SizedBox(height: 10),
          _AccountsRow(accounts: data.accounts),
          const SizedBox(height: 24),
        ],

        // ── Monthly Summary ────────────────────────────────────────────────
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

        // ── 30-day Spending Sparkline ──────────────────────────────────────
        _SectionHeader(title: '30-Day Spending'),
        const SizedBox(height: 10),
        _SpendingSparkline(spendingByDay: data.spendingByDay),
        const SizedBox(height: 24),

        // ── Budget Health ──────────────────────────────────────────────────
        budgetsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (budgets) {
            final alerts = budgets
                .where((b) => b.isOverBudget || b.progress >= 0.8)
                .toList()
              ..sort((a, b) => b.progress.compareTo(a.progress));
            if (alerts.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Budget Health',
                  actionLabel: 'See all',
                  onAction: (ctx) => ctx.go('/budget'),
                ),
                const SizedBox(height: 10),
                ...alerts.take(3).map((b) => _BudgetAlertTile(budget: b)),
                const SizedBox(height: 24),
              ],
            );
          },
        ),

        // ── Top Categories ─────────────────────────────────────────────────
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

        // ── Recent Transactions ────────────────────────────────────────────
        if (data.recentTransactions.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent Transactions',
            actionLabel: 'See all',
            onAction: (ctx) => ctx.go('/transactions'),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: data.recentTransactions
                  .map((tx) => TransactionCard(transaction: tx))
                  .toList(),
            ),
          ),
        ],

        // ── Empty state ────────────────────────────────────────────────────
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

// ── Sub-widgets ────────────────────────────────────────────────────────────────

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

/// Horizontally scrollable row of compact account chips.
class _AccountsRow extends StatelessWidget {
  final List<Account> accounts;
  const _AccountsRow({required this.accounts});

  Color _typeColor(Account a) {
    if (a.color != null) {
      return Color(int.parse('FF${a.color!.replaceAll('#', '')}', radix: 16));
    }
    return switch (a.accountType.group) {
      AccountGroup.banking => const Color(0xFF3B82F6),
      AccountGroup.creditCards => const Color(0xFFEF4444),
      AccountGroup.loans => const Color(0xFFF59E0B),
      AccountGroup.investments => const Color(0xFF22C55E),
    };
  }

  IconData _typeIcon(AccountType t) => switch (t) {
        AccountType.checking => Icons.account_balance_outlined,
        AccountType.savings => Icons.savings_outlined,
        AccountType.creditCard => Icons.credit_card_outlined,
        AccountType.brokerage => Icons.trending_up_outlined,
        AccountType.iraTraditional ||
        AccountType.iraRoth =>
          Icons.account_balance_wallet_outlined,
        AccountType.retirement401k ||
        AccountType.retirement403b =>
          Icons.work_outline,
        AccountType.hsa => Icons.health_and_safety_outlined,
        AccountType.college529 => Icons.school_outlined,
        AccountType.cash => Icons.payments_outlined,
        AccountType.mortgage => Icons.home_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final a = accounts[i];
          final color = _typeColor(a);
          final isCreditCard = a.accountType == AccountType.creditCard;
          return Container(
            width: 148,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_typeIcon(a.accountType), size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        a.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  formatCurrency(a.currentBalance),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCreditCard
                        ? const Color(0xFFEF4444)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (a.institution != null)
                  Text(
                    a.institution!,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
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

/// Bar chart showing daily spending for the last 30 days.
/// Each bar is one day; today is on the right. Tapping a bar shows the amount.
class _SpendingSparkline extends StatelessWidget {
  final List<int> spendingByDay; // 30 items, index 29 = today
  const _SpendingSparkline({required this.spendingByDay});

  @override
  Widget build(BuildContext context) {
    final maxVal = spendingByDay.fold<int>(0, (m, v) => v > m ? v : m);

    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: maxVal == 0
          ? Center(
              child: Text('No spending in the last 30 days',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 13)),
            )
          : BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        // Show label every 7 days + today
                        if (idx == 29) {
                          return const Text('Today',
                              style: TextStyle(
                                  fontSize: 9, color: Color(0xFF64748B)));
                        }
                        if ((29 - idx) % 7 == 0 && idx != 29) {
                          return Text('${29 - idx}d',
                              style: const TextStyle(
                                  fontSize: 9, color: Color(0xFF64748B)));
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 18,
                    ),
                  ),
                ),
                barGroups: List.generate(30, (i) {
                  final isToday = i == 29;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: spendingByDay[i].toDouble(),
                        color: isToday
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3)),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                      formatCurrency(rod.toY.round()),
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Alert row for a budget that is over or nearing its limit.
class _BudgetAlertTile extends StatelessWidget {
  final BudgetWithSpending budget;
  const _BudgetAlertTile({required this.budget});

  @override
  Widget build(BuildContext context) {
    final isOver = budget.isOverBudget;
    final color = isOver ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final pct = (budget.progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isOver ? Icons.warning_rounded : Icons.info_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.categoryName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  isOver
                      ? '${formatCurrency(budget.spentCents - budget.budget.amount)} over budget'
                      : '${formatCurrency(budget.budget.amount - budget.spentCents)} remaining ($pct% used)',
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatCurrency(budget.spentCents),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text('of ${formatCurrency(budget.budget.amount)}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF64748B))),
            ],
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: categories.map((cat) {
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final void Function(BuildContext)? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.outline,
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
