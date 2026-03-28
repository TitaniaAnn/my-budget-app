// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      accountId: json['account_id'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String,
      description: json['description'] as String,
      merchant: json['merchant'] as String?,
      categoryId: json['category_id'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      postedDate: json['posted_date'] == null
          ? null
          : DateTime.parse(json['posted_date'] as String),
      pending: json['pending'] as bool,
      source: json['source'] as String,
      enteredBy: json['entered_by'] as String?,
      receiptId: json['receipt_id'] as String?,
      rateId: json['rate_id'] as String?,
      notes: json['notes'] as String?,
      externalId: json['external_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['category'] == null
          ? null
          : Category.fromJson(json['category'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'household_id': instance.householdId,
      'account_id': instance.accountId,
      'amount': instance.amount,
      'currency': instance.currency,
      'description': instance.description,
      'merchant': instance.merchant,
      'category_id': instance.categoryId,
      'transaction_date': instance.transactionDate.toIso8601String(),
      'posted_date': instance.postedDate?.toIso8601String(),
      'pending': instance.pending,
      'source': instance.source,
      'entered_by': instance.enteredBy,
      'receipt_id': instance.receiptId,
      'rate_id': instance.rateId,
      'notes': instance.notes,
      'external_id': instance.externalId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'category': instance.category?.toJson(),
    };
