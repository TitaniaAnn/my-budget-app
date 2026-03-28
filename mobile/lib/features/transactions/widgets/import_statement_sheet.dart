// CSV statement import sheet.
//
// Flow: pick file → parse rows → preview → bulk upsert.
// Column detection is heuristic: it searches common header names for date,
// description, and amount. Deduplication is handled server-side via the
// UNIQUE(account_id, external_id) constraint in the transactions table.
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/utils/money.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/accounts/models/account.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';

class ImportStatementSheet extends ConsumerStatefulWidget {
  const ImportStatementSheet({super.key});

  @override
  ConsumerState<ImportStatementSheet> createState() =>
      _ImportStatementSheetState();
}

class _ImportStatementSheetState extends ConsumerState<ImportStatementSheet> {
  String? _selectedAccountId;
  List<_ParsedRow> _preview = [];
  String? _fileName;
  bool _loading = false;
  bool _importing = false;
  String? _error;

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _preview = [];
      _fileName = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _loading = true;
      _fileName = file.name;
    });

    try {
      final content = File(file.path!).readAsStringSync();
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      if (rows.length < 2) throw Exception('File appears empty');

      final headers = rows.first
          .map((h) => h.toString().toLowerCase().trim())
          .toList();

      final dateIdx = _findCol(headers, ['date', 'posted', 'transaction date', 'post date']);
      final descIdx = _findCol(headers, ['description', 'payee', 'merchant', 'memo', 'name']);
      final amountIdx = _findCol(headers, ['amount', 'debit', 'credit']);

      if (dateIdx == -1 || descIdx == -1 || amountIdx == -1) {
        throw Exception(
          'Could not detect columns.\nFound: ${headers.join(', ')}\nExpected: date, description, amount',
        );
      }

      final parsed = <_ParsedRow>[];
      for (final row in rows.skip(1)) {
        if (row.length <= amountIdx) continue;
        final dateStr = row[dateIdx].toString().trim();
        final desc = row[descIdx].toString().trim();
        final amountStr = row[amountIdx].toString().trim();
        if (dateStr.isEmpty || desc.isEmpty || amountStr.isEmpty) continue;

        final date = _parseDate(dateStr);
        if (date == null) continue;

        final cleaned = amountStr.replaceAll(RegExp(r'[^\d.\-]'), '');
        if (cleaned.isEmpty) continue;
        final amount = double.tryParse(cleaned);
        if (amount == null) continue;

        // Bank CSVs typically export debits as negative. Preserve the sign
        // so the amount reflects real money flow (negative = expense).
        final cents = (amount * 100).round();

        // externalId is a stable dedup key derived from the row's data.
        // It prevents re-importing the same row if the same CSV is uploaded again.
        parsed.add(_ParsedRow(
          date: date,
          description: desc,
          amountCents: cents,
          externalId: '${dateStr}_${desc}_$amountStr'.hashCode.toString(),
        ));
      }

      if (parsed.isEmpty) throw Exception('No valid rows found in file');
      setState(() => _preview = parsed);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Returns the index of the first header that contains any candidate string.
  /// Returns -1 if no match is found (triggers a user-visible error).
  int _findCol(List<String> headers, List<String> candidates) {
    for (final c in candidates) {
      final idx = headers.indexWhere((h) => h.contains(c));
      if (idx != -1) return idx;
    }
    return -1;
  }

  DateTime? _parseDate(String s) {
    final fmts = [
      DateFormat('MM/dd/yyyy'),
      DateFormat('MM/dd/yy'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('M/d/yyyy'),
      DateFormat('M/d/yy'),
    ];
    for (final fmt in fmts) {
      try {
        return fmt.parseStrict(s);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _import() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an account first')),
      );
      return;
    }
    setState(() => _importing = true);

    try {
      final householdId = await ref.read(householdIdProvider.future);
      final user = ref.read(currentUserProvider);
      if (householdId == null || user == null) throw Exception('Not logged in');

      final rows = _preview
          .map((r) => {
                'description': r.description,
                'amount': r.amountCents,
                'transaction_date':
                    r.date.toIso8601String().substring(0, 10),
                'external_id': r.externalId,
                'pending': false,
              })
          .toList();

      final count = await ref.read(transactionsRepositoryProvider).bulkImport(
            householdId: householdId,
            accountId: _selectedAccountId!,
            enteredBy: user.id,
            rows: rows,
          );

      ref.invalidate(transactionsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count transactions')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

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
              const Text('Import Statement',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'CSV files from most banks are supported',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          // Account selector
          accountsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Failed to load accounts'),
            data: (accounts) => _AccountDropdown(
              accounts: accounts,
              selectedId: _selectedAccountId,
              onChanged: (id) => setState(() => _selectedAccountId = id),
            ),
          ),
          const SizedBox(height: 16),
          // File picker button
          OutlinedButton.icon(
            onPressed: _loading ? null : _pickFile,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(_fileName ?? 'Choose CSV file'),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Text(_error!,
                    style: const TextStyle(
                        color: Color(0xFFEF4444), fontSize: 13)),
              ),
            ),
          if (_preview.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${_preview.length} transactions found',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF22C55E)),
                ),
                const Spacer(),
                Text(
                  'Total: ${formatCurrency(_preview.fold<int>(0, (s, r) => s + r.amountCents))}',
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _preview.length.clamp(0, 20),
                separatorBuilder: (_, _) => const Divider(
                    height: 1, color: Color(0xFF334155)),
                itemBuilder: (_, i) {
                  final r = _preview[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MM/dd').format(r.date),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            r.description,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formatCurrency(r.amountCents),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: r.amountCents < 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_preview.length > 20)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${_preview.length - 20} more',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _importing ? null : _import,
              child: _importing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Import ${_preview.length} Transactions'),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _AccountDropdown({
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      hint: const Text('Select account to import into'),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: accounts
          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ParsedRow {
  final DateTime date;
  final String description;
  final int amountCents;
  final String externalId;

  const _ParsedRow({
    required this.date,
    required this.description,
    required this.amountCents,
    required this.externalId,
  });
}
