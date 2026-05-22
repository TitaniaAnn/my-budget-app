// Bottom sheet for adding or editing a scenario event.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../../accounts/models/account.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../models/scenario_event.dart';
import '../providers/scenarios_provider.dart';
import '../repositories/scenarios_repository.dart';
import '../services/payoff_simulator.dart';

final _isoDateFmt = DateFormat('yyyy-MM-dd');

class AddEventSheet extends ConsumerStatefulWidget {
  const AddEventSheet({super.key, required this.scenarioId, this.existing});

  final String scenarioId;
  final ScenarioEvent? existing;

  @override
  ConsumerState<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<AddEventSheet> {
  final _labelCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  EventType _eventType = EventType.expense;
  DateTime _eventDate = DateTime.now();
  bool _isRecurring = false;
  String _freq = 'MONTHLY'; // DAILY, WEEKLY, MONTHLY, YEARLY
  int? _count; // null = indefinite
  final _countCtrl = TextEditingController();

  /// "Every N units". Empty / null / <2 is treated as 1, which the
  /// engine and the RRULE spec both consider the default. We keep
  /// _intervalCtrl as the source of truth so a user backspacing the
  /// field doesn't get a phantom "1" displayed.
  final _intervalCtrl = TextEditingController();

  // ── Payoff-plan state (EventType.payoff only) ─────────────────
  /// id of the debt account being paid off. Required for payoff
  /// events; the projection looks up the principal from
  /// `accounts.currentBalance`.
  String? _payoffAccountId;

  /// APR in percent (e.g. "21.99"). Persisted as basis points on
  /// the event row; the controller's string is the source of truth
  /// while editing.
  final _aprCtrl = TextEditingController();

  /// False = "monthly payment → payoff date" (user types payment,
  /// we compute when it pays off). True = "target date → required
  /// payment" (user picks a date, we compute the payment).
  bool _payoffByDate = false;

  /// Target payoff date when [_payoffByDate] is true.
  DateTime? _payoffTargetDate;

  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existing!;
      _labelCtrl.text = e.label;
      _amountCtrl.text = (e.amount / 100).toStringAsFixed(0);
      _eventType = e.eventType;
      _eventDate = e.eventDate;
      _isRecurring = e.isRecurring;
      if (e.recurrenceRule != null) {
        final rule = e.recurrenceRule!.toUpperCase();
        final freqMatch = RegExp(r'FREQ=([^;]+)').firstMatch(rule);
        if (freqMatch != null) _freq = freqMatch.group(1)!;
        final countMatch = RegExp(r'COUNT=(\d+)').firstMatch(rule);
        if (countMatch != null) {
          _count = int.tryParse(countMatch.group(1)!);
          _countCtrl.text = _count?.toString() ?? '';
        }
        // INTERVAL=1 is the default — only pre-fill the field for
        // values that actually change the cadence (avoid showing a
        // redundant "1" on every edit).
        final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rule);
        if (intervalMatch != null) {
          final n = int.tryParse(intervalMatch.group(1)!);
          if (n != null && n > 1) _intervalCtrl.text = n.toString();
        }
      }
      // Payoff fields. Pre-fill from the saved event so the user
      // can review/edit; the choice-chip selection will already
      // reflect EventType.payoff via _eventType = e.eventType above.
      if (e.eventType == EventType.payoff) {
        _payoffAccountId = e.accountId;
        if (e.paymentAprBps != null) {
          _aprCtrl.text = (e.paymentAprBps! / 100).toStringAsFixed(2);
        }
      }
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    _countCtrl.dispose();
    _intervalCtrl.dispose();
    _aprCtrl.dispose();
    super.dispose();
  }

  bool get _isPayoff => _eventType == EventType.payoff;

  /// User-entered APR parsed to basis points, or null if unparseable
  /// or empty.
  int? get _aprBps {
    final raw = _aprCtrl.text.trim();
    if (raw.isEmpty) return null;
    final pct = double.tryParse(raw);
    if (pct == null || pct < 0) return null;
    return (pct * 100).round();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  /// Pluralised unit label matching the selected frequency so the
  /// "Repeat every N ___" field reads naturally — "weeks", "months",
  /// not the raw RRULE codeword.
  String get _intervalUnitLabel => switch (_freq) {
    'DAILY' => 'days',
    'WEEKLY' => 'weeks',
    'MONTHLY' => 'months',
    'YEARLY' => 'years',
    _ => 'units',
  };

  String? get _rrule {
    if (!_isRecurring) return null;
    final count = int.tryParse(_countCtrl.text);
    final interval = int.tryParse(_intervalCtrl.text);
    final parts = <String>['FREQ=$_freq'];
    // Only emit INTERVAL when it actually changes the cadence —
    // FREQ=WEEKLY and FREQ=WEEKLY;INTERVAL=1 are equivalent per
    // the engine and the spec, so omitting the redundant param
    // keeps stored RRULEs shorter and cleaner to read.
    if (interval != null && interval > 1) parts.add('INTERVAL=$interval');
    if (count != null && count > 0) parts.add('COUNT=$count');
    return parts.join(';');
  }

  Future<void> _save() async {
    if (_labelCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter a label.');
      return;
    }

    // Payoff path: pull the monthly payment from the simulator
    // (either user-typed or derived from target date). Standard
    // path: parse the amount field.
    final int cents;
    final int? aprBpsToStore;
    final String? accountIdToStore;
    if (_isPayoff) {
      if (_payoffAccountId == null) {
        setState(() => _error = 'Pick a debt account to pay off.');
        return;
      }
      final apr = _aprBps;
      if (apr == null) {
        setState(() => _error = 'Enter an APR (0 if interest-free).');
        return;
      }
      final monthly = _resolvedMonthlyPaymentCents;
      if (monthly == null || monthly <= 0) {
        setState(
          () => _error = _payoffByDate
              ? 'Pick a target date the math can hit.'
              : 'Enter a monthly payment.',
        );
        return;
      }
      cents = monthly;
      aprBpsToStore = apr;
      accountIdToStore = _payoffAccountId;
    } else {
      final raw = _amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
      final dollars = double.tryParse(raw);
      if (dollars == null || dollars <= 0) {
        setState(() => _error = 'Enter a valid amount.');
        return;
      }
      cents = (dollars * 100).round();
      aprBpsToStore = null;
      accountIdToStore = null;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(scenariosRepositoryProvider);

      if (_isEditing) {
        await repo.updateEvent(
          eventId: widget.existing!.id,
          label: _labelCtrl.text.trim(),
          eventDate: _eventDate,
          amountCents: cents,
          eventType: _eventType,
          isRecurring: _isPayoff ? false : _isRecurring,
          recurrenceRule: _isPayoff ? null : _rrule,
          paymentAprBps: aprBpsToStore,
        );
      } else {
        await repo.createEvent(
          scenarioId: widget.scenarioId,
          eventType: _eventType,
          label: _labelCtrl.text.trim(),
          eventDate: _eventDate,
          amountCents: cents,
          isRecurring: _isPayoff ? false : _isRecurring,
          recurrenceRule: _isPayoff ? null : _rrule,
          accountId: accountIdToStore,
          paymentAprBps: aprBpsToStore,
        );
      }

      ref.invalidate(scenarioDetailProvider(widget.scenarioId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Monthly payment in cents derived from the current form state.
  /// In payment mode: parse the amount field directly. In target-
  /// date mode: feed (balance, APR, monthsBetween) into
  /// requiredMonthlyPayment. Null on missing/invalid inputs.
  int? get _resolvedMonthlyPaymentCents {
    if (_payoffByDate) {
      final balance = _payoffAccountBalance;
      final apr = _aprBps;
      final target = _payoffTargetDate;
      if (balance == null || apr == null || target == null) return null;
      final months = _monthsBetween(_eventDate, target);
      if (months <= 0) return null;
      return requiredMonthlyPayment(
        startingBalanceCents: balance,
        aprBps: apr,
        months: months,
      );
    }
    final raw = _amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
    final d = double.tryParse(raw);
    if (d == null || d <= 0) return null;
    return (d * 100).round();
  }

  /// Outstanding principal magnitude on the selected debt account.
  /// Returns null when no account is picked or the balance is
  /// non-negative (i.e., the user selected a non-debt account by
  /// mistake — the dropdown filters these out, but defend anyway).
  int? get _payoffAccountBalance {
    if (_payoffAccountId == null) return null;
    final accountsAsync = ref.read(accountsProvider);
    final list = accountsAsync.valueOrNull;
    if (list == null) return null;
    for (final a in list) {
      if (a.id == _payoffAccountId && a.currentBalance < 0) {
        return a.currentBalance.abs();
      }
    }
    return null;
  }

  static int _monthsBetween(DateTime from, DateTime to) {
    // Inclusive month count: Jan-15 → Feb-15 is one month. Used
    // to drive the inverse amortisation formula.
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  Future<void> _pickPayoffTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _payoffTargetDate ??
          DateTime(_eventDate.year + 2, _eventDate.month, _eventDate.day),
      firstDate: _eventDate,
      lastDate: _eventDate.add(const Duration(days: 365 * 40)),
    );
    if (picked != null) setState(() => _payoffTargetDate = picked);
  }

  /// Standard event fields (income / expense / etc) — amount,
  /// date, recurring toggle. Extracted so the payoff branch can
  /// hide them without nesting the main build method's children.
  List<Widget> _standardFields() {
    return [
      TextField(
        controller: _amountCtrl,
        decoration: const InputDecoration(
          labelText: 'Amount (\$)',
          prefixIcon: Icon(Icons.attach_money),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(_isoDateFmt.format(_eventDate)),
      ),
      const SizedBox(height: 12),
      SwitchListTile(
        value: _isRecurring,
        onChanged: (v) => setState(() => _isRecurring = v),
        title: const Text('Recurring'),
        contentPadding: EdgeInsets.zero,
      ),
    ];
  }

  /// Payoff-plan form: debt-account picker, APR, mode toggle
  /// (monthly payment vs target date), and a live preview that
  /// runs simulatePayoff to show payoff date + total interest.
  List<Widget> _payoffFields(ThemeData theme, ColorScheme cs) {
    final accountsAsync = ref.watch(accountsProvider);
    final debtAccounts = (accountsAsync.valueOrNull ?? const <Account>[])
        .where(
          (a) =>
              a.isActive &&
              (a.accountType.group == AccountGroup.creditCards ||
                  a.accountType.group == AccountGroup.loans) &&
              a.currentBalance < 0,
        )
        .toList();

    return [
      // Debt account picker.
      DropdownButtonFormField<String>(
        initialValue: _payoffAccountId,
        decoration: const InputDecoration(
          labelText: 'Debt account',
          prefixIcon: Icon(Icons.credit_card_outlined),
        ),
        items: [
          for (final a in debtAccounts)
            DropdownMenuItem(
              value: a.id,
              child: Text(
                '${a.name} (\$${(a.currentBalance.abs() / 100).toStringAsFixed(0)})',
              ),
            ),
        ],
        onChanged: (v) {
          setState(() {
            _payoffAccountId = v;
            // Auto-fill APR from the account's stored interest rate
            // on first selection. The user can override; we don't
            // overwrite an existing value.
            if (v != null && _aprCtrl.text.trim().isEmpty) {
              final acct = debtAccounts.firstWhere(
                (a) => a.id == v,
                orElse: () => debtAccounts.first,
              );
              final rate = acct.interestRate;
              if (rate != null) {
                _aprCtrl.text = (rate * 100).toStringAsFixed(2);
              }
            }
          });
        },
      ),
      const SizedBox(height: 12),

      // APR (in percent for human readability; stored as bps).
      TextField(
        controller: _aprCtrl,
        decoration: const InputDecoration(
          labelText: 'APR (%)',
          prefixIcon: Icon(Icons.percent),
          hintText: 'e.g. 21.99',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),

      // Mode toggle: payment ↔ target date.
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Monthly payment')),
          ButtonSegment(value: true, label: Text('Target date')),
        ],
        selected: {_payoffByDate},
        onSelectionChanged: (s) => setState(() => _payoffByDate = s.first),
      ),
      const SizedBox(height: 12),

      if (_payoffByDate)
        OutlinedButton.icon(
          onPressed: _pickPayoffTargetDate,
          icon: const Icon(Icons.event_outlined),
          label: Text(
            _payoffTargetDate == null
                ? 'Pick target date'
                : _isoDateFmt.format(_payoffTargetDate!),
          ),
        )
      else
        TextField(
          controller: _amountCtrl,
          decoration: const InputDecoration(
            labelText: 'Monthly payment (\$)',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
      const SizedBox(height: 12),

      // Start-date picker (when payments begin). Reuses the
      // existing eventDate state.
      OutlinedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text('Start: ${_isoDateFmt.format(_eventDate)}'),
      ),
      const SizedBox(height: 12),

      // Live preview — runs the simulator with current state and
      // shows payoff date + total interest. Pure compute, cheap.
      _payoffPreview(theme, cs),
    ];
  }

  Widget _payoffPreview(ThemeData theme, ColorScheme cs) {
    final balance = _payoffAccountBalance;
    final apr = _aprBps;
    final monthly = _resolvedMonthlyPaymentCents;
    if (balance == null || apr == null || monthly == null || monthly <= 0) {
      return Text(
        'Pick a debt account, APR, and ${_payoffByDate ? "target date" : "monthly payment"} to see the schedule.',
        style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
      );
    }
    final sim = simulatePayoff(
      startingBalanceCents: balance,
      monthlyPaymentCents: monthly,
      aprBps: apr,
      startDate: _eventDate,
    );
    if (!sim.paidOff) {
      return Text(
        'At this payment, the balance never reaches zero. '
        'Increase the payment or extend the target date.',
        style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
      );
    }
    final months = sim.monthCount;
    final years = months ~/ 12;
    final remMonths = months % 12;
    final horizon = years > 0 ? '$years yr ${remMonths}mo' : '${months}mo';
    final paymentLine = _payoffByDate
        ? 'Required payment: \$${(monthly / 100).toStringAsFixed(2)}/mo'
        : 'Paid off by ${_isoDateFmt.format(sim.payoffDate!)} ($horizon)';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(paymentLine, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'Total interest: \$${(sim.totalInterestCents / 100).toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppSheetScaffold(
      title: _isEditing ? 'Edit Event' : 'Add Event',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Event type chips
          Wrap(
            spacing: 8,
            children: EventType.values.map((t) {
              final selected = t == _eventType;
              return ChoiceChip(
                label: Text(t.label),
                selected: selected,
                onSelected: (_) => setState(() => _eventType = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Label
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(
              labelText: 'Label',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),

          if (_isPayoff) ..._payoffFields(theme, cs) else ..._standardFields(),

          if (_isRecurring && !_isPayoff) ...[
            // Frequency picker
            DropdownButtonFormField<String>(
              initialValue: _freq,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                DropdownMenuItem(value: 'YEARLY', child: Text('Yearly')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _freq = v);
              },
            ),
            const SizedBox(height: 12),
            // INTERVAL: "Every N <freq>" — supports biweekly,
            // quarterly, every-other-year. Blank or 1 means
            // "every unit" (the spec default).
            TextField(
              controller: _intervalCtrl,
              decoration: InputDecoration(
                labelText: 'Repeat every ($_intervalUnitLabel)',
                hintText: '1 (every ${_freq.toLowerCase()})',
                prefixIcon: const Icon(Icons.update),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Optional count
            TextField(
              controller: _countCtrl,
              decoration: const InputDecoration(
                labelText: 'Number of times (leave blank for indefinite)',
                prefixIcon: Icon(Icons.repeat),
              ),
              keyboardType: TextInputType.number,
            ),
          ],

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
            child: Text(_isEditing ? 'Save Changes' : 'Add Event'),
          ),
        ],
      ),
    );
  }
}
