// Receipts list screen — shows a scrollable grid of receipt thumbnails.
//
// Tapping a card navigates to the detail screen. The FAB opens the
// CaptureReceiptSheet to add a new receipt.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/state_views.dart';
import '../models/receipt.dart';
import '../providers/receipts_provider.dart';
import '../widgets/capture_receipt_sheet.dart';

class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Receipts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            showAppSheet<void>(context, child: const CaptureReceiptSheet()),
        tooltip: 'Add Receipt',
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: receiptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(receiptsProvider),
        ),
        data: (receipts) {
          if (receipts.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No Receipts Yet',
              subtitle: 'Tap the camera button to capture\nyour first receipt.',
            );
          }
          return RefreshIndicator(
            // Phase 5b: drain offline writes + invalidate ledger.
            onRefresh: () =>
                ref.read(syncCoordinatorProvider).pullToRefresh(ref),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75, // taller cards to show merchant + date
              ),
              itemCount: receipts.length,
              itemBuilder: (context, index) =>
                  _ReceiptCard(receipt: receipts[index]),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual receipt card in the grid
// ---------------------------------------------------------------------------

class _ReceiptCard extends ConsumerWidget {
  const _ReceiptCard({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Audit P5: prefer the 256-px thumbnail when the receipt has one
    // (uploaded after P5 shipped). Pre-P5 receipts have NULL
    // thumbnail_path and fall back to the full image — slower first
    // paint, but cached_network_image still caches it to disk so
    // subsequent renders skip the network.
    final imagePath = receipt.thumbnailPath ?? receipt.storagePath;
    final imageAsync = ref.watch(receiptImageUrlProvider(imagePath));

    return GestureDetector(
      onTap: () => context.push('/receipts/${receipt.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail — fills top 60 % of the card
            Expanded(
              child: imageAsync.when(
                loading: () => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 40,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                data: (url) => CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  // Same placeholder shape as the loading state so a
                  // cache miss doesn't pop a flash of nothing.
                  placeholder: (context, _) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, _, _) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),

            // Metadata below the image
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.merchantName ?? 'Unknown',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    receipt.receiptDate != null
                        ? DateFormat.yMMMd().format(receipt.receiptDate!)
                        : DateFormat.yMMMd().format(receipt.uploadedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  if (receipt.totalAmount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      NumberFormat.currency(
                        symbol: '\$',
                      ).format(receipt.totalAmount! / 100),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // OCR status indicator bar at the very bottom
            if (!receipt.ocrStatus.isDone)
              LinearProgressIndicator(
                minHeight: 3,
                color: receipt.ocrStatus == OcrStatus.processing
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}
