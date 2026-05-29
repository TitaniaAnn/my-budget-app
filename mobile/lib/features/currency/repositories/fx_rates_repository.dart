// Data access for FX rates (migration 036).
//
// The hot query is "what's the most recent rate from X to Y at or
// before today" — answered with one round-trip via the
// (household, from, to, as_of_date DESC) index. Setter is a plain
// upsert on the composite PK.
//
// Audit L1 Phase 2b: cache-through. fetchAll + latestRate refresh
// the local mirror on success; offline the mirror serves whatever
// rates were last seen. Write paths (setRate / deleteRate) update
// the cache after the server-side write succeeds.

import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/fx_rate.dart';

part 'fx_rates_repository.g.dart';

@riverpod
FxRatesRepository fxRatesRepository(FxRatesRepositoryRef ref) {
  return FxRatesRepository(db: ref.watch(appDatabaseProvider));
}

class FxRatesRepository {
  FxRatesRepository({AppDatabase? db}) : _db = db;
  final AppDatabase? _db;

  /// All rates for the household, newest first. Used by the
  /// Settings → FX Rates editor. Households without any rates
  /// returns an empty list — the dashboard's conversion math
  /// treats that as "every non-display-currency account is
  /// missing a rate" and surfaces accordingly.
  Future<List<FxRate>> fetchAll(String householdId) async {
    try {
      final data = await supabase
          .from('fx_rates')
          .select()
          .eq('household_id', householdId)
          .order('as_of_date', ascending: false);
      final rates = data.map<FxRate>(FxRate.fromJson).toList();
      await _refreshFxCache(householdId, rates);
      return rates;
    } catch (_) {
      final cached = await _loadFromCache(householdId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Returns the latest rate for the (from, to) pair on or before
  /// [asOf]. Null when no rate has been recorded yet.
  ///
  /// Rate symmetry: the table stores rates one direction at a
  /// time. EUR→USD doesn't imply USD→EUR in the database; the
  /// editor saves the inverse explicitly when the user wants
  /// both directions. This is the safer default — applying 1/rate
  /// silently could surface a stale or implicit inversion the
  /// user didn't intend.
  Future<FxRate?> latestRate({
    required String householdId,
    required String fromCurrency,
    required String toCurrency,
    DateTime? asOf,
  }) async {
    final cutoff = (asOf ?? DateTime.now().toUtc())
        .toIso8601String()
        .substring(0, 10);
    try {
      final data = await supabase
          .from('fx_rates')
          .select()
          .eq('household_id', householdId)
          .eq('from_currency', fromCurrency)
          .eq('to_currency', toCurrency)
          .lte('as_of_date', cutoff)
          .order('as_of_date', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      final rate = FxRate.fromJson(data);
      // Cache this specific row so the offline lookup for the
      // same pair returns it. Doesn't replace the whole household
      // set — a hot-path call mustn't blow away rates the editor
      // hasn't refreshed.
      await _writeFxCacheRow(rate);
      return rate;
    } catch (_) {
      final cached = await _loadLatestFromCache(
        householdId: householdId,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        asOf: asOf,
      );
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Upserts a rate on the (household, from, to, as_of_date) PK.
  /// Re-saving the same date overwrites — that's the editor's
  /// "fix yesterday's wrong rate" path.
  Future<void> setRate({
    required String householdId,
    required String fromCurrency,
    required String toCurrency,
    required double rate,
    required DateTime asOfDate,
    required String createdBy,
  }) async {
    await supabase
        .from('fx_rates')
        .upsert(
          {
            'household_id': householdId,
            'from_currency': fromCurrency,
            'to_currency': toCurrency,
            'as_of_date': asOfDate.toIso8601String().substring(0, 10),
            'rate': rate,
            'created_by': createdBy,
          },
          onConflict: 'household_id,from_currency,to_currency,as_of_date',
        );
    // Write-through: the server didn't return the row so we
    // build the cache companion from the inputs + now() for the
    // tracking timestamps. The next fetchAll() will overwrite
    // with the canonical server values, including server-side
    // createdAt/updatedAt.
    final db = _db;
    if (db != null) {
      try {
        final now = DateTime.now().toUtc();
        await db.upsertFxRate(
          FxRatesCacheCompanion(
            householdId: Value(householdId),
            fromCurrency: Value(fromCurrency),
            toCurrency: Value(toCurrency),
            // M10: DATE column — no .toUtc().
            asOfDate: Value(asOfDate),
            rate: Value(rate),
            createdBy: Value(createdBy),
            createdAt: Value(now),
            updatedAt: Value(now),
            cachedAt: Value(now),
          ),
        );
      } catch (_) {/**/}
    }
  }

  /// Removes a single rate row. Used by the editor when the user
  /// wants to undo a manual entry — distinct from "set to a new
  /// value", which keeps the row.
  Future<void> deleteRate({
    required String householdId,
    required String fromCurrency,
    required String toCurrency,
    required DateTime asOfDate,
  }) async {
    await supabase
        .from('fx_rates')
        .delete()
        .eq('household_id', householdId)
        .eq('from_currency', fromCurrency)
        .eq('to_currency', toCurrency)
        .eq('as_of_date', asOfDate.toIso8601String().substring(0, 10));
    final db = _db;
    if (db != null) {
      try {
        await db.deleteFxRate(
          householdId: householdId,
          fromCurrency: fromCurrency,
          toCurrency: toCurrency,
          // M10: DATE column — no .toUtc().
          asOfDate: asOfDate,
        );
      } catch (_) {/**/}
    }
  }

  // ── Cache helpers ──────────────────────────────────────────

  Future<void> _refreshFxCache(
    String householdId,
    List<FxRate> rates,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.replaceFxRatesForHousehold(
        householdId,
        rates.map(_fxToCompanion).toList(),
      );
    } catch (_) {/**/}
  }

  Future<void> _writeFxCacheRow(FxRate r) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.upsertFxRate(_fxToCompanion(r));
    } catch (_) {/**/}
  }

  Future<List<FxRate>?> _loadFromCache(String householdId) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.loadFxRatesForHousehold(householdId);
      if (rows.isEmpty) return null;
      return rows.map(_fxFromCacheRow).toList();
    } catch (_) {
      return null;
    }
  }

  Future<FxRate?> _loadLatestFromCache({
    required String householdId,
    required String fromCurrency,
    required String toCurrency,
    DateTime? asOf,
  }) async {
    final db = _db;
    if (db == null) return null;
    try {
      final row = await db.loadLatestFxRate(
        householdId: householdId,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        asOf: asOf,
      );
      if (row == null) return null;
      return _fxFromCacheRow(row);
    } catch (_) {
      return null;
    }
  }
}

FxRatesCacheCompanion _fxToCompanion(FxRate r) {
  return FxRatesCacheCompanion(
    householdId: Value(r.householdId),
    fromCurrency: Value(r.fromCurrency),
    toCurrency: Value(r.toCurrency),
    // M10: DATE column — no .toUtc().
    asOfDate: Value(r.asOfDate),
    rate: Value(r.rate),
    createdBy: Value(r.createdBy),
    createdAt: Value(r.createdAt.toUtc()),
    updatedAt: Value(r.updatedAt.toUtc()),
    cachedAt: Value(DateTime.now().toUtc()),
  );
}

FxRate _fxFromCacheRow(FxRatesCacheRow r) {
  return FxRate(
    householdId: r.householdId,
    fromCurrency: r.fromCurrency,
    toCurrency: r.toCurrency,
    asOfDate: r.asOfDate,
    rate: r.rate,
    createdBy: r.createdBy,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}
