// Result shapes for the four PlaidRepository methods. Each
// mirrors one Edge Function's JSON response shape but keeps
// the Dart-side surface narrow — only the fields the UI / sync
// orchestrator actually reads.
//
// Kept in its own file (not co-located with PlaidItem) because
// these are ephemeral request/response objects, not table-
// mirroring entities.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'plaid_link_result.freezed.dart';
part 'plaid_link_result.g.dart';

/// Response shape from `plaid-public-token-exchange`. The
/// caller (Phase 3 launcher) reads `plaidItemId` to immediately
/// trigger an initial sync, and `skippedAccounts` to surface a
/// "couldn't map these" prompt.
@freezed
class PlaidExchangeResult with _$PlaidExchangeResult {
  const factory PlaidExchangeResult({
    required String plaidItemId,
    required PlaidInstitutionRef institution,
    @Default([]) List<PlaidInsertedAccount> insertedAccounts,
    @Default([]) List<PlaidSkippedAccount> skippedAccounts,
  }) = _PlaidExchangeResult;

  factory PlaidExchangeResult.fromJson(Map<String, dynamic> json) =>
      _$PlaidExchangeResultFromJson(json);
}

@freezed
class PlaidInstitutionRef with _$PlaidInstitutionRef {
  const factory PlaidInstitutionRef({
    required String id,
    required String name,
  }) = _PlaidInstitutionRef;

  factory PlaidInstitutionRef.fromJson(Map<String, dynamic> json) =>
      _$PlaidInstitutionRefFromJson(json);
}

@freezed
class PlaidInsertedAccount with _$PlaidInsertedAccount {
  const factory PlaidInsertedAccount({
    required String accountId,
    required String plaidAccountId,
    required String accountType,
    required String name,
  }) = _PlaidInsertedAccount;

  factory PlaidInsertedAccount.fromJson(Map<String, dynamic> json) =>
      _$PlaidInsertedAccountFromJson(json);
}

@freezed
class PlaidSkippedAccount with _$PlaidSkippedAccount {
  const factory PlaidSkippedAccount({
    required String plaidAccountId,
    required String name,
    required String plaidType,
    required String plaidSubtype,
    required String reason,
  }) = _PlaidSkippedAccount;

  factory PlaidSkippedAccount.fromJson(Map<String, dynamic> json) =>
      _$PlaidSkippedAccountFromJson(json);
}

/// Response shape from `plaid-transactions-sync`. The
/// orchestrator uses `requiresReauth` to surface the re-auth
/// prompt and the counts for the post-sync toast.
@freezed
class PlaidSyncResult with _$PlaidSyncResult {
  const factory PlaidSyncResult({
    @Default(0) int added,
    @Default(0) int modified,
    @Default(0) int removed,
    @Default(0) int merged,
    @Default([]) List<String> accountsSynced,
    @Default(false) bool requiresReauth,
    String? errorCode,
  }) = _PlaidSyncResult;

  factory PlaidSyncResult.fromJson(Map<String, dynamic> json) =>
      _$PlaidSyncResultFromJson(json);
}
