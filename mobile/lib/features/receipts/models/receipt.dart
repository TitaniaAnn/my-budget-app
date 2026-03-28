// Receipt model — mirrors the `receipts` table.
// A receipt is an uploaded image of a paper receipt. OCR runs asynchronously
// (via a Supabase Edge Function + Google Cloud Vision) to extract line items.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt.freezed.dart';
part 'receipt.g.dart';

/// Maps to the `ocr_status` Postgres enum.
enum OcrStatus {
  @JsonValue('pending') pending,
  @JsonValue('processing') processing,
  @JsonValue('complete') complete,
  @JsonValue('failed') failed;

  /// User-facing label for the current OCR state.
  String get displayLabel => switch (this) {
        OcrStatus.pending => 'Queued',
        OcrStatus.processing => 'Processing…',
        OcrStatus.complete => 'Done',
        OcrStatus.failed => 'OCR failed',
      };

  bool get isDone => this == OcrStatus.complete || this == OcrStatus.failed;
}

/// Immutable representation of a row in the `receipts` table.
///
/// [storagePath] is the path inside the `receipts` Supabase Storage bucket,
/// e.g. "{household_id}/{uuid}.jpg". Use the repository to get a signed URL.
/// [totalAmount] is in cents (null until confirmed by user or OCR).
@freezed
class Receipt with _$Receipt {
  const factory Receipt({
    required String id,
    required String householdId,
    required String uploadedBy,
    /// Path inside the `receipts` bucket: "{household_id}/{filename}"
    required String storagePath,
    String? thumbnailPath,
    String? merchantName,
    DateTime? receiptDate,
    /// Total amount in cents, confirmed by user or extracted by OCR.
    int? totalAmount,
    required OcrStatus ocrStatus,
    /// Raw JSON blob returned by the OCR provider (Cloud Vision).
    Map<String, dynamic>? ocrRaw,
    required DateTime uploadedAt,
  }) = _Receipt;

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);
}
