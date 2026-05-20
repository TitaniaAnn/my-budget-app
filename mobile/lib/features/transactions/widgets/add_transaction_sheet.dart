import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/utils/money.dart';
import '../../../features/accounts/models/account.dart';
import '../../../features/accounts/providers/accounts_provider.dart';
import '../../../features/accounts/providers/credit_card_rates_provider.dart';
import '../../../features/accounts/repositories/accounts_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/dialogs.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/money_text_field.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../../receipts/providers/receipts_provider.dart';
import '../../receipts/widgets/attach_receipt_sheet.dart';
import '../models/transaction.dart';
import '../providers/transaction_tags_provider.dart';
import '../providers/transactions_provider.dart';
import '../repositories/transaction_tags_repository.dart';
import '../repositories/transactions_repository.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  /// Pre-select an account when opened from an account's transaction list.
  final String? preselectedAccountId;

  /// When provided the sheet is in edit mode — fields are pre-filled and
  /// the submit action calls [updateTransaction] instead of [createTransaction].
  final Transaction? transaction;

  const AddTransactionSheet({
    super.key,
    this.preselectedAccountId,
    this.transaction,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isExpense = true;
  DateTime _date = DateTime.now();
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedRateId;
  bool _loading = false;

  /// Receipt currently paired with this transaction (edit mode only).
  /// Attaching/unpairing writes through to Supabase immediately rather
  /// than waiting for Save Changes — that matches the receipt-side
  /// flow where pairing is also a standalone action. Local mirror so
  /// the UI can swap between "attach" and "paired" without round-
  /// tripping through the parent provider.
  String? _receiptId;

  /// Tag ids currently selected in the picker (edit mode only). Null
  /// until the first load of [tagIdsForTransactionProvider] completes
  /// — `null` and `{}` mean different things here, so we can't pre-
  /// initialize with an empty set.
  Set<String>? _assignedTagIds;

  /// Snapshot of the assignments as loaded from the server. Compared
  /// against [_assignedTagIds] on save so we only re-write when the
  /// user actually changed something, avoiding a no-op delete-and-
  /// re-insert pair (and the brief window where the row has no tags).
  Set<String> _initialAssignedTagIds = const {};

  bool get _isEditMode => widget.transaction != null;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      _isExpense = tx.amount < 0;
      _amountController.text = (tx.amount.abs() / 100).toStringAsFixed(2);
      _descriptionController.text = tx.description;
      _merchantController.text = tx.merchant ?? '';
      _notesController.text = tx.notes ?? '';
      _date = tx.transactionDate;
      _selectedAccountId = tx.accountId;
      _selectedCategoryId = tx.categoryId;
      _selectedRateId = tx.rateId;
      _receiptId = tx.receiptId;
    } else {
      _selectedAccountId = widget.preselectedAccountId;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Opens the attach-receipt picker. The picker writes
  /// `transactions.receipt_id` itself and pops with the chosen receipt's
  /// id, so this method only needs to mirror that into local state to
  /// flip the UI from "Attach" to "Paired" without a round-trip.
  Future<void> _pickReceiptToAttach() async {
    final picked = await showAppSheet<String>(
      context,
      child: AttachReceiptSheet(transactionId: widget.transaction!.id),
    );
    if (picked != null && mounted) {
      setState(() => _receiptId = picked);
    }
  }

  /// Unpairs the currently-attached receipt. Writes through to Supabase
  /// immediately and offers an undo so a fat-finger doesn't lose the
  /// link. Mirrors the receipt-detail screen's unpair flow.
  Future<void> _unpairReceipt() async {
    final priorId = _receiptId;
    if (priorId == null) return;
    final repo = ref.read(transactionsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await repo.setReceiptId(
        transactionId: widget.transaction!.id,
        receiptId: null,
      );
      setState(() => _receiptId = null);

      // Providers downstream of receipt_id need to refresh:
      //   * unpairedReceiptsProvider — receipt re-enters the pool
      //   * transactionsProvider     — paperclip indicator drops off
      //   * transactionsForReceipt   — receipt detail's paired list
      ref.invalidate(unpairedReceiptsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(transactionsForReceiptProvider(priorId));

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Receipt unpaired'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await repo.setReceiptId(
                transactionId: widget.transaction!.id,
                receiptId: priorId,
              );
              if (mounted) setState(() => _receiptId = priorId);
              ref.invalidate(unpairedReceiptsProvider);
              ref.invalidate(transactionsProvider);
              ref.invalidate(transactionsForReceiptProvider(priorId));
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  /// Opens a small dialog to capture a new tag's name, creates it in
  /// the household dictionary, and assigns it to the current
  /// transaction in the picker. Refreshes [transactionTagsProvider]
  /// so the new chip appears immediately.
  Future<void> _createTag() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. contractor'),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null || !mounted) return;
    try {
      final tag = await ref
          .read(transactionTagsRepositoryProvider)
          .createTag(householdId: householdId, name: name);
      // Surface the new tag in the picker chip row immediately, and
      // pre-select it (the user just confirmed they want it on this
      // transaction by creating it from this context).
      ref.invalidate(transactionTagsProvider);
      setState(() => _assignedTagIds = {...?_assignedTagIds, tag.id});
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  /// True iff the two sets have the same elements. Used in _submit
  /// to decide whether tag assignments actually need re-writing.
  static bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final e in a) {
      if (!b.contains(e)) return false;
    }
    return true;
  }

  Future<void> _delete() async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Delete Transaction?',
      message: 'This transaction will be permanently removed.',
    );
    if (!confirmed) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(transactionsRepositoryProvider);
      final accountsRepo = ref.read(accountsRepositoryProvider);
      await repo.deleteTransaction(widget.transaction!.id);
      await accountsRepo.recalculateBalance(widget.transaction!.accountId);
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an account')));
      return;
    }
    setState(() => _loading = true);

    try {
      final amountCents = parseToCents(_amountController.text).abs();
      final signedAmount = _isExpense ? -amountCents : amountCents;
      final repo = ref.read(transactionsRepositoryProvider);

      final accountsRepo = ref.read(accountsRepositoryProvider);
      final String affectedAccountId;

      if (_isEditMode) {
        await repo.updateTransaction(
          id: widget.transaction!.id,
          amount: signedAmount,
          description: _descriptionController.text.trim(),
          transactionDate: _date,
          merchant: _merchantController.text.trim().isEmpty
              ? null
              : _merchantController.text.trim(),
          categoryId: _selectedCategoryId,
          rateId: _selectedRateId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        affectedAccountId = widget.transaction!.accountId;

        // Persist tag changes only when the user actually moved
        // chips — otherwise an idempotent delete-then-insert would
        // briefly leave the row with zero tags for no reason.
        final selected = _assignedTagIds;
        if (selected != null && !_setsEqual(selected, _initialAssignedTagIds)) {
          await ref
              .read(transactionTagsRepositoryProvider)
              .replaceAssignments(
                transactionId: widget.transaction!.id,
                tagIds: selected.toList(),
              );
          ref.invalidate(tagIdsForTransactionProvider(widget.transaction!.id));
        }
      } else {
        final householdId = await ref.read(householdIdProvider.future);
        final user = ref.read(currentUserProvider);
        if (householdId == null || user == null) {
          throw Exception('Not logged in');
        }

        await repo.createTransaction(
          householdId: householdId,
          accountId: _selectedAccountId!,
          enteredBy: user.id,
          amount: signedAmount,
          description: _descriptionController.text.trim(),
          transactionDate: _date,
          merchant: _merchantController.text.trim().isEmpty
              ? null
              : _merchantController.text.trim(),
          categoryId: _selectedCategoryId,
          rateId: _selectedRateId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
        affectedAccountId = _selectedAccountId!;
      }

      await accountsRepo.recalculateBalance(affectedAccountId);
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return AppSheetScaffold(
      title: _isEditMode ? 'Edit Transaction' : 'Add Transaction',
      formKey: _formKey,
      scrollable: true,
      actions: [
        if (_isEditMode)
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            tooltip: 'Delete transaction',
            onPressed: _loading ? null : _delete,
          ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Expense / Income toggle
          Container(
            decoration: BoxDecoration(
              color: context.appColors.surfaceDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _toggleBtn('Expense', true),
                _toggleBtn('Income', false),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Amount
          const FieldLabel('Amount'),
          MoneyTextField(
            controller: _amountController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          // Account selector
          const FieldLabel('Account'),
          accountsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Failed to load accounts'),
            data: (accounts) => DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              hint: const Text('Select account'),
              decoration: const InputDecoration(),
              items: accounts
                  .map(
                    (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedAccountId = v),
            ),
          ),
          const SizedBox(height: 14),
          // Description
          const FieldLabel('Description'),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'What was this for?'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Merchant (optional)'),
                    TextFormField(
                      controller: _merchantController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Amazon',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Date'),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: context.cs.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: context.appColors.textSubtle,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _dateFmt.format(_date),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Category
          const FieldLabel('Category (optional)'),
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (cats) => DropdownButtonFormField<String>(
              initialValue: _selectedCategoryId,
              hint: const Text('None'),
              decoration: const InputDecoration(),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...cats
                    .where((c) => c.parentId == null)
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            Icon(categoryIconData(c.icon), size: 16),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      ),
                    ),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ),
          // Rate picker — only for credit card accounts
          if (_selectedAccountId != null)
            accountsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (accounts) {
                final acct = accounts
                    .where((a) => a.id == _selectedAccountId)
                    .firstOrNull;
                if (acct == null ||
                    acct.accountType != AccountType.creditCard) {
                  return const SizedBox.shrink();
                }
                final ratesAsync = ref.watch(
                  creditCardRatesProvider(_selectedAccountId!),
                );
                return ratesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (rates) {
                    final active = rates.where((r) => r.isActive).toList();
                    if (active.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        const FieldLabel('Interest Rate (optional)'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRateId,
                          hint: const Text('Default (purchase rate)'),
                          decoration: const InputDecoration(),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Default (purchase rate)'),
                            ),
                            ...active.map(
                              (r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(
                                  '${r.label ?? r.rateType.displayName}'
                                  ' — ${(r.rate * 100).toStringAsFixed(2)}%'
                                  '${r.isIntro ? ' (intro)' : ''}',
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _selectedRateId = v),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          // Receipt — edit mode only. You can't pair a receipt to a
          // transaction that doesn't exist yet, so the section stays
          // hidden in the create flow rather than offering an action
          // that requires a deferred two-step write.
          if (_isEditMode) ...[
            const SizedBox(height: 14),
            const FieldLabel('Receipt'),
            if (_receiptId != null)
              _PairedReceiptCard(
                receiptId: _receiptId!,
                onUnpair: _loading ? null : _unpairReceipt,
              )
            else
              OutlinedButton.icon(
                onPressed: _loading ? null : _pickReceiptToAttach,
                icon: const Icon(Icons.attach_file_outlined),
                label: const Text('Attach Receipt'),
              ),
          ],
          // Tags — edit mode only, same rationale as Receipt: assigning
          // tags to a transaction that doesn't exist yet would mean a
          // deferred multi-write on submit. Tags are also additive (no
          // budget consequence), so attaching them as a separate
          // action after creation is fine.
          if (_isEditMode) ...[
            const SizedBox(height: 14),
            const FieldLabel('Tags (optional)'),
            _TagPicker(
              transactionId: widget.transaction!.id,
              selected: _assignedTagIds,
              onInitialLoaded: (ids) {
                // Captured once on first server load. Subsequent
                // provider refreshes leave the user's in-progress
                // selection alone.
                setState(() {
                  _assignedTagIds = {...ids};
                  _initialAssignedTagIds = {...ids};
                });
              },
              onToggle: (tagId, isOn) {
                setState(() {
                  final s = _assignedTagIds ?? <String>{};
                  if (isOn) {
                    s.add(tagId);
                  } else {
                    s.remove(tagId);
                  }
                  _assignedTagIds = s;
                });
              },
              onNewTag: _loading ? null : _createTag,
              enabled: !_loading,
            ),
          ],
          const SizedBox(height: 24),
          LoadingButton(
            loading: _loading,
            onPressed: _submit,
            child: Text(_isEditMode ? 'Save Changes' : 'Add Transaction'),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool isExpense) {
    final selected = _isExpense == isExpense;
    final colors = context.appColors;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isExpense = isExpense),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isExpense ? colors.expense : colors.income)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : colors.textSubtle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paired-receipt summary card shown inside the transaction edit sheet
// when receipt_id is already set.
// ---------------------------------------------------------------------------

/// Renders the currently-paired receipt's merchant / date / total
/// inline in the transaction edit form, with a trailing unpair button.
///
/// Watches [receiptProvider] directly rather than threading the
/// [Receipt] in from the parent — the parent only tracks the id and
/// shouldn't have to know how to fetch a receipt.
class _PairedReceiptCard extends ConsumerWidget {
  const _PairedReceiptCard({required this.receiptId, required this.onUnpair});

  final String receiptId;

  /// Null disables the unpair button (used while the parent form is
  /// mid-submit so a race can't fire two writes against the same row).
  final VoidCallback? onUnpair;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final fmt = NumberFormat.currency(symbol: r'$');
    final receiptAsync = ref.watch(receiptProvider(receiptId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: receiptAsync.when(
        // Quiet skeleton: a loading spinner here would flash on every
        // open of an edit sheet whose tx already has a receipt.
        loading: () => Row(
          children: [
            Icon(
              Icons.attach_file_outlined,
              size: 18,
              color: colors.textSubtle,
            ),
            const SizedBox(width: 10),
            Text(
              'Loading receipt…',
              style: TextStyle(fontSize: 13, color: colors.textSubtle),
            ),
          ],
        ),
        error: (_, _) => Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Could not load attached receipt',
                style: TextStyle(fontSize: 13, color: theme.colorScheme.error),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.link_off_outlined),
              tooltip: 'Unpair',
              onPressed: onUnpair,
            ),
          ],
        ),
        data: (receipt) {
          final shownDate = receipt.receiptDate ?? receipt.uploadedAt;
          return Row(
            children: [
              Icon(
                Icons.attach_file_outlined,
                size: 18,
                color: colors.textSubtle,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.merchantName ?? 'Untitled receipt',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      receipt.totalAmount != null
                          ? '${_dateFmt.format(shownDate)} · '
                                '${fmt.format(receipt.totalAmount! / 100)}'
                          : _dateFmt.format(shownDate),
                      style: TextStyle(fontSize: 12, color: colors.textSubtle),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.link_off_outlined),
                tooltip: 'Unpair',
                onPressed: onUnpair,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tag picker — multi-select chip row used inside the transaction edit sheet.
// ---------------------------------------------------------------------------

/// FilterChip row over [transactionTagsProvider]. Self-contained
/// loading state — when the dictionary or the per-tx assignments
/// haven't loaded yet, the picker renders a slim placeholder so the
/// rest of the form isn't blocked.
///
/// State (the selected set and the load-once initial set) lives in
/// the parent sheet because Save Changes batches the tag write with
/// the rest of the form. The widget gets [selected] as a snapshot
/// and reports edits via [onToggle] / [onInitialLoaded].
class _TagPicker extends ConsumerWidget {
  const _TagPicker({
    required this.transactionId,
    required this.selected,
    required this.onInitialLoaded,
    required this.onToggle,
    required this.onNewTag,
    required this.enabled,
  });

  final String transactionId;

  /// Currently-selected tag ids. Null until the first server load
  /// completes (the parent state initialises this from
  /// [onInitialLoaded]).
  final Set<String>? selected;

  /// Fired exactly once when the per-transaction assignment list
  /// loads from the server. Lets the parent take ownership of the
  /// "selected" set and capture an initial snapshot for diffing.
  final ValueChanged<List<String>> onInitialLoaded;

  /// Fired when the user taps a chip. (tagId, newSelectedState).
  final void Function(String tagId, bool isOn) onToggle;

  /// Opens the new-tag dialog. Null disables the "+ New" affordance
  /// while the form is mid-submit.
  final VoidCallback? onNewTag;

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(transactionTagsProvider);
    final assignedAsync = ref.watch(
      tagIdsForTransactionProvider(transactionId),
    );

    // Capture the first server-side load of assignments into the
    // parent state. The check on `selected == null` makes this fire
    // exactly once per editor open — subsequent provider refreshes
    // (e.g. another tab created a new tag) don't overwrite the
    // user's in-progress chip selections.
    assignedAsync.whenData((ids) {
      if (selected == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onInitialLoaded(ids);
        });
      }
    });

    return tagsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 32,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (e, _) => Text(
        'Could not load tags: $e',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      data: (tags) {
        final selectedSet = selected ?? const <String>{};
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final tag in tags)
              FilterChip(
                label: Text(tag.name),
                selected: selectedSet.contains(tag.id),
                onSelected: enabled ? (isOn) => onToggle(tag.id, isOn) : null,
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('New'),
              onPressed: onNewTag,
            ),
          ],
        );
      },
    );
  }
}
