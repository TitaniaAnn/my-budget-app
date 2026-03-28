// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_line_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReceiptLineItemImpl _$$ReceiptLineItemImplFromJson(
  Map<String, dynamic> json,
) => _$ReceiptLineItemImpl(
  id: json['id'] as String,
  receiptId: json['receipt_id'] as String,
  description: json['description'] as String,
  amount: (json['amount'] as num).toInt(),
  quantity: (json['quantity'] as num?)?.toDouble(),
  unitPrice: (json['unit_price'] as num?)?.toInt(),
  categoryId: json['category_id'] as String?,
  isTax: json['is_tax'] as bool,
  isTip: json['is_tip'] as bool,
  isDiscount: json['is_discount'] as bool,
  sortOrder: (json['sort_order'] as num).toInt(),
);

Map<String, dynamic> _$$ReceiptLineItemImplToJson(
  _$ReceiptLineItemImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'receipt_id': instance.receiptId,
  'description': instance.description,
  'amount': instance.amount,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'category_id': instance.categoryId,
  'is_tax': instance.isTax,
  'is_tip': instance.isTip,
  'is_discount': instance.isDiscount,
  'sort_order': instance.sortOrder,
};
