// Receipt detail screen — shows the receipt image, editable metadata, and
// the list of line items extracted by OCR (or entered manually).
//
// Line items can be edited in-place and saved back to the database.
// "Pair to Transaction" opens [PairReceiptSheet] which calls the
// `find_receipt_match_candidates` RPC (migration 019) and writes
// `transactions.receipt_id` on the chosen row.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../settings/providers/settings_provider.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/repositories/transactions_repository.dart';
import '../models/receipt.dart';
import '../models/receipt_line_item.dart';
import '../providers/receipts_provider.dart';
import '../repositories/receipts_repository.dart';
import '../widgets/pair_receipt_sheet.dart';
import 'line_items_editor_screen.dart';

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
      _dateCtrl.text = kIsoDate.format(receipt.receiptDate!);
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
        merchantName: _merchantCtrl.text.trim().isNotEmpty
            ? _merchantCtrl.text.trim()
            : null,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Receipt updated')));
      }
    } catch (e) {
      setState(() => _savingMeta = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteReceipt(Receipt receipt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Receipt?'),
        content: const Text(
          'This will permanently remove the image and all data.',
        ),
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
    try {
      await repo.deleteReceipt(
        receiptId: receipt.id,
        storagePath: receipt.storagePath,
      );
      ref.invalidate(receiptsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Audit H2: a storage failure (both retries) leaves the DB
      // row intact so the user CAN retry — surface the failure so
      // they know to do that.
      if (mounted) context.showErrorSnackBar(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptAsync = ref.watch(receiptProvider(widget.receiptId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          receiptAsync
                  .whenData(
                    (r) => IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteReceipt(r),
                      tooltip: 'Delete',
                    ),
                  )
                  .valueOrNull ??
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
    final lineItemsAsync = ref.watch(receiptLineItemsProvider(receipt.id));

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
                    Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    const Text('Could not load image'),
                  ],
                ),
              ),
            ),
            data: (url) => CachedNetworkImage(
              imageUrl: url,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              // Audit P5: backed by cached_network_image so the full
              // image isn't re-fetched on every cold start of the
              // detail screen.
              placeholder: (context, _) => const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, _, _) => SizedBox(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      const Text('Could not load image'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── OCR status chip ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _OcrStatusChip(status: receipt.ocrStatus),
              const SizedBox(width: 12),
              // Audit H3: when OCR sits at `failed` (production
              // function errored) or `pending` for more than an hour
              // (production function never dequeued the row, common
              // when the external OCR backend is briefly down),
              // give the user an escape hatch — re-invoke the
              // function explicitly. Hidden in the happy-path so the
              // chip doesn't shout for attention.
              if (_shouldOfferOcrRetry(receipt))
                _OcrRetryButton(receiptId: receipt.id),
            ],
          ),
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(savingMeta ? 'Saving…' : 'Save Changes'),
          ),
        ],

        // ── Paired Transactions ─────────────────────────────────────────
        // Shows transactions whose receipt_id points at this receipt, each
        // with an unpair affordance. Hidden entirely when nothing is paired
        // so an unpaired receipt only shows the "Pair to Transaction" CTA.
        _PairedTransactionsSection(receiptId: receipt.id),

        // ── Pair to Transaction ─────────────────────────────────────────
        // The schema allows many transactions per receipt (split bills,
        // installments) so this stays visible even when something is
        // already paired.
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showAppSheet<void>(
            context,
            child: PairReceiptSheet(receiptId: receipt.id),
          ),
          icon: const Icon(Icons.link_outlined),
          label: const Text('Pair to Transaction'),
        ),

        // ── Line items ──────────────────────────────────────────────────
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: _SectionHeader('Line Items')),
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        LineItemsEditorScreen(receiptId: receipt.id),
                  ),
                );
                // Editor pops back here after Save. The line items
                // provider invalidates inside the editor, so the
                // refreshed list flows in automatically — no manual
                // invalidate needed.
              },
            ),
          ],
        ),
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

/// Threshold beyond which a `pending` OCR row is treated as stuck
/// rather than "just queued." The production OCR backend usually
/// completes in seconds; an hour comfortably absorbs cold-start
/// queues without nagging the user with a retry button on every
/// fresh upload.
const _kOcrStuckAfter = Duration(hours: 1);

/// True when the receipt's OCR status warrants a "Retry OCR"
/// affordance — `failed` always qualifies, `pending` qualifies once
/// it's been queued long enough to suspect the external backend
/// dropped it.
bool _shouldOfferOcrRetry(Receipt r) {
  if (r.ocrStatus == OcrStatus.failed) return true;
  if (r.ocrStatus == OcrStatus.pending) {
    return DateTime.now().toUtc().difference(r.uploadedAt.toUtc()) >
        _kOcrStuckAfter;
  }
  return false;
}

/// Compact "Retry OCR" button. Disables itself while a retry is
/// in-flight so a double-tap can't queue two invocations against
/// the same row. On success the receipt provider is invalidated so
/// the parent re-renders with the new status.
class _OcrRetryButton extends ConsumerStatefulWidget {
  const _OcrRetryButton({required this.receiptId});

  final String receiptId;

  @override
  ConsumerState<_OcrRetryButton> createState() => _OcrRetryButtonState();
}

class _OcrRetryButtonState extends ConsumerState<_OcrRetryButton> {
  bool _busy = false;

  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(receiptsRepositoryProvider)
          .retryOcr(widget.receiptId);
      ref.invalidate(receiptProvider(widget.receiptId));
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _busy ? null : _retry,
      icon: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, size: 16),
      label: const Text('Retry OCR'),
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }
}

// ---------------------------------------------------------------------------
// Line items list
// ---------------------------------------------------------------------------

class _LineItemsList extends ConsumerWidget {
  const _LineItemsList({required this.items});

  final List<ReceiptLineItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Audit C1: line-item amounts must render in the household's
    // display currency, not a hardcoded "$". Receipts don't carry
    // their own currency column today — if that changes, switch to
    // the receipt's currency rather than the household's.
    final currency = ref
        .watch(householdInfoProvider)
        .maybeWhen(data: (h) => h.displayCurrency, orElse: () => 'USD');

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
                      Text(item.description, style: theme.textTheme.bodyMedium),
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
                      ? '-${formatCurrency(item.amount, currency: currency)}'
                      : formatCurrency(item.amount, currency: currency),
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
// Paired Transactions section
// ---------------------------------------------------------------------------

/// Lists transactions currently paired to [receiptId] (via
/// `transactions.receipt_id`) and lets the user unpair each one.
///
/// Returns an empty `SizedBox` when nothing is paired so a fresh
/// receipt doesn't render an empty header. Loading and error states
/// are intentionally quiet — the section is supplementary, not the
/// primary content, so a long spinner here would just look like a
/// layout bug.
class _PairedTransactionsSection extends ConsumerWidget {
  const _PairedTransactionsSection({required this.receiptId});

  final String receiptId;

  Future<void> _unpair(
    BuildContext context,
    WidgetRef ref,
    Transaction tx,
  ) async {
    final repo = ref.read(transactionsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await repo.setReceiptId(transactionId: tx.id, receiptId: null);

      ref.invalidate(transactionsForReceiptProvider(receiptId));
      // Global transactions list re-reads so the row's receipt indicator
      // (once we ship one) reflects the unpaired state immediately.
      ref.invalidate(transactionsProvider);

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Receipt unpaired'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              // Re-pair using the same repo; the user can fat-finger
              // unpair on a long list without losing the link.
              await repo.setReceiptId(
                transactionId: tx.id,
                receiptId: receiptId,
              );
              ref.invalidate(transactionsForReceiptProvider(receiptId));
              ref.invalidate(transactionsProvider);
            },
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error unpairing: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pairedAsync = ref.watch(transactionsForReceiptProvider(receiptId));
    final dateFmt = DateFormat.yMMMd();

    return pairedAsync.when(
      // Quiet states: the section is optional, so we don't surface
      // loading/error chrome that would look like a problem with the
      // rest of the screen.
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (transactions) {
        if (transactions.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader('Paired Transactions'),
              const SizedBox(height: 4),
              for (final tx in transactions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    tx.merchant ?? tx.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    dateFmt.format(tx.transactionDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        // Each paired tx renders in its OWN currency
                        // (transactions.currency, set server-side from
                        // the account). For a USD-only household this
                        // is identical to the household symbol; for a
                        // multi-currency household it correctly shows
                        // the leg's actual currency.
                        formatCurrency(tx.amount.abs(), currency: tx.currency),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.link_off_outlined),
                        tooltip: 'Unpair',
                        onPressed: () => _unpair(context, ref, tx),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
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
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
