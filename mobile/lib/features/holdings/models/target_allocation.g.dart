// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_allocation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TargetAllocationImpl _$$TargetAllocationImplFromJson(
  Map<String, dynamic> json,
) => _$TargetAllocationImpl(
  householdId: json['household_id'] as String,
  assetClass: $enumDecode(_$AssetClassEnumMap, json['asset_class']),
  targetPctBp: (json['target_pct_bp'] as num).toInt(),
  createdBy: json['created_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$TargetAllocationImplToJson(
  _$TargetAllocationImpl instance,
) => <String, dynamic>{
  'household_id': instance.householdId,
  'asset_class': _$AssetClassEnumMap[instance.assetClass]!,
  'target_pct_bp': instance.targetPctBp,
  'created_by': instance.createdBy,
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
