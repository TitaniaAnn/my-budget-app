// Attach-Receipt sheet — opened from the transaction edit sheet when
// the user wants to attach a receipt to an existing transaction.
//
// The inverse direction of [PairReceiptSheet]: starts from a
// transaction and picks one of the household's unpaired receipts.
// Writes `transactions.receipt_id` via
// [TransactionsRepository.setReceiptId] and pops with the chosen
// receipt's id so the caller can update its local state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/sheet_scaffold.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/repositories/transactions_repository.dart';
import '../models/receipt.dart';
import '../providers/receipts_provider.dart';

class AttachReceiptSheet extends ConsumerStatefulWidget {
  const AttachReceiptSheet({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<AttachReceiptSheet> createState() => _AttachReceiptSheetState();
}

class _AttachReceiptSheetState extends ConsumerState<AttachReceiptSheet> {
  /// Receipt currently being written. Disables every row while the
  /// round-trip is in flight so a fast double-tap can't bind the
  /// transaction to two receipts in sequence.
  String? _attachingReceiptId;

  Future<void> _attach(Receipt r) async {
    if (_attachingReceiptId != null) return;
    setState(() => _attachingReceiptId = r.id);

    try {
      await ref
          .read(transactionsRepositoryProvider)
          .setReceiptId(transactionId: widget.transactionId, receiptId: r.id);

      // The receipt just left the unpaired pool; the transactions list
      // re-reads to surface the paperclip indicator; if the receipt
      // detail screen happens to be open it picks up its new paired
      // transaction.
      ref.invalidate(unpairedReceiptsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(transactionsForReceiptProvider(r.id));

      if (mounted) {
        Navigator.of(context).pop(r.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Receipt attached')));
      }
    } catch (e) {
      setState(() => _attachingReceiptId = null);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error attaching: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unpairedAsync = ref.watch(unpairedReceiptsProvider);

    return AppSheetScaffold(
      title: 'Attach Receipt',
      child: SizedBox(
        // Cap height so a loading / empty state doesn't make the sheet
        // collapse to nothing and a long list doesn't push the close
        // button off the top. Matches PairReceiptSheet for visual parity.
        height: 360,
        child: unpairedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load receipts: $e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (receipts) {
            if (receipts.isEmpty) return const _EmptyState();
            return _ReceiptList(
              receipts: receipts,
              attachingId: _attachingReceiptId,
              onPick: _attach,
            );
          },
        ),
      ),
    );
  }
}

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
              Icons.receipt_long_outlined,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text('No unpaired receipts', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Capture a receipt first from the Receipts tab, then come '
              'back here to attach it.',
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

class _ReceiptList extends StatelessWidget {
  const _ReceiptList({
    required this.receipts,
    required this.attachingId,
    required this.onPick,
  });

  final List<Receipt> receipts;
  final String? attachingId;
  final ValueChanged<Receipt> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: r'$');
    final dateFmt = DateFormat.yMMMd();

    return ListView.separated(
      itemCount: receipts.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, i) {
        final r = receipts[i];
        final isAttachingThis = attachingId == r.id;
        final isAnythingAttaching = attachingId != null;

        // Anchor for the displayed date: confirmed receipt_date wins,
        // else upload date (matches the candidate-finder RPC's anchor
        // choice in migration 019).
        final shownDate = r.receiptDate ?? r.uploadedAt;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          enabled: !isAnythingAttaching,
          title: Text(
            r.merchantName ?? 'Untitled receipt',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            dateFmt.format(shownDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          trailing: isAttachingThis
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  r.totalAmount != null
                      ? fmt.format(r.totalAmount! / 100)
                      : '—',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
          onTap: () => onPick(r),
        );
      },
    );
  }
}
