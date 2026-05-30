// Data access layer for holdings (per-security positions inside
// investment accounts). Mirrors the migration 027 schema: holdings
// are scoped to a household and to a specific account; RLS handles
// the visibility filter, so callers pass the householdId only when
// they need the wider rollup for the dashboard's allocation donut.
//
// Audit L1 Phase 2d: cache-through on the read paths
// (fetchForAccount, fetchForHousehold). Audit L1 Phase 3c:
// writes go through the queue on transient failure via the
// shared atomicCacheAndEnqueue helper.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/sync/atomic_write.dart';
import '../../../core/sync/pending_writes_queue.dart';
import '../../../core/sync/transient_error.dart';
import '../models/holding.dart';

part 'holdings_repository.g.dart';

@riverpod
HoldingsRepository holdingsRepository(HoldingsRepositoryRef ref) {
  return HoldingsRepository(
    db: ref.watch(appDatabaseProvider),
    queue: ref.watch(pendingWritesQueueProvider),
  );
}

class HoldingsRepository {
  HoldingsRepository({AppDatabase? db, PendingWritesQueue? queue})
    : _db = db,
      _queue = queue;
  final AppDatabase? _db;
  final PendingWritesQueue? _queue;
  final _uuid = const Uuid();

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
    final clientId = _uuid.v4();
    final trimmedSymbol = symbol.trim();
    final payload = <String, dynamic>{
      'id': clientId,
      'household_id': householdId,
      'account_id': accountId,
      'symbol': trimmedSymbol,
      'description': description,
      'quantity': quantity,
      'cost_basis': costBasis,
      'current_value': currentValue,
      'asset_class': assetClass?.dbValue,
      'last_priced_at': lastPricedAt?.toUtc().toIso8601String(),
    };
    try {
      final data = await supabase
          .from('holdings')
          .insert(payload)
          .select()
          .single();
      final holding = Holding.fromJson(data);
      await _writeHoldingsCache([holding]);
      return holding;
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      final now = DateTime.now().toUtc();
      final optimistic = Holding(
        id: clientId,
        householdId: householdId,
        accountId: accountId,
        symbol: trimmedSymbol,
        description: description,
        quantity: quantity,
        costBasis: costBasis,
        currentValue: currentValue,
        assetClass: assetClass,
        lastPricedAt: lastPricedAt,
        createdAt: now,
        updatedAt: now,
      );
      await atomicCacheAndEnqueue(
        db: _db,
        queue: _queue,
        write: () => _writeHoldingsCache([optimistic]),
        queueOp: QueuedInsert(
          table: 'holdings',
          payload: payload,
          rowId: clientId,
        ),
      );
      return optimistic;
    }
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

    try {
      final data = await supabase
          .from('holdings')
          .update(patch)
          .eq('id', holdingId)
          .select()
          .single();
      final holding = Holding.fromJson(data);
      await _writeHoldingsCache([holding]);
      return holding;
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      // Optimistic patch on the cached row. If the row isn't
      // cached we can't synthesise a meaningful Holding; rethrow.
      final existing = await _loadHoldingCacheRowById(holdingId);
      if (existing == null) rethrow;
      final patched = existing.copyWith(
        symbol: symbol?.trim() ?? existing.symbol,
        description: description ?? existing.description,
        quantity: quantity ?? existing.quantity,
        costBasis: costBasis ?? existing.costBasis,
        currentValue: currentValue ?? existing.currentValue,
        assetClass: assetClass ?? existing.assetClass,
        lastPricedAt: currentValue != null
            ? DateTime.now().toUtc()
            : existing.lastPricedAt,
        updatedAt: DateTime.now().toUtc(),
      );
      await atomicCacheAndEnqueue(
        db: _db,
        queue: _queue,
        write: () => _writeHoldingsCache([patched]),
        queueOp: QueuedUpdate(
          table: 'holdings',
          rowId: holdingId,
          payload: patch,
        ),
      );
      return patched;
    }
  }

  /// Removes a holding. The trade itself (a sale) lives in the
  /// transactions table; this just clears the position record.
  Future<void> deleteHolding(String holdingId) async {
    try {
      await supabase.from('holdings').delete().eq('id', holdingId);
      await _deleteHoldingCacheRow(holdingId);
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      await atomicCacheAndEnqueue(
        db: _db,
        queue: _queue,
        write: () => _deleteHoldingCacheRow(holdingId),
        queueOp: QueuedDelete(table: 'holdings', rowId: holdingId),
      );
    }
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

  /// Phase 3c: read-by-id for the optimistic-update path. Scans
  /// the per-install cache (small — typically <50 holdings).
  Future<Holding?> _loadHoldingCacheRowById(String id) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.select(db.holdingsCache).get();
      for (final r in rows) {
        if (r.id == id) return _fromCacheRow(r);
      }
      return null;
    } catch (_) {
      return null;
    }
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
