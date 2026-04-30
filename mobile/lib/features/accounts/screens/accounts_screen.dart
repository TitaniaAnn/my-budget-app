// Accounts screen — lists all household accounts grouped by type
// and shows a net worth summary card at the top.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../widgets/account_card.dart';
import '../widgets/add_account_sheet.dart';
/// Displays accounts grouped into Banking / Credit Cards / Investments sections
/// with a net-worth header. The + FAB opens [AddAccountSheet].
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(accountsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(accountsProvider)),
        data: (accounts) => _AccountsList(accounts: accounts),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showAppSheet<void>(context, child: const AddAccountSheet());
  }
}

class _AccountsList extends StatelessWidget {
  final List<Account> accounts;
  const _AccountsList({required this.accounts});

  /// Net worth = sum of every account's signed balance.
  /// Liability accounts (credit_card, mortgage) are stored as negative cents
  /// so a plain sum already deducts them.
  int get _netWorth =>
      accounts.fold<int>(0, (sum, a) => sum + a.currentBalance);

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const EmptyView(
        icon: Icons.account_balance_outlined,
        title: 'No accounts yet',
        subtitle: 'Tap + to add your first account',
      );
    }

    // Group accounts by their AccountGroup (banking / credit / investments).
    // AccountGroup.values preserves display order when iterating below.
    final grouped = <AccountGroup, List<Account>>{};
    for (final account in accounts) {
      grouped.putIfAbsent(account.accountType.group, () => []).add(account);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _NetWorthCard(netWorthCents: _netWorth),
        const SizedBox(height: 24),
        for (final group in AccountGroup.values)
          if (grouped.containsKey(group)) ...[
            _GroupHeader(group: group, accounts: grouped[group]!),
            const SizedBox(height: 8),
            ...grouped[group]!.map((a) => AccountCard(
                  account: a,
                  onTap: () => context.go('/accounts/${a.id}'),
                )),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  final int netWorthCents;
  const _NetWorthCard({required this.netWorthCents});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.gradientStart, colors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net Worth',
              style: TextStyle(fontSize: 13, color: colors.textMuted)),
          const SizedBox(height: 6),
          Text(
            formatCurrency(netWorthCents),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: netWorthCents >= 0
                  ? context.cs.onSurface
                  : colors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final AccountGroup group;
  final List<Account> accounts;
  const _GroupHeader({required this.group, required this.accounts});

  int get _groupTotal =>
      accounts.fold<int>(0, (sum, a) => sum + a.currentBalance);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Text(
          group.displayName.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.textMuted,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        Text(
          formatCurrency(_groupTotal),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textMuted,
          ),
        ),
      ],
    );
  }
}
