// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScenarioImpl _$$ScenarioImplFromJson(Map<String, dynamic> json) =>
    _$ScenarioImpl(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      createdBy: json['created_by'] as String,
      parentId: json['parent_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      baseDate: DateTime.parse(json['base_date'] as String),
      isBaseline: json['is_baseline'] as bool,
      color: json['color'] as String?,
      isGoal: json['is_goal'] as bool,
      targetAmount: (json['target_amount'] as num?)?.toInt(),
      targetDate: json['target_date'] == null
          ? null
          : DateTime.parse(json['target_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ScenarioImplToJson(_$ScenarioImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'household_id': instance.householdId,
      'created_by': instance.createdBy,
      'parent_id': instance.parentId,
      'name': instance.name,
      'description': instance.description,
      'base_date': instance.baseDate.toIso8601String(),
      'is_baseline': instance.isBaseline,
      'color': instance.color,
      'is_goal': instance.isGoal,
      'target_amount': instance.targetAmount,
      'target_date': instance.targetDate?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
