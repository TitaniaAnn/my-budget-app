// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'holding.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HoldingImpl _$$HoldingImplFromJson(Map<String, dynamic> json) =>
    _$HoldingImpl(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      accountId: json['account_id'] as String,
      symbol: json['symbol'] as String,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      costBasis: (json['cost_basis'] as num?)?.toInt(),
      currentValue: (json['current_value'] as num).toInt(),
      assetClass: $enumDecodeNullable(_$AssetClassEnumMap, json['asset_class']),
      lastPricedAt: json['last_priced_at'] == null
          ? null
          : DateTime.parse(json['last_priced_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$HoldingImplToJson(_$HoldingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'household_id': instance.householdId,
      'account_id': instance.accountId,
      'symbol': instance.symbol,
      'description': instance.description,
      'quantity': instance.quantity,
      'cost_basis': instance.costBasis,
      'current_value': instance.currentValue,
      'asset_class': _$AssetClassEnumMap[instance.assetClass],
      'last_priced_at': instance.lastPricedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$AssetClassEnumMap = {
  AssetClass.usEquity: 'us_equity',
  AssetClass.intlEquity: 'intl_equity',
  AssetClass.bond: 'bond',
  AssetClass.realEstate: 'real_estate',
  AssetClass.cash: 'cash',
  AssetClass.crypto: 'crypto',
  AssetClass.other: 'other',
};
