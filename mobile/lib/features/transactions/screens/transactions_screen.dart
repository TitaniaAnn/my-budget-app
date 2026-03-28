// Transactions screen — grouped list with account filter, search, date range,
// swipe-to-delete, and tap-to-edit.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/models/account.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../models/transaction.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/import_statement_sheet.dart';
import '../widgets/transaction_card.dart';

// ── Date-range quick filter ────────────────────────────────────────────────────

enum _DateFilter {
  all('All time'),
  thisMonth('This month'),
  lastMonth('Last month'),
  last90('Last 90 days'),
  thisYear('This year');

  const _DateFilter(this.label);
  final String label;

  (DateTime? from, DateTime? to) get range {
    final now = DateTime.now();
    return switch (this) {
      _DateFilter.all => (null, null),
      _DateFilter.thisMonth =>
        (DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0)),
      _DateFilter.lastMonth => (
          DateTime(now.year, now.month - 1, 1),
          DateTime(now.year, now.month, 0),
        ),
      _DateFilter.last90 => (
          DateTime(now.year, now.month, now.day)
              .subtract(const Duration(days: 89)),
          DateTime(now.year, now.month, now.day),
        ),
      _DateFilter.thisYear => (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31)),
    };
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TransactionsScreen extends ConsumerStatefulWidget {
  /// When set, the account filter is locked to this account (used from
  /// the account detail screen).
  final String? lockedAccountId;

  const TransactionsScreen({super.key, this.lockedAccountId});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedAccountId;
  _DateFilter _dateFilter = _DateFilter.thisMonth;
  String _search = '';
  bool _showSearch = false;
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.lockedAccountId;
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  (DateTime? from, DateTime? to) get _dateRange => _dateFilter.range;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final (from, to) = _dateRange;
    final txAsync = ref.watch(transactionsProvider(
      accountId: _selectedAccountId,
      search: _search.isEmpty ? null : _search,
      dateFrom: from,
      dateTo: to,
    ));

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search transactions…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _search = v),
              )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _search = '';
                _searchCtrl.clear();
              }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.upload_outlined),
            tooltip: 'Import statement',
            onPressed: () => _showImportSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Account filter (hidden when locked to one account)
          if (widget.lockedAccountId == null)
            accountsAsync.when(
              loading: () => const SizedBox(height: 48),
              error: (_, _) => const SizedBox.shrink(),
              data: (accounts) => _AccountFilterBar(
                accounts: accounts,
                selectedId: _selectedAccountId,
                onSelected: (id) => setState(() => _selectedAccountId = id),
              ),
            ),
          // Date filter chips
          _DateFilterBar(
            selected: _dateFilter,
            onSelected: (f) => setState(() => _dateFilter = f),
          ),
          // Transaction list
          Expanded(
            child: txAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFEF4444), size: 48),
                    const SizedBox(height: 12),
                    Text(e.toString(),
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(transactionsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (transactions) => _TransactionList(
                transactions: transactions,
                onEdit: (tx) => _showEditSheet(context, tx),
                onDelete: (tx) => _deleteTransaction(tx),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          AddTransactionSheet(preselectedAccountId: _selectedAccountId),
    );
  }

  void _showEditSheet(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTransactionSheet(transaction: tx),
    );
  }

  void _showImportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ImportStatementSheet(),
    );
  }

  Future<void> _deleteTransaction(Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
            'Delete "${tx.merchant ?? tx.description}" for ${formatCurrency(tx.amount.abs())}?'),
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
      await ref.read(transactionsRepositoryProvider).deleteTransaction(tx.id);
      ref.invalidate(transactionsProvider);
    }
  }
}

// ── Filter bars ───────────────────────────────────────────────────────────────

class _AccountFilterBar extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _AccountFilterBar({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, null, 'All'),
          ...accounts.map((a) => _chip(context, a.id, a.name)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String? id, String label) {
    final selected = selectedId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: () => onSelected(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateFilterBar extends StatelessWidget {
  final _DateFilter selected;
  final ValueChanged<_DateFilter> onSelected;

  const _DateFilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _DateFilter.values
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label,
                        style: const TextStyle(fontSize: 12)),
                    selected: selected == f,
                    onSelected: (_) => onSelected(f),
                    visualDensity: VisualDensity.compact,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Transaction list ──────────────────────────────────────────────────────────

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final ValueChanged<Transaction> onEdit;
  final ValueChanged<Transaction> onDelete;

  const _TransactionList({
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Color(0xFF334155)),
            SizedBox(height: 16),
            Text('No transactions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            SizedBox(height: 8),
            Text('Tap + to add one or import a statement',
                style: TextStyle(color: Color(0xFF475569))),
          ],
        ),
      );
    }

    // Group by calendar day
    final groups = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final day = DateTime(tx.transactionDate.year,
          tx.transactionDate.month, tx.transactionDate.day);
      groups.putIfAbsent(day, () => []).add(tx);
    }
    final sortedDays = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: sortedDays.length,
      itemBuilder: (context, i) {
        final day = sortedDays[i];
        final dayTxs = groups[day]!;
        final dayTotal = dayTxs.fold<int>(0, (s, t) => s + t.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateHeader(date: day, totalCents: dayTotal),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                children: dayTxs.map((tx) {
                  return Dismissible(
                    key: ValueKey(tx.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: const Color(0xFFEF4444),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      onDelete(tx);
                      return false; // actual deletion handled in parent
                    },
                    child: TransactionCard(
                      transaction: tx,
                      onTap: () => onEdit(tx),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final int totalCents;

  const _DateHeader({required this.date, required this.totalCents});

  static final _fmt = DateFormat('EEEE, MMMM d');
  static final _thisYear = DateTime.now().year;

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    if (date.year == _thisYear) return _fmt.format(date);
    return DateFormat('MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(
            _label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const Spacer(),
          Text(
            totalCents < 0
                ? '-${formatCurrency(totalCents.abs())}'
                : '+${formatCurrency(totalCents)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: totalCents < 0
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }
}
