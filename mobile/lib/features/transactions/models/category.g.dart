// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Category _$CategoryFromJson(Map<String, dynamic> json) => _Category(
  id: json['id'] as String,
  householdId: json['household_id'] as String?,
  name: json['name'] as String,
  parentId: json['parent_id'] as String?,
  icon: json['icon'] as String?,
  color: json['color'] as String?,
  isIncome: json['is_income'] as bool,
  sortOrder: (json['sort_order'] as num).toInt(),
);

Map<String, dynamic> _$CategoryToJson(_Category instance) => <String, dynamic>{
  'id': instance.id,
  'household_id': instance.householdId,
  'name': instance.name,
  'parent_id': instance.parentId,
  'icon': instance.icon,
  'color': instance.color,
  'is_income': instance.isIncome,
  'sort_order': instance.sortOrder,
};
