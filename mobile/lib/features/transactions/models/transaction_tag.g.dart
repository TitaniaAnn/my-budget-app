// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionTagImpl _$$TransactionTagImplFromJson(Map<String, dynamic> json) =>
    _$TransactionTagImpl(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$TransactionTagImplToJson(
  _$TransactionTagImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'household_id': instance.householdId,
  'name': instance.name,
  'color': instance.color,
  'created_at': instance.createdAt.toIso8601String(),
};
