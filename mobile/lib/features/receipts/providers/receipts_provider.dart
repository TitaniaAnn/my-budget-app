// Riverpod providers for receipts.
//
// Keeps the list of receipts and individual receipt detail as separate
// providers so the detail screen can refresh without invalidating the grid.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../models/receipt.dart';
import '../models/receipt_line_item.dart';
import '../repositories/receipts_repository.dart';

part 'receipts_provider.g.dart';

/// All receipts for the current household, newest first.
@riverpod
Future<List<Receipt>> receipts(ReceiptsRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return [];

  final repo = ref.watch(receiptsRepositoryProvider);
  return repo.fetchReceipts(householdId);
}

/// Single receipt by [receiptId]. Used by the detail screen.
@riverpod
Future<Receipt> receipt(ReceiptRef ref, String receiptId) async {
  final repo = ref.watch(receiptsRepositoryProvider);
  return repo.fetchReceipt(receiptId);
}

/// Line items for a receipt. Separate provider so the grid list doesn't
/// need to load line items for every thumbnail.
@riverpod
Future<List<ReceiptLineItem>> receiptLineItems(
  ReceiptLineItemsRef ref,
  String receiptId,
) async {
  final repo = ref.watch(receiptsRepositoryProvider);
  return repo.fetchLineItems(receiptId);
}

/// Receipts in the current household with no transaction pointing at
/// them. Powers the transaction edit sheet's "Attach Receipt" picker —
/// the inverse direction of the existing pair-from-receipt flow.
@riverpod
Future<List<Receipt>> unpairedReceipts(UnpairedReceiptsRef ref) async {
  final repo = ref.watch(receiptsRepositoryProvider);
  return repo.fetchUnpaired();
}

/// Signed URLs for EVERY receipt in the current household, keyed by
/// `storagePath`. Audit P4: pre-fix each `_ReceiptCard` watched its
/// own per-path provider so a 50-receipt grid fired 50 sign-url
/// HTTP round-trips on first paint. This pulls them in one
/// `createSignedUrls` POST that covers both full-resolution paths
/// AND thumbnail paths — the grid uses thumbnails when present,
/// the detail screen uses full images, but one wire fetch covers
/// both. Cards resolve from the map.
@riverpod
Future<Map<String, String>> signedReceiptUrls(SignedReceiptUrlsRef ref) async {
  final receipts = await ref.watch(receiptsProvider.future);
  if (receipts.isEmpty) return const {};
  final repo = ref.watch(receiptsRepositoryProvider);
  final paths = <String>[
    for (final r in receipts) r.storagePath,
    for (final r in receipts) ?r.thumbnailPath,
  ];
  return repo.getSignedUrls(paths);
}

/// Signed URL for one receipt image, by [storagePath]. Resolves
/// from the batched [signedReceiptUrlsProvider] when the path is
/// part of the current household receipts list (the common case);
/// falls back to a one-off sign for paths outside that list
/// (e.g. detail screen opened via deep link before the list has
/// been fetched, or for a brand-new receipt that hasn't propagated
/// into the cached `receiptsProvider` value yet).
@riverpod
Future<String> receiptImageUrl(
  ReceiptImageUrlRef ref,
  String storagePath,
) async {
  final batched = await ref.watch(signedReceiptUrlsProvider.future);
  final hit = batched[storagePath];
  if (hit != null) return hit;
  final repo = ref.watch(receiptsRepositoryProvider);
  return repo.getSignedUrl(storagePath);
}
