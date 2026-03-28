// Bottom sheet for adding or editing a scenario event.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scenario_event.dart';
import '../providers/scenarios_provider.dart';
import '../repositories/scenarios_repository.dart';

class AddEventSheet extends ConsumerStatefulWidget {
  const AddEventSheet({
    super.key,
    required this.scenarioId,
    this.existing,
  });

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
      }
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
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

  String? get _rrule {
    if (!_isRecurring) return null;
    final count = int.tryParse(_countCtrl.text);
    return count != null && count > 0
        ? 'FREQ=$_freq;COUNT=$count'
        : 'FREQ=$_freq';
  }

  Future<void> _save() async {
    if (_labelCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter a label.');
      return;
    }
    final raw = _amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
    final dollars = double.tryParse(raw);
    if (dollars == null || dollars <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(scenariosRepositoryProvider);
      final cents = (dollars * 100).round();

      if (_isEditing) {
        await repo.updateEvent(
          eventId: widget.existing!.id,
          label: _labelCtrl.text.trim(),
          eventDate: _eventDate,
          amountCents: cents,
          eventType: _eventType,
          isRecurring: _isRecurring,
          recurrenceRule: _rrule,
        );
      } else {
        await repo.createEvent(
          scenarioId: widget.scenarioId,
          eventType: _eventType,
          label: _labelCtrl.text.trim(),
          eventDate: _eventDate,
          amountCents: cents,
          isRecurring: _isRecurring,
          recurrenceRule: _rrule,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              _isEditing ? 'Edit Event' : 'Add Event',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

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

            // Amount
            TextField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount (\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // Date picker
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                '${_eventDate.year}-'
                '${_eventDate.month.toString().padLeft(2, '0')}-'
                '${_eventDate.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 12),

            // Recurring toggle
            SwitchListTile(
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
              title: const Text('Recurring'),
              contentPadding: EdgeInsets.zero,
            ),

            if (_isRecurring) ...[
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
              Text(_error!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.error),
                  textAlign: TextAlign.center),
            ],

            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Save Changes' : 'Add Event'),
            ),
          ],
        ),
      ),
    );
  }
}
