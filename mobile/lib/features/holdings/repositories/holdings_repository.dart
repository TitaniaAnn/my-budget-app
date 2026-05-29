// Data access layer for holdings (per-security positions inside
// investment accounts). Mirrors the migration 027 schema: holdings
// are scoped to a household and to a specific account; RLS handles
// the visibility filter, so callers pass the householdId only when
// they need the wider rollup for the dashboard's allocation donut.
//
// Audit L1 Phase 2d: cache-through on the read paths
// (fetchForAccount, fetchForHousehold). Writes update the cache
// after the server returns the row.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/holding.dart';

part 'holdings_repository.g.dart';

@riverpod
HoldingsRepository holdingsRepository(HoldingsRepositoryRef ref) {
  return HoldingsRepository(db: ref.watch(appDatabaseProvider));
}

class HoldingsRepository {
  HoldingsRepository({AppDatabase? db}) : _db = db;
  final AppDatabase? _db;

  /// Every holding inside [accountId], symbol-sorted (case-
  /// insensitive A→Z). Powers the per-account holdings list.
  ///
  /// postgrest's .order() defaults to DESCENDING — see the audit in
  /// commit d194f07 — so the `ascending: true` here is load-bearing.
  ///
  /// Cache fallback: returns rows from the local mirror filtered to
  /// the same account. The mirror is refreshed by every
  /// fetchForHousehold or fetchForAccount call.
  Future<List<Holding>> fetchForAccount(String accountId) async {
    try {
      final data = await supabase
          .from('holdings')
          .select()
          .eq('account_id', accountId)
          .order('symbol', ascending: true);
      final holdings = data.map<Holding>(Holding.fromJson).toList();
      await _writeHoldingsCache(holdings);
      return holdings;
    } catch (_) {
      final cached = await _loadFromCacheForAccount(accountId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Every holding in [householdId]. Used by the dashboard to roll
  /// up by asset_class without per-account round-trips. RLS on the
  /// table already scopes to the caller's household; the explicit
  /// filter is belt-and-braces and keeps the caching key stable
  /// when the household changes.
  Future<List<Holding>> fetchForHousehold(String householdId) async {
    try {
      final data = await supabase
          .from('holdings')
          .select()
          .eq('household_id', householdId)
          .order('symbol', ascending: true);
      final holdings = data.map<Holding>(Holding.fromJson).toList();
      await _refreshHoldingsCacheForHousehold(householdId, holdings);
      return holdings;
    } catch (_) {
      final cached = await _loadFromCacheForHousehold(householdId);
      if (cached != null) return cached;
      rethrow;
    }
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
    final holding = Holding.fromJson(data);
    await _writeHoldingsCache([holding]);
    return holding;
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
    final holding = Holding.fromJson(data);
    await _writeHoldingsCache([holding]);
    return holding;
  }

  /// Removes a holding. The trade itself (a sale) lives in the
  /// transactions table; this just clears the position record.
  Future<void> deleteHolding(String holdingId) async {
    await supabase.from('holdings').delete().eq('id', holdingId);
    await _deleteHoldingCacheRow(holdingId);
  }

  // ── Cache helpers ──────────────────────────────────────────

  Future<void> _refreshHoldingsCacheForHousehold(
    String householdId,
    List<Holding> holdings,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.replaceHoldingsForHousehold(
        householdId,
        holdings.map(_toCompanion).toList(),
      );
    } catch (_) {/**/}
  }

  Future<void> _writeHoldingsCache(List<Holding> holdings) async {
    final db = _db;
    if (db == null || holdings.isEmpty) return;
    try {
      for (final h in holdings) {
        await db.upsertHolding(_toCompanion(h));
      }
    } catch (_) {/**/}
  }

  Future<void> _deleteHoldingCacheRow(String id) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.deleteHolding(id);
    } catch (_) {/**/}
  }

  Future<List<Holding>?> _loadFromCacheForHousehold(String householdId) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.loadHoldingsForHousehold(householdId);
      if (rows.isEmpty) return null;
      return rows.map(_fromCacheRow).toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<Holding>?> _loadFromCacheForAccount(String accountId) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.loadHoldingsForAccount(accountId);
      if (rows.isEmpty) return null;
      return rows.map(_fromCacheRow).toList();
    } catch (_) {
      return null;
    }
  }
}

HoldingsCacheCompanion _toCompanion(Holding h) {
  return HoldingsCacheCompanion(
    id: Value(h.id),
    householdId: Value(h.householdId),
    accountId: Value(h.accountId),
    symbol: Value(h.symbol),
    description: Value(h.description),
    quantity: Value(h.quantity),
    costBasis: Value(h.costBasis),
    currentValue: Value(h.currentValue),
    assetClass: Value(h.assetClass?.dbValue),
    lastPricedAt: Value(h.lastPricedAt?.toUtc()),
    createdAt: Value(h.createdAt.toUtc()),
    updatedAt: Value(h.updatedAt.toUtc()),
    cachedAt: Value(DateTime.now().toUtc()),
  );
}

Holding _fromCacheRow(HoldingsCacheRow r) {
  return Holding(
    id: r.id,
    householdId: r.householdId,
    accountId: r.accountId,
    symbol: r.symbol,
    description: r.description,
    quantity: r.quantity,
    costBasis: r.costBasis,
    currentValue: r.currentValue,
    assetClass: r.assetClass == null
        ? null
        : AssetClass.values.firstWhere(
            (a) => a.dbValue == r.assetClass,
            orElse: () => AssetClass.other,
          ),
    lastPricedAt: r.lastPricedAt,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}
