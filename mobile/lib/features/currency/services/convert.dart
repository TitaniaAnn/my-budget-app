// Pure currency conversion math.
//
// All money in this app is integer cents. Conversion goes
//   amountInToCents = round(amountInFromCents × rate)
//
// We round at the boundary — keeping a half-cent floating around
// would let small drifts accumulate across many holdings into a
// visibly wrong total. round() is the right ties-half-to-even
// behaviour for our purposes; the alternative (truncate) would
// systematically under-report.
//
// Same-currency conversion is a no-op short-circuit — the rate
// might not even exist in the table (we don't store identity
// rates) and shouldn't need to.

import '../../accounts/models/account.dart';

/// Converts an integer-cents amount using a multiplier rate.
/// Returns the converted cents, rounded.
int convertCents(int amountCents, double rate) {
  return (amountCents * rate).round();
}

/// Output of [multiCurrencyNetWorth]. Carries the converted
/// total alongside diagnostic state — what currencies appeared,
/// which ones the caller didn't have rates for — so the UI can
/// surface a "rate missing for EUR" banner instead of silently
/// dropping accounts from the sum.
class ConvertedNetWorth {
  const ConvertedNetWorth({
    required this.displayCurrency,
    required this.totalCents,
    required this.perCurrencyCents,
    required this.missingRateCurrencies,
  });

  /// Display currency (e.g. 'USD') the [totalCents] is in.
  final String displayCurrency;

  /// Sum of every account's current_balance, with each account's
  /// native currency converted to [displayCurrency] when a rate
  /// is available. Accounts in currencies in
  /// [missingRateCurrencies] are NOT included — including them
  /// at rate=1 would silently lie.
  final int totalCents;

  /// Pre-conversion subtotals keyed by native currency. The
  /// dashboard surfaces this so users can see "you have 100k JPY
  /// somewhere" even when no JPY→USD rate is set.
  final Map<String, int> perCurrencyCents;

  /// Currencies that appeared on at least one account but had no
  /// rate to [displayCurrency]. Empty means every account is
  /// either in the display currency or has a usable rate.
  final Set<String> missingRateCurrencies;

  /// Convenience getter — true when nothing prevented a complete
  /// conversion. The dashboard suppresses the "missing rate"
  /// banner when this is true.
  bool get isComplete => missingRateCurrencies.isEmpty;
}

/// Aggregates net worth across accounts that may sit in different
/// currencies.
///
/// [ratesToDisplay] maps `fromCurrency → rate` where rate is the
/// multiplier into [displayCurrency]. The display currency itself
/// is implicit (rate = 1) — the caller doesn't need to include
/// it.
///
/// Accounts in a currency missing from [ratesToDisplay] are kept
/// out of [totalCents] and their currency surfaces in
/// [missingRateCurrencies]. They still appear in
/// [perCurrencyCents] so the user knows the position exists.
///
/// A USD-only household with displayCurrency='USD' degenerates to
/// the existing single-currency net worth, no rates needed.
ConvertedNetWorth multiCurrencyNetWorth({
  required List<Account> accounts,
  required String displayCurrency,
  required Map<String, double> ratesToDisplay,
}) {
  final perCurrency = <String, int>{};
  for (final a in accounts) {
    perCurrency.update(
      a.currency,
      (v) => v + a.currentBalance,
      ifAbsent: () => a.currentBalance,
    );
  }

  var total = 0;
  final missing = <String>{};
  for (final entry in perCurrency.entries) {
    if (entry.key == displayCurrency) {
      total += entry.value;
      continue;
    }
    final rate = ratesToDisplay[entry.key];
    if (rate == null) {
      missing.add(entry.key);
      continue;
    }
    total += convertCents(entry.value, rate);
  }

  return ConvertedNetWorth(
    displayCurrency: displayCurrency,
    totalCents: total,
    perCurrencyCents: perCurrency,
    missingRateCurrencies: missing,
  );
}
