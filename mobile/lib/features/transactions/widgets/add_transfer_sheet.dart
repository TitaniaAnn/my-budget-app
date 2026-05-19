// Add-transfer sheet: records an account-to-account money movement as
// two paired transactions sharing a transfer_id (migration 030).
//
// Kept as its own widget (rather than a mode-switch inside
// AddTransactionSheet) because the form is structurally different —
// no category, no tags, no receipt — and conflating the two would
// either bury the transfer fields behind conditional rendering or
// surface a confusing union of irrelevant inputs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/household_provider.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../../../features/accounts/repositories/accounts_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/money_text_field.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';

class AddTransferSheet extends ConsumerStatefulWidget {
  const AddTransferSheet({super.key});

  @override
  ConsumerState<AddTransferSheet> createState() => _AddTransferSheetState();
}

class _AddTransferSheetState extends ConsumerState<AddTransferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _fromAccountId;
  String? _toAccountId;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccountId == null || _toAccountId == null) return;
    if (_fromAccountId == _toAccountId) {
      // Belt-and-suspenders: the dropdowns already prevent picking the
      // same account on both sides, but a stale state could slip
      // through. The RPC also rejects this — we surface a friendlier
      // message before reaching the wire.
      context.showErrorSnackBar('Source and destination must be different');
      return;
    }

    final amountCents = parseToCents(_amountController.text);
    if (amountCents <= 0) {
      context.showErrorSnackBar('Amount must be greater than zero');
      return;
    }

    setState(() => _loading = true);
    final repo = ref.read(transactionsRepositoryProvider);
    final accountsRepo = ref.read(accountsRepositoryProvider);
    try {
      final householdId = await ref.read(householdIdProvider.future);
      final user = ref.read(currentUserProvider);
      if (householdId == null || user == null) throw Exception('Not logged in');

      await repo.createTransfer(
        householdId: householdId,
        fromAccountId: _fromAccountId!,
        toAccountId: _toAccountId!,
        amountCents: amountCents,
        transactionDate: _date,
        description: _descriptionController.text.trim().isEmpty
            ? 'Transfer'
            : _descriptionController.text.trim(),
        enteredBy: user.id,
      );

      // Both accounts' current_balance has to be recomputed. The
      // RPC inserts the rows but doesn't run the balance trigger
      // — same pattern as createTransaction.
      await accountsRepo.recalculateBalance(_fromAccountId!);
      await accountsRepo.recalculateBalance(_toAccountId!);
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

    return AppSheetScaffold(
      title: 'Transfer Between Accounts',
      formKey: _formKey,
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Amount'),
          MoneyTextField(
            controller: _amountController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          const FieldLabel('From'),
          accountsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Failed to load accounts'),
            data: (accounts) => DropdownButtonFormField<String>(
              initialValue: _fromAccountId,
              hint: const Text('Source account'),
              // Exclude the destination from the source list and vice
              // versa so the UI can't even present an illegal pair.
              items: accounts
                  .where((a) => a.id != _toAccountId)
                  .map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                  )
                  .toList(),
              validator: (v) => v == null ? 'Required' : null,
              onChanged: (v) => setState(() => _fromAccountId = v),
            ),
          ),
          const SizedBox(height: 14),
          const FieldLabel('To'),
          accountsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Failed to load accounts'),
            data: (accounts) => DropdownButtonFormField<String>(
              initialValue: _toAccountId,
              hint: const Text('Destination account'),
              items: accounts
                  .where((a) => a.id != _fromAccountId)
                  .map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                  )
                  .toList(),
              validator: (v) => v == null ? 'Required' : null,
              onChanged: (v) => setState(() => _toAccountId = v),
            ),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Date'),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(DateFormat.yMMMd().format(_date)),
            ),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Description (optional)'),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'e.g. May rent buffer',
            ),
          ),
          const SizedBox(height: 24),
          LoadingButton.filled(
            loading: _loading,
            onPressed: _loading ? null : _submit,
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }
}
