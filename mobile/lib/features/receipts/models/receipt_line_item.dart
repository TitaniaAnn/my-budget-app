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
  }) = _ReceiptLineItem;

  factory ReceiptLineItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptLineItemFromJson(json);
}
