// Monthly report screen — pick a month, see a preview, share as PDF.
//
// The screen owns its own loading future rather than going through a
// Riverpod provider because the data here is one-shot and tied to a
// transient UI selection (the chosen month). Caching across screens
// isn't useful and would just retain stale data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/repositories/accounts_repository.dart';
import '../../../features/budget/repositories/budget_repository.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/transactions/models/transaction.dart';
import '../../../features/transactions/repositories/transactions_repository.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/monthly_report_data.dart';
import '../services/monthly_report_builder.dart';
import '../services/monthly_report_pdf.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late DateTime _monthStart = _firstOfMonth(DateTime.now());
  late Future<MonthlyReportData> _future = _load(_monthStart);
  bool _sharing = false;

  DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime _lastOfMonth(DateTime monthStart) =>
      DateTime(monthStart.year, monthStart.month + 1, 0);

  Future<MonthlyReportData> _load(DateTime monthStart) async {
    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null) throw Exception('No household');

    final txRepo = ref.read(transactionsRepositoryProvider);
    final budgetRepo = ref.read(budgetRepositoryProvider);
    final accountsRepo = ref.read(accountsRepositoryProvider);
    final monthEnd = _lastOfMonth(monthStart);
    // For past months, the closing balance is the literal end of the
    // reporting month. For an in-progress month, monthEnd is in the
    // future and the walkback has nothing to undo — so the as-of date
    // is "now". The renderer reads this to label the table correctly.
    final now = DateTime.now();
    final closingAsOf = monthEnd.isBefore(now) ? monthEnd : now;

    final householdInfoFuture = ref.read(householdInfoProvider.future);
    final transactionsFuture = txRepo.fetchTransactions(
      householdId: householdId,
      from: monthStart,
      to: monthEnd,
      // High limit — a busy household can rack up several hundred
      // rows in a month, and the report should reflect all of them.
      limit: 5000,
    );
    final spendingFuture = budgetRepo.fetchSpendingByCategory(
      householdId: householdId,
      from: monthStart,
      to: monthEnd,
    );
    final categoriesFuture = txRepo.fetchCategories();
    final accountsFuture = accountsRepo.fetchAccounts(householdId);
    // Post-month transactions for the per-account walkback. For an
    // in-progress month this resolves to an empty list — closingAsOf
    // is now, so there's nothing dated strictly after it to undo.
    final postMonthTxFuture = monthEnd.isBefore(now)
        ? txRepo.fetchTransactions(
            householdId: householdId,
            from: monthEnd.add(const Duration(days: 1)),
            to: now,
            limit: 5000,
          )
        : Future<List<Transaction>>.value(const []);

    final (
      info,
      transactions,
      spending,
      categories,
      accounts,
      postMonthTx,
    ) = await (
      householdInfoFuture,
      transactionsFuture,
      spendingFuture,
      categoriesFuture,
      accountsFuture,
      postMonthTxFuture,
    ).wait;

    return buildMonthlyReport(
      monthStart: monthStart,
      monthEnd: monthEnd,
      householdName: info.householdName,
      transactionsInMonth: transactions,
      spendingByCategory: spending,
      categoryLookup: {for (final c in categories) c.id: c},
      accounts: accounts,
      transactionsAfterMonth: postMonthTx,
      closingAsOf: closingAsOf,
    );
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _monthStart,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      // Material's date picker is day-granular; users select any day
      // in the desired month and we clamp to the first.
      helpText: 'Pick any day in the month',
    );
    if (picked == null) return;
    final next = _firstOfMonth(picked);
    if (next == _monthStart) return;
    setState(() {
      _monthStart = next;
      _future = _load(next);
    });
  }

  Future<void> _share(MonthlyReportData data) async {
    setState(() => _sharing = true);
    try {
      final bytes = await renderMonthlyReportPdf(data);
      final monthSlug = DateFormat('yyyy-MM').format(data.monthStart);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'monthly-report-$monthSlug.pdf',
        subject: 'Monthly report — '
            '${DateFormat.yMMMM().format(data.monthStart)}',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM().format(_monthStart);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Report')),
      body: FutureBuilder<MonthlyReportData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: () => setState(() => _future = _load(_monthStart)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickMonth,
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: const Text('Change'),
                    ),
                  ],
                ),
              ),
              Expanded(child: _Preview(data: data)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: LoadingButton.filled(
                    loading: _sharing,
                    onPressed: _sharing ? null : () => _share(data),
                    child: const Text('Share PDF'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.data});
  final MonthlyReportData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryCell(
                  label: 'Income',
                  value: formatCurrency(data.incomeCents),
                  color: colors.income,
                ),
                _SummaryCell(
                  label: 'Expenses',
                  value: formatCurrency(data.expensesCents),
                  color: colors.expense,
                ),
                _SummaryCell(
                  label: 'Net',
                  value: formatCurrency(data.netChangeCents),
                  color: data.netChangeCents >= 0
                      ? colors.income
                      : colors.expense,
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Spending by category',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        if (data.byCategory.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No spending this month.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...data.byCategory.map(
            (row) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _parseColor(row.colorHex) ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(row.name),
              trailing: Text(formatCurrency(row.cents)),
            ),
          ),
        if (data.closingBalances.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              // Adaptive label: past months show "at month end",
              // an in-progress month shows the actual as-of date
              // so the user can tell the report is partial.
              data.closingAsOf.isBefore(data.monthEnd)
                  ? 'Balances as of '
                        '${DateFormat.yMMMd().format(data.closingAsOf)}'
                  : 'Balances at month end',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...data.closingBalances.map(
            (row) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(row.accountName),
              subtitle: Text(
                row.accountType.displayName,
                style: TextStyle(fontSize: 11, color: colors.textSubtle),
              ),
              trailing: Text(
                formatCurrency(row.balanceCents),
                style: TextStyle(
                  color: row.balanceCents < 0 ? colors.expense : null,
                ),
              ),
            ),
          ),
        ],
        if (data.transferLegCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Transfers excluded: ${data.transferLegCount} '
              'account-to-account transaction legs were left out of '
              'income and expense totals.',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
          ),
      ],
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final s = hex.startsWith('#') ? hex.substring(1) : hex;
    if (s.length != 6) return null;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(0xFF000000 | v);
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
