// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plaid_link_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaidExchangeResultImpl _$$PlaidExchangeResultImplFromJson(
  Map<String, dynamic> json,
) => _$PlaidExchangeResultImpl(
  plaidItemId: json['plaid_item_id'] as String,
  institution: PlaidInstitutionRef.fromJson(
    json['institution'] as Map<String, dynamic>,
  ),
  insertedAccounts:
      (json['inserted_accounts'] as List<dynamic>?)
          ?.map((e) => PlaidInsertedAccount.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  skippedAccounts:
      (json['skipped_accounts'] as List<dynamic>?)
          ?.map((e) => PlaidSkippedAccount.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$PlaidExchangeResultImplToJson(
  _$PlaidExchangeResultImpl instance,
) => <String, dynamic>{
  'plaid_item_id': instance.plaidItemId,
  'institution': instance.institution.toJson(),
  'inserted_accounts': instance.insertedAccounts
      .map((e) => e.toJson())
      .toList(),
  'skipped_accounts': instance.skippedAccounts.map((e) => e.toJson()).toList(),
};

_$PlaidInstitutionRefImpl _$$PlaidInstitutionRefImplFromJson(
  Map<String, dynamic> json,
) => _$PlaidInstitutionRefImpl(
  id: json['id'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$$PlaidInstitutionRefImplToJson(
  _$PlaidInstitutionRefImpl instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

_$PlaidInsertedAccountImpl _$$PlaidInsertedAccountImplFromJson(
  Map<String, dynamic> json,
) => _$PlaidInsertedAccountImpl(
  accountId: json['account_id'] as String,
  plaidAccountId: json['plaid_account_id'] as String,
  accountType: json['account_type'] as String,
  name: json['name'] as String,
);

Map<String, dynamic> _$$PlaidInsertedAccountImplToJson(
  _$PlaidInsertedAccountImpl instance,
) => <String, dynamic>{
  'account_id': instance.accountId,
  'plaid_account_id': instance.plaidAccountId,
  'account_type': instance.accountType,
  'name': instance.name,
};

_$PlaidSkippedAccountImpl _$$PlaidSkippedAccountImplFromJson(
  Map<String, dynamic> json,
) => _$PlaidSkippedAccountImpl(
  plaidAccountId: json['plaid_account_id'] as String,
  name: json['name'] as String,
  plaidType: json['plaid_type'] as String,
  plaidSubtype: json['plaid_subtype'] as String,
  reason: json['reason'] as String,
);

Map<String, dynamic> _$$PlaidSkippedAccountImplToJson(
  _$PlaidSkippedAccountImpl instance,
) => <String, dynamic>{
  'plaid_account_id': instance.plaidAccountId,
  'name': instance.name,
  'plaid_type': instance.plaidType,
  'plaid_subtype': instance.plaidSubtype,
  'reason': instance.reason,
};

_$PlaidSyncResultImpl _$$PlaidSyncResultImplFromJson(
  Map<String, dynamic> json,
) => _$PlaidSyncResultImpl(
  added: (json['added'] as num?)?.toInt() ?? 0,
  modified: (json['modified'] as num?)?.toInt() ?? 0,
  removed: (json['removed'] as num?)?.toInt() ?? 0,
  merged: (json['merged'] as num?)?.toInt() ?? 0,
  accountsSynced:
      (json['accounts_synced'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  requiresReauth: json['requires_reauth'] as bool? ?? false,
  errorCode: json['error_code'] as String?,
);

Map<String, dynamic> _$$PlaidSyncResultImplToJson(
  _$PlaidSyncResultImpl instance,
) => <String, dynamic>{
  'added': instance.added,
  'modified': instance.modified,
  'removed': instance.removed,
  'merged': instance.merged,
  'accounts_synced': instance.accountsSynced,
  'requires_reauth': instance.requiresReauth,
  'error_code': instance.errorCode,
};
