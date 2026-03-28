// Account detail screen — shows account info, edit/delete actions, and the
// account's own transaction list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/money.dart';
import '../../transactions/screens/transactions_screen.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../widgets/add_account_sheet.dart';
import '../widgets/credit_card_rates_sheet.dart';
import '../repositories/accounts_repository.dart';

class AccountDetailScreen extends ConsumerWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (accounts) {
        final account = accounts.where((a) => a.id == accountId).firstOrNull;
        if (account == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Account')),
            body: const Center(child: Text('Account not found')),
          );
        }
        return _AccountDetailBody(account: account);
      },
    );
  }
}

class _AccountDetailBody extends ConsumerWidget {
  final Account account;
  const _AccountDetailBody({required this.account});

  Color get _typeColor {
    if (account.color != null) {
      return Color(
          int.parse('FF${account.color!.replaceAll('#', '')}', radix: 16));
    }
    return switch (account.accountType.group) {
      AccountGroup.banking => const Color(0xFF3B82F6),
      AccountGroup.creditCards => const Color(0xFFEF4444),
      AccountGroup.investments => const Color(0xFF22C55E),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCreditCard = account.accountType == AccountType.creditCard;
    final limit = account.creditLimit;
    final utilization = isCreditCard && limit != null && limit > 0
        ? creditUtilization(account.currentBalance.abs(), limit)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          if (isCreditCard)
            IconButton(
              icon: const Icon(Icons.percent_rounded),
              tooltip: 'Manage rates',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) =>
                    CreditCardRatesSheet(accountId: account.id),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditSheet(context, ref),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Account summary header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_typeIcon, color: _typeColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.accountType.displayName,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline)),
                        if (account.institution != null)
                          Text(account.institution!,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const Spacer(),
                    if (account.lastFour != null)
                      Text('••••${account.lastFour}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.outline)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isCreditCard ? 'Balance (owed)' : 'Current Balance',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(account.currentBalance),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isCreditCard
                        ? const Color(0xFFEF4444)
                        : account.currentBalance >= 0
                            ? Theme.of(context).colorScheme.onSurface
                            : const Color(0xFFEF4444),
                  ),
                ),
                if (utilization != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (utilization / 100).clamp(0, 1),
                            minHeight: 5,
                            backgroundColor: Theme.of(context).dividerColor,
                            valueColor: AlwaysStoppedAnimation(
                              utilization > 80
                                  ? const Color(0xFFEF4444)
                                  : utilization > 50
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF22C55E),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${utilization.toStringAsFixed(0)}% of ${formatCurrency(limit!)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ],
                if (account.interestRate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        isCreditCard
                            ? Icons.percent_rounded
                            : Icons.trending_up_rounded,
                        size: 14,
                        color: isCreditCard
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF22C55E),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCreditCard
                            ? '${(account.interestRate! * 100).toStringAsFixed(2)}% APR'
                            : account.accountType == AccountType.savings ||
                                    account.accountType == AccountType.checking
                                ? '${(account.interestRate! * 100).toStringAsFixed(2)}% APY'
                                : '${(account.interestRate! * 100).toStringAsFixed(2)}% expected return',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isCreditCard
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Monthly: ${formatCurrency(((account.currentBalance.abs() * account.interestRate!) / 12).round())}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Transactions for this account
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  'TRANSACTIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TransactionsScreen(lockedAccountId: account.id),
          ),
        ],
      ),
    );
  }

  IconData get _typeIcon => switch (account.accountType) {
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
      };

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddAccountSheet(account: account),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Archive Account?'),
        content: Text(
          'This will hide "${account.name}" and its transactions. '
          'Your transaction history is preserved.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(accountsRepositoryProvider)
          .deleteAccount(account.id);
      ref.invalidate(accountsProvider);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
