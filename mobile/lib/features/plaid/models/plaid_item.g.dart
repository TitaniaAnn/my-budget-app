// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plaid_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaidItemImpl _$$PlaidItemImplFromJson(Map<String, dynamic> json) =>
    _$PlaidItemImpl(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      createdBy: json['created_by'] as String,
      plaidItemId: json['plaid_item_id'] as String,
      plaidInstitutionId: json['plaid_institution_id'] as String?,
      institutionName: json['institution_name'] as String?,
      environment: $enumDecode(_$PlaidEnvironmentEnumMap, json['environment']),
      syncCursor: json['sync_cursor'] as String?,
      lastSyncAt: json['last_sync_at'] == null
          ? null
          : DateTime.parse(json['last_sync_at'] as String),
      lastSyncError: json['last_sync_error'] as String?,
      consentExpiresAt: json['consent_expires_at'] == null
          ? null
          : DateTime.parse(json['consent_expires_at'] as String),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$PlaidItemImplToJson(_$PlaidItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'household_id': instance.householdId,
      'created_by': instance.createdBy,
      'plaid_item_id': instance.plaidItemId,
      'plaid_institution_id': instance.plaidInstitutionId,
      'institution_name': instance.institutionName,
      'environment': _$PlaidEnvironmentEnumMap[instance.environment]!,
      'sync_cursor': instance.syncCursor,
      'last_sync_at': instance.lastSyncAt?.toIso8601String(),
      'last_sync_error': instance.lastSyncError,
      'consent_expires_at': instance.consentExpiresAt?.toIso8601String(),
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$PlaidEnvironmentEnumMap = {
  PlaidEnvironment.sandbox: 'sandbox',
  PlaidEnvironment.development: 'development',
  PlaidEnvironment.production: 'production',
};
