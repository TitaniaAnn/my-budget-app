// Calls the three Plaid Edge Functions. The repository never
// touches Plaid directly — every Plaid API call is server-side
// in Phase 2. Mobile only ever sees:
//   * link_token (short-lived, one Link session)
//   * publicToken (returned by Link onSuccess, immediately
//     handed back to the exchange function)
//   * sync result counts + reauth flag
// The long-lived access_token never enters the mobile binary
// (database column-grant + Edge Function service-role boundary
// enforce that; see migration 054).

import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../models/plaid_item.dart';
import '../models/plaid_link_result.dart';

part 'plaid_repository.g.dart';

@riverpod
PlaidRepository plaidRepository(PlaidRepositoryRef ref) {
  return PlaidRepository();
}

class PlaidRepository {
  /// Mints a short-lived Link token via
  /// `plaid-link-token-create`. The caller passes the returned
  /// token into [LinkTokenConfiguration] and opens [PlaidLink].
  /// Each Link session needs a fresh token; do NOT cache.
  Future<String> createLinkToken() async {
    final response = await supabase.functions.invoke(
      'plaid-link-token-create',
      body: const <String, dynamic>{},
    );
    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['link_token'] is! String) {
      throw const PlaidEdgeFunctionException(
        'plaid-link-token-create returned no link_token',
      );
    }
    return data['link_token'] as String;
  }

  /// Mints a Link token for re-auth (update mode) against an
  /// existing Item. Phase 4: passes `plaidItemId` to
  /// plaid-link-token-create which loads the item's
  /// access_token server-side and asks Plaid for an update-mode
  /// token. The mobile app gets back the same link_token shape
  /// as the fresh-link path and feeds it into PlaidLink.
  ///
  /// On `onSuccess`, no public_token exchange is needed (update
  /// mode reuses the existing access_token); just re-sync.
  Future<String> createUpdateLinkToken(String plaidItemRowId) async {
    final response = await supabase.functions.invoke(
      'plaid-link-token-create',
      body: {'plaidItemId': plaidItemRowId},
    );
    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['link_token'] is! String) {
      throw const PlaidEdgeFunctionException(
        'plaid-link-token-create (update mode) returned no link_token',
      );
    }
    return data['link_token'] as String;
  }

  /// Exchanges the [publicToken] returned by Plaid Link
  /// onSuccess for a long-lived access_token (server-side),
  /// inserts the `plaid_items` row and one `accounts` row per
  /// account in [accounts], and returns the IDs of what landed.
  /// Idempotent: re-calling with the same Item / accounts
  /// upserts in place.
  Future<PlaidExchangeResult> exchangePublicToken({
    required String publicToken,
    required LinkInstitution institution,
    required List<LinkAccount> accounts,
  }) async {
    final response = await supabase.functions.invoke(
      'plaid-public-token-exchange',
      body: {
        'publicToken': publicToken,
        'institution': {'id': institution.id, 'name': institution.name},
        'accounts': [
          for (final a in accounts)
            {
              'id': a.id,
              'name': a.name,
              'mask': a.mask,
              'type': a.type,
              'subtype': a.subtype,
              // The Plaid SDK's LinkAccount metadata doesn't
              // surface iso_currency_code on the client side; the
              // Edge Function defaults to USD when null. A future
              // refinement could thread it through balances if
              // Plaid exposes it.
              'currency': null,
            },
        ],
      },
    );
    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const PlaidEdgeFunctionException(
        'plaid-public-token-exchange returned no body',
      );
    }
    // Pass the snake_case shape straight through — the project's
    // build.yaml has `json_serializable.field_rename: snake`, so
    // the generated fromJson reads `json['plaid_item_id']` /
    // `json['inserted_accounts']` etc. directly. A prior
    // camelize-helper that pre-processed the keys was wrong
    // (caught in code review) and broke every fromJson it touched.
    return PlaidExchangeResult.fromJson(data);
  }

  /// Triggers `/transactions/sync` for one linked Item. The
  /// Edge Function loops the cursor pages, transforms per-
  /// account, and calls `upsert_plaid_transactions` once per
  /// account. Returns the per-call counts + the re-auth flag.
  Future<PlaidSyncResult> sync(String plaidItemRowId) async {
    final response = await supabase.functions.invoke(
      'plaid-transactions-sync',
      body: {'plaid_item_id': plaidItemRowId},
    );
    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw const PlaidEdgeFunctionException(
        'plaid-transactions-sync returned no body',
      );
    }
    return PlaidSyncResult.fromJson(data);
  }

  /// Lists active Plaid Items in the caller's household. Read
  /// straight from the table — RLS gates to household_members.
  /// The `access_token` column is invisible to the client
  /// (migration 054 column-grant) so even a SELECT * is safe.
  Future<List<PlaidItem>> fetchActiveItems() async {
    final rows = await supabase
        .from('plaid_items')
        .select()
        .eq('is_active', true)
        .order('institution_name', ascending: true);
    return [
      for (final row in rows as List)
        PlaidItem.fromJson(row as Map<String, dynamic>),
    ];
  }
}

class PlaidEdgeFunctionException implements Exception {
  const PlaidEdgeFunctionException(this.message);
  final String message;
  @override
  String toString() => 'PlaidEdgeFunctionException: $message';
}
