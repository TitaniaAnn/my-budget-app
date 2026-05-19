// Transactions screen — grouped list with account filter, search, date range,
// swipe-to-delete, and tap-to-edit.
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/models/account.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../../../features/accounts/repositories/accounts_repository.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/transaction_tag.dart';
import '../providers/transaction_tags_provider.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transactions_repository.dart';
import '../services/categorizer.dart';
import '../services/transactions_csv.dart';
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
      _DateFilter.thisMonth => (
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0),
      ),
      _DateFilter.lastMonth => (
        DateTime(now.year, now.month - 1, 1),
        DateTime(now.year, now.month, 0),
      ),
      _DateFilter.last90 => (
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 89)),
        DateTime(now.year, now.month, now.day),
      ),
      _DateFilter.thisYear => (
        DateTime(now.year, 1, 1),
        DateTime(now.year, 12, 31),
      ),
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

  const TransactionsScreen({
    super.key,
    this.lockedAccountId,
    this.startingBalance,
  });

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedTagId;
  _DateFilter _dateFilter = _DateFilter.thisMonth;
  String _search = '';
  bool _showSearch = false;
  bool _recategorizing = false;
  bool _exporting = false;
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
          // Export the currently-filtered transactions as CSV. The
          // active filters (account / category / tag / date / search)
          // determine the export scope — "filter to the contractor
          // tag, then tap Export" is the intended tax-time workflow.
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            tooltip: 'Export CSV',
            onPressed: _exporting ? null : _exportCsv,
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
    final txAsync = ref.watch(
      transactionsProvider(
        accountId: _selectedAccountId,
        categoryId: _selectedCategoryId,
        tagId: _selectedTagId,
        search: _search.isEmpty ? null : _search,
        dateFrom: from,
        dateTo: to,
      ),
    );
    final tagsAsync = ref.watch(transactionTagsProvider);
    final assignmentsAsync = ref.watch(transactionTagAssignmentsProvider);

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
        ref
                .watch(categoriesProvider)
                .whenOrNull(
                  data: (cats) => _CategoryFilterBar(
                    categories: cats.where((c) => c.parentId == null).toList(),
                    selectedId: _selectedCategoryId,
                    onSelected: (id) =>
                        setState(() => _selectedCategoryId = id),
                  ),
                ) ??
            const SizedBox.shrink(),
        // Tag filter chips — only renders when the household has at
        // least one tag, so a fresh user without tags doesn't see an
        // empty bar.
        tagsAsync.whenOrNull(
              data: (tags) => tags.isEmpty
                  ? null
                  : _TagFilterBar(
                      tags: tags,
                      selectedId: _selectedTagId,
                      onSelected: (id) => setState(() => _selectedTagId = id),
                    ),
            ) ??
            const SizedBox.shrink(),
        // Transaction list
        Expanded(
          child: txAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(transactionsProvider),
            ),
            data: (transactions) {
              // Resolve per-tx tag lists once before passing down — the
              // list view shouldn't have to know how to join two
              // providers, and we want a single dictionary lookup
              // per row rather than O(rows × tags) scans.
              final tagsByName = {
                for (final tag in tagsAsync.valueOrNull ?? const [])
                  tag.id: tag,
              };
              final assignments =
                  assignmentsAsync.valueOrNull ?? const <String, Set<String>>{};
              final perTxTags = <String, List<TransactionTag>>{
                for (final tx in transactions)
                  tx.id: [
                    for (final tagId in assignments[tx.id] ?? const <String>{})
                      if (tagsByName[tagId] != null) tagsByName[tagId]!,
                  ],
              };
              return _TransactionList(
                transactions: transactions,
                tagsByTransactionId: perTxTags,
                startingBalance: widget.startingBalance,
                onEdit: (tx) => _showEditSheet(context, tx),
                onDelete: (tx) => _deleteTransaction(tx),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context) {
    showAppSheet<void>(
      context,
      child: AddTransactionSheet(preselectedAccountId: _selectedAccountId),
    );
  }

  void _showEditSheet(BuildContext context, Transaction tx) {
    showAppSheet<void>(context, child: AddTransactionSheet(transaction: tx));
  }

  Future<void> _recategorize() async {
    setState(() => _recategorizing = true);
    try {
      final householdId = await ref.read(householdIdProvider.future);
      if (householdId == null) return;
      final categorizer = await ref.read(categorizerProvider.future);
      final count = await ref
          .read(transactionsRepositoryProvider)
          .bulkRecategorize(
            householdId: householdId,
            accountId: widget.lockedAccountId,
            categorizer: categorizer,
          );
      ref.invalidate(transactionsProvider);
      if (mounted) {
        context.showSnackBar(
          'Categorized $count transaction${count == 1 ? '' : 's'}',
        );
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _recategorizing = false);
    }
  }

  void _showImportSheet(BuildContext context) {
    showAppSheet<void>(context, child: const ImportStatementSheet());
  }

  /// Lowercases [name] and collapses runs of non-alphanumeric
  /// characters to single dashes, with no leading/trailing dashes.
  /// Used by the CSV-export filename so a tag like "@home" yields
  /// "home" (not "-home") and "Tax Deductible" yields
  /// "tax-deductible".
  static String _slugify(String name) {
    final lower = name.toLowerCase();
    final dashed = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return dashed.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Exports the currently-filtered transactions as CSV. Reads from
  /// the same providers the list view does, so the export honors
  /// every active filter (account / category / tag / search / date).
  ///
  /// Writes via [FilePicker.saveFile] with the bytes inline — no
  /// intermediate temp file. On Android the system save dialog
  /// (SAF) lets the user pick a destination; cancel returns null
  /// and the export becomes a no-op.
  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final (from, to) = _dateRange;
      // .future on each so the export blocks until data is loaded
      // — exporting partial data because a provider hadn't settled
      // would silently truncate the CSV.
      final accounts = await ref.read(accountsProvider.future);
      final tags = await ref.read(transactionTagsProvider.future);
      final assignments = await ref.read(
        transactionTagAssignmentsProvider.future,
      );
      final transactions = await ref.read(
        transactionsProvider(
          accountId: _selectedAccountId,
          categoryId: _selectedCategoryId,
          tagId: _selectedTagId,
          search: _search.isEmpty ? null : _search,
          dateFrom: from,
          dateTo: to,
        ).future,
      );

      if (transactions.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No transactions to export with the current filter.'),
          ),
        );
        return;
      }

      final csv = transactionsToCsv(
        transactions: transactions,
        accountsById: {for (final a in accounts) a.id: a},
        tagsById: {for (final t in tags) t.id: t},
        tagAssignments: assignments,
      );

      // Filename includes the tag name when filtering by tag so the
      // exported file is self-identifying after the user shares it
      // out of the app. The slug:
      //   * resolves the tag id against the loaded dictionary; if
      //     the tag was deleted concurrently (another member of the
      //     household, mid-export) we drop the slug entirely
      //     rather than pick a wrong one
      //   * lowercases, collapses non-alphanumeric runs to single
      //     dashes, then strips leading/trailing dashes so a tag
      //     named "@home" doesn't become "transactions--home-…"
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final selectedTag = _selectedTagId == null
          ? null
          : tags.where((t) => t.id == _selectedTagId).firstOrNull;
      final tagSlug = selectedTag == null ? '' : _slugify(selectedTag.name);
      final suggestedName =
          'transactions${tagSlug.isEmpty ? '' : '-$tagSlug'}-$today.csv';

      final saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Save transactions CSV',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: Uint8List.fromList(utf8.encode(csv)),
      );

      if (!mounted) return;
      if (saved != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Exported ${transactions.length} transactions'),
          ),
        );
      }
      // Null return = user cancelled the save dialog. No feedback —
      // surfacing "cancelled" would feel like an error.
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteTransaction(Transaction tx) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Delete Transaction?',
      message:
          'Delete "${tx.merchant ?? tx.description}" for ${formatCurrency(tx.amount.abs())}?',
    );
    if (confirmed) {
      await ref.read(transactionsRepositoryProvider).deleteTransaction(tx.id);
      await ref
          .read(accountsRepositoryProvider)
          .recalculateBalance(tx.accountId);
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
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal chip row of every tag in the household. Same pill
/// style as [_CategoryFilterBar] for visual consistency. Selecting
/// a tag narrows the transactions list to rows carrying that tag;
/// the "All tags" pill clears the filter. Tag chips are prefixed
/// with `#` so they can't be confused with category chips on a
/// glance.
class _TagFilterBar extends StatelessWidget {
  final List<TransactionTag> tags;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _TagFilterBar({
    required this.tags,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip(context, null, 'All tags'),
          ...tags.map((t) => _chip(context, t.id, '#${t.name}')),
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
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
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
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.label, style: const TextStyle(fontSize: 12)),
                  selected: selected == f,
                  onSelected: (_) => onSelected(f),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ── Transaction list ──────────────────────────────────────────────────────────

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  /// Pre-resolved tags per transaction id, computed once in the
  /// parent so the list view doesn't have to join two providers per
  /// row. An absent key is treated the same as an empty list.
  final Map<String, List<TransactionTag>> tagsByTransactionId;
  final int? startingBalance;
  final ValueChanged<Transaction> onEdit;
  final ValueChanged<Transaction> onDelete;

  const _TransactionList({
    required this.transactions,
    this.tagsByTransactionId = const {},
    this.startingBalance,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const EmptyView(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions',
        subtitle: 'Tap + to add one or import a statement',
      );
    }

    // Group by calendar day
    final groups = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final day = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );
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
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      onDelete(tx);
                      return false; // actual deletion handled in parent
                    },
                    child: TransactionCard(
                      transaction: tx,
                      tags: tagsByTransactionId[tx.id] ?? const [],
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
