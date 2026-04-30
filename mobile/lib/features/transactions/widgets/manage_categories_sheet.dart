import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/utils/color.dart';
import '../models/category.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';
import 'add_category_sheet.dart';

class ManageCategoriesSheet extends ConsumerWidget {
  const ManageCategoriesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Column(
        children: [
          // Handle + header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                const Text('Categories',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'New category',
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (_) => const AddCategorySheet(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: categoriesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (categories) {
                final custom =
                    categories.where((c) => c.householdId != null).toList();
                final system =
                    categories.where((c) => c.householdId == null).toList();

                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    if (custom.isNotEmpty) ...[
                      _sectionHeader('Custom (tap to delete)'),
                      ...custom.map((c) => _CategoryTile(
                            category: c,
                            canDelete: true,
                            onDelete: () =>
                                _confirmDelete(context, ref, c),
                          )),
                    ],
                    _sectionHeader('System'),
                    ...system.map((c) => _CategoryTile(
                          category: c,
                          canDelete: false,
                          onDelete: null,
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) => Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ctx.appColors.textSubtle,
            ),
          ),
        ),
      );

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          '"${category.name}" will be removed. Transactions assigned to it '
          'will become uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(transactionsRepositoryProvider)
        .deleteCategory(category.id);
    ref.invalidate(categoriesProvider);
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool canDelete;
  final VoidCallback? onDelete;

  const _CategoryTile({
    required this.category,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = colorFromHex(category.color, fallback: colors.textSubtle);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(categoryIconData(category.icon), color: color, size: 18),
      ),
      title: Text(category.name),
      subtitle: Text(
        category.isIncome ? 'Income' : 'Expense',
        style: TextStyle(
          fontSize: 12,
          color: category.isIncome ? colors.income : colors.textMuted,
        ),
      ),
      trailing: canDelete
          ? IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              onPressed: onDelete,
            )
          : Icon(Icons.lock_outline,
              size: 16, color: colors.textSubtle),
    );
  }
}
