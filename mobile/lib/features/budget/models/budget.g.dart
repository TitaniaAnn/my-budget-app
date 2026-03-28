// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BudgetImpl _$$BudgetImplFromJson(Map<String, dynamic> json) => _$BudgetImpl(
  id: json['id'] as String,
  householdId: json['household_id'] as String,
  categoryId: json['category_id'] as String,
  amount: (json['amount'] as num).toInt(),
  period: $enumDecode(_$BudgetPeriodEnumMap, json['period']),
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: json['end_date'] == null
      ? null
      : DateTime.parse(json['end_date'] as String),
  createdBy: json['created_by'] as String,
);

Map<String, dynamic> _$$BudgetImplToJson(_$BudgetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'household_id': instance.householdId,
      'category_id': instance.categoryId,
      'amount': instance.amount,
      'period': _$BudgetPeriodEnumMap[instance.period]!,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate?.toIso8601String(),
      'created_by': instance.createdBy,
    };

const _$BudgetPeriodEnumMap = {
  BudgetPeriod.weekly: 'weekly',
  BudgetPeriod.biweekly: 'biweekly',
  BudgetPeriod.monthly: 'monthly',
  BudgetPeriod.semiannual: 'semiannual',
  BudgetPeriod.annual: 'annual',
};
