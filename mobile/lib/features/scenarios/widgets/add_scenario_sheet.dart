// Bottom sheet for creating or editing a scenario / goal.
//
// Two kinds of scenarios live behind one form:
//   * general — name, description, optional "track as goal" toggle
//     with target $ + date. Owns an events timeline (added on the
//     detail screen).
//   * debt_payoff — picks one or more debt accounts (credit cards /
//     loans / mortgages), a payoff strategy, and a monthly budget.
//     Min payments auto-fill from `recommendedMinPayment` per debt
//     and remain editable. Per-debt extras only show in custom mode.
//
// The kind selector is the first control; everything below it
// re-renders on toggle. Editing an existing scenario locks the
// kind (a general↔debt-payoff swap would invalidate either the
// event list or the targets, neither of which the sheet owns).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/dates.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/utils/color.dart';
import '../../../core/utils/money.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../../accounts/models/account.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../models/scenario.dart';
import '../providers/scenarios_provider.dart';
import '../repositories/scenarios_repository.dart';
import '../services/debt_payoff_simulator.dart';

final _isoDateFmt = kIsoDate;

/// Preset accent colors the user can pick for a scenario card / chart line.
const _palette = [
  Color(0xFF6366F1), // indigo
  Color(0xFF22C55E), // green
  Color(0xFFF59E0B), // amber
  Color(0xFFEF4444), // red
  Color(0xFF3B82F6), // blue
  Color(0xFFEC4899), // pink
  Color(0xFF14B8A6), // teal
  Color(0xFFF97316), // orange
];

class AddScenarioSheet extends ConsumerStatefulWidget {
  const AddScenarioSheet({super.key, this.existing});
  final Scenario? existing;

  @override
  ConsumerState<AddScenarioSheet> createState() => _AddScenarioSheetState();
}

/// Editable per-debt row. Mirrors [DebtPayoffTarget] but with
/// `TextEditingController`s so the user can type min/extra payments
/// without each keystroke rebuilding the parent state.
class _DebtRow {
  _DebtRow({
    required this.accountId,
    required this.principalCents,
    required this.aprBps,
    required int initialMinCents,
    int initialExtraCents = 0,
  }) : minCtrl = TextEditingController(
         text: (initialMinCents / 100).toStringAsFixed(2),
       ),
       extraCtrl = TextEditingController(
         text: initialExtraCents > 0
             ? (initialExtraCents / 100).toStringAsFixed(2)
             : '',
       );

  final String accountId;
  final int principalCents;
  final int aprBps;
  final TextEditingController minCtrl;
  final TextEditingController extraCtrl;

  int get minCents => parseToCents(minCtrl.text);
  int get extraCents => parseToCents(extraCtrl.text);

  DebtPayoffTarget toTarget() => DebtPayoffTarget(
    accountId: accountId,
    minPaymentCents: minCents,
    aprBps: aprBps,
    extraPaymentCents: extraCents > 0 ? extraCents : null,
  );

  void dispose() {
    minCtrl.dispose();
    extraCtrl.dispose();
  }
}

class _AddScenarioSheetState extends ConsumerState<AddScenarioSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _monthlyBudgetCtrl = TextEditingController();
  Color _color = _palette.first;
  bool _isGoal = false;
  DateTime? _targetDate;
  bool _saving = false;
  String? _error;

  ScenarioKind _kind = ScenarioKind.general;
  DebtPayoffStrategy _strategy = DebtPayoffStrategy.avalanche;
  final List<_DebtRow> _debtRows = [];

  bool get _isEditing => widget.existing != null;
  bool get _isDebtPayoff => _kind == ScenarioKind.debtPayoff;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final s = widget.existing!;
      _nameCtrl.text = s.name;
      _descCtrl.text = s.description ?? '';
      _isGoal = s.isGoal;
      _targetDate = s.targetDate;
      if (s.targetAmount != null) {
        _targetCtrl.text = (s.targetAmount! / 100).toStringAsFixed(0);
      }
      if (s.color != null) {
        _color = colorFromHex(s.color, fallback: _palette.first);
      }
      _kind = s.kind;
      if (_isDebtPayoff) {
        _strategy = s.debtPayoffStrategy ?? DebtPayoffStrategy.avalanche;
        if (s.debtPayoffMonthlyBudgetCents != null) {
          _monthlyBudgetCtrl.text = (s.debtPayoffMonthlyBudgetCents! / 100)
              .toStringAsFixed(0);
        }
        // Per-debt rows hydrate once accounts load; see _hydrateDebtRows.
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _monthlyBudgetCtrl.dispose();
    for (final r in _debtRows) {
      r.dispose();
    }
    super.dispose();
  }

  /// On first build after accounts are available, populate _debtRows
  /// from the saved targets (edit flow) — needs the current account
  /// balance to pass into the simulator later, which isn't on the
  /// scenario row itself.
  void _hydrateDebtRowsIfNeeded(List<Account> accounts) {
    if (!_isEditing || !_isDebtPayoff || _debtRows.isNotEmpty) return;
    final targets = widget.existing!.debtPayoffTargets ?? const [];
    for (final t in targets) {
      final acct = accounts.where((a) => a.id == t.accountId).firstOrNull;
      if (acct == null) continue; // account deleted — silently drop
      _debtRows.add(
        _DebtRow(
          accountId: t.accountId,
          principalCents: acct.currentBalance.abs(),
          aprBps: t.aprBps,
          initialMinCents: t.minPaymentCents,
          initialExtraCents: t.extraPaymentCents ?? 0,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _addDebt(Account a) {
    final principal = a.currentBalance.abs();
    final aprBps = ((a.interestRate ?? 0) * 10000).round();
    setState(() {
      _debtRows.add(
        _DebtRow(
          accountId: a.id,
          principalCents: principal,
          aprBps: aprBps,
          initialMinCents: recommendedMinPayment(
            principalCents: principal,
            aprBps: aprBps,
          ),
        ),
      );
    });
  }

  void _removeDebt(int index) {
    setState(() {
      final r = _debtRows.removeAt(index);
      r.dispose();
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    if (_isGoal && _targetDate == null) {
      setState(() => _error = 'Pick a target date for your goal.');
      return;
    }
    int? monthlyBudgetCents;
    if (_isDebtPayoff) {
      if (_debtRows.isEmpty) {
        setState(() => _error = 'Add at least one debt account.');
        return;
      }
      monthlyBudgetCents = parseToCents(_monthlyBudgetCtrl.text);
      if (monthlyBudgetCents <= 0) {
        setState(() => _error = 'Enter your total monthly budget.');
        return;
      }
      final sumMins = _debtRows.fold<int>(0, (acc, r) => acc + r.minCents);
      if (monthlyBudgetCents < sumMins) {
        setState(
          () => _error =
              'Budget (${formatCurrency(monthlyBudgetCents!)}) must cover the '
              'sum of minimums (${formatCurrency(sumMins)}).',
        );
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(scenariosRepositoryProvider);
      final hexColor = colorToHex(_color);
      final rawTarget = _targetCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
      final targetCents = rawTarget.isNotEmpty
          ? ((double.tryParse(rawTarget) ?? 0) * 100).round()
          : null;
      final targets = _isDebtPayoff
          ? _debtRows.map((r) => r.toTarget()).toList()
          : null;

      if (_isEditing) {
        await repo.updateScenario(
          scenarioId: widget.existing!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isNotEmpty
              ? _descCtrl.text.trim()
              : null,
          color: hexColor,
          // Debt-payoff scenarios can't simultaneously be tracked as
          // a $-target goal — the projection shape is different.
          isGoal: _isDebtPayoff ? false : _isGoal,
          targetAmount: !_isDebtPayoff && _isGoal ? targetCents : null,
          targetDate: !_isDebtPayoff && _isGoal ? _targetDate : null,
          debtPayoffTargets: targets,
          debtPayoffStrategy: _isDebtPayoff ? _strategy : null,
          debtPayoffMonthlyBudgetCents: monthlyBudgetCents,
        );
      } else {
        final householdId = await ref.read(householdIdProvider.future);
        final user = ref.read(currentUserProvider);
        if (householdId == null || user == null) {
          setState(() => _error = 'Not logged in.');
          return;
        }
        await repo.createScenario(
          householdId: householdId,
          createdBy: user.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isNotEmpty
              ? _descCtrl.text.trim()
              : null,
          color: hexColor,
          isGoal: _isDebtPayoff ? false : _isGoal,
          targetAmount: !_isDebtPayoff && _isGoal ? targetCents : null,
          targetDate: !_isDebtPayoff && _isGoal ? _targetDate : null,
          kind: _kind,
          debtPayoffTargets: targets,
          debtPayoffStrategy: _isDebtPayoff ? _strategy : null,
          debtPayoffMonthlyBudgetCents: monthlyBudgetCents,
        );
      }

      ref.invalidate(scenariosProvider);
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
    final cs = theme.colorScheme;
    final accountsAsync = ref.watch(accountsProvider);

    // Hydrate edit-flow debt rows once accounts data is available.
    accountsAsync.whenData((accounts) {
      _hydrateDebtRowsIfNeeded(accounts);
    });

    return AppSheetScaffold(
      title: _isEditing ? 'Edit Scenario' : 'New Scenario',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Kind selector ──────────────────────────────────────────
          // Locked when editing because changing the kind would orphan
          // either the events timeline (general) or the debt targets
          // (debt-payoff), and neither cleanup lives here.
          _KindSegmented(
            kind: _kind,
            enabled: !_isEditing,
            onChanged: (k) => setState(() => _kind = k),
          ),
          const SizedBox(height: 16),

          // Name
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.label_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          // Description
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.notes),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // ── General-kind fields ────────────────────────────────────
          if (!_isDebtPayoff) ...[
            SwitchListTile(
              value: _isGoal,
              onChanged: (v) => setState(() => _isGoal = v),
              title: const Text('Save as Goal'),
              subtitle: const Text('Track progress toward a target'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isGoal) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _targetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target Amount (\$)',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _targetDate == null
                      ? 'Pick Target Date'
                      : 'Target: ${_isoDateFmt.format(_targetDate!)}',
                ),
              ),
            ],
          ],

          // ── Debt-payoff-kind fields ────────────────────────────────
          if (_isDebtPayoff) ...[
            _StrategySegmented(
              strategy: _strategy,
              onChanged: (s) => setState(() => _strategy = s),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _monthlyBudgetCtrl,
              decoration: const InputDecoration(
                labelText: 'Monthly budget (\$)',
                helperText: 'Total committed across all debts',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Debts', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            // The list + picker rely on accounts loading; show a
            // small inline indicator instead of blocking the whole
            // form.
            accountsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text(
                'Couldn\'t load accounts: $e',
                style: TextStyle(color: cs.error),
              ),
              data: (accounts) {
                // Eligible debts = liability-group accounts (CC + loans),
                // active, with non-zero magnitude balance. The
                // simulator drops zero-balance targets anyway, but
                // surfacing them in the picker would just confuse.
                final eligible = accounts
                    .where(
                      (a) =>
                          a.isActive &&
                          a.accountType.isLiability &&
                          a.currentBalance.abs() > 0,
                    )
                    .toList();
                final selectedIds = _debtRows.map((r) => r.accountId).toSet();
                final available = eligible
                    .where((a) => !selectedIds.contains(a.id))
                    .toList();
                return Column(
                  children: [
                    for (var i = 0; i < _debtRows.length; i++)
                      _DebtRowEditor(
                        row: _debtRows[i],
                        account: accounts.firstWhere(
                          (a) => a.id == _debtRows[i].accountId,
                          orElse: () => accounts.first,
                        ),
                        showExtra: _strategy == DebtPayoffStrategy.custom,
                        onRemove: () => _removeDebt(i),
                      ),
                    const SizedBox(height: 8),
                    _AddDebtButton(available: available, onAdd: _addDebt),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 16),

          // Color palette
          Text('Color', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _palette.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(color: cs.onSurface, width: 2.5)
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),
          LoadingButton.filled(
            loading: _saving,
            onPressed: _save,
            child: Text(_isEditing ? 'Save Changes' : 'Create'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Three-way segmented control over [ScenarioKind]. Disabled state
/// dims the unselected option so the edit-flow lock is visible.
class _KindSegmented extends StatelessWidget {
  const _KindSegmented({
    required this.kind,
    required this.onChanged,
    required this.enabled,
  });
  final ScenarioKind kind;
  final ValueChanged<ScenarioKind> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ScenarioKind>(
      segments: const [
        ButtonSegment(
          value: ScenarioKind.general,
          label: Text('General'),
          icon: Icon(Icons.timeline),
        ),
        ButtonSegment(
          value: ScenarioKind.debtPayoff,
          label: Text('Debt payoff'),
          icon: Icon(Icons.credit_card_off_outlined),
        ),
      ],
      selected: {kind},
      onSelectionChanged: enabled ? (s) => onChanged(s.first) : null,
    );
  }
}

/// Strategy selector for the debt-payoff form. Three small buttons
/// in a row — avalanche / snowball / custom — with descriptive
/// helper text below.
class _StrategySegmented extends StatelessWidget {
  const _StrategySegmented({required this.strategy, required this.onChanged});
  final DebtPayoffStrategy strategy;
  final ValueChanged<DebtPayoffStrategy> onChanged;

  String _explanationFor(DebtPayoffStrategy s) => switch (s) {
    DebtPayoffStrategy.avalanche =>
      'Extra payments target the highest APR first — lowest total interest.',
    DebtPayoffStrategy.snowball =>
      'Extra payments target the smallest balance first — fastest wins.',
    DebtPayoffStrategy.custom =>
      'You set the extra-over-minimum on each debt yourself.',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<DebtPayoffStrategy>(
          segments: const [
            ButtonSegment(
              value: DebtPayoffStrategy.avalanche,
              label: Text('Avalanche'),
            ),
            ButtonSegment(
              value: DebtPayoffStrategy.snowball,
              label: Text('Snowball'),
            ),
            ButtonSegment(
              value: DebtPayoffStrategy.custom,
              label: Text('Custom'),
            ),
          ],
          selected: {strategy},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
        const SizedBox(height: 6),
        Text(
          _explanationFor(strategy),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// One row in the debts list — account name + balance + APR header,
/// editable min payment, editable extra (custom strategy only),
/// remove button.
class _DebtRowEditor extends StatelessWidget {
  const _DebtRowEditor({
    required this.row,
    required this.account,
    required this.showExtra,
    required this.onRemove,
  });
  final _DebtRow row;
  final Account account;
  final bool showExtra;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(account.accountType.icon, size: 18, color: cs.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${formatCurrency(row.principalCents)} owed · '
                      '${(row.aprBps / 100).toStringAsFixed(2)}% APR',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Remove',
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.minCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Min payment (\$)',
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              if (showExtra) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.extraCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Extra (\$)',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact PopupMenuButton "Add debt" — only renders something when
/// at least one eligible debt account isn't already in the list.
class _AddDebtButton extends StatelessWidget {
  const _AddDebtButton({required this.available, required this.onAdd});
  final List<Account> available;
  final ValueChanged<Account> onAdd;

  @override
  Widget build(BuildContext context) {
    if (available.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No more eligible debt accounts to add.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<Account>(
        onSelected: onAdd,
        itemBuilder: (_) => [
          for (final a in available)
            PopupMenuItem(
              value: a,
              child: Text(
                '${a.name} — ${formatCurrency(a.currentBalance.abs())}',
              ),
            ),
        ],
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, size: 18),
              SizedBox(width: 6),
              Text('Add debt'),
            ],
          ),
        ),
      ),
    );
  }
}
