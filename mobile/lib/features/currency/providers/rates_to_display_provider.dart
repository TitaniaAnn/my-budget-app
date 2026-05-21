// Shared {from-currency → rate} map for the household's display
// currency.
//
// The dashboard, budget, scenarios, monthly report, and
// notification runner all need this exact map to convert
// transaction/budget cap amounts into the display currency. Before
// this provider, each of them ran their own copy of:
//
//   final allRates = await fxRepo.fetchAll(householdId);
//   final ratesToDisplay = <String, double>{};
//   for (final r in allRates) {
//     if (r.toCurrency != info.displayCurrency) continue;
//     ratesToDisplay.putIfAbsent(r.fromCurrency, () => r.rate);
//   }
//
// Five fetches per dashboard load, five copies of the same loop to
// keep in sync. Centralising fixes both.
//
// USD-only household behaviour: when no fx_rates rows exist (or
// when display_currency matches every account's currency), the
// map is empty. Every downstream caller is already designed to
// short-circuit on an empty map, so the behaviour is unchanged for
// the common case.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../settings/providers/settings_provider.dart';
import '../repositories/fx_rates_repository.dart';

part 'rates_to_display_provider.g.dart';

/// {from-currency → rate} where rate converts INTO the household's
/// display currency. Picks the most recent rate per (from, display)
/// pair — `fetchAll` orders newest-first by `as_of_date`, so
/// `putIfAbsent` latches onto the latest row.
///
/// Empty map for USD-only households (no fx_rates rows OR every
/// rate's `to_currency` doesn't match display). Callers treat
/// missing entries as "exclude this currency, don't lie at rate=1"
/// per the project-wide multi-currency contract.
@riverpod
Future<Map<String, double>> ratesToDisplay(RatesToDisplayRef ref) async {
  final info = await ref.watch(householdInfoProvider.future);
  final allRates = await ref
      .read(fxRatesRepositoryProvider)
      .fetchAll(info.householdId);
  final out = <String, double>{};
  for (final r in allRates) {
    if (r.toCurrency != info.displayCurrency) continue;
    out.putIfAbsent(r.fromCurrency, () => r.rate);
  }
  return out;
}
