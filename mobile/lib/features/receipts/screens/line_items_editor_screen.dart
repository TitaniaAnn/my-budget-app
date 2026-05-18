// Line-items editor — pushed from the receipt detail screen when the
// user wants to correct OCR output or assign per-item categories.
//
// Owns the receipt's full line-item list locally as a mutable draft
// list (one [_LineItemDraft] per row) so the user can reorder by
// adding/removing rows without round-tripping each edit through
// Supabase. Save calls [ReceiptsRepository.saveLineItems], which
// atomically replaces all rows via the `save_receipt_line_items` RPC
// (migration 018).
//
// Lives on its own screen — not inline in receipt_detail — because the
// keyboard would otherwise fight the receipt image and the per-item
// category dropdown is too tall for an embedded list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icon.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/money_text_field.dart';
import '../../transactions/models/category.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../models/receipt_line_item.dart';
import '../providers/receipts_provider.dart';
import '../repositories/receipts_repository.dart';

class LineItemsEditorScreen extends ConsumerStatefulWidget {
  const LineItemsEditorScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  ConsumerState<LineItemsEditorScreen> createState() =>
      _LineItemsEditorScreenState();
}

class _LineItemsEditorScreenState extends ConsumerState<LineItemsEditorScreen> {
  /// Local draft list. Null until the first load completes — we
  /// initialize from the loaded line items exactly once, then own
  /// the state. A subsequent provider refresh would otherwise blow
  /// away in-progress edits and leak [TextEditingController]s.
  List<_LineItemDraft>? _drafts;

  bool _saving = false;

  @override
  void dispose() {
    for (final draft in _drafts ?? const <_LineItemDraft>[]) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() => _drafts!.add(_LineItemDraft.empty()));
  }

  void _removeRow(int index) {
    setState(() {
      _drafts![index].dispose();
      _drafts!.removeAt(index);
    });
  }

  Future<void> _save() async {
    final drafts = _drafts;
    if (drafts == null) return;

    // Skip empties — a fresh "Add Line" row that the user never filled
    // out shouldn't survive save. Description-only OR amount-only rows
    // do save: the description preserves a known item even before its
    // price is filled in, and a $0 with description is a discount stub.
    final usable = drafts.where((d) => d.hasContent).toList();

    setState(() => _saving = true);
    try {
      final repo = ref.read(receiptsRepositoryProvider);
      await repo.saveLineItems(
        receiptId: widget.receiptId,
        items: usable.map((d) => d.toRpcJson()).toList(),
      );

      // The receipt detail screen's list re-reads to render the new
      // items; the budget aggregation reads receipt_line_items.
      // category_id now that Option B is live (see migration 026), so
      // it needs to invalidate too.
      ref.invalidate(receiptLineItemsProvider(widget.receiptId));

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(receiptLineItemsProvider(widget.receiptId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add line',
            onPressed: _drafts == null || _saving ? null : _addRow,
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading line items: $e')),
        data: (items) {
          // First-load handoff: copy the loaded rows into editable
          // drafts exactly once. Future provider refreshes (e.g. from
          // another tab) leave the in-progress draft state alone.
          _drafts ??= items.map(_LineItemDraft.fromExisting).toList();

          return categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error loading categories: $e')),
            data: (categories) {
              return Column(
                children: [
                  Expanded(
                    child: _drafts!.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: _drafts!.length,
                            itemBuilder: (context, i) => _LineItemRow(
                              draft: _drafts![i],
                              categories: categories,
                              onRemove: () => _removeRow(i),
                              enabled: !_saving,
                            ),
                          ),
                  ),
                  _SaveBar(loading: _saving, onSave: _save),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save bar (sticky bottom) — total + Save button.
// ---------------------------------------------------------------------------

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.loading, required this.onSave});

  final bool loading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: context.cs.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: LoadingButton(
          loading: loading,
          onPressed: onSave,
          child: const Text('Save'),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — shown when the receipt has no line items yet.
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list_alt_outlined,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text('No line items yet', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Tap + to add the first item.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One editable line item row.
// ---------------------------------------------------------------------------

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.draft,
    required this.categories,
    required this.onRemove,
    required this.enabled,
  });

  final _LineItemDraft draft;
  final List<Category> categories;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.descriptionCtrl,
                    enabled: enabled,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete line',
                  onPressed: enabled ? onRemove : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  child: MoneyTextField(controller: draft.amountCtrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CategoryDropdown(
                    value: draft.categoryId,
                    categories: categories,
                    enabled: enabled,
                    onChanged: (v) => draft.categoryId = v,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category dropdown — reuses the same parent-only filter as
// add_transaction_sheet so the picker stays consistent.
// ---------------------------------------------------------------------------

class _CategoryDropdown extends StatefulWidget {
  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.enabled,
    required this.onChanged,
  });

  final String? value;
  final List<Category> categories;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  State<_CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<_CategoryDropdown> {
  late String? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _value,
      isExpanded: true,
      decoration: const InputDecoration(isDense: true, hintText: 'Category'),
      items: [
        const DropdownMenuItem(value: null, child: Text('None')),
        ...widget.categories
            .where((c) => c.parentId == null)
            .map(
              (c) => DropdownMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Icon(categoryIconData(c.icon), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
      ],
      onChanged: widget.enabled
          ? (v) {
              setState(() => _value = v);
              widget.onChanged(v);
            }
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Draft model — one editable row's mutable state.
// ---------------------------------------------------------------------------

/// Mutable scratch state for one row in the editor. Owns its
/// [TextEditingController]s so the editor screen can dispose them
/// deterministically when the row is removed or the screen pops.
class _LineItemDraft {
  _LineItemDraft({
    required this.descriptionCtrl,
    required this.amountCtrl,
    this.categoryId,
    this.isTax = false,
    this.isTip = false,
    this.isDiscount = false,
  });

  factory _LineItemDraft.empty() => _LineItemDraft(
    descriptionCtrl: TextEditingController(),
    amountCtrl: TextEditingController(),
  );

  factory _LineItemDraft.fromExisting(ReceiptLineItem item) => _LineItemDraft(
    descriptionCtrl: TextEditingController(text: item.description),
    amountCtrl: TextEditingController(
      text: (item.amount / 100).toStringAsFixed(2),
    ),
    categoryId: item.categoryId,
    isTax: item.isTax,
    isTip: item.isTip,
    isDiscount: item.isDiscount,
  );

  final TextEditingController descriptionCtrl;
  final TextEditingController amountCtrl;
  String? categoryId;

  // Flags are preserved across an edit pass even though the v1 UI
  // doesn't expose toggles for them. Keeps OCR-classified rows
  // (tax / tip / discount) intact when the user just tweaks the
  // category — losing those flags would corrupt receipt totals.
  bool isTax;
  bool isTip;
  bool isDiscount;

  /// True when the row has at least a description OR a non-zero amount.
  /// Used to skip empty "Add Line" stubs the user never filled in.
  bool get hasContent {
    final desc = descriptionCtrl.text.trim();
    if (desc.isNotEmpty) return true;
    final cents = parseToCents(amountCtrl.text);
    return cents != 0;
  }

  Map<String, dynamic> toRpcJson() {
    return {
      'description': descriptionCtrl.text.trim(),
      'amount': parseToCents(amountCtrl.text).abs(),
      'category_id': categoryId,
      'is_tax': isTax,
      'is_tip': isTip,
      'is_discount': isDiscount,
    };
  }

  void dispose() {
    descriptionCtrl.dispose();
    amountCtrl.dispose();
  }
}
