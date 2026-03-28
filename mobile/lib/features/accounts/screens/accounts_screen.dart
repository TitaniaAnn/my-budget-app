// Accounts screen — lists all household accounts grouped by type
// and shows a net worth summary card at the top.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/money.dart';
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
                onPressed: () => ref.invalidate(accountsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (accounts) => _AccountsList(accounts: accounts),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddAccountSheet(),
    );
  }
}

class _AccountsList extends StatelessWidget {
  final List<Account> accounts;
  const _AccountsList({required this.accounts});

  /// Net worth = sum of all balances, with credit card balances subtracted
  /// (they represent debt, so a $500 balance reduces net worth by $500).
  int get _netWorth {
    return accounts.fold<int>(0, (sum, a) {
      if (a.accountType == AccountType.creditCard) {
        return sum - a.currentBalance.abs();
      }
      return sum + a.currentBalance;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_outlined,
                size: 64, color: Color(0xFF334155)),
            const SizedBox(height: 16),
            const Text('No accounts yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            const Text('Tap + to add your first account',
                style: TextStyle(color: Color(0xFF475569))),
          ],
        ),
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
            ...grouped[group]!.map((a) => AccountCard(account: a)),
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
              fontSize: 32,
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

class _GroupHeader extends StatelessWidget {
  final AccountGroup group;
  final List<Account> accounts;
  const _GroupHeader({required this.group, required this.accounts});

  int get _groupTotal =>
      accounts.fold<int>(0, (sum, a) => sum + a.currentBalance);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          group.displayName.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        Text(
          formatCurrency(_groupTotal),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
