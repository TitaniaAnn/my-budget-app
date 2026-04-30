// Account detail screen — shows account info, edit/delete actions, and the
// account's own transaction list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../transactions/screens/transactions_screen.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../repositories/accounts_repository.dart';
import '../widgets/add_account_sheet.dart';
import '../widgets/credit_card_rates_sheet.dart';
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

  Color get _typeColor =>
      colorFromHex(account.color, fallback: account.accountType.group.defaultColor);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCreditCard = account.accountType == AccountType.creditCard;
    // Liability balances are stored as negative cents but shown as the
    // magnitude owed.
    final isLiability = account.accountType.isLiability;
    final displayCents = isLiability
        ? account.currentBalance.abs()
        : account.currentBalance;
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
              onPressed: () => showAppSheet<void>(
                context,
                child: CreditCardRatesSheet(accountId: account.id),
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
                      child: Icon(account.accountType.icon,
                          color: _typeColor, size: 22),
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
                  isLiability ? 'Balance (owed)' : 'Current Balance',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.outline),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(displayCents),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isLiability
                        ? context.appColors.expense
                        : account.currentBalance >= 0
                            ? Theme.of(context).colorScheme.onSurface
                            : context.appColors.expense,
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
                                  ? context.appColors.expense
                                  : utilization > 50
                                      ? context.appColors.warning
                                      : context.appColors.income,
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
                            ? context.appColors.expense
                            : context.appColors.income,
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
                              ? context.appColors.expense
                              : context.appColors.income,
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
            child: TransactionsScreen(
              lockedAccountId: account.id,
              startingBalance: account.startingBalance,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showAppSheet<void>(context, child: AddAccountSheet(account: account));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Archive Account?',
      message: 'This will hide "${account.name}" and its transactions. '
          'Your transaction history is preserved.',
      confirmLabel: 'Archive',
    );
    if (confirmed && context.mounted) {
      await ref.read(accountsRepositoryProvider).deleteAccount(account.id);
      ref.invalidate(accountsProvider);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
