// Client-side mirror of a `plaid_items` row (one linked bank Item).
//
// Deliberately omits `access_token` — the column is locked at the
// database level (migration 054 revokes SELECT on it from anon /
// authenticated), so even if the mobile app asked for SELECT *
// the column wouldn't be in the response. Mirroring that omission
// in the model keeps the client surface clean and means a stray
// reference to `accessToken` would be a compile error.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'plaid_item.freezed.dart';
part 'plaid_item.g.dart';

/// Maps to the `plaid_environment` Postgres enum (migration 054).
enum PlaidEnvironment {
  @JsonValue('sandbox')
  sandbox,
  @JsonValue('development')
  development,
  @JsonValue('production')
  production;

  String get displayLabel => switch (this) {
    PlaidEnvironment.sandbox => 'Sandbox',
    PlaidEnvironment.development => 'Development',
    PlaidEnvironment.production => 'Production',
  };
}

/// One row from `plaid_items`. Carries the per-Item sync state
/// the UI needs (institution name, last sync, re-auth error)
/// without ever touching the access_token.
@freezed
class PlaidItem with _$PlaidItem {
  const factory PlaidItem({
    required String id,
    required String householdId,
    required String createdBy,
    required String plaidItemId,
    String? plaidInstitutionId,
    String? institutionName,
    required PlaidEnvironment environment,
    String? syncCursor,
    DateTime? lastSyncAt,
    String? lastSyncError,
    DateTime? consentExpiresAt,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PlaidItem;

  factory PlaidItem.fromJson(Map<String, dynamic> json) =>
      _$PlaidItemFromJson(json);
}

/// Error codes from `plaid_items.last_sync_error` that mean the
/// user needs to re-link this Item. Mirrors the set in
/// `supabase/functions/plaid-transactions-sync/index.ts`. Use
/// [PlaidItem.requiresReauth] rather than checking the strings
/// at call sites.
const _kReauthErrorCodes = {
  'ITEM_LOGIN_REQUIRED',
  'PENDING_EXPIRATION',
  'PENDING_DISCONNECT',
};

extension PlaidItemReauth on PlaidItem {
  /// True when the most recent sync surfaced an error that the
  /// re-auth flow can fix. The dashboard ReauthPrompt watches this.
  bool get requiresReauth =>
      lastSyncError != null && _kReauthErrorCodes.contains(lastSyncError);
}
