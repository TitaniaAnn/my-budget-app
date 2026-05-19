// Data access layer for holdings (per-security positions inside
// investment accounts). Mirrors the migration 027 schema: holdings
// are scoped to a household and to a specific account; RLS handles
// the visibility filter, so callers pass the householdId only when
// they need the wider rollup for the dashboard's allocation donut.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/holding.dart';

part 'holdings_repository.g.dart';

@riverpod
HoldingsRepository holdingsRepository(HoldingsRepositoryRef ref) {
  return HoldingsRepository();
}

class HoldingsRepository {
  /// Every holding inside [accountId], symbol-sorted (case-
  /// insensitive A→Z). Powers the per-account holdings list.
  ///
  /// postgrest's .order() defaults to DESCENDING — see the audit in
  /// commit d194f07 — so the `ascending: true` here is load-bearing.
  Future<List<Holding>> fetchForAccount(String accountId) async {
    final data = await supabase
        .from('holdings')
        .select()
        .eq('account_id', accountId)
        .order('symbol', ascending: true);
    return data.map<Holding>(Holding.fromJson).toList();
  }

  /// Every holding in [householdId]. Used by the dashboard to roll
  /// up by asset_class without per-account round-trips. RLS on the
  /// table already scopes to the caller's household; the explicit
  /// filter is belt-and-braces and keeps the caching key stable
  /// when the household changes.
  Future<List<Holding>> fetchForHousehold(String householdId) async {
    final data = await supabase
        .from('holdings')
        .select()
        .eq('household_id', householdId)
        .order('symbol', ascending: true);
    return data.map<Holding>(Holding.fromJson).toList();
  }

  /// Inserts a new holding and returns it.
  ///
  /// [lastPricedAt] defaults to `now()` server-side via column
  /// default... actually no, the schema has no default. The caller
  /// passes the wall-clock when the user enters a value so a future
  /// "stale price" indicator has something to compare against;
  /// passing null is fine for an initial position whose price will
  /// be filled in later.
  Future<Holding> createHolding({
    required String householdId,
    required String accountId,
    required String symbol,
    String? description,
    required double quantity,
    int? costBasis,
    required int currentValue,
    AssetClass? assetClass,
    DateTime? lastPricedAt,
  }) async {
    final data = await supabase
        .from('holdings')
        .insert({
          'household_id': householdId,
          'account_id': accountId,
          'symbol': symbol.trim(),
          'description': description,
          'quantity': quantity,
          'cost_basis': costBasis,
          'current_value': currentValue,
          'asset_class': assetClass?.dbValue,
          'last_priced_at': lastPricedAt?.toUtc().toIso8601String(),
        })
        .select()
        .single();
    return Holding.fromJson(data);
  }

  /// Updates an existing holding. All fields are mutable — symbol
  /// changes are allowed (a ticker rename happens occasionally).
  ///
  /// `last_priced_at` is refreshed whenever [currentValue] is
  /// passed: re-marking the value is precisely the event the
  /// stale-price indicator wants to observe. If the caller wants
  /// to change other fields without touching the timestamp they
  /// can pass null for currentValue (no-op).
  Future<Holding> updateHolding({
    required String holdingId,
    String? symbol,
    String? description,
    double? quantity,
    int? costBasis,
    int? currentValue,
    AssetClass? assetClass,
  }) async {
    final patch = <String, dynamic>{};
    if (symbol != null) patch['symbol'] = symbol.trim();
    if (description != null) patch['description'] = description;
    if (quantity != null) patch['quantity'] = quantity;
    if (costBasis != null) patch['cost_basis'] = costBasis;
    if (currentValue != null) {
      patch['current_value'] = currentValue;
      patch['last_priced_at'] = DateTime.now().toUtc().toIso8601String();
    }
    if (assetClass != null) patch['asset_class'] = assetClass.dbValue;

    final data = await supabase
        .from('holdings')
        .update(patch)
        .eq('id', holdingId)
        .select()
        .single();
    return Holding.fromJson(data);
  }

  /// Removes a holding. The trade itself (a sale) lives in the
  /// transactions table; this just clears the position record.
  Future<void> deleteHolding(String holdingId) async {
    await supabase.from('holdings').delete().eq('id', holdingId);
  }
}
