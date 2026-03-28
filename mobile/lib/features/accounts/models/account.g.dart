// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountImpl _$$AccountImplFromJson(Map<String, dynamic> json) =>
    _$AccountImpl(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      name: json['name'] as String,
      accountType: $enumDecode(_$AccountTypeEnumMap, json['account_type']),
      institution: json['institution'] as String?,
      lastFour: json['last_four'] as String?,
      currency: json['currency'] as String,
      currentBalance: (json['current_balance'] as num).toInt(),
      creditLimit: (json['credit_limit'] as num?)?.toInt(),
      isActive: json['is_active'] as bool,
      color: json['color'] as String?,
      interestRate: (json['interest_rate'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$AccountImplToJson(_$AccountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'household_id': instance.householdId,
      'owner_user_id': instance.ownerUserId,
      'name': instance.name,
      'account_type': _$AccountTypeEnumMap[instance.accountType]!,
      'institution': instance.institution,
      'last_four': instance.lastFour,
      'currency': instance.currency,
      'current_balance': instance.currentBalance,
      'credit_limit': instance.creditLimit,
      'is_active': instance.isActive,
      'color': instance.color,
      'interest_rate': instance.interestRate,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$AccountTypeEnumMap = {
  AccountType.checking: 'checking',
  AccountType.savings: 'savings',
  AccountType.creditCard: 'credit_card',
  AccountType.brokerage: 'brokerage',
  AccountType.iraTraditional: 'ira_traditional',
  AccountType.iraRoth: 'ira_roth',
  AccountType.retirement401k: 'retirement_401k',
  AccountType.retirement403b: 'retirement_403b',
  AccountType.hsa: 'hsa',
  AccountType.college529: 'college_529',
  AccountType.cash: 'cash',
};
