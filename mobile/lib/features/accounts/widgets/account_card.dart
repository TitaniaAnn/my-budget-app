// Visual card for a single account shown in the Accounts list.
// Credit cards get an additional utilization progress bar.
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color.dart';
import '../../../core/utils/money.dart';
import '../models/account.dart';

/// Displays one account's name, institution, balance, and (for credit cards)
/// a colour-coded utilization bar that turns red above 80%.
class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const AccountCard({super.key, required this.account, this.onTap});

  /// Returns the account's custom color if set, otherwise the group default.
  Color get _typeColor => colorFromHex(
    account.color,
    fallback: account.accountType.group.defaultColor,
  );

  @override
  Widget build(BuildContext context) {
    final isCreditCard = account.accountType == AccountType.creditCard;
    // Liability balances are stored as negative cents (debt) but
    // shown as the magnitude. A CC with currentBalance > 0 is in
    // CREDIT territory (post-overpayment / refund) — the label and
    // colour need to flip, same fix as AccountDetailScreen.
    final isLiability = account.accountType.isLiability;
    final balance = account.currentBalance;
    final inCredit = isLiability && balance > 0;
    final displayCents = isLiability ? balance.abs() : balance;
    final limit = account.creditLimit;
    // Signed credit-utilisation percentage: positive when in debt
    // (standard), negative when in credit (visualises "headroom
    // below zero"). The bar clamps at 0..1 so negative empties it;
    // the label still shows the signed percentage so the credit
    // position is visible.
    final signedUtilization = isCreditCard && limit != null && limit > 0
        ? -balance / limit * 100
        : null;

    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      account.accountType.icon,
                      color: _typeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (account.institution != null)
                          Text(
                            account.institution!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSubtle,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(displayCents),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          // CC in credit territory shows the income
                          // colour (bank owes user), debt shows
                          // expense, asset accounts use sign vs zero.
                          color: inCredit
                              ? colors.income
                              : isLiability
                              ? colors.expense
                              : balance >= 0
                              ? context.cs.onSurface
                              : colors.expense,
                        ),
                      ),
                      if (account.lastFour != null)
                        Text(
                          '••••${account.lastFour}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSubtle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (signedUtilization != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          // Negative utilisation (credit balance)
                          // clamps to 0 — bar empties; signed % in
                          // the label tells the story.
                          value: (signedUtilization / 100).clamp(0, 1),
                          minHeight: 4,
                          backgroundColor: Theme.of(context).dividerColor,
                          valueColor: AlwaysStoppedAnimation(
                            signedUtilization > 80
                                ? colors.expense
                                : signedUtilization > 50
                                ? colors.warning
                                : colors.income,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${signedUtilization.toStringAsFixed(0)}% of ${formatCurrency(limit!)}',
                      style: TextStyle(fontSize: 11, color: colors.textSubtle),
                    ),
                  ],
                ),
              ],
              if (account.interestRate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      isCreditCard
                          ? Icons.percent_rounded
                          : Icons.trending_up_rounded,
                      size: 12,
                      color: isCreditCard ? colors.expense : colors.income,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCreditCard
                          ? '${(account.interestRate! * 100).toStringAsFixed(2)}% APR'
                          : '${(account.interestRate! * 100).toStringAsFixed(2)}% APY',
                      style: TextStyle(
                        fontSize: 11,
                        color: isCreditCard ? colors.expense : colors.income,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
