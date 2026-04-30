import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../repositories/accounts_repository.dart';

import '../../../shared/widgets/field_label.dart';
class AddAccountSheet extends ConsumerStatefulWidget {
  /// When provided the sheet is in edit mode.
  final Account? account;

  const AddAccountSheet({super.key, this.account});

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _lastFourController = TextEditingController();
  final _balanceController = TextEditingController();
  final _limitController = TextEditingController();
  final _rateController = TextEditingController();

  AccountType _selectedType = AccountType.checking;
  bool _loading = false;

  bool get _isEditMode => widget.account != null;

  // Account types that can carry an interest rate
  bool get _hasInterestRate => const {
        AccountType.creditCard,
        AccountType.savings,
        AccountType.checking,
        AccountType.brokerage,
        AccountType.iraTraditional,
        AccountType.iraRoth,
        AccountType.retirement401k,
        AccountType.retirement403b,
        AccountType.hsa,
        AccountType.college529,
      }.contains(_selectedType);

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _selectedType = a.accountType;
      _nameController.text = a.name;
      _institutionController.text = a.institution ?? '';
      _lastFourController.text = a.lastFour ?? '';
      // For asset accounts the user enters and edits the balance directly.
      // For liability accounts (credit_card, mortgage) we always present
      // the magnitude — internally stored as negative, displayed as the
      // amount owed so the user types "500" for a $500 balance.
      _balanceController.text =
          (a.startingBalance.abs() / 100).toStringAsFixed(2);
      if (a.creditLimit != null) {
        _limitController.text =
            (a.creditLimit! / 100).toStringAsFixed(2);
      }
      if (a.interestRate != null) {
        _rateController.text =
            (a.interestRate! * 100).toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _lastFourController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Parse the magnitude the user typed, then sign based on account type.
      // Liabilities (credit_card, mortgage) are stored as negative cents so
      // SUM(starting_balance + transactions) yields the right balance and
      // SUM(current_balance) gives net worth without special-casing.
      final magnitudeCents = parseToCents(_balanceController.text).abs();
      final balanceCents =
          _selectedType.isLiability ? -magnitudeCents : magnitudeCents;

      int? limitCents;
      if (_selectedType == AccountType.creditCard &&
          _limitController.text.isNotEmpty) {
        limitCents = parseToCents(_limitController.text).abs();
      }

      double? interestRate;
      if (_hasInterestRate && _rateController.text.isNotEmpty) {
        interestRate = double.parse(
                _rateController.text.replaceAll(RegExp(r'[^\d.]'), '')) /
            100;
      }

      final repo = ref.read(accountsRepositoryProvider);

      if (_isEditMode) {
        await repo.updateAccount(
          accountId: widget.account!.id,
          name: _nameController.text.trim(),
          institution: _institutionController.text.trim().isEmpty
              ? null
              : _institutionController.text.trim(),
          lastFour: _lastFourController.text.trim().isEmpty
              ? null
              : _lastFourController.text.trim(),
          startingBalance: balanceCents,
          creditLimit: limitCents,
          interestRate: interestRate,
        );
        await repo.recalculateBalance(widget.account!.id);
      } else {
        final householdId = await ref.read(householdIdProvider.future);
        final user = ref.read(currentUserProvider);
        if (householdId == null || user == null) {
          throw Exception('Not logged in');
        }
        await repo.createAccount(
          householdId: householdId,
          ownerUserId: user.id,
          name: _nameController.text.trim(),
          accountType: _selectedType,
          institution: _institutionController.text.trim().isEmpty
              ? null
              : _institutionController.text.trim(),
          lastFour: _lastFourController.text.trim().isEmpty
              ? null
              : _lastFourController.text.trim(),
          startingBalance: balanceCents,
          creditLimit: limitCents,
          interestRate: interestRate,
        );
      }

      ref.invalidate(accountsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(_isEditMode ? 'Edit Account' : 'Add Account',
                    style:
                        const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const FieldLabel('Account Type'),
            _AccountTypeSelector(
              selected: _selectedType,
              onChanged: (t) => setState(() => _selectedType = t),
            ),
            const SizedBox(height: 14),
            const FieldLabel('Account Name'),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '${_selectedType.displayName} account name',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            const FieldLabel('Institution (optional)'),
            TextFormField(
              controller: _institutionController,
              decoration: const InputDecoration(hintText: 'e.g. Chase, Fidelity'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Starting Balance'),
                      TextFormField(
                        controller: _balanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(
                          prefixText: '\$',
                          hintText: '0.00',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FieldLabel('Last 4 (optional)'),
                      TextFormField(
                        controller: _lastFourController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration:
                            const InputDecoration(hintText: '1234'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_selectedType == AccountType.creditCard) ...[
              const SizedBox(height: 14),
              const FieldLabel('Credit Limit'),
              TextFormField(
                controller: _limitController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  prefixText: '\$',
                  hintText: '0.00',
                ),
                validator: (v) =>
                    _selectedType == AccountType.creditCard &&
                            (v == null || v.isEmpty)
                        ? 'Enter credit limit'
                        : null,
              ),
            ],
            if (_hasInterestRate) ...[
              const SizedBox(height: 14),
              FieldLabel(_selectedType == AccountType.creditCard
                  ? 'Interest Rate (APR)'
                  : _selectedType == AccountType.savings ||
                          _selectedType == AccountType.checking
                      ? 'Interest Rate (APY)'
                      : 'Expected Return Rate'),
              TextFormField(
                controller: _rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  suffixText: '%',
                  hintText: '0.00',
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditMode ? 'Save Changes' : 'Add Account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTypeSelector extends StatelessWidget {
  final AccountType selected;
  final ValueChanged<AccountType> onChanged;

  const _AccountTypeSelector(
      {required this.selected, required this.onChanged});

  static const _groups = [
    (label: 'Banking', types: [
      AccountType.checking,
      AccountType.savings,
      AccountType.cash,
    ]),
    (label: 'Credit', types: [
      AccountType.creditCard,
    ]),
    (label: 'Loans', types: [
      AccountType.mortgage,
    ]),
    (label: 'Investment & Retirement', types: [
      AccountType.brokerage,
      AccountType.iraTraditional,
      AccountType.iraRoth,
      AccountType.retirement401k,
      AccountType.retirement403b,
      AccountType.hsa,
      AccountType.college529,
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final cs = context.cs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _groups.map((group) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(group.label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textSubtle,
                      letterSpacing: 0.5)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.types.map((type) {
                final isSelected = type == selected;
                return GestureDetector(
                  onTap: () => onChanged(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary.withValues(alpha: 0.15)
                          : cs.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? cs.primary
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? cs.primary : colors.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }
}
