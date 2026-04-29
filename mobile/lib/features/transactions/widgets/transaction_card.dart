// Single transaction row widget used in the grouped list on TransactionsScreen.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/utils/money.dart';
import '../models/transaction.dart';

/// Displays one transaction with its category icon, description, amount,
/// and date. Expenses are shown in red; income in green.
class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionCard({super.key, required this.transaction, this.onTap});

  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.amount < 0;
    final category = transaction.category;

    Color? categoryColor;
    if (category?.color != null) {
      categoryColor = Color(
          int.parse('FF${category!.color!.replaceAll('#', '')}', radix: 16));
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
        ),
        child: Row(
          children: [
            // Category icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (categoryColor ?? const Color(0xFF3B82F6))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  categoryIconData(category?.icon),
                  size: 18,
                  color: categoryColor ?? const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Description + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchant ?? transaction.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (category != null)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (categoryColor ?? const Color(0xFF334155))
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: categoryColor ?? const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Amount + date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '-' : '+'}${formatCurrency(transaction.amount.abs())}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isExpense
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF22C55E),
                  ),
                ),
                Text(
                  _dateFmt.format(transaction.transactionDate),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
