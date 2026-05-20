// Review uncertain OCR line items.
//
// Mirrors the "Review uncertain ML guesses" surface in
// review_categorisations_screen.dart, but for receipt line items
// the OCR recognizer flagged as low-confidence. Each row carries
// the receipt's date + merchant for context; tapping opens an
// inline edit sheet where the user confirms or corrects the line.
//
// Confirming the row (with or without changes) clears its
// `ocr_confidence_bp` so it doesn't keep resurfacing here — see
// [ReceiptsRepository.confirmLineItem] for the contract.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/household_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/color.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/field_label.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/money_text_field.dart';
import '../../../shared/widgets/sheet_scaffold.dart';
import '../../../shared/widgets/state_views.dart';
import '../../transactions/models/category.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../models/receipt_line_item.dart';
import '../repositories/receipts_repository.dart';

class ReviewOcrLinesScreen extends ConsumerStatefulWidget {
  const ReviewOcrLinesScreen({super.key});

  @override
  ConsumerState<ReviewOcrLinesScreen> createState() =>
      _ReviewOcrLinesScreenState();
}

class _ReviewOcrLinesScreenState extends ConsumerState<ReviewOcrLinesScreen> {
  late Future<List<UncertainLineItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UncertainLineItem>> _load() async {
    final householdId = await ref.read(householdIdProvider.future);
    if (householdId == null) return const [];
    return ref
        .read(receiptsRepositoryProvider)
        .fetchUncertainLineItems(householdId: householdId);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review OCR lines')),
      body: FutureBuilder<List<UncertainLineItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(error: snap.error!, onRetry: _refresh);
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const EmptyView(
              icon: Icons.fact_check_outlined,
              title: 'Nothing to review',
              subtitle:
                  'No low-confidence OCR line items right now. New '
                  'items the recognizer is unsure about will land here.',
            );
          }
          final categories = categoriesAsync.valueOrNull ?? const <Category>[];
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _UncertainTile(
              item: items[i],
              categories: categories,
              onAction: _refresh,
            ),
          );
        },
      ),
    );
  }
}

class _UncertainTile extends ConsumerWidget {
  const _UncertainTile({
    required this.item,
    required this.categories,
    required this.onAction,
  });

  final UncertainLineItem item;
  final List<Category> categories;

  /// Invoked after a confirm action completes so the parent can
  /// refresh the list — once a row is confirmed, its confidence
  /// is cleared and the next fetch won't return it.
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final line = item.lineItem;
    final confidence = (line.ocrConfidenceBp ?? 0) / 100; // → percent
    final dateLabel = item.receiptDate == null
        ? ''
        : DateFormat.yMMMd().format(item.receiptDate!);
    final merchantLabel = item.merchant ?? '—';

    return ListTile(
      onTap: () => _openEdit(context, ref),
      title: Text(
        line.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          [
            merchantLabel,
            if (dateLabel.isNotEmpty) dateLabel,
            // Confidence rendered as a percent with one decimal so the
            // user can tell a "barely uncertain" 54% row from a "very
            // uncertain" 21% row.
            '${confidence.toStringAsFixed(1)}% confidence',
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: colors.textSubtle),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Text(
        formatCurrency(line.amount),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, WidgetRef ref) async {
    await showAppSheet<void>(
      context,
      child: _ReviewLineSheet(
        item: item,
        categories: categories,
      ),
    );
    onAction();
  }
}

/// Bottom sheet for confirming or correcting a single uncertain
/// line item. "Looks right" clears the confidence and pops; "Save
/// changes" applies the edits + clears confidence + pops.
class _ReviewLineSheet extends ConsumerStatefulWidget {
  const _ReviewLineSheet({required this.item, required this.categories});

  final UncertainLineItem item;
  final List<Category> categories;

  @override
  ConsumerState<_ReviewLineSheet> createState() => _ReviewLineSheetState();
}

class _ReviewLineSheetState extends ConsumerState<_ReviewLineSheet> {
  late final _descController = TextEditingController(
    text: widget.item.lineItem.description,
  );
  late final _amountController = TextEditingController(
    text: centsToString(widget.item.lineItem.amount),
  );
  late String? _categoryId = widget.item.lineItem.categoryId;
  bool _loading = false;

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirm({required bool acceptAsIs}) async {
    setState(() => _loading = true);
    final repo = ref.read(receiptsRepositoryProvider);
    try {
      if (acceptAsIs) {
        await repo.confirmLineItem(lineItemId: widget.item.lineItem.id);
      } else {
        await repo.confirmLineItem(
          lineItemId: widget.item.lineItem.id,
          description: _descController.text.trim(),
          amountCents: parseToCents(_amountController.text),
          categoryId: _categoryId,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: 'Review line item',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FieldLabel('Description'),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Amount'),
          MoneyTextField(controller: _amountController),
          const SizedBox(height: 14),
          const FieldLabel('Category'),
          DropdownButtonFormField<String?>(
            initialValue: _categoryId,
            hint: const Text('Uncategorised'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Uncategorised'),
              ),
              for (final c in widget.categories)
                DropdownMenuItem<String?>(
                  value: c.id,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: c.color != null
                              ? colorFromHex(c.color)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c.name)),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => _confirm(acceptAsIs: true),
                  child: const Text('Looks right'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LoadingButton.filled(
                  loading: _loading,
                  onPressed: _loading ? null : () => _confirm(acceptAsIs: false),
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
