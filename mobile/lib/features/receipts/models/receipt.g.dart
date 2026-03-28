// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReceiptImpl _$$ReceiptImplFromJson(Map<String, dynamic> json) =>
    _$ReceiptImpl(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      merchantName: json['merchant_name'] as String?,
      receiptDate: json['receipt_date'] == null
          ? null
          : DateTime.parse(json['receipt_date'] as String),
      totalAmount: (json['total_amount'] as num?)?.toInt(),
      ocrStatus: $enumDecode(_$OcrStatusEnumMap, json['ocr_status']),
      ocrRaw: json['ocr_raw'] as Map<String, dynamic>?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );

Map<String, dynamic> _$$ReceiptImplToJson(_$ReceiptImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'household_id': instance.householdId,
      'uploaded_by': instance.uploadedBy,
      'storage_path': instance.storagePath,
      'thumbnail_path': instance.thumbnailPath,
      'merchant_name': instance.merchantName,
      'receipt_date': instance.receiptDate?.toIso8601String(),
      'total_amount': instance.totalAmount,
      'ocr_status': _$OcrStatusEnumMap[instance.ocrStatus]!,
      'ocr_raw': instance.ocrRaw,
      'uploaded_at': instance.uploadedAt.toIso8601String(),
    };

const _$OcrStatusEnumMap = {
  OcrStatus.pending: 'pending',
  OcrStatus.processing: 'processing',
  OcrStatus.complete: 'complete',
  OcrStatus.failed: 'failed',
};
