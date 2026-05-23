// Account detail screen — shows account info, edit/delete actions, and the
// account's own transaction list.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../holdings/screens/holdings_screen.dart';
import '../../transactions/screens/transactions_screen.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';
import '../../transactions/widgets/import_statement_sheet.dart';
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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

  Color get _typeColor => colorFromHex(
    account.color,
    fallback: account.accountType.group.defaultColor,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCreditCard = account.accountType == AccountType.creditCard;
    // Liability balances are stored as negative cents (debt) and
    // shown as the magnitude owed. Edge case worth pinning: an
    // overpayment / refund flip puts the balance POSITIVE, which
    // means the bank now owes the user — that's a credit balance,
    // not a debt. The label and color need to flip with the sign
    // so a $700 credit doesn't read as "$700 owed".
    final isLiability = account.accountType.isLiability;
    final inCredit = isLiability && account.currentBalance > 0;
    final displayCents = isLiability
        ? account.currentBalance.abs()
        : account.currentBalance;
    final balanceLabel = !isLiability
        ? 'Current Balance'
        : inCredit
        ? 'Credit balance'
        : 'Balance (owed)';
    final limit = account.creditLimit;
    // Magnitude of active debt — what the interest calc applies to.
    // A CC in credit territory accrues no interest.
    final debtForUtilisation = isLiability && account.currentBalance < 0
        ? account.currentBalance.abs()
        : 0;
    // Signed credit-utilisation percentage. Positive when in debt
    // (standard meaning); negative when in credit, surfacing the
    // "headroom beyond zero" position. A $700 credit on a $2k limit
    // reads "-35% of $2,000" — clearer than 0% (hides the position)
    // or +35% (treats the credit as debt).
    final signedUtilization = isCreditCard && limit != null && limit > 0
        ? -account.currentBalance / limit * 100
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
          // Holdings entry — only on investment-group accounts
          // (brokerage / IRA / 401k / 403b / HSA / 529). The detail
          // screen itself stays unchanged; tapping pushes a
          // dedicated HoldingsScreen with FAB-add + edit-on-tap.
          if (account.accountType.group == AccountGroup.investments)
            IconButton(
              icon: const Icon(Icons.trending_up_outlined),
              tooltip: 'Holdings',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => HoldingsScreen(
                    accountId: account.id,
                    accountName: account.name,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import statement',
            onPressed: () => showAppSheet<void>(
              context,
              child: ImportStatementSheet(preselectedAccountId: account.id),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditSheet(context, ref),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transaction',
        onPressed: () => showAppSheet<void>(
          context,
          child: AddTransactionSheet(preselectedAccountId: account.id),
        ),
        child: const Icon(Icons.add),
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
                      child: Icon(
                        account.accountType.icon,
                        color: _typeColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.accountType.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        if (account.institution != null)
                          Text(
                            account.institution!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    if (account.lastFour != null)
                      Text(
                        '••••${account.lastFour}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  balanceLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(displayCents),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    // Color matches the SIGN of the balance, not just
                    // the account type: a CC in credit territory
                    // shows the income color (the bank owes you);
                    // a CC in debt shows the expense color. Asset
                    // accounts use the same sign rule against zero.
                    color: inCredit
                        ? context.appColors.income
                        : isLiability
                        ? context.appColors.expense
                        : account.currentBalance >= 0
                        ? Theme.of(context).colorScheme.onSurface
                        : context.appColors.expense,
                  ),
                ),
                if (signedUtilization != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            // Negative utilisation (credit balance)
                            // clamps to 0 — the bar empties and the
                            // signed % in the label conveys "below
                            // zero owed" without a leftward-growing
                            // bar that'd need a new widget.
                            value: (signedUtilization / 100).clamp(0, 1),
                            minHeight: 5,
                            backgroundColor: Theme.of(context).dividerColor,
                            valueColor: AlwaysStoppedAnimation(
                              signedUtilization > 80
                                  ? context.appColors.expense
                                  : signedUtilization > 50
                                  ? context.appColors.warning
                                  : context.appColors.income,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${signedUtilization.toStringAsFixed(0)}% of ${formatCurrency(limit!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
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
                        // Interest only accrues on DEBT; a credit
                        // balance has nothing to compound, so a CC
                        // sitting at $0 or in credit shows $0.00
                        // monthly. Mortgages / loans always charge
                        // on |balance| since their "balance" is the
                        // unpaid principal magnitude regardless of
                        // storage sign.
                        'Monthly: ${formatCurrency(((debtForUtilisation * account.interestRate!) / 12).round())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
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
      message:
          'This will hide "${account.name}" and its transactions. '
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
