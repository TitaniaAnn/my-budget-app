// Budget screen — shows all household budgets with progress bars indicating
// how much of each budget has been spent in the current period.
//
// Tapping a card opens the edit sheet. The FAB opens the add sheet.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/utils/color.dart';
import '../../../features/transactions/widgets/manage_categories_sheet.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../repositories/budget_repository.dart';
import '../widgets/add_budget_sheet.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outlined),
            tooltip: 'Manage Categories',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => const ManageCategoriesSheet(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSheet(context),
        tooltip: 'Add Budget',
        child: const Icon(Icons.add),
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (budgets) {
          if (budgets.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(budgetDataProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: budgets.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _BudgetCard(
                item: budgets[i],
                onEdit: () => _openSheet(context, existing: budgets[i].budget),
                onDelete: () => _confirmDelete(context, ref, budgets[i].budget),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openSheet(BuildContext context, {Budget? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddBudgetSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: const Text('This will remove the budget limit for this category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(budgetRepositoryProvider).deleteBudget(budget.id);
    ref.invalidate(budgetDataProvider);
  }
}

// ---------------------------------------------------------------------------
// Budget card — progress bar + spent / remaining amounts
// ---------------------------------------------------------------------------

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetWithSpending item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Use the category color if present, otherwise fall back to primary.
    final barColor = colorFromHex(item.categoryColor, fallback: cs.primary);

    final overBudget = item.isOverBudget;

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────────
              Row(
                children: [
                  // Category icon bubble
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        categoryIconData(item.categoryIcon),
                        size: 18,
                        color: barColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.categoryName,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item.budget.period.label,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                  // Overflow menu
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Stacked progress bars: actual (solid) + projected (ghost) ──
              // The ghost bar sits behind and shows the projected end-of-period
              // spend. The solid bar shows what has actually been spent so far.
              Stack(
                children: [
                  // Ghost bar — projection
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.projectedProgress,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        item.isProjectedOver
                            ? cs.error.withValues(alpha: 0.30)
                            : barColor.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  // Solid bar — actual spend
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        overBudget ? cs.error : barColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Spent / budget row ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${fmt.format(item.spentCents / 100)} spent',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: overBudget ? cs.error : cs.onSurface,
                      fontWeight:
                          overBudget ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    'of ${fmt.format(item.budget.amount / 100)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                  ),
                ],
              ),

              // ── Projection row ──────────────────────────────────────────
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    item.isProjectedOver
                        ? Icons.trending_up
                        : Icons.trending_flat,
                    size: 13,
                    color: item.isProjectedOver ? cs.error : cs.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'On track for ${fmt.format(item.projectedCents / 100)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.isProjectedOver ? cs.error : cs.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),

              // ── Over-budget warning ─────────────────────────────────────
              if (overBudget) ...[
                const SizedBox(height: 4),
                Text(
                  'Over by ${fmt.format((-item.remainingCents) / 100)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.error, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No Budgets Yet',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to set a spending limit\nfor a category.',
            style: TextStyle(color: context.appColors.textSubtle),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
