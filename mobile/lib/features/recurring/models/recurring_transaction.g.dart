// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecurringTransactionImpl _$$RecurringTransactionImplFromJson(
  Map<String, dynamic> json,
) => _$RecurringTransactionImpl(
  id: json['id'] as String,
  householdId: json['household_id'] as String,
  accountId: json['account_id'] as String,
  amountCents: (json['amount_cents'] as num).toInt(),
  currency: json['currency'] as String,
  description: json['description'] as String,
  merchant: json['merchant'] as String?,
  categoryId: json['category_id'] as String?,
  cadence: $enumDecode(_$RecurrenceCadenceEnumMap, json['cadence']),
  nextOccurrenceDate: DateTime.parse(json['next_occurrence_date'] as String),
  lastEmittedAt: json['last_emitted_at'] == null
      ? null
      : DateTime.parse(json['last_emitted_at'] as String),
  skippedUntilDate: json['skipped_until_date'] == null
      ? null
      : DateTime.parse(json['skipped_until_date'] as String),
  isActive: json['is_active'] as bool,
  createdBy: json['created_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$RecurringTransactionImplToJson(
  _$RecurringTransactionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'household_id': instance.householdId,
  'account_id': instance.accountId,
  'amount_cents': instance.amountCents,
  'currency': instance.currency,
  'description': instance.description,
  'merchant': instance.merchant,
  'category_id': instance.categoryId,
  'cadence': _$RecurrenceCadenceEnumMap[instance.cadence]!,
  'next_occurrence_date': instance.nextOccurrenceDate.toIso8601String(),
  'last_emitted_at': instance.lastEmittedAt?.toIso8601String(),
  'skipped_until_date': instance.skippedUntilDate?.toIso8601String(),
  'is_active': instance.isActive,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$RecurrenceCadenceEnumMap = {
  RecurrenceCadence.weekly: 'weekly',
  RecurrenceCadence.biweekly: 'biweekly',
  RecurrenceCadence.monthly: 'monthly',
  RecurrenceCadence.quarterly: 'quarterly',
  RecurrenceCadence.annual: 'annual',
};
