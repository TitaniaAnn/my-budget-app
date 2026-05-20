// Manual column-override sheet — shown when statement import's
// heuristic detection can't lock onto the date/description/amount
// columns. The user picks which header is which from dropdowns;
// the resulting [ColumnMapping] is saved under the file's header
// fingerprint so the next import from the same bank skips this
// step.
//
// The sheet's only output is the chosen mapping — the import sheet
// re-parses with it and handles persistence + bulk upsert.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../services/statement_parser.dart';

class ColumnOverrideSheet extends StatefulWidget {
  const ColumnOverrideSheet({super.key, required this.headers});

  /// Lowercased, trimmed header strings as they came out of the
  /// CSV. The sheet's dropdowns show them verbatim so a user can
  /// match "trans dt" to "Date" without guessing.
  final List<String> headers;

  @override
  State<ColumnOverrideSheet> createState() => _ColumnOverrideSheetState();
}

class _ColumnOverrideSheetState extends State<ColumnOverrideSheet> {
  // -1 sentinel = no selection. Lets us validate "all required
  // dropdowns set" without a separate set of bools.
  int _dateIdx = -1;
  int _descIdx = -1;
  int _amountIdx = -1;
  int _debitIdx = -1;
  int _creditIdx = -1;
  // True when the bank exports amounts as separate debit/credit
  // columns. The single-amount mode is the more common case so it's
  // the default.
  bool _splitMode = false;

  bool get _ready {
    if (_dateIdx == -1 || _descIdx == -1) return false;
    if (_splitMode) return _debitIdx != -1 && _creditIdx != -1;
    return _amountIdx != -1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppSheetScaffold(
      title: 'Match columns',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'We couldn\'t recognise the column headers in this file. '
            'Pick the right column for each field — we\'ll remember '
            'your choice for the next import from this bank.',
            style: TextStyle(fontSize: 12, color: colors.textSubtle),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Date column'),
          _headerDropdown(
            value: _dateIdx,
            onChanged: (v) => setState(() => _dateIdx = v ?? -1),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Description column'),
          _headerDropdown(
            value: _descIdx,
            onChanged: (v) => setState(() => _descIdx = v ?? -1),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Separate debit / credit columns'),
            subtitle: Text(
              _splitMode
                  ? 'Two unsigned columns (debits, credits)'
                  : 'One signed-amount column',
              style: TextStyle(fontSize: 11, color: colors.textSubtle),
            ),
            value: _splitMode,
            onChanged: (v) => setState(() {
              _splitMode = v;
              // Clear the other mode's picks so a half-set mapping
              // can't slip through validation.
              if (v) {
                _amountIdx = -1;
              } else {
                _debitIdx = -1;
                _creditIdx = -1;
              }
            }),
          ),
          if (_splitMode) ...[
            const SizedBox(height: 6),
            const FieldLabel('Debit column'),
            _headerDropdown(
              value: _debitIdx,
              onChanged: (v) => setState(() => _debitIdx = v ?? -1),
            ),
            const SizedBox(height: 14),
            const FieldLabel('Credit column'),
            _headerDropdown(
              value: _creditIdx,
              onChanged: (v) => setState(() => _creditIdx = v ?? -1),
            ),
          ] else ...[
            const SizedBox(height: 6),
            const FieldLabel('Amount column'),
            _headerDropdown(
              value: _amountIdx,
              onChanged: (v) => setState(() => _amountIdx = v ?? -1),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _ready ? _submit : null,
            child: const Text('Use these columns'),
          ),
        ],
      ),
    );
  }

  Widget _headerDropdown({
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value == -1 ? null : value,
      hint: const Text('Select column'),
      items: [
        for (var i = 0; i < widget.headers.length; i++)
          DropdownMenuItem(value: i, child: Text(widget.headers[i])),
      ],
      onChanged: onChanged,
    );
  }

  void _submit() {
    final mapping = _splitMode
        ? ColumnMapping.split(
            dateIdx: _dateIdx,
            descIdx: _descIdx,
            debitIdx: _debitIdx,
            creditIdx: _creditIdx,
          )
        : ColumnMapping.signed(
            dateIdx: _dateIdx,
            descIdx: _descIdx,
            amountIdx: _amountIdx,
          );
    Navigator.of(context).pop(mapping);
  }
}
