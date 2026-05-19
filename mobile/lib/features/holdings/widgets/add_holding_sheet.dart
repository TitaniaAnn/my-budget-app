// Add / edit a single holding inside an investment account.
//
// Symbol + quantity + current_value are required; description,
// cost_basis, and asset_class are optional. Mirrors the
// AddTransactionSheet shape (validated form, LoadingButton submit,
// delete affordance in the AppBar actions in edit mode) so the
// muscle-memory carries across the app.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/household_provider.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/money_text_field.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../models/holding.dart';
import '../providers/holdings_provider.dart';
import '../repositories/holdings_repository.dart';

class AddHoldingSheet extends ConsumerStatefulWidget {
  /// Account this holding belongs to. Always required — holdings
  /// can't exist outside an account.
  final String accountId;

  /// When provided, the sheet is in edit mode.
  final Holding? holding;

  const AddHoldingSheet({super.key, required this.accountId, this.holding});

  @override
  ConsumerState<AddHoldingSheet> createState() => _AddHoldingSheetState();
}

class _AddHoldingSheetState extends ConsumerState<AddHoldingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _symbolCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _currentValueCtrl = TextEditingController();
  final _costBasisCtrl = TextEditingController();

  AssetClass? _assetClass;
  bool _loading = false;

  bool get _isEditMode => widget.holding != null;

  // Allows digits + a single decimal point with up to 8 places —
  // matches the NUMERIC(20,8) precision on the column so the user
  // can't enter a number that gets silently rounded server-side.
  static final _quantityFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*\.?\d{0,8}'),
  );

  @override
  void initState() {
    super.initState();
    final h = widget.holding;
    if (h != null) {
      _symbolCtrl.text = h.symbol;
      _descriptionCtrl.text = h.description ?? '';
      // Trim trailing zeros for display so "10.00000000" doesn't
      // render — the formatter on edit accepts fewer decimals fine.
      _quantityCtrl.text = _formatQuantity(h.quantity);
      _currentValueCtrl.text = (h.currentValue / 100).toStringAsFixed(2);
      if (h.costBasis != null) {
        _costBasisCtrl.text = (h.costBasis! / 100).toStringAsFixed(2);
      }
      _assetClass = h.assetClass;
    }
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _descriptionCtrl.dispose();
    _quantityCtrl.dispose();
    _currentValueCtrl.dispose();
    _costBasisCtrl.dispose();
    super.dispose();
  }

  static String _formatQuantity(double q) {
    // Show enough decimals to be useful but drop trailing zeros so
    // the field reads "10" / "1.5" / "0.00021" rather than the full
    // 8-place form.
    final s = q.toStringAsFixed(8);
    if (!s.contains('.')) return s;
    final trimmed = s.replaceFirst(RegExp(r'0+$'), '');
    return trimmed.endsWith('.')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(holdingsRepositoryProvider);
      final quantity = double.parse(_quantityCtrl.text);
      final currentValueCents = parseToCents(_currentValueCtrl.text);
      final costBasisCents = _costBasisCtrl.text.trim().isEmpty
          ? null
          : parseToCents(_costBasisCtrl.text);

      if (_isEditMode) {
        await repo.updateHolding(
          holdingId: widget.holding!.id,
          symbol: _symbolCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          quantity: quantity,
          costBasis: costBasisCents,
          currentValue: currentValueCents,
          assetClass: _assetClass,
        );
      } else {
        final householdId = await ref.read(householdIdProvider.future);
        if (householdId == null) throw Exception('Not logged in');
        await repo.createHolding(
          householdId: householdId,
          accountId: widget.accountId,
          symbol: _symbolCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          quantity: quantity,
          costBasis: costBasisCents,
          currentValue: currentValueCents,
          assetClass: _assetClass,
          lastPricedAt: DateTime.now(),
        );
      }

      ref.invalidate(holdingsForAccountProvider(widget.accountId));
      ref.invalidate(householdHoldingsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Remove Holding?',
      message:
          'This removes the position record only — any related '
          'transactions stay intact.',
    );
    if (!confirmed) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(holdingsRepositoryProvider)
          .deleteHolding(widget.holding!.id);
      ref.invalidate(holdingsForAccountProvider(widget.accountId));
      ref.invalidate(householdHoldingsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: _isEditMode ? 'Edit Holding' : 'Add Holding',
      formKey: _formKey,
      scrollable: true,
      actions: [
        if (_isEditMode)
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Remove holding',
            onPressed: _loading ? null : _delete,
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Symbol'),
          TextFormField(
            controller: _symbolCtrl,
            decoration: const InputDecoration(hintText: 'e.g. VTSAX'),
            textCapitalization: TextCapitalization.characters,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          const FieldLabel('Description (optional)'),
          TextFormField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Vanguard Total Stock Market Admiral',
            ),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Quantity'),
          TextFormField(
            controller: _quantityCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_quantityFormatter],
            decoration: const InputDecoration(hintText: '0.00'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              final n = double.tryParse(v);
              if (n == null || n <= 0) return 'Must be a positive number';
              return null;
            },
          ),
          const SizedBox(height: 14),
          const FieldLabel('Current Value'),
          MoneyTextField(
            controller: _currentValueCtrl,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          const FieldLabel('Cost Basis (optional)'),
          MoneyTextField(controller: _costBasisCtrl),
          const SizedBox(height: 14),
          const FieldLabel('Asset Class (optional)'),
          DropdownButtonFormField<AssetClass>(
            initialValue: _assetClass,
            hint: const Text('Unclassified'),
            decoration: const InputDecoration(),
            items: [
              const DropdownMenuItem<AssetClass>(
                value: null,
                child: Text('Unclassified'),
              ),
              ...AssetClass.values.map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: c.sliceColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(c.displayName),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _assetClass = v),
          ),
          const SizedBox(height: 24),
          LoadingButton(
            loading: _loading,
            onPressed: _submit,
            child: Text(_isEditMode ? 'Save Changes' : 'Add Holding'),
          ),
        ],
      ),
    );
  }
}
