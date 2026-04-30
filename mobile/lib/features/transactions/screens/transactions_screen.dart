// Transactions screen — grouped list with account filter, search, date range,
// swipe-to-delete, and tap-to-edit.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/models/account.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../../../features/accounts/repositories/accounts_repository.dart';
import '../../../core/providers/household_provider.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';
import '../services/category_matcher.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/import_statement_sheet.dart';
import '../widgets/transaction_card.dart';

import '../../../shared/widgets/app_sheet.dart';
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

  /// Starting balance in cents for the locked account. When provided,
  /// a running balance is shown on each day header.
  final int? startingBalance;

  const TransactionsScreen({super.key, this.lockedAccountId, this.startingBalance});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedAccountId;
  String? _selectedCategoryId;
  _DateFilter _dateFilter = _DateFilter.thisMonth;
  String _search = '';
  bool _showSearch = false;
  bool _recategorizing = false;
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

  bool get _embedded => widget.lockedAccountId != null;

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    // When embedded inside another screen (e.g. account detail) the parent
    // owns the Scaffold/AppBar/FAB. Returning a second Scaffold here would
    // render a duplicate toolbar and FAB inside the parent's body.
    if (_embedded) return body;

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
            icon: _recategorizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_fix_high_outlined),
            tooltip: 'Auto-categorize uncategorized',
            onPressed: _recategorizing ? null : () => _recategorize(),
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
      body: body,
    );
  }

  Widget _buildBody() {
    final accountsAsync = ref.watch(accountsProvider);
    final (from, to) = _dateRange;
    final txAsync = ref.watch(transactionsProvider(
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
      search: _search.isEmpty ? null : _search,
      dateFrom: from,
      dateTo: to,
    ));

    return Column(
      children: [
        // Account filter (hidden when locked to one account)
        if (!_embedded)
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
        // Category filter chips
        ref.watch(categoriesProvider).whenOrNull(
              data: (cats) => _CategoryFilterBar(
                categories: cats.where((c) => c.parentId == null).toList(),
                selectedId: _selectedCategoryId,
                onSelected: (id) =>
                    setState(() => _selectedCategoryId = id),
              ),
            ) ??
            const SizedBox.shrink(),
        // Transaction list
        Expanded(
          child: txAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      color: context.cs.error, size: 48),
                  const SizedBox(height: 12),
                  Text(e.toString(),
                      style: TextStyle(color: context.appColors.textMuted),
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
              startingBalance: widget.startingBalance,
              onEdit: (tx) => _showEditSheet(context, tx),
              onDelete: (tx) => _deleteTransaction(tx),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    showAppSheet<void>(context, child: AddTransactionSheet(preselectedAccountId: _selectedAccountId));
  }

  void _showEditSheet(BuildContext context, Transaction tx) {
    showAppSheet<void>(context, child: AddTransactionSheet(transaction: tx));
  }

  Future<void> _recategorize() async {
    setState(() => _recategorizing = true);
    try {
      final householdId = await ref.read(householdIdProvider.future);
      if (householdId == null) return;
      final categories = await ref.read(categoriesProvider.future);
      final matcher = CategoryMatcher(categories);
      final count = await ref.read(transactionsRepositoryProvider).bulkRecategorize(
        householdId: householdId,
        accountId: widget.lockedAccountId,
        matcher: (desc, {required isIncome}) => matcher.match(desc, isIncome: isIncome),
      );
      ref.invalidate(transactionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categorized $count transaction${count == 1 ? '' : 's'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _recategorizing = false);
    }
  }

  void _showImportSheet(BuildContext context) {
    showAppSheet<void>(context, child: const ImportStatementSheet());
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
      await ref.read(accountsRepositoryProvider).recalculateBalance(tx.accountId);
      ref.invalidate(accountsProvider);
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

class _CategoryFilterBar extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, null, 'All categories'),
          ...categories.map((c) => _chip(context, c.id, c.name)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String? id, String label) {
    final selected = selectedId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 4),
      child: GestureDetector(
        onTap: () => onSelected(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
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
  final int? startingBalance;
  final ValueChanged<Transaction> onEdit;
  final ValueChanged<Transaction> onDelete;

  const _TransactionList({
    required this.transactions,
    this.startingBalance,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Theme.of(context).dividerColor),
            const SizedBox(height: 16),
            Text('No transactions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textMuted)),
            const SizedBox(height: 8),
            Text('Tap + to add one or import a statement',
                style: TextStyle(color: context.appColors.textSubtle)),
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

    // Compute running balance after each day (oldest → newest), then look up
    // per day when rendering newest-first.
    Map<DateTime, int>? runningBalanceByDay;
    if (startingBalance != null) {
      int running = startingBalance!;
      final ascDays = [...sortedDays]..sort((a, b) => a.compareTo(b));
      runningBalanceByDay = {};
      for (final day in ascDays) {
        running += groups[day]!.fold<int>(0, (s, t) => s + t.amount);
        runningBalanceByDay[day] = running;
      }
    }

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
            _DateHeader(
              date: day,
              totalCents: dayTotal,
              runningBalanceCents: runningBalanceByDay?[day],
            ),
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
                      color: context.cs.error,
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
  final int? runningBalanceCents;

  const _DateHeader({
    required this.date,
    required this.totalCents,
    this.runningBalanceCents,
  });

  static final _fmt = DateFormat('EEEE, MMMM d');
  static final _withYearFmt = DateFormat('MMMM d, yyyy');

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    if (date.year == now.year) return _fmt.format(date);
    return _withYearFmt.format(date);
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
          if (runningBalanceCents != null) ...[
            Text(
              formatCurrency(runningBalanceCents!),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: runningBalanceCents! < 0
                    ? context.appColors.expense
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              totalCents < 0
                  ? '(${formatCurrency(totalCents)})'
                  : '(+${formatCurrency(totalCents)})',
              style: TextStyle(
                fontSize: 12,
                color: totalCents < 0
                    ? context.appColors.expense
                    : context.appColors.income,
              ),
            ),
          ] else
            Text(
              totalCents < 0
                  ? '-${formatCurrency(totalCents.abs())}'
                  : '+${formatCurrency(totalCents)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: totalCents < 0
                    ? context.appColors.expense
                    : context.appColors.income,
              ),
            ),
        ],
      ),
    );
  }
}
