// Add/edit sheet for recurring transaction rules.
//
// One widget covers both modes — create when `rule == null`, edit
// when it's set. Edit mode additionally surfaces the active toggle,
// pause-until controls, and a delete button. Mirrors the
// AddTransactionSheet pattern.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/money_text_field.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../models/recurring_transaction.dart';
import '../providers/recurring_transactions_provider.dart';
import '../repositories/recurring_transactions_repository.dart';

class AddRecurringSheet extends ConsumerStatefulWidget {
  /// When non-null, the sheet opens in edit mode with fields
  /// pre-filled. Submit updates that rule instead of creating one.
  final RecurringTransaction? rule;

  const AddRecurringSheet({super.key, this.rule});

  @override
  ConsumerState<AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends ConsumerState<AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();

  bool _isExpense = true;
  String? _accountId;
  RecurrenceCadence _cadence = RecurrenceCadence.monthly;
  DateTime _nextOccurrence = DateTime.now();
  DateTime? _skippedUntil;
  bool _isActive = true;
  bool _loading = false;

  bool get _isEditMode => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    if (r != null) {
      _isExpense = r.amountCents < 0;
      _amountController.text = centsToString(r.amountCents.abs());
      _descriptionController.text = r.description;
      _merchantController.text = r.merchant ?? '';
      _accountId = r.accountId;
      _cadence = r.cadence;
      _nextOccurrence = r.nextOccurrenceDate;
      _skippedUntil = r.skippedUntilDate;
      _isActive = r.isActive;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  Future<void> _pickNextOccurrence() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextOccurrence,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _nextOccurrence = picked);
  }

  Future<void> _pickSkippedUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _skippedUntil ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Skip emissions on or before',
    );
    if (picked != null) setState(() => _skippedUntil = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) return;

    final magnitude = parseToCents(_amountController.text);
    if (magnitude <= 0) {
      context.showErrorSnackBar('Amount must be greater than zero');
      return;
    }
    final signedAmount = _isExpense ? -magnitude : magnitude;

    setState(() => _loading = true);
    final repo = ref.read(recurringTransactionsRepositoryProvider);
    try {
      if (_isEditMode) {
        await repo.update(
          id: widget.rule!.id,
          amountCents: signedAmount,
          description: _descriptionController.text.trim(),
          merchant: _merchantController.text.trim().isEmpty
              ? null
              : _merchantController.text.trim(),
          cadence: _cadence,
          nextOccurrenceDate: _nextOccurrence,
          // Only set skippedUntilDate when it changed AND is non-null
          // — the repo's update() can't distinguish "leave alone"
          // from "clear" via null. Clearing is a separate codepath
          // below (the pause-row's Clear button).
          skippedUntilDate: _skippedUntil != widget.rule!.skippedUntilDate
              ? _skippedUntil
              : null,
          isActive: _isActive,
        );
      } else {
        final user = ref.read(currentUserProvider);
        final householdId = await ref.read(householdIdProvider.future);
        if (householdId == null || user == null) {
          throw Exception('Not logged in');
        }
        await repo.create(
          householdId: householdId,
          accountId: _accountId!,
          amountCents: signedAmount,
          description: _descriptionController.text.trim(),
          merchant: _merchantController.text.trim().isEmpty
              ? null
              : _merchantController.text.trim(),
          cadence: _cadence,
          nextOccurrenceDate: _nextOccurrence,
          createdBy: user.id,
        );
      }
      ref.invalidate(recurringTransactionsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final r = widget.rule;
    if (r == null) return;
    final confirmed = await confirmDestructive(
      context,
      title: 'Delete Recurring Rule?',
      message:
          'Delete "${r.description}"? Past transactions this rule '
          'has emitted will stay on the ledger; only the rule itself '
          'is removed.',
    );
    if (!confirmed) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(recurringTransactionsRepositoryProvider)
          .delete(r.id);
      ref.invalidate(recurringTransactionsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearSkippedUntil() async {
    final r = widget.rule;
    if (r == null) {
      // Pre-create state: just drop the local value.
      setState(() => _skippedUntil = null);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(recurringTransactionsRepositoryProvider)
          .clearSkippedUntil(r.id);
      ref.invalidate(recurringTransactionsProvider);
      if (mounted) setState(() => _skippedUntil = null);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _toggleBtn(String label, bool expense) {
    final selected = _isExpense == expense;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isExpense = expense),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : context.appColors.textSubtle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return AppSheetScaffold(
      title: _isEditMode ? 'Edit Recurring Rule' : 'New Recurring Rule',
      formKey: _formKey,
      scrollable: true,
      actions: [
        if (_isEditMode)
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Delete rule',
            onPressed: _loading ? null : _delete,
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Expense / Income toggle — same affordance as the regular
          // add-transaction sheet so the sign convention is familiar.
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
          const FieldLabel('Amount'),
          MoneyTextField(
            controller: _amountController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          const FieldLabel('Account'),
          accountsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Failed to load accounts'),
            data: (accounts) => DropdownButtonFormField<String>(
              initialValue: _accountId,
              hint: const Text('Select account'),
              items: accounts
                  .map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                  )
                  .toList(),
              validator: (v) => v == null ? 'Required' : null,
              // In edit mode the rule already has an account; keep the
              // dropdown enabled so the user can move a rule between
              // accounts without recreating it.
              onChanged: (v) => setState(() => _accountId = v),
            ),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Description'),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'e.g. Spotify'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          const FieldLabel('Merchant (optional)'),
          TextFormField(
            controller: _merchantController,
            decoration: const InputDecoration(
              hintText: 'Cleaned merchant name',
            ),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Cadence'),
          DropdownButtonFormField<RecurrenceCadence>(
            initialValue: _cadence,
            items: RecurrenceCadence.values
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.displayName),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _cadence = v);
            },
          ),
          const SizedBox(height: 14),
          const FieldLabel('Next occurrence'),
          InkWell(
            onTap: _pickNextOccurrence,
            child: InputDecorator(
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(DateFormat.yMMMd().format(_nextOccurrence)),
            ),
          ),
          if (_isEditMode) ...[
            const SizedBox(height: 18),
            const Divider(),
            // Active toggle. Inactive rules are ignored by the
            // scheduler but kept on the list — useful for "we used
            // to have this subscription" history.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: Text(
                _isActive
                    ? 'Scheduler will emit on the next occurrence'
                    : 'Paused — scheduler will not emit',
                style: TextStyle(
                  fontSize: 11,
                  color: context.appColors.textSubtle,
                ),
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 4),
            const FieldLabel('Pause until (optional)'),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickSkippedUntil,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.calendar_today, size: 18),
                      ),
                      child: Text(
                        _skippedUntil == null
                            ? 'Not paused'
                            : DateFormat.yMMMd().format(_skippedUntil!),
                        style: TextStyle(
                          color: _skippedUntil == null
                              ? context.appColors.textSubtle
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_skippedUntil != null)
                  TextButton(
                    onPressed: _loading ? null : _clearSkippedUntil,
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          LoadingButton.filled(
            loading: _loading,
            onPressed: _loading ? null : _submit,
            child: Text(_isEditMode ? 'Save changes' : 'Create rule'),
          ),
        ],
      ),
    );
  }
}
