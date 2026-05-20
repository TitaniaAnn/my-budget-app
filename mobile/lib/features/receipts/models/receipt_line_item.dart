// Receipt line item model — mirrors the `receipt_line_items` table.
// Line items are either extracted by OCR or entered manually by the user.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_line_item.freezed.dart';
part 'receipt_line_item.g.dart';

/// One line on a receipt (product, tax, tip, discount, etc.).
/// [amount] is in cents. Special lines (tax, tip, discount) are flagged
/// with boolean fields so totals can be computed correctly.
@freezed
class ReceiptLineItem with _$ReceiptLineItem {
  const factory ReceiptLineItem({
    required String id,
    required String receiptId,
    required String description,

    /// Amount in cents (always positive; sign determined by [isDiscount]).
    required int amount,

    /// Optional quantity for unit-priced items (e.g. 2.0 lbs of produce).
    double? quantity,

    /// Unit price in cents (amount / quantity, when available from OCR).
    int? unitPrice,
    String? categoryId,

    /// True if this line represents sales tax.
    required bool isTax,

    /// True if this line represents a tip/gratuity.
    required bool isTip,

    /// True if this line is a discount (coupon, promo, etc.) — negative value.
    required bool isDiscount,
    required int sortOrder,

    /// Per-line OCR confidence in basis points (0–10000, where 10000
    /// == 1.00). Null when no recognizer ran (user typed the line in
    /// manually). The "Review uncertain OCR lines" surface filters
    /// on this; user edits don't update the value, so a row the user
    /// already corrected won't keep resurfacing for review.
    int? ocrConfidenceBp,
  }) = _ReceiptLineItem;

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptLineItemFromJson(json);
}

/// A line item joined with light receipt context, returned by the
/// uncertain-review fetch. Plain class (not freezed) — it isn't
/// persisted, just rendered. The review screen needs the receipt
/// date and merchant to give each row enough context for the user
/// to recognise it without having to drill into the parent receipt.
class UncertainLineItem {
  const UncertainLineItem({
    required this.lineItem,
    this.receiptDate,
    this.merchant,
  });

  final ReceiptLineItem lineItem;

  /// Date written on the receipt, when OCR / the user captured one.
  /// Null when the receipt is still pending and the date isn't
  /// known yet.
  final DateTime? receiptDate;

  /// Optional merchant name from the parent receipt row.
  final String? merchant;
}
