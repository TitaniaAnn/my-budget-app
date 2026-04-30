// Bottom sheet for creating or editing a scenario / goal.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/utils/color.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../models/scenario.dart';
import '../providers/scenarios_provider.dart';
import '../repositories/scenarios_repository.dart';

final _isoDateFmt = DateFormat('yyyy-MM-dd');

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

class _AddScenarioSheetState extends ConsumerState<AddScenarioSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  Color _color = _palette.first;
  bool _isGoal = false;
  DateTime? _targetDate;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

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
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _targetDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    if (picked != null) setState(() => _targetDate = picked);
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

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(scenariosRepositoryProvider);
      final hexColor = colorToHex(_color);
      final rawTarget =
          _targetCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
      final targetCents = rawTarget.isNotEmpty
          ? ((double.tryParse(rawTarget) ?? 0) * 100).round()
          : null;

      if (_isEditing) {
        await repo.updateScenario(
          scenarioId: widget.existing!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim().isNotEmpty
              ? _descCtrl.text.trim()
              : null,
          color: hexColor,
          isGoal: _isGoal,
          targetAmount: _isGoal ? targetCents : null,
          targetDate: _isGoal ? _targetDate : null,
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
          isGoal: _isGoal,
          targetAmount: _isGoal ? targetCents : null,
          targetDate: _isGoal ? _targetDate : null,
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

    return AppSheetScaffold(
      title: _isEditing ? 'Edit Scenario' : 'New Scenario',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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

          // Goal toggle
          SwitchListTile(
            value: _isGoal,
            onChanged: (v) => setState(() => _isGoal = v),
            title: const Text('Save as Goal'),
            subtitle: const Text('Track progress toward a target'),
            contentPadding: EdgeInsets.zero,
          ),

          // Goal fields
          if (_isGoal) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _targetCtrl,
              decoration: const InputDecoration(
                labelText: 'Target Amount (\$)',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
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
                  width: 32, height: 32,
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
            Text(_error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.error),
                textAlign: TextAlign.center),
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
