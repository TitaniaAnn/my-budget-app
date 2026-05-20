// Currency settings — pushed from Settings → Investing → Currency.
//
// Two surfaces in one screen:
//   1. Display currency picker (3-letter ISO code). Drives every
//      cross-currency aggregation that knows to read it. Slice 1
//      wires the dashboard's net worth; later slices add budget
//      math and the monthly report.
//   2. FX rate editor — list of all rates the household has saved,
//      grouped by pair, plus a "+ Add rate" action that captures
//      (from, to, date, rate).
//
// The editor is intentionally minimal in v1 — typing a rate is a
// rare action and a full picker UI would be over-built. The
// "missing rate" warning on the dashboard net worth card is the
// primary entry point that brings users here.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/fx_rate.dart';
import '../repositories/fx_rates_repository.dart';

class CurrencySettingsScreen extends ConsumerStatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  ConsumerState<CurrencySettingsScreen> createState() =>
      _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState
    extends ConsumerState<CurrencySettingsScreen> {
  late Future<List<FxRate>> _rates;

  @override
  void initState() {
    super.initState();
    _rates = _loadRates();
  }

  Future<List<FxRate>> _loadRates() async {
    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null) return const [];
    return ref.read(fxRatesRepositoryProvider).fetchAll(householdId);
  }

  void _refreshRates() => setState(() => _rates = _loadRates());

  Future<void> _editDisplayCurrency() async {
    final info = await ref.read(householdInfoProvider.future);
    if (!mounted) return;
    final picked = await _showCurrencyPickerDialog(
      context,
      title: 'Display currency',
      initial: info.displayCurrency,
    );
    if (picked == null || picked == info.displayCurrency) return;
    try {
      await SettingsRepository().updateDisplayCurrency(
        householdId: info.householdId,
        currencyCode: picked,
      );
      ref.invalidate(householdInfoProvider);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  Future<void> _addRate() async {
    final added = await showAppSheet<bool>(
      context,
      child: const _AddFxRateSheet(),
    );
    if (added == true) _refreshRates();
  }

  Future<void> _deleteRate(FxRate rate) async {
    try {
      await ref
          .read(fxRatesRepositoryProvider)
          .deleteRate(
            householdId: rate.householdId,
            fromCurrency: rate.fromCurrency,
            toCurrency: rate.toCurrency,
            asOfDate: rate.asOfDate,
          );
      _refreshRates();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(householdInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Currency')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRate,
        icon: const Icon(Icons.add),
        label: const Text('Add rate'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          infoAsync.when(
            loading: () => const _LoadingTile(),
            error: (e, _) => ListTile(
              title: const Text('Display currency'),
              subtitle: Text('Error: $e'),
            ),
            data: (info) => ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Display currency'),
              subtitle: Text(
                '${info.displayCurrency} — used for all aggregated '
                'totals on the dashboard',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editDisplayCurrency,
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Exchange rates',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.outline,
                letterSpacing: 1,
              ),
            ),
          ),
          FutureBuilder<List<FxRate>>(
            future: _rates,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return ErrorView(error: snap.error!, onRetry: _refreshRates);
              }
              final rates = snap.data ?? const [];
              if (rates.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: EmptyView(
                    icon: Icons.currency_exchange,
                    title: 'No exchange rates yet',
                    subtitle:
                        'Add rates for currency pairs your accounts use. '
                        'They\'re needed to compute net worth across '
                        'currencies.',
                  ),
                );
              }
              return Column(
                children: [for (final r in rates) _RateTile(rate: r, onDelete: () => _deleteRate(r))],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RateTile extends StatelessWidget {
  const _RateTile({required this.rate, required this.onDelete});
  final FxRate rate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListTile(
      title: Text(
        '${rate.fromCurrency} → ${rate.toCurrency}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Rate ${rate.rate.toStringAsFixed(6)} '
        '· as of ${DateFormat.yMMMd().format(rate.asOfDate)}',
        style: TextStyle(fontSize: 12, color: colors.textSubtle),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: colors.expense),
        onPressed: onDelete,
      ),
    );
  }
}

class _AddFxRateSheet extends ConsumerStatefulWidget {
  const _AddFxRateSheet();

  @override
  ConsumerState<_AddFxRateSheet> createState() => _AddFxRateSheetState();
}

class _AddFxRateSheetState extends ConsumerState<_AddFxRateSheet> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _rateController = TextEditingController();
  DateTime _asOf = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOf,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _asOf = picked);
  }

  bool get _ready {
    final from = _fromController.text.trim().toUpperCase();
    final to = _toController.text.trim().toUpperCase();
    final rate = double.tryParse(_rateController.text.trim());
    return from.length == 3 &&
        to.length == 3 &&
        from != to &&
        rate != null &&
        rate > 0;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = ref.read(currentUserProvider);
      final householdId = await ref.read(householdIdProvider.future);
      if (user == null || householdId == null) {
        throw Exception('Not logged in');
      }
      await ref.read(fxRatesRepositoryProvider).setRate(
            householdId: householdId,
            fromCurrency: _fromController.text.trim().toUpperCase(),
            toCurrency: _toController.text.trim().toUpperCase(),
            rate: double.parse(_rateController.text.trim()),
            asOfDate: _asOf,
            createdBy: user.id,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: 'Add exchange rate',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'From (e.g. EUR)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward),
              ),
              Expanded(
                child: TextField(
                  controller: _toController,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'To (e.g. USD)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}(\.\d{0,8})?')),
            ],
            decoration: const InputDecoration(
              labelText: 'Rate (e.g. 1.0573)',
              helperText: '1 unit of "from" = this many units of "to"',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'As of',
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(DateFormat.yMMMd().format(_asOf)),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _ready && !_saving ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save rate'),
          ),
        ],
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Tiny inline dialog that lets the user pick a 3-letter ISO
/// currency code. Free-text rather than a fixed list so a
/// household using e.g. a less-common currency isn't blocked by
/// our incomplete list.
Future<String?> _showCurrencyPickerDialog(
  BuildContext context, {
  required String title,
  required String initial,
}) async {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        autofocus: true,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: const InputDecoration(
          hintText: '3-letter ISO code (e.g. USD)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final code = controller.text.trim().toUpperCase();
            if (code.length == 3) Navigator.of(ctx).pop(code);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
