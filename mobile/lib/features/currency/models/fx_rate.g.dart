// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fx_rate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FxRateImpl _$$FxRateImplFromJson(Map<String, dynamic> json) => _$FxRateImpl(
  householdId: json['household_id'] as String,
  fromCurrency: json['from_currency'] as String,
  toCurrency: json['to_currency'] as String,
  asOfDate: DateTime.parse(json['as_of_date'] as String),
  rate: _rateFromJson(json['rate']),
  createdBy: json['created_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$FxRateImplToJson(_$FxRateImpl instance) =>
    <String, dynamic>{
      'household_id': instance.householdId,
      'from_currency': instance.fromCurrency,
      'to_currency': instance.toCurrency,
      'as_of_date': instance.asOfDate.toIso8601String(),
      'rate': instance.rate,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
