// Riverpod glue: combines accounts + household display currency
// + latest FX rates into a single ConvertedNetWorth that the
// dashboard card reads.
//
// Cheap when nothing is multi-currency: a USD-only household with
// displayCurrency='USD' bypasses the rate lookup entirely
// (every account's currency matches display, no rate is needed).

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../accounts/providers/accounts_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../repositories/fx_rates_repository.dart';
import '../services/convert.dart';

part 'converted_net_worth_provider.g.dart';

@riverpod
Future<ConvertedNetWorth> convertedNetWorth(ConvertedNetWorthRef ref) async {
  final accounts = await ref.watch(accountsProvider.future);
  final info = await ref.watch(householdInfoProvider.future);
  final display = info.displayCurrency;

  // Build the set of non-display currencies we actually have
  // accounts in. If empty, no rate lookups are needed.
  final foreignCurrencies = {
    for (final a in accounts)
      if (a.currency != display) a.currency,
  };

  final rates = <String, double>{};
  if (foreignCurrencies.isNotEmpty) {
    final repo = ref.read(fxRatesRepositoryProvider);
    for (final cur in foreignCurrencies) {
      final fx = await repo.latestRate(
        householdId: info.householdId,
        fromCurrency: cur,
        toCurrency: display,
      );
      if (fx != null) rates[cur] = fx.rate;
    }
  }

  return multiCurrencyNetWorth(
    accounts: accounts,
    displayCurrency: display,
    ratesToDisplay: rates,
  );
}
