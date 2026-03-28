// Receipt detail screen — shows the receipt image, editable metadata, and
// the list of line items extracted by OCR (or entered manually).
//
// Line items can be edited in-place and saved back to the database.
// The "Pair to Transaction" action is a placeholder for future linking logic.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';
import '../models/receipt_line_item.dart';
import '../providers/receipts_provider.dart';
import '../repositories/receipts_repository.dart';

/// Displays the full receipt: image, merchant/date/total fields, and line items.
///
/// [receiptId] is passed from the router (e.g. `/receipts/:id`).
class ReceiptDetailScreen extends ConsumerStatefulWidget {
  const ReceiptDetailScreen({super.key, required this.receiptId});

  final String receiptId;

  @override
  ConsumerState<ReceiptDetailScreen> createState() =>
      _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends ConsumerState<ReceiptDetailScreen> {
  // Form controllers for editable metadata fields.
  final _merchantCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();

  // Tracks whether the metadata form has unsaved changes.
  bool _metaDirty = false;
  bool _savingMeta = false;

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _dateCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  /// Populates form fields from the loaded receipt (runs once on first load).
  void _populateFields(Receipt receipt) {
    if (_merchantCtrl.text.isEmpty && receipt.merchantName != null) {
      _merchantCtrl.text = receipt.merchantName!;
    }
    if (_dateCtrl.text.isEmpty && receipt.receiptDate != null) {
      _dateCtrl.text =
          DateFormat('yyyy-MM-dd').format(receipt.receiptDate!);
    }
    if (_totalCtrl.text.isEmpty && receipt.totalAmount != null) {
      // Display as decimal dollars for editing (stored as cents).
      _totalCtrl.text = (receipt.totalAmount! / 100).toStringAsFixed(2);
    }
  }

  Future<void> _saveMeta(Receipt receipt) async {
    setState(() => _savingMeta = true);
    try {
      final repo = ref.read(receiptsRepositoryProvider);

      // Parse the total field back to cents, ignoring formatting.
      final rawTotal = _totalCtrl.text.replaceAll(RegExp(r'[^\d.]'), '');
      final cents = rawTotal.isNotEmpty
          ? (double.tryParse(rawTotal) ?? 0) * 100
          : null;

      await repo.updateReceipt(
        receiptId: receipt.id,
        merchantName:
            _merchantCtrl.text.trim().isNotEmpty ? _merchantCtrl.text.trim() : null,
        receiptDate: _dateCtrl.text.isNotEmpty
            ? DateTime.tryParse(_dateCtrl.text)
            : null,
        totalAmountCents: cents?.round(),
      );

      // Refresh the detail and list providers.
      ref.invalidate(receiptProvider(widget.receiptId));
      ref.invalidate(receiptsProvider);

      setState(() {
        _metaDirty = false;
        _savingMeta = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt updated')),
        );
      }
    } catch (e) {
      setState(() => _savingMeta = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteReceipt(Receipt receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Receipt?'),
        content:
            const Text('This will permanently remove the image and all data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final repo = ref.read(receiptsRepositoryProvider);
    await repo.deleteReceipt(
      receiptId: receipt.id,
      storagePath: receipt.storagePath,
    );
    ref.invalidate(receiptsProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final receiptAsync = ref.watch(receiptProvider(widget.receiptId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          receiptAsync.whenData(
            (r) => IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteReceipt(r),
              tooltip: 'Delete',
            ),
          ).valueOrNull ??
              const SizedBox.shrink(),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (receipt) {
          // Populate text fields once when the receipt first loads.
          _populateFields(receipt);
          return _ReceiptDetailBody(
            receipt: receipt,
            merchantCtrl: _merchantCtrl,
            dateCtrl: _dateCtrl,
            totalCtrl: _totalCtrl,
            metaDirty: _metaDirty,
            savingMeta: _savingMeta,
            onMetaChanged: () => setState(() => _metaDirty = true),
            onSaveMeta: () => _saveMeta(receipt),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body widget — separated to keep the state class readable.
// ---------------------------------------------------------------------------

class _ReceiptDetailBody extends ConsumerWidget {
  const _ReceiptDetailBody({
    required this.receipt,
    required this.merchantCtrl,
    required this.dateCtrl,
    required this.totalCtrl,
    required this.metaDirty,
    required this.savingMeta,
    required this.onMetaChanged,
    required this.onSaveMeta,
  });

  final Receipt receipt;
  final TextEditingController merchantCtrl;
  final TextEditingController dateCtrl;
  final TextEditingController totalCtrl;
  final bool metaDirty;
  final bool savingMeta;
  final VoidCallback onMetaChanged;
  final VoidCallback onSaveMeta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final imageAsync = ref.watch(receiptImageUrlProvider(receipt.storagePath));
    final lineItemsAsync =
        ref.watch(receiptLineItemsProvider(receipt.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Receipt image ───────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imageAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 220,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined,
                        size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    const Text('Could not load image'),
                  ],
                ),
              ),
            ),
            data: (url) => Image.network(
              url,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // ── OCR status chip ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _OcrStatusChip(status: receipt.ocrStatus),
        ),

        // ── Metadata form ───────────────────────────────────────────────
        _SectionHeader('Details'),
        const SizedBox(height: 8),
        TextField(
          controller: merchantCtrl,
          decoration: const InputDecoration(
            labelText: 'Merchant',
            prefixIcon: Icon(Icons.store_outlined),
          ),
          onChanged: (_) => onMetaChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: dateCtrl,
          decoration: const InputDecoration(
            labelText: 'Date (yyyy-mm-dd)',
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          keyboardType: TextInputType.datetime,
          onChanged: (_) => onMetaChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: totalCtrl,
          decoration: const InputDecoration(
            labelText: 'Total (\$)',
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onMetaChanged(),
        ),
        if (metaDirty) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: savingMeta ? null : onSaveMeta,
            icon: savingMeta
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(savingMeta ? 'Saving…' : 'Save Changes'),
          ),
        ],

        // ── Line items ──────────────────────────────────────────────────
        const SizedBox(height: 24),
        _SectionHeader('Line Items'),
        const SizedBox(height: 8),
        lineItemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading items: $e'),
          data: (items) => items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      receipt.ocrStatus == OcrStatus.pending ||
                              receipt.ocrStatus == OcrStatus.processing
                          ? 'OCR in progress — line items will appear here.'
                          : 'No line items found.',
                      style: TextStyle(color: theme.colorScheme.outline),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _LineItemsList(items: items),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// OCR status chip
// ---------------------------------------------------------------------------

class _OcrStatusChip extends StatelessWidget {
  const _OcrStatusChip({required this.status});

  final OcrStatus status;

  Color _color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      OcrStatus.pending => cs.secondary,
      OcrStatus.processing => cs.tertiary,
      OcrStatus.complete => Colors.green,
      OcrStatus.failed => cs.error,
    };
  }

  IconData get _icon => switch (status) {
        OcrStatus.pending => Icons.hourglass_empty,
        OcrStatus.processing => Icons.autorenew,
        OcrStatus.complete => Icons.check_circle_outline,
        OcrStatus.failed => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          'OCR: ${status.displayLabel}',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Line items list
// ---------------------------------------------------------------------------

class _LineItemsList extends StatelessWidget {
  const _LineItemsList({required this.items});

  final List<ReceiptLineItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '\$');

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (item.isTax || item.isTip || item.isDiscount)
                        Text(
                          item.isTax
                              ? 'Tax'
                              : item.isTip
                                  ? 'Tip'
                                  : 'Discount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  // Discounts display as negative.
                  item.isDiscount
                      ? '-${fmt.format(item.amount / 100)}'
                      : fmt.format(item.amount / 100),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: item.isDiscount
                        ? Colors.green
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared section header widget
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
