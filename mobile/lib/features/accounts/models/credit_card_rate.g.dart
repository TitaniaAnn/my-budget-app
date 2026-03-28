// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_rate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreditCardRateImpl _$$CreditCardRateImplFromJson(Map<String, dynamic> json) =>
    _$CreditCardRateImpl(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      rateType: $enumDecode(_$CreditRateTypeEnumMap, json['rate_type']),
      rate: (json['rate'] as num).toDouble(),
      isIntro: json['is_intro'] as bool,
      introEndsOn: json['intro_ends_on'] == null
          ? null
          : DateTime.parse(json['intro_ends_on'] as String),
      isActive: json['is_active'] as bool,
      label: json['label'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$CreditCardRateImplToJson(
  _$CreditCardRateImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'account_id': instance.accountId,
  'rate_type': _$CreditRateTypeEnumMap[instance.rateType]!,
  'rate': instance.rate,
  'is_intro': instance.isIntro,
  'intro_ends_on': instance.introEndsOn?.toIso8601String(),
  'is_active': instance.isActive,
  'label': instance.label,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$CreditRateTypeEnumMap = {
  CreditRateType.purchase: 'purchase',
  CreditRateType.cashAdvance: 'cash_advance',
  CreditRateType.balanceTransfer: 'balance_transfer',
  CreditRateType.penalty: 'penalty',
};
