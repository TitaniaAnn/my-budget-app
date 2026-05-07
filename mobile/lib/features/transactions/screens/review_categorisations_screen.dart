// Review uncertain ML categorisations.
//
// Surfaces transactions where the ML model assigned a category at low
// confidence (below the auto-apply threshold but above the lower bound).
// The user confirms or corrects each one — both flip
// `category_assigned_by` to 'user', which feeds the next training dump
// in tools/categorizer/dump_labels.py. Confirming a guess is the cheap
// path that turns model uncertainty into ground truth.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';

class ReviewCategorisationsScreen extends ConsumerWidget {
  const ReviewCategorisationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uncertainAsync = ref.watch(uncertainTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review categorisations')),
      body: uncertainAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (txs) {
          if (txs.isEmpty) {
            return _EmptyState();
          }
          return categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load: $e')),
            data: (cats) => ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: txs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) =>
                  _UncertainTile(transaction: txs[i], categories: cats),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: context.appColors.success,
            ),
            const SizedBox(height: 12),
            Text(
              'Nothing to review',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'No uncertain ML categorisations right now.',
              style: TextStyle(color: context.appColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UncertainTile extends ConsumerStatefulWidget {
  const _UncertainTile({required this.transaction, required this.categories});

  final Transaction transaction;
  final List<Category> categories;

  @override
  ConsumerState<_UncertainTile> createState() => _UncertainTileState();
}

class _UncertainTileState extends ConsumerState<_UncertainTile> {
  bool _busy = false;

  Transaction get tx => widget.transaction;

  String get _confidenceLabel {
    final bp = tx.mlModelConfidence;
    if (bp == null) return '';
    // Basis points (0–10000) → percentage with no decimals.
    return '${(bp / 100).round()}%';
  }

  Future<void> _apply(String categoryId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(transactionsRepositoryProvider)
          .setUserCategory(transactionId: tx.id, categoryId: categoryId);
      // Drop this row from the list. transactionsProvider also covers any
      // other view that might be showing this row.
      ref.invalidate(uncertainTransactionsProvider);
      ref.invalidate(transactionsProvider);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDifferent() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryPickerSheet(categories: widget.categories),
    );
    if (picked != null) await _apply(picked);
  }

  @override
  Widget build(BuildContext context) {
    final guess = tx.category;
    final amountColor = tx.amount < 0
        ? context.appColors.expense
        : context.appColors.income;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tx.description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatCurrency(tx.amount),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                DateFormat('MMM d').format(tx.transactionDate),
                style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.textSubtle,
                ),
              ),
              const SizedBox(width: 8),
              if (guess != null) ...[
                Icon(
                  categoryIconData(guess.icon),
                  size: 14,
                  color: context.appColors.textSubtle,
                ),
                const SizedBox(width: 4),
                Text(
                  '${guess.name} · $_confidenceLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textSubtle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy || guess == null
                      ? null
                      : () => _apply(guess.id),
                  child: const Text('Confirm'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _pickDifferent,
                  child: const Text('Change…'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final topLevel = categories.where((c) => c.parentId == null).toList();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: topLevel.length,
          itemBuilder: (_, i) {
            final c = topLevel[i];
            return ListTile(
              leading: Icon(categoryIconData(c.icon)),
              title: Text(c.name),
              onTap: () => Navigator.of(context).pop(c.id),
            );
          },
        ),
      ),
    );
  }
}
