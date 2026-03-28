// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenario_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScenarioEventImpl _$$ScenarioEventImplFromJson(Map<String, dynamic> json) =>
    _$ScenarioEventImpl(
      id: json['id'] as String,
      scenarioId: json['scenario_id'] as String,
      eventType: $enumDecode(_$EventTypeEnumMap, json['event_type']),
      label: json['label'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      amount: (json['amount'] as num).toInt(),
      accountId: json['account_id'] as String?,
      isRecurring: json['is_recurring'] as bool,
      recurrenceRule: json['recurrence_rule'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
      sortOrder: (json['sort_order'] as num).toInt(),
    );

Map<String, dynamic> _$$ScenarioEventImplToJson(_$ScenarioEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scenario_id': instance.scenarioId,
      'event_type': _$EventTypeEnumMap[instance.eventType]!,
      'label': instance.label,
      'event_date': instance.eventDate.toIso8601String(),
      'amount': instance.amount,
      'account_id': instance.accountId,
      'is_recurring': instance.isRecurring,
      'recurrence_rule': instance.recurrenceRule,
      'parameters': instance.parameters,
      'sort_order': instance.sortOrder,
    };

const _$EventTypeEnumMap = {
  EventType.income: 'income',
  EventType.expense: 'expense',
  EventType.transfer: 'transfer',
  EventType.purchase: 'purchase',
  EventType.debt: 'debt',
  EventType.savings: 'savings',
};
