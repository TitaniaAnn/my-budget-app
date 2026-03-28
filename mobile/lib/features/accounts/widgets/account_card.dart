// Visual card for a single account shown in the Accounts list.
// Credit cards get an additional utilization progress bar.
import 'package:flutter/material.dart';
import '../../../core/utils/money.dart';
import '../models/account.dart';

/// Displays one account's name, institution, balance, and (for credit cards)
/// a colour-coded utilization bar that turns red above 80%.
class AccountCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const AccountCard({super.key, required this.account, this.onTap});

  /// Returns the account's custom color if set, otherwise a group default.
  /// The hex string from the DB (e.g. "#3B82F6") is converted to a Color by
  /// prepending FF (full opacity) and parsing as a 32-bit integer.
  Color get _typeColor {
    if (account.color != null) {
      return Color(int.parse('FF${account.color!.replaceAll('#', '')}', radix: 16));
    }
    return switch (account.accountType.group) {
      AccountGroup.banking => const Color(0xFF3B82F6),
      AccountGroup.creditCards => const Color(0xFFEF4444),
      AccountGroup.investments => const Color(0xFF22C55E),
    };
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

  @override
  Widget build(BuildContext context) {
    final isCreditCard = account.accountType == AccountType.creditCard;
    final balance = account.currentBalance;
    final limit = account.creditLimit;
    final utilization = isCreditCard && limit != null && limit > 0
        ? creditUtilization(balance.abs(), limit)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155), width: 1),
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
                    child: Icon(_typeIcon, color: _typeColor, size: 20),
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(balance),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isCreditCard
                              ? const Color(0xFFEF4444)
                              : balance >= 0
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFFEF4444),
                        ),
                      ),
                      if (account.lastFour != null)
                        Text(
                          '••••${account.lastFour}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
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
                          backgroundColor: const Color(0xFF334155),
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
                    const SizedBox(width: 8),
                    Text(
                      '${utilization.toStringAsFixed(0)}% of ${formatCurrency(limit!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
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
