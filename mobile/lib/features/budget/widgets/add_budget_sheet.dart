// Bottom sheet for creating or editing a budget.
// Lets the user pick a category, enter an amount, and choose a period.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/utils/money.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/transactions/providers/transactions_provider.dart';
import '../../../features/transactions/widgets/add_category_sheet.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/money_text_field.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../models/budget.dart';
import '../providers/budget_provider.dart';
import '../repositories/budget_repository.dart';

/// Opens a bottom sheet for adding a new budget or editing an existing one.
///
/// Pass [existing] to pre-fill the form for editing.
class AddBudgetSheet extends ConsumerStatefulWidget {
  const AddBudgetSheet({super.key, this.existing});

  final Budget? existing;

  @override
  ConsumerState<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends ConsumerState<AddBudgetSheet> {
  final _amountCtrl = TextEditingController();
  String? _selectedCategoryId;
  BudgetPeriod _period = BudgetPeriod.monthly;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final b = widget.existing!;
      _amountCtrl.text = (b.amount / 100).toStringAsFixed(2);
      _selectedCategoryId = b.categoryId;
      _period = b.period;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cents = parseToCents(_amountCtrl.text).abs();
    if (cents <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (_selectedCategoryId == null) {
      setState(() => _error = 'Select a category.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(budgetRepositoryProvider);

      if (_isEditing) {
        await repo.updateBudget(
          budgetId: widget.existing!.id,
          amountCents: cents,
          period: _period,
        );
      } else {
        final householdId = await ref.read(householdIdProvider.future);
        final user = ref.read(currentUserProvider);
        if (householdId == null || user == null) {
          setState(() => _error = 'Not logged in.');
          return;
        }
        await repo.createBudget(
          householdId: householdId,
          categoryId: _selectedCategoryId!,
          amountCents: cents,
          period: _period,
          createdBy: user.id,
        );
      }

      ref.invalidate(budgetDataProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return AppSheetScaffold(
      title: _isEditing ? 'Edit Budget' : 'New Budget',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category picker — disabled when editing (can't change category)
          const FieldLabel('Category'),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (cats) {
              // Show only expense categories (isIncome == false).
              final expense = cats.where((c) => !c.isIncome).toList();
              return DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  ...expense.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Icon(categoryIconData(c.icon), size: 16),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      )),
                  DropdownMenuItem(
                    value: '__new__',
                    child: Row(
                      children: const [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 8),
                        Text('New category…'),
                      ],
                    ),
                  ),
                ],
                onChanged: _isEditing
                    ? null
                    : (v) {
                        if (v == '__new__') {
                          showAppSheet<void>(context,
                              child: const AddCategorySheet());
                        } else {
                          setState(() => _selectedCategoryId = v);
                        }
                      },
              );
            },
          ),
          const SizedBox(height: 14),

          // Amount field
          const FieldLabel('Amount'),
          MoneyTextField(controller: _amountCtrl),
          const SizedBox(height: 14),

          // Period selector — dropdown so all 4 options fit comfortably.
          const FieldLabel('Period'),
          DropdownButtonFormField<BudgetPeriod>(
            initialValue: _period,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            items: BudgetPeriod.values
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.label),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _period = v);
            },
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),
          LoadingButton.filled(
            loading: _saving,
            onPressed: _save,
            child: Text(_isEditing ? 'Save Changes' : 'Create Budget'),
          ),
        ],
      ),
    );
  }
}

