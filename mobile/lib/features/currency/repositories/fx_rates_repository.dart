// Data access for FX rates (migration 036).
//
// The hot query is "what's the most recent rate from X to Y at or
// before today" — answered with one round-trip via the
// (household, from, to, as_of_date DESC) index. Setter is a plain
// upsert on the composite PK.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../models/fx_rate.dart';

part 'fx_rates_repository.g.dart';

@riverpod
FxRatesRepository fxRatesRepository(FxRatesRepositoryRef ref) {
  return FxRatesRepository();
}

class FxRatesRepository {
  /// All rates for the household, newest first. Used by the
  /// Settings → FX Rates editor. Households without any rates
  /// returns an empty list — the dashboard's conversion math
  /// treats that as "every non-display-currency account is
  /// missing a rate" and surfaces accordingly.
  Future<List<FxRate>> fetchAll(String householdId) async {
    final data = await supabase
        .from('fx_rates')
        .select()
        .eq('household_id', householdId)
        .order('as_of_date', ascending: false);
    return data.map<FxRate>(FxRate.fromJson).toList();
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
    return FxRate.fromJson(data);
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
  }
}
