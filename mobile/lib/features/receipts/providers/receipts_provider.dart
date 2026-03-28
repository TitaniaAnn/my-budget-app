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

/// Signed URL for displaying a private receipt image.
/// Cached by [storagePath]; expires in 1 hour (Supabase re-signs on cache miss).
@riverpod
Future<String> receiptImageUrl(
  ReceiptImageUrlRef ref,
  String storagePath,
) async {
  final repo = ref.watch(receiptsRepositoryProvider);
  return repo.getSignedUrl(storagePath);
}
