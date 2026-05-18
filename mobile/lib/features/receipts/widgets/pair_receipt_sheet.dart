// Pair-to-Transaction sheet — shown from the receipt detail screen.
//
// Calls the `find_receipt_match_candidates` RPC (migration 019) to rank
// nearby transactions, then writes `transactions.receipt_id` on the
// chosen one via [TransactionsRepository.setReceiptId]. The sheet is
// fire-and-forget: pick a row and it pops immediately on success.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/sheet_scaffold.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/repositories/transactions_repository.dart';
import '../providers/receipts_provider.dart';
import '../repositories/receipts_repository.dart';

class PairReceiptSheet extends ConsumerStatefulWidget {
  const PairReceiptSheet({super.key, required this.receiptId});

  final String receiptId;

  @override
  ConsumerState<PairReceiptSheet> createState() => _PairReceiptSheetState();
}

class _PairReceiptSheetState extends ConsumerState<PairReceiptSheet> {
  late Future<List<ReceiptMatchCandidate>> _candidatesFuture;

  /// Transaction we're currently writing receipt_id to. Used to disable
  /// taps on every row while the round-trip is in flight, so a fast
  /// double-tap can't pair to two transactions.
  String? _pairingTransactionId;

  @override
  void initState() {
    super.initState();
    _candidatesFuture = ref
        .read(receiptsRepositoryProvider)
        .findMatchCandidates(widget.receiptId);
  }

  Future<void> _pair(ReceiptMatchCandidate c) async {
    if (_pairingTransactionId != null) return;
    setState(() => _pairingTransactionId = c.transactionId);

    try {
      await ref
          .read(transactionsRepositoryProvider)
          .setReceiptId(
            transactionId: c.transactionId,
            receiptId: widget.receiptId,
          );

      // Receipt detail re-reads to show the new linkage; transactions
      // list re-reads so the paired row gets its receipt indicator.
      ref.invalidate(receiptProvider(widget.receiptId));
      ref.invalidate(transactionsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt paired to transaction')),
        );
      }
    } catch (e) {
      setState(() => _pairingTransactionId = null);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error pairing: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: 'Pair to Transaction',
      child: SizedBox(
        // Cap height so an empty/loading state doesn't make the sheet
        // collapse to nothing and a long list doesn't push the close
        // button off the top.
        height: 360,
        child: FutureBuilder<List<ReceiptMatchCandidate>>(
          future: _candidatesFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load candidates: ${snap.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final candidates = snap.data ?? const <ReceiptMatchCandidate>[];
            if (candidates.isEmpty) {
              return _EmptyState();
            }
            return _CandidateList(
              candidates: candidates,
              pairingId: _pairingTransactionId,
              onPick: _pair,
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
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
              Icons.search_off_outlined,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text('No matching transactions', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              'Confirm the merchant, date, and total on the receipt — '
              'an exact total widens the search.',
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

class _CandidateList extends StatelessWidget {
  const _CandidateList({
    required this.candidates,
    required this.pairingId,
    required this.onPick,
  });

  final List<ReceiptMatchCandidate> candidates;
  final String? pairingId;
  final ValueChanged<ReceiptMatchCandidate> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.currency(symbol: '\$');
    final dateFmt = DateFormat.yMMMd();

    return ListView.separated(
      itemCount: candidates.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, i) {
        final c = candidates[i];
        final isPairingThis = pairingId == c.transactionId;
        final isAnythingPairing = pairingId != null;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          enabled: !isAnythingPairing,
          title: Text(
            c.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            c.merchant != null
                ? '${dateFmt.format(c.transactionDate)} · ${c.merchant}'
                : dateFmt.format(c.transactionDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          trailing: isPairingThis
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmt.format(c.amountCents.abs() / 100),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _scoreLabel(c.score),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
          onTap: () => onPick(c),
        );
      },
    );
  }

  /// User-facing label for the RPC's 0–1 score.
  /// We don't expose the raw number — buckets are easier to read.
  String _scoreLabel(double score) {
    if (score >= 0.95) return 'Exact match';
    if (score >= 0.75) return 'Strong match';
    if (score >= 0.5) return 'Possible match';
    return 'Loose match';
  }
}
