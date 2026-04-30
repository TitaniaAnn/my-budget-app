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
  Color get _typeColor =>
      colorFromHex(account.color, fallback: account.accountType.group.defaultColor);

  @override
  Widget build(BuildContext context) {
    final isCreditCard = account.accountType == AccountType.creditCard;
    // Liability balances are stored as negative cents but shown as the
    // magnitude owed ("$500.00" rather than "-$500.00").
    final isLiability = account.accountType.isLiability;
    final balance = account.currentBalance;
    final displayCents = isLiability ? balance.abs() : balance;
    final limit = account.creditLimit;
    final utilization = isCreditCard && limit != null && limit > 0
        ? creditUtilization(balance.abs(), limit)
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
                    child: Icon(account.accountType.icon,
                        color: _typeColor, size: 20),
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
                          color: isLiability
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
              if (utilization != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (utilization / 100).clamp(0, 1),
                          minHeight: 4,
                          backgroundColor: Theme.of(context).dividerColor,
                          valueColor: AlwaysStoppedAnimation(
                            utilization > 80
                                ? colors.expense
                                : utilization > 50
                                    ? colors.warning
                                    : colors.income,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${utilization.toStringAsFixed(0)}% of ${formatCurrency(limit!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSubtle,
                      ),
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
