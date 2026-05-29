// Data access layer for receipts and receipt line items.
// Also owns the Supabase Storage upload/signed-URL logic so the rest
// of the app never references the bucket name directly.
//
// Audit L1 Phase 2c: cache-through on the read paths (fetchReceipts,
// fetchReceipt, fetchLineItems). Storage uploads + Edge Function
// invokes (uploadReceipt, deleteReceipt, retryOcr) stay network-
// only — Phase 4 handles offline storage queueing.
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/receipt.dart';
import '../models/receipt_line_item.dart';

part 'receipts_repository.g.dart';

const _bucket = 'receipts';

@riverpod
ReceiptsRepository receiptsRepository(ReceiptsRepositoryRef ref) {
  return ReceiptsRepository(db: ref.watch(appDatabaseProvider));
}

class ReceiptsRepository {
  ReceiptsRepository({AppDatabase? db}) : _db = db;
  final AppDatabase? _db;
  final _uuid = const Uuid();

  /// Fetches all receipts for a household, newest first.
  Future<List<Receipt>> fetchReceipts(String householdId) async {
    try {
      final data = await supabase
          .from('receipts')
          .select()
          .eq('household_id', householdId)
          .order('uploaded_at', ascending: false);

      final receipts = data.map<Receipt>(Receipt.fromJson).toList();
      await _refreshReceiptsCacheForHousehold(householdId, receipts);
      return receipts;
    } catch (_) {
      final cached = await _loadReceiptsFromCache(householdId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Fetches a single receipt by ID (for the detail screen).
  Future<Receipt> fetchReceipt(String receiptId) async {
    try {
      final data = await supabase
          .from('receipts')
          .select()
          .eq('id', receiptId)
          .single();

      final receipt = Receipt.fromJson(data);
      await _writeReceiptCacheRow(receipt);
      return receipt;
    } catch (_) {
      final cached = await _loadReceiptFromCache(receiptId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Fetches all line items for a receipt, ordered by sort_order ASC
  /// (the order the user — or OCR — saved them in).
  ///
  /// `save_receipt_line_items` (migration 018) writes sort_order from
  /// the input array's ordinality, so ASC reproduces the on-paper
  /// reading order. postgrest's .order() defaults to DESC, so the
  /// `ascending: true` here is load-bearing — without it the editor
  /// would render line items bottom-up.
  Future<List<ReceiptLineItem>> fetchLineItems(String receiptId) async {
    try {
      final data = await supabase
          .from('receipt_line_items')
          .select()
          .eq('receipt_id', receiptId)
          .order('sort_order', ascending: true);

      final items = data
          .map<ReceiptLineItem>(ReceiptLineItem.fromJson)
          .toList();
      await _refreshLineItemsCacheForReceipt(receiptId, items);
      return items;
    } catch (_) {
      final cached = await _loadLineItemsFromCache(receiptId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Uploads [imageFile] (full resolution) AND a 256-px JPEG thumbnail
  /// alongside it, then inserts a receipt row pointing at both objects.
  ///
  /// Audit P5: pre-fix the grid downloaded the full-resolution image
  /// (500 KB - 1.5 MB per receipt) for a 200-px thumbnail card; the
  /// `thumbnail_path` column existed (since migration 001) but
  /// nothing populated it. Now we generate the thumb client-side
  /// once at upload time and the grid reads from the small object.
  /// Failure to compress (decoder corner-cases on some camera JPEGs)
  /// is non-fatal — the receipt still uploads and the grid falls
  /// back to the full image.
  ///
  /// The receipt starts with [OcrStatus.pending]. An Edge Function (or manual
  /// update) advances the status once OCR is complete.
  ///
  /// If the row insert fails after the upload, both storage objects
  /// are best-effort removed so the bucket doesn't accumulate
  /// orphans the user can't see.
  Future<Receipt> uploadReceipt({
    required String householdId,
    required String uploadedBy,
    required File imageFile,
    String? merchantName,
    DateTime? receiptDate,
    int? totalAmountCents,
  }) async {
    // Stable unique base name; thumbnail uses the same uuid + suffix
    // so the pair is recognisable in Storage and easy to clean up.
    final uuid = _uuid.v4();
    final storagePath = '$householdId/$uuid.jpg';
    final thumbnailPath = '$householdId/${uuid}_thumb.jpg';

    // Upload full resolution first — if this fails we never even
    // generate the thumb, no cleanup needed.
    await supabase.storage.from(_bucket).upload(storagePath, imageFile);

    // Generate + upload the thumbnail. Failures here are NOT fatal:
    // the receipt still gets stored without a thumbnail; the grid
    // falls back to the full image (slower, but works). We swallow
    // the compress error inline rather than failing the whole upload
    // over a UX-perf optimisation.
    String? actualThumbnailPath;
    try {
      final thumbBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 256,
        minHeight: 256,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      if (thumbBytes != null && thumbBytes.isNotEmpty) {
        await supabase.storage
            .from(_bucket)
            .uploadBinary(thumbnailPath, thumbBytes);
        actualThumbnailPath = thumbnailPath;
      }
    } catch (_) {
      // Compress / upload failed — proceed with thumbnail_path NULL.
    }

    try {
      final data = await supabase
          .from('receipts')
          .insert({
            'household_id': householdId,
            'uploaded_by': uploadedBy,
            'storage_path': storagePath,
            'thumbnail_path': actualThumbnailPath,
            'merchant_name': merchantName,
            'receipt_date': receiptDate?.toIso8601String().substring(0, 10),
            'total_amount': totalAmountCents,
            'ocr_status': 'pending',
          })
          .select()
          .single();
      final receipt = Receipt.fromJson(data);
      await _writeReceiptCacheRow(receipt);
      return receipt;
    } catch (_) {
      // Compensate both objects. Swallow cleanup failures — the
      // original insert error is what the caller needs to see.
      final pathsToRemove = <String>[storagePath, ?actualThumbnailPath];
      try {
        await supabase.storage.from(_bucket).remove(pathsToRemove);
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

    final receipt = Receipt.fromJson(data);
    await _writeReceiptCacheRow(receipt);
    return receipt;
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
    if (data == null) {
      // The RPC returned nothing — mirror that on the cache side
      // by clearing the receipt's line items. Otherwise stale rows
      // from a prior save would survive a clear-out.
      await _refreshLineItemsCacheForReceipt(receiptId, const []);
      return [];
    }
    final saved = (data as List)
        .map<ReceiptLineItem>(
          (e) => ReceiptLineItem.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    await _refreshLineItemsCacheForReceipt(receiptId, saved);
    return saved;
  }

  /// Fetches line items whose OCR confidence (basis points) falls in
  /// the "uncertain" band — by default, anything at or below
  /// [maxConfidenceBp]. Joined with the parent receipt to surface
  /// the receipt date and (when present) merchant in the review
  /// screen without a second round-trip.
  ///
  /// Scoped to the caller's household via the receipts join — RLS
  /// on `receipts` does the gating. Rows the user has manually
  /// edited are still surfaced because we don't (yet) track a
  /// "reviewed" flag separate from the confidence value; a future
  /// migration could add `ocr_reviewed_at` for that.
  ///
  /// Default 5500 mirrors the [Categorizer]'s ML uncertain band so
  /// the OCR review surface feels consistent with the existing
  /// "Review uncertain ML guesses" screen.
  Future<List<UncertainLineItem>> fetchUncertainLineItems({
    required String householdId,
    int maxConfidenceBp = 5500,
    int limit = 100,
  }) async {
    final data = await supabase
        .from('receipt_line_items')
        .select(
          'id, receipt_id, description, amount, '
          'category_id, is_tax, is_tip, is_discount, '
          'ocr_confidence_bp, sort_order, '
          'receipt:receipts!inner(household_id, receipt_date, merchant_name)',
        )
        .eq('receipt.household_id', householdId)
        .not('ocr_confidence_bp', 'is', null)
        .lte('ocr_confidence_bp', maxConfidenceBp)
        .order('ocr_confidence_bp', ascending: true)
        .limit(limit);

    return data.map<UncertainLineItem>((row) {
      final r = row;
      final receipt = r['receipt'] as Map<String, dynamic>;
      final dateStr = receipt['receipt_date'] as String?;
      return UncertainLineItem(
        lineItem: ReceiptLineItem.fromJson({
          ...r,
          // quantity / unit_price aren't selected — fill nulls so
          // fromJson is happy. The review surface doesn't show them.
          'quantity': r['quantity'],
          'unit_price': r['unit_price'],
        }),
        receiptDate: dateStr == null ? null : DateTime.parse(dateStr),
        merchant: receipt['merchant_name'] as String?,
      );
    }).toList();
  }

  /// Confirms or corrects a line item via the review surface.
  /// Clears `ocr_confidence_bp` so the row stops surfacing in the
  /// uncertain list — the act of editing or confirming IS the
  /// review. Optionally accepts new field values for inline edits
  /// (description / amount / category).
  Future<void> confirmLineItem({
    required String lineItemId,
    String? description,
    int? amountCents,
    String? categoryId,
  }) async {
    await supabase
        .from('receipt_line_items')
        .update({
          'ocr_confidence_bp': null,
          'description': ?description,
          'amount': ?amountCents,
          'category_id': ?categoryId,
        })
        .eq('id', lineItemId);
    // The server doesn't return the modified row, so we can't
    // upsert into the cache directly. The "uncertain review"
    // surface only cares whether ocr_confidence_bp is non-null,
    // which is a server-only filter — the next fetchLineItems
    // for the parent receipt reconciles. Skip cache writes here.
  }

  /// Generates a short-lived signed URL for displaying a private receipt image.
  /// URLs expire after 1 hour.
  Future<String> getSignedUrl(String storagePath) async {
    final response = await supabase.storage
        .from(_bucket)
        .createSignedUrl(storagePath, 3600);
    return response;
  }

  /// Batched signed-URL sign-off: one HTTP round-trip to
  /// `/storage/v1/object/sign/{bucket}` returns a URL for every
  /// requested path. Audit P4: the prior per-receipt family
  /// provider fired one `createSignedUrl` per card, so opening a
  /// household with 50 receipts cost 50 wire round-trips on first
  /// paint of the grid. Returns a `path → signed URL` map keyed by
  /// the same paths the caller passed in; missing paths (storage
  /// returns an error for them) simply don't appear in the result.
  Future<Map<String, String>> getSignedUrls(List<String> paths) async {
    if (paths.isEmpty) return const {};
    final response = await supabase.storage
        .from(_bucket)
        .createSignedUrls(paths, 3600);
    return {
      for (final s in response)
        if (s.signedUrl.isNotEmpty) s.path: s.signedUrl,
    };
  }

  /// Deletes a receipt's storage object first, then its DB row.
  ///
  /// Audit H2: pre-fix this was a parallel `Future.wait` of the two
  /// deletes; whenever the DB delete won the race and storage delete
  /// failed, the storage object became permanently unreachable —
  /// once the row was gone, RLS no longer authorised any
  /// `{household_id}/...` path read, so the object just accumulated
  /// invisible.
  ///
  /// Sequencing storage-first with a single retry trades one silent
  /// failure mode for one visible failure mode:
  ///
  ///   * Storage delete fails (both attempts) → DB row stays. The
  ///     user sees the receipt still in the list and can retry. No
  ///     orphan.
  ///   * Storage delete succeeds, DB delete fails → DB row stays as
  ///     a "broken" receipt (its image URL will 404). The row is
  ///     still RLS-readable so a retry from the UI cleans it up
  ///     (storage.remove is idempotent — the second attempt no-ops
  ///     past the missing object).
  ///
  /// The retry covers the dominant failure shape (transient network
  /// blip during storage.remove). For a hosted-service rewrite, the
  /// senior fix is an Edge Function with a pending-deletion queue
  /// (mark-for-delete in DB, retry storage cleanup with backoff).
  /// Line items cascade-delete on the DB row (migration 001 sets
  /// `ON DELETE CASCADE` on `receipt_line_items.receipt_id`) so we
  /// don't have to delete them by hand.
  Future<void> deleteReceipt({
    required String receiptId,
    required String storagePath,
  }) async {
    try {
      await supabase.storage.from(_bucket).remove([storagePath]);
    } catch (_) {
      // One transient retry. Most storage failures are network
      // blips that resolve on the second attempt; harder failures
      // (auth, missing bucket) will throw the same exception again
      // and bubble up to the caller's catch site.
      await supabase.storage.from(_bucket).remove([storagePath]);
    }
    await supabase.from('receipts').delete().eq('id', receiptId);
    await _deleteReceiptCacheRow(receiptId);
  }

  /// Invokes the `process-receipt-ocr` Edge Function to re-attempt
  /// OCR on a receipt. Used by the "Retry OCR" affordance (audit H3)
  /// when a receipt is stuck on `pending` or sat at `failed`.
  ///
  /// The function sets `ocr_status` to `'processing'` immediately
  /// and either `'complete'` or `'failed'` after the OCR pass —
  /// callers should invalidate [receiptProvider] after this returns
  /// so the UI picks up the new status. In the local dev stub a
  /// retry produces synthetic line items; in production it
  /// re-queues the real Cloud Vision pass.
  Future<void> retryOcr(String receiptId) async {
    await supabase.functions.invoke(
      'process-receipt-ocr',
      body: {'receipt_id': receiptId},
    );
  }

  /// Returns receipts no transaction is currently pointing at, newest
  /// upload first. Used by the transaction edit sheet's "Attach Receipt"
  /// picker — the inverse of [findMatchCandidates].
  ///
  /// Backed by `fetch_unpaired_receipts` (migration 025) rather than a
  /// PostgREST query: the underlying filter ("no row in transactions has
  /// receipt_id = r.id") doesn't express cleanly in the URL grammar, and
  /// pushing it into SQL means the wire payload is bounded by [limit]
  /// instead of "every receipt in the household".
  Future<List<Receipt>> fetchUnpaired({int limit = 20}) async {
    final data = await supabase.rpc(
      'fetch_unpaired_receipts',
      params: {'p_limit': limit},
    );
    if (data == null) return [];
    return (data as List)
        .map<Receipt>((row) => Receipt.fromJson(row as Map<String, dynamic>))
        .toList();
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

  // ── Cache helpers ──────────────────────────────────────────

  Future<void> _refreshReceiptsCacheForHousehold(
    String householdId,
    List<Receipt> receipts,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.replaceReceiptsForHousehold(
        householdId,
        receipts.map(_receiptToCompanion).toList(),
      );
    } catch (_) {/**/}
  }

  Future<void> _writeReceiptCacheRow(Receipt r) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.upsertReceipt(_receiptToCompanion(r));
    } catch (_) {/**/}
  }

  Future<void> _deleteReceiptCacheRow(String id) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.deleteReceipt(id);
    } catch (_) {/**/}
  }

  Future<List<Receipt>?> _loadReceiptsFromCache(String householdId) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.loadReceiptsForHousehold(householdId);
      if (rows.isEmpty) return null;
      return rows.map(_receiptFromCacheRow).toList();
    } catch (_) {
      return null;
    }
  }

  Future<Receipt?> _loadReceiptFromCache(String id) async {
    final db = _db;
    if (db == null) return null;
    try {
      final row = await db.loadReceiptById(id);
      if (row == null) return null;
      return _receiptFromCacheRow(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshLineItemsCacheForReceipt(
    String receiptId,
    List<ReceiptLineItem> items,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.replaceLineItemsForReceipt(
        receiptId,
        items.map(_lineItemToCompanion).toList(),
      );
    } catch (_) {/**/}
  }

  Future<List<ReceiptLineItem>?> _loadLineItemsFromCache(
    String receiptId,
  ) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.loadLineItemsForReceipt(receiptId);
      if (rows.isEmpty) return null;
      return rows.map(_lineItemFromCacheRow).toList();
    } catch (_) {
      return null;
    }
  }
}

// ── Receipt ↔ drift Companion mappers ──────────────────────────

ReceiptsCacheCompanion _receiptToCompanion(Receipt r) {
  return ReceiptsCacheCompanion(
    id: Value(r.id),
    householdId: Value(r.householdId),
    uploadedBy: Value(r.uploadedBy),
    storagePath: Value(r.storagePath),
    thumbnailPath: Value(r.thumbnailPath),
    merchantName: Value(r.merchantName),
    receiptDate: Value(r.receiptDate?.toUtc()),
    totalAmount: Value(r.totalAmount),
    ocrStatus: Value(_ocrStatusDbValue(r.ocrStatus)),
    ocrRawJson: Value(r.ocrRaw == null ? null : jsonEncode(r.ocrRaw)),
    uploadedAt: Value(r.uploadedAt.toUtc()),
    cachedAt: Value(DateTime.now().toUtc()),
  );
}

Receipt _receiptFromCacheRow(ReceiptsCacheRow r) {
  return Receipt(
    id: r.id,
    householdId: r.householdId,
    uploadedBy: r.uploadedBy,
    storagePath: r.storagePath,
    thumbnailPath: r.thumbnailPath,
    merchantName: r.merchantName,
    receiptDate: r.receiptDate,
    totalAmount: r.totalAmount,
    ocrStatus: _ocrStatusFromDbValue(r.ocrStatus),
    ocrRaw: r.ocrRawJson == null
        ? null
        : jsonDecode(r.ocrRawJson!) as Map<String, dynamic>,
    uploadedAt: r.uploadedAt,
  );
}

ReceiptLineItemsCacheCompanion _lineItemToCompanion(ReceiptLineItem li) {
  return ReceiptLineItemsCacheCompanion(
    id: Value(li.id),
    receiptId: Value(li.receiptId),
    description: Value(li.description),
    amount: Value(li.amount),
    quantity: Value(li.quantity),
    unitPrice: Value(li.unitPrice),
    categoryId: Value(li.categoryId),
    isTax: Value(li.isTax),
    isTip: Value(li.isTip),
    isDiscount: Value(li.isDiscount),
    sortOrder: Value(li.sortOrder),
    ocrConfidenceBp: Value(li.ocrConfidenceBp),
    cachedAt: Value(DateTime.now().toUtc()),
  );
}

ReceiptLineItem _lineItemFromCacheRow(ReceiptLineItemsCacheRow r) {
  return ReceiptLineItem(
    id: r.id,
    receiptId: r.receiptId,
    description: r.description,
    amount: r.amount,
    quantity: r.quantity,
    unitPrice: r.unitPrice,
    categoryId: r.categoryId,
    isTax: r.isTax,
    isTip: r.isTip,
    isDiscount: r.isDiscount,
    sortOrder: r.sortOrder,
    ocrConfidenceBp: r.ocrConfidenceBp,
  );
}

/// OcrStatus.values uses Dart identifier names, not the DB strings.
/// `@JsonValue` annotations on the enum map snake_case for the
/// wire — these helpers do the same for cache writes/reads.
String _ocrStatusDbValue(OcrStatus s) => switch (s) {
  OcrStatus.pending => 'pending',
  OcrStatus.processing => 'processing',
  OcrStatus.complete => 'complete',
  OcrStatus.failed => 'failed',
};

OcrStatus _ocrStatusFromDbValue(String v) => switch (v) {
  'pending' => OcrStatus.pending,
  'processing' => OcrStatus.processing,
  'complete' => OcrStatus.complete,
  'failed' => OcrStatus.failed,
  // Forward-compat fallback for a cache row written by a newer
  // app version that added an OcrStatus variant.
  _ => OcrStatus.pending,
};

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
