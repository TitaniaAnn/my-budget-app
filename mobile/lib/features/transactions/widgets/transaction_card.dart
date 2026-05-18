// Single transaction row widget used in the grouped list on TransactionsScreen.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/utils/color.dart';
import '../../../core/utils/money.dart';
import '../models/transaction.dart';
import '../models/transaction_tag.dart';

/// Displays one transaction with its category icon, description, amount,
/// and date. Expenses are shown in red; income in green.
class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  /// Tags assigned to this transaction. The list view resolves the
  /// txId → tags mapping once via [transactionTagAssignmentsProvider]
  /// and passes the result in per row, so the card never fetches.
  /// Defaults to empty so cards rendered from screens that don't (yet)
  /// surface tags simply render without them.
  final List<TransactionTag> tags;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.tags = const [],
  });

  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.amount < 0;
    final category = transaction.category;
    final cs = context.cs;
    final colors = context.appColors;

    final categoryColor = category?.color == null
        ? null
        : colorFromHex(category!.color);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: cs.surface),
        child: Row(
          children: [
            // Category icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (categoryColor ?? cs.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  categoryIconData(category?.icon),
                  size: 18,
                  color: categoryColor ?? colors.textSubtle,
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
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (category != null || tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          if (category != null)
                            _Chip(
                              label: category.name,
                              color:
                                  categoryColor ??
                                  Theme.of(context).dividerColor,
                              textColor: categoryColor ?? colors.textSubtle,
                            ),
                          for (final tag in tags)
                            _Chip(
                              label: '#${tag.name}',
                              color: tag.color != null
                                  ? colorFromHex(tag.color)
                                  : Theme.of(context).dividerColor,
                              textColor: tag.color != null
                                  ? colorFromHex(tag.color)
                                  : colors.textSubtle,
                            ),
                        ],
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
                    color: isExpense ? colors.expense : colors.income,
                  ),
                ),
                // Paperclip + date. The paperclip surfaces whenever the
                // row is linked to a receipt (via `transactions.receipt_id`)
                // so users can scan a list and tell at a glance which
                // expenses already have proof attached.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (transaction.receiptId != null) ...[
                      Icon(
                        Icons.attach_file_outlined,
                        size: 12,
                        color: colors.textSubtle,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      _dateFmt.format(transaction.transactionDate),
                      style: TextStyle(fontSize: 12, color: colors.textSubtle),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small text-only chip used inside [TransactionCard] for both the
/// category and tag badges. Background is a 20%-alpha tint of [color]
/// so the chip stays subdued; text uses the full color for contrast.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
