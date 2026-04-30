import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/models/account.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../../../features/accounts/providers/credit_card_rates_provider.dart';
import '../../../features/accounts/repositories/accounts_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/money_text_field.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../models/transaction.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';
class AddTransactionSheet extends ConsumerStatefulWidget {
  /// Pre-select an account when opened from an account's transaction list.
  final String? preselectedAccountId;

  /// When provided the sheet is in edit mode — fields are pre-filled and
  /// the submit action calls [updateTransaction] instead of [createTransaction].
  final Transaction? transaction;

  const AddTransactionSheet({
    super.key,
    this.preselectedAccountId,
    this.transaction,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isExpense = true;
  DateTime _date = DateTime.now();
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedRateId;
  bool _loading = false;

  bool get _isEditMode => widget.transaction != null;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      _isExpense = tx.amount < 0;
      _amountController.text =
          (tx.amount.abs() / 100).toStringAsFixed(2);
      _descriptionController.text = tx.description;
      _merchantController.text = tx.merchant ?? '';
      _notesController.text = tx.notes ?? '';
      _date = tx.transactionDate;
      _selectedAccountId = tx.accountId;
      _selectedCategoryId = tx.categoryId;
      _selectedRateId = tx.rateId;
    } else {
      _selectedAccountId = widget.preselectedAccountId;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _delete() async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Delete Transaction?',
      message: 'This transaction will be permanently removed.',
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(transactionsRepositoryProvider);
      final accountsRepo = ref.read(accountsRepositoryProvider);
      await repo.deleteTransaction(widget.transaction!.id);
      await accountsRepo.recalculateBalance(widget.transaction!.accountId);
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final amountCents = parseToCents(_amountController.text).abs();
      final signedAmount = _isExpense ? -amountCents : amountCents;
      final repo = ref.read(transactionsRepositoryProvider);

      final accountsRepo = ref.read(accountsRepositoryProvider);
      final String affectedAccountId;

      if (_isEditMode) {
        await repo.updateTransaction(
          id: widget.transaction!.id,
          amount: signedAmount,
          description: _descriptionController.text.trim(),
          transactionDate: _date,
          merchant: _merchantController.text.trim().isEmpty
              ? null
              : _merchantController.text.trim(),
          categoryId: _selectedCategoryId,
          rateId: _selectedRateId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        affectedAccountId = widget.transaction!.accountId;
      } else {
        final householdId = await ref.read(householdIdProvider.future);
        final user = ref.read(currentUserProvider);
        if (householdId == null || user == null) throw Exception('Not logged in');

        await repo.createTransaction(
          householdId: householdId,
          accountId: _selectedAccountId!,
          enteredBy: user.id,
          amount: signedAmount,
          description: _descriptionController.text.trim(),
          transactionDate: _date,
          merchant: _merchantController.text.trim().isEmpty
              ? null
              : _merchantController.text.trim(),
          categoryId: _selectedCategoryId,
          rateId: _selectedRateId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        affectedAccountId = _selectedAccountId!;
      }

      await accountsRepo.recalculateBalance(affectedAccountId);
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return AppSheetScaffold(
      title: _isEditMode ? 'Edit Transaction' : 'Add Transaction',
      formKey: _formKey,
      scrollable: true,
      actions: [
        if (_isEditMode)
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.error),
            tooltip: 'Delete transaction',
            onPressed: _loading ? null : _delete,
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Expense / Income toggle
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _toggleBtn('Expense', true),
                _toggleBtn('Income', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Amount
          const FieldLabel('Amount'),
          MoneyTextField(
            controller: _amountController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
              const SizedBox(height: 14),
              // Account selector
              const FieldLabel('Account'),
              accountsAsync.when(
                loading: () =>
                    const LinearProgressIndicator(),
                error: (_, _) =>
                    const Text('Failed to load accounts'),
                data: (accounts) => DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  hint: const Text('Select account'),
                  decoration: const InputDecoration(),
                  items: accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedAccountId = v),
                ),
              ),
              const SizedBox(height: 14),
              // Description
              const FieldLabel('Description'),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(hintText: 'What was this for?'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Merchant (optional)'),
                        TextFormField(
                          controller: _merchantController,
                          decoration: const InputDecoration(
                              hintText: 'e.g. Amazon'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Date'),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: context.cs.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 16,
                                    color: context.appColors.textSubtle),
                                const SizedBox(width: 6),
                                Text(
                                  _dateFmt.format(_date),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Category
              const FieldLabel('Category (optional)'),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (cats) => DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  hint: const Text('None'),
                  decoration: const InputDecoration(),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('None'),
                    ),
                    ...cats.where((c) => c.parentId == null).map((c) =>
                        DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(categoryIconData(c.icon), size: 16),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
              ),
              // Rate picker — only for credit card accounts
              if (_selectedAccountId != null)
                accountsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (accounts) {
                    final acct = accounts
                        .where((a) => a.id == _selectedAccountId)
                        .firstOrNull;
                    if (acct == null ||
                        acct.accountType != AccountType.creditCard) {
                      return const SizedBox.shrink();
                    }
                    final ratesAsync = ref
                        .watch(creditCardRatesProvider(_selectedAccountId!));
                    return ratesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (rates) {
                        final active =
                            rates.where((r) => r.isActive).toList();
                        if (active.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            const FieldLabel('Interest Rate (optional)'),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRateId,
                              hint: const Text('Default (purchase rate)'),
                              decoration: const InputDecoration(),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Default (purchase rate)'),
                                ),
                                ...active.map((r) => DropdownMenuItem(
                                      value: r.id,
                                      child: Text(
                                        '${r.label ?? r.rateType.displayName}'
                                        ' — ${(r.rate * 100).toStringAsFixed(2)}%'
                                        '${r.isIntro ? ' (intro)' : ''}',
                                      ),
                                    )),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedRateId = v),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
          const SizedBox(height: 24),
          LoadingButton(
            loading: _loading,
            onPressed: _submit,
            child: Text(_isEditMode ? 'Save Changes' : 'Add Transaction'),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool isExpense) {
    final selected = _isExpense == isExpense;
    final colors = context.appColors;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isExpense = isExpense),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isExpense ? colors.expense : colors.income)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : colors.textSubtle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
