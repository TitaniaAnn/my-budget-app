// CSV statement import sheet.
//
// Flow: pick file → parse rows → preview → bulk upsert.
// Column detection is heuristic: it searches common header names for date,
// description, and amount. Deduplication is handled server-side via the
// UNIQUE(account_id, external_id) constraint in the transactions table.
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/models/account.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../../../features/accounts/repositories/accounts_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';
import '../services/categorizer.dart';
import '../services/statement_parser.dart';

class ImportStatementSheet extends ConsumerStatefulWidget {
  const ImportStatementSheet({super.key});

  @override
  ConsumerState<ImportStatementSheet> createState() =>
      _ImportStatementSheetState();
}

class _ImportStatementSheetState extends ConsumerState<ImportStatementSheet> {
  String? _selectedAccountId;
  List<ParsedStatementRow> _preview = [];
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
      // Read async + parse on a background isolate so a multi-MB statement
      // doesn't freeze the UI thread.
      final content = await File(file.path!).readAsString();
      final parsed = await compute(parseStatementCsv, content);

      if (parsed.rows.isEmpty) throw Exception('No valid rows found in file');
      if (!mounted) return;
      setState(() {
        _preview = parsed.rows;
        final lines = <String>[];
        if (parsed.skipped.isNotEmpty) {
          lines.add('${parsed.skipped.length} row(s) skipped:');
          lines.addAll(parsed.skipped);
        }
        if (parsed.warnings.isNotEmpty) {
          if (lines.isNotEmpty) lines.add('');
          lines.add('${parsed.warnings.length} row(s) imported with warnings:');
          lines.addAll(parsed.warnings);
        }
        _error = lines.isEmpty ? null : lines.join('\n');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _import() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select an account first')));
      return;
    }
    setState(() => _importing = true);

    try {
      final householdId = await ref.read(householdIdProvider.future);
      final user = ref.read(currentUserProvider);
      if (householdId == null || user == null) throw Exception('Not logged in');

      final categorizer = await ref.read(categorizerProvider.future);
      final now = DateTime.now().toIso8601String();

      // Pull the account_type once so the categorizer's amount-bucket /
      // account-type features see the right value for every row in the
      // batch (all rows belong to the same account here).
      final selectedAccount = ref
          .read(accountsProvider)
          .valueOrNull
          ?.firstWhere(
            (a) => a.id == _selectedAccountId,
            orElse: () => throw Exception('Selected account not found'),
          );
      final accountType = selectedAccount?.accountType.dbValue;

      final rows = _preview.map((r) {
        final result = categorizer.categorize(
          description: r.description,
          amountCents: r.amountCents,
          accountType: accountType,
        );
        final confidenceBp = result == null
            ? null
            : confidenceToBasisPoints(result);
        return {
          'description': r.description,
          'amount': r.amountCents,
          'transaction_date': r.date.toIso8601String().substring(0, 10),
          'external_id': r.externalId,
          'pending': false,
          if (result != null) ...{
            'category_id': result.categoryId,
            'category_assigned_by': result.source.dbValue,
            'category_assigned_at': now,
            'ml_model_confidence': ?confidenceBp,
          },
        };
      }).toList();

      final accountsRepo = ref.read(accountsRepositoryProvider);
      final result = await ref
          .read(transactionsRepositoryProvider)
          .bulkImport(
            householdId: householdId,
            accountId: _selectedAccountId!,
            enteredBy: user.id,
            rows: rows,
          );

      await accountsRepo.recalculateBalance(_selectedAccountId!);
      ref.invalidate(transactionsProvider);
      ref.invalidate(accountsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        final msg = result.skipped > 0
            ? 'Imported ${result.inserted} transactions '
                  '(${result.skipped} duplicates skipped)'
            : 'Imported ${result.inserted} transactions';
        context.showSnackBar(msg);
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return AppSheetScaffold(
      title: 'Import Statement',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CSV files from most banks are supported',
            style: TextStyle(fontSize: 13, color: context.appColors.textSubtle),
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
                  color: context.cs.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.cs.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: context.cs.error, fontSize: 13),
                ),
              ),
            ),
          if (_preview.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${_preview.length} transactions found',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.appColors.income,
                  ),
                ),
                const Spacer(),
                Text(
                  'Total: ${formatCurrency(_preview.fold<int>(0, (s, r) => s + r.amountCents))}',
                  style: TextStyle(color: context.appColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _preview.length.clamp(0, 20),
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                itemBuilder: (_, i) {
                  final r = _preview[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('MM/dd').format(r.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.textSubtle,
                          ),
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
                                ? context.appColors.expense
                                : context.appColors.income,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textSubtle,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            LoadingButton(
              loading: _importing,
              onPressed: _import,
              child: Text('Import ${_preview.length} Transactions'),
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
