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
  ///
  /// If the row insert fails after the upload, the storage object is
  /// best-effort removed so the bucket doesn't accumulate orphans the user
  /// can't see.
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

    try {
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
    } catch (_) {
      // Compensate the just-uploaded object. Swallow cleanup failures —
      // the original error is what the caller needs to see.
      try {
        await supabase.storage.from(_bucket).remove([storagePath]);
      } catch (_) {}
      rethrow;
    }
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

  /// Atomically replaces all line items for a receipt.
  ///
  /// Implemented as a single Postgres RPC (migration 018) so a delete-then-
  /// insert race can't leave the receipt with zero line items if the insert
  /// half fails. The RPC assigns `sort_order` from the array position.
  Future<List<ReceiptLineItem>> saveLineItems({
    required String receiptId,
    required List<Map<String, dynamic>> items,
  }) async {
    final data = await supabase.rpc(
      'save_receipt_line_items',
      params: {'p_receipt_id': receiptId, 'p_items': items},
    );
    if (data == null) return [];
    return (data as List)
        .map<ReceiptLineItem>(
          (e) => ReceiptLineItem.fromJson(e as Map<String, dynamic>),
        )
        .toList();
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

  /// Finds transactions that plausibly pair with [receiptId], ranked by
  /// the SQL `find_receipt_match_candidates` RPC (migration 019).
  ///
  /// The RPC handles the ranking and RLS — we just deserialize the rows.
  /// Empty list means no nearby transactions matched (or the user can't
  /// see the receipt; RLS hides both cases the same way).
  Future<List<ReceiptMatchCandidate>> findMatchCandidates(
    String receiptId,
  ) async {
    final data = await supabase.rpc(
      'find_receipt_match_candidates',
      params: {'p_receipt_id': receiptId},
    );
    if (data == null) return [];
    return (data as List)
        .map<ReceiptMatchCandidate>(
          (row) => ReceiptMatchCandidate.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }
}

/// A transaction surfaced as a candidate for pairing with a receipt.
///
/// This is a query-result DTO, not a database table — kept next to the
/// repository rather than in `models/` because nothing else owns it.
/// Score is the RPC's combined date+amount proximity (0–1, higher better).
class ReceiptMatchCandidate {
  const ReceiptMatchCandidate({
    required this.transactionId,
    required this.accountId,
    required this.transactionDate,
    required this.amountCents,
    required this.description,
    required this.merchant,
    required this.score,
  });

  final String transactionId;
  final String accountId;
  final DateTime transactionDate;

  /// Signed amount in cents (negative for debits — same sign convention
  /// as `transactions.amount`). The sheet displays `.abs()`.
  final int amountCents;

  final String description;
  final String? merchant;

  /// Combined match score from the RPC, 0.0–1.0. 1.0 means same date and
  /// exact amount; ~0.5 means one of the two is off but still in window.
  final double score;

  factory ReceiptMatchCandidate.fromJson(Map<String, dynamic> json) {
    return ReceiptMatchCandidate(
      transactionId: json['transaction_id'] as String,
      accountId: json['account_id'] as String,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      amountCents: json['amount'] as int,
      description: json['description'] as String,
      merchant: json['merchant'] as String?,
      score: (json['score'] as num).toDouble(),
    );
  }
}
