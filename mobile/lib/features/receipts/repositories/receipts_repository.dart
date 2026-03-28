// Data access layer for receipts and receipt line items.
// Also owns the Supabase Storage upload/signed-URL logic so the rest
// of the app never references the bucket name directly.
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/receipt.dart';
import '../models/receipt_line_item.dart';

part 'receipts_repository.g.dart';

const _bucket = 'receipts';

@riverpod
ReceiptsRepository receiptsRepository(ReceiptsRepositoryRef ref) {
  return ReceiptsRepository();
}

class ReceiptsRepository {
  final _uuid = const Uuid();

  /// Fetches all receipts for a household, newest first.
  Future<List<Receipt>> fetchReceipts(String householdId) async {
    final data = await supabase
        .from('receipts')
        .select()
        .eq('household_id', householdId)
        .order('uploaded_at', ascending: false);

    return data.map<Receipt>(Receipt.fromJson).toList();
  }

  /// Fetches a single receipt by ID (for the detail screen).
  Future<Receipt> fetchReceipt(String receiptId) async {
    final data = await supabase
        .from('receipts')
        .select()
        .eq('id', receiptId)
        .single();

    return Receipt.fromJson(data);
  }

  /// Fetches all line items for a receipt, ordered by sort_order.
  Future<List<ReceiptLineItem>> fetchLineItems(String receiptId) async {
    final data = await supabase
        .from('receipt_line_items')
        .select()
        .eq('receipt_id', receiptId)
        .order('sort_order');

    return data.map<ReceiptLineItem>(ReceiptLineItem.fromJson).toList();
  }

  /// Uploads [imageFile] to Storage under "{householdId}/{uuid}.jpg",
  /// then inserts a receipt row and returns it.
  ///
  /// The receipt starts with [OcrStatus.pending]. An Edge Function (or manual
  /// update) advances the status once OCR is complete.
  Future<Receipt> uploadReceipt({
    required String householdId,
    required String uploadedBy,
    required File imageFile,
    String? merchantName,
    DateTime? receiptDate,
    int? totalAmountCents,
  }) async {
    // Generate a stable unique filename for the Storage object.
    final fileName = '${_uuid.v4()}.jpg';
    final storagePath = '$householdId/$fileName';

    // Upload image to the private receipts bucket.
    await supabase.storage.from(_bucket).upload(storagePath, imageFile);

    // Insert the receipt row with pending OCR status.
    final data = await supabase
        .from('receipts')
        .insert({
          'household_id': householdId,
          'uploaded_by': uploadedBy,
          'storage_path': storagePath,
          'merchant_name': merchantName,
          'receipt_date': receiptDate?.toIso8601String().substring(0, 10),
          'total_amount': totalAmountCents,
          'ocr_status': 'pending',
        })
        .select()
        .single();

    return Receipt.fromJson(data);
  }

  /// Updates editable receipt metadata (merchant, date, total).
  Future<Receipt> updateReceipt({
    required String receiptId,
    String? merchantName,
    DateTime? receiptDate,
    int? totalAmountCents,
  }) async {
    final data = await supabase
        .from('receipts')
        .update({
          'merchant_name': ?merchantName,
          'receipt_date': ?receiptDate?.toIso8601String().substring(0, 10),
          'total_amount': ?totalAmountCents,
        })
        .eq('id', receiptId)
        .select()
        .single();

    return Receipt.fromJson(data);
  }

  /// Inserts or replaces all line items for a receipt in a single upsert.
  Future<List<ReceiptLineItem>> saveLineItems({
    required String receiptId,
    required List<Map<String, dynamic>> items,
  }) async {
    // Delete existing items first to avoid orphaned rows when count changes.
    await supabase
        .from('receipt_line_items')
        .delete()
        .eq('receipt_id', receiptId);

    if (items.isEmpty) return [];

    final withReceipt = items
        .asMap()
        .entries
        .map((e) => {...e.value, 'receipt_id': receiptId, 'sort_order': e.key})
        .toList();

    final data = await supabase
        .from('receipt_line_items')
        .insert(withReceipt)
        .select();

    return data.map<ReceiptLineItem>(ReceiptLineItem.fromJson).toList();
  }

  /// Generates a short-lived signed URL for displaying a private receipt image.
  /// URLs expire after 1 hour.
  Future<String> getSignedUrl(String storagePath) async {
    final response = await supabase.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 3600);
    return response;
  }

  /// Soft-deletes a receipt by removing both the DB row and Storage object.
  Future<void> deleteReceipt({
    required String receiptId,
    required String storagePath,
  }) async {
    // Explicit type needed: PostgrestFilterBuilder and Future<List<FileObject>>
    // have different types, so Future.wait can't infer a common Future<T>.
    await Future.wait<dynamic>([
      supabase.from('receipts').delete().eq('id', receiptId),
      supabase.storage.from(_bucket).remove([storagePath]),
    ]);
  }
}
