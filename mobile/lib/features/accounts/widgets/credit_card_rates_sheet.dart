// Sheet for viewing, adding, and editing credit card interest rates.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credit_card_rate.dart';
import '../providers/credit_card_rates_provider.dart';
import '../repositories/credit_card_rates_repository.dart';

import '../../../shared/widgets/field_label.dart';
class CreditCardRatesSheet extends ConsumerWidget {
  final String accountId;
  const CreditCardRatesSheet({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(creditCardRatesProvider(accountId));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Interest Rates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddEdit(context, ref, null),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ratesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(e.toString(),
                style: TextStyle(color: context.cs.error)),
            data: (rates) {
              if (rates.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No rates added yet. Tap + to add one.',
                        style: TextStyle(color: context.appColors.textSubtle)),
                  ),
                );
              }
              return Column(
                children: rates
                    .map((r) => _RateTile(
                          rate: r,
                          onEdit: () => _showAddEdit(context, ref, r),
                          onDelete: () => _delete(context, ref, r),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddEdit(BuildContext context, WidgetRef ref, CreditCardRate? rate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddEditRateSheet(
        accountId: accountId,
        rate: rate,
        onSaved: () => ref.invalidate(creditCardRatesProvider(accountId)),
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, CreditCardRate rate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Rate?'),
        content: Text('Remove "${rate.label ?? rate.rateType.displayName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(creditCardRatesRepositoryProvider)
          .deleteRate(rate.id);
      ref.invalidate(creditCardRatesProvider(accountId));
    }
  }
}

class _RateTile extends StatelessWidget {
  final CreditCardRate rate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RateTile(
      {required this.rate, required this.onEdit, required this.onDelete});

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expired = rate.introEndsOn != null &&
        rate.introEndsOn!.isBefore(DateTime(now.year, now.month, now.day));
    final colors = context.appColors;
    final mutedColor = colors.textSubtle;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rate.label ?? rate.rateType.displayName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (rate.isIntro) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (expired ? mutedColor : colors.income)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          expired ? 'INTRO EXPIRED' : 'INTRO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: expired ? mutedColor : colors.income,
                          ),
                        ),
                      ),
                    ],
                    if (!rate.isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: mutedColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('INACTIVE',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: mutedColor)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rate.rateType.displayName,
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
                if (rate.introEndsOn != null)
                  Text(
                    expired
                        ? 'Expired ${_dateFmt.format(rate.introEndsOn!)}'
                        : 'Intro ends ${_dateFmt.format(rate.introEndsOn!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: expired ? colors.expense : colors.income,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(rate.rate * 100).toStringAsFixed(2)}%',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.expense),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: mutedColor),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline,
                        size: 18, color: colors.expense),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddEditRateSheet extends ConsumerStatefulWidget {
  final String accountId;
  final CreditCardRate? rate;
  final VoidCallback onSaved;

  const _AddEditRateSheet({
    required this.accountId,
    required this.rate,
    required this.onSaved,
  });

  @override
  ConsumerState<_AddEditRateSheet> createState() => _AddEditRateSheetState();
}

class _AddEditRateSheetState extends ConsumerState<_AddEditRateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  final _labelController = TextEditingController();

  CreditRateType _rateType = CreditRateType.purchase;
  bool _isIntro = false;
  bool _isActive = true;
  DateTime? _introEndsOn;
  bool _loading = false;

  bool get _isEditMode => widget.rate != null;
  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final r = widget.rate;
    if (r != null) {
      _rateType = r.rateType;
      _rateController.text = (r.rate * 100).toStringAsFixed(2);
      _labelController.text = r.label ?? '';
      _isIntro = r.isIntro;
      _isActive = r.isActive;
      _introEndsOn = r.introEndsOn;
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _introEndsOn ?? now.add(const Duration(days: 180)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _introEndsOn = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isIntro && _introEndsOn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set an intro end date')),
      );
      return;
    }
    setState(() => _loading = true);

    try {
      final rate = double.parse(
              _rateController.text.replaceAll(RegExp(r'[^\d.]'), '')) /
          100;
      final label =
          _labelController.text.trim().isEmpty ? null : _labelController.text.trim();
      final repo = ref.read(creditCardRatesRepositoryProvider);

      if (_isEditMode) {
        await repo.updateRate(
          rateId: widget.rate!.id,
          rate: rate,
          isIntro: _isIntro,
          introEndsOn: _isIntro ? _introEndsOn : null,
          label: label,
          isActive: _isActive,
        );
      } else {
        await repo.createRate(
          accountId: widget.accountId,
          rateType: _rateType,
          rate: rate,
          isIntro: _isIntro,
          introEndsOn: _isIntro ? _introEndsOn : null,
          label: label,
        );
      }

      widget.onSaved();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(_isEditMode ? 'Edit Rate' : 'Add Rate',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Rate type (locked on edit)
              const FieldLabel('Rate Type'),
              DropdownButtonFormField<CreditRateType>(
                initialValue: _rateType,
                decoration: const InputDecoration(),
                items: CreditRateType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ))
                    .toList(),
                onChanged: _isEditMode
                    ? null
                    : (v) => setState(() => _rateType = v!),
              ),
              const SizedBox(height: 14),
              // APR value
              const FieldLabel('Annual Rate (APR)'),
              TextFormField(
                controller: _rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                    suffixText: '%', hintText: '24.99'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              // Optional custom label
              const FieldLabel('Label (optional)'),
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(
                    hintText: 'e.g. Intro 0% offer'),
              ),
              const SizedBox(height: 14),
              // Intro toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Introductory rate'),
                subtitle: const Text('Has an expiry date'),
                value: _isIntro,
                onChanged: (v) => setState(() {
                  _isIntro = v;
                  if (!v) _introEndsOn = null;
                }),
              ),
              if (_isIntro) ...[
                const FieldLabel('Intro Ends On'),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: context.appColors.textSubtle),
                        const SizedBox(width: 8),
                        Text(
                          _introEndsOn != null
                              ? _dateFmt.format(_introEndsOn!)
                              : 'Select date',
                          style: TextStyle(
                            color: _introEndsOn != null
                                ? null
                                : context.appColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              // Active toggle (edit only)
              if (_isEditMode)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle:
                      const Text('Inactive rates are hidden from pickers'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
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
                    : Text(_isEditMode ? 'Save Changes' : 'Add Rate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
