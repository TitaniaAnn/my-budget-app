// Pure-function tests for currency conversion + multi-currency
// net worth aggregation.
//
// Contracts pinned:
//   * convertCents rounds (not truncates) — small drifts must not
//     accumulate across holdings;
//   * same-currency conversion is a no-op short-circuit (the
//     caller doesn't need to include a 1.0 rate for the display
//     currency itself);
//   * accounts in missing-rate currencies are kept OUT of the
//     converted total but surface in perCurrencyCents AND in
//     missingRateCurrencies — silently dropping them would
//     under-report net worth without the user knowing;
//   * a USD-only household with displayCurrency='USD' degenerates
//     to the existing single-currency math.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/accounts/models/account.dart';
import 'package:mybudget/features/currency/services/convert.dart';

Account _a({
  required int balance,
  String currency = 'USD',
  String id = 'a',
  AccountType type = AccountType.checking,
}) {
  final ts = DateTime(2026, 1, 1);
  return Account(
    id: id,
    householdId: 'h',
    ownerUserId: 'u',
    name: id,
    accountType: type,
    currency: currency,
    startingBalance: 0,
    currentBalance: balance,
    isActive: true,
    createdAt: ts,
    updatedAt: ts,
  );
}

void main() {
  group('convertCents', () {
    test('rounds (does not truncate) so drift doesn\'t accumulate', () {
      // 1234 × 1.05 = 1295.7 → rounds to 1296. Truncation would
      // give 1295 and a many-position portfolio would lose a
      // visibly wrong amount.
      expect(convertCents(1234, 1.05), 1296);
    });

    test('negative amounts (liabilities) round symmetrically', () {
      // A -$50,000 mortgage in EUR converted to USD at 1.08 should
      // come out as -54,000 (signed), not magnitude-flipped or
      // off by a half-cent.
      expect(convertCents(-5000000, 1.08), -5400000);
    });

    test('rate = 1 is a no-op', () {
      expect(convertCents(12345, 1.0), 12345);
      expect(convertCents(-12345, 1.0), -12345);
    });
  });

  group('multiCurrencyNetWorth', () {
    test('USD-only household with display=USD degenerates to plain sum', () {
      final result = multiCurrencyNetWorth(
        accounts: [
          _a(balance: 100000, currency: 'USD', id: 'checking'),
          _a(balance: 500000, currency: 'USD', id: 'savings'),
        ],
        displayCurrency: 'USD',
        ratesToDisplay: const {},
      );
      expect(result.totalCents, 600000);
      expect(result.missingRateCurrencies, isEmpty);
      expect(result.perCurrencyCents, {'USD': 600000});
    });

    test('converts non-display-currency accounts via the rate map', () {
      // $1,000 USD checking + €500 EUR savings, display USD, EUR→USD 1.0573.
      // EUR side: 50000 × 1.0573 = 52865 cents.
      final result = multiCurrencyNetWorth(
        accounts: [
          _a(balance: 100000, currency: 'USD', id: 'us-checking'),
          _a(balance: 50000, currency: 'EUR', id: 'eu-savings'),
        ],
        displayCurrency: 'USD',
        ratesToDisplay: const {'EUR': 1.0573},
      );
      expect(result.totalCents, 100000 + 52865);
      expect(result.perCurrencyCents, {'USD': 100000, 'EUR': 50000});
      expect(result.missingRateCurrencies, isEmpty);
      expect(result.isComplete, isTrue);
    });

    test('missing-rate currency stays OUT of the total but surfaces in '
        'perCurrencyCents and missingRateCurrencies', () {
      // ¥100,000 JPY position with no JPY→USD rate. The total
      // must NOT silently include 100k (that would imply rate=1).
      // The position still surfaces so the user knows it exists.
      final result = multiCurrencyNetWorth(
        accounts: [
          _a(balance: 100000, currency: 'USD', id: 'us-checking'),
          _a(balance: 10000000, currency: 'JPY', id: 'jp-savings'),
        ],
        displayCurrency: 'USD',
        ratesToDisplay: const {},
      );
      expect(
        result.totalCents,
        100000,
        reason:
            'JPY must be excluded from total when no rate is '
            'available — including it at rate=1 would silently '
            'lie about net worth.',
      );
      expect(result.perCurrencyCents['JPY'], 10000000);
      expect(result.missingRateCurrencies, {'JPY'});
      expect(result.isComplete, isFalse);
    });

    test(
      'same-currency display short-circuits (no rate needed for display)',
      () {
        // Display = EUR, account in EUR. The caller doesn't need to
        // pass an EUR→EUR rate; the math just sums.
        final result = multiCurrencyNetWorth(
          accounts: [_a(balance: 50000, currency: 'EUR', id: 'eu')],
          displayCurrency: 'EUR',
          ratesToDisplay: const {},
        );
        expect(result.totalCents, 50000);
        expect(result.isComplete, isTrue);
      },
    );

    test('multiple non-display currencies each consult their own rate', () {
      // USD display, EUR and GBP positions. EUR converts at 1.05,
      // GBP at 1.27. Verify both are applied independently.
      final result = multiCurrencyNetWorth(
        accounts: [
          _a(balance: 100000, currency: 'USD', id: 'us'),
          _a(balance: 50000, currency: 'EUR', id: 'eu'),
          _a(balance: 20000, currency: 'GBP', id: 'uk'),
        ],
        displayCurrency: 'USD',
        ratesToDisplay: const {'EUR': 1.05, 'GBP': 1.27},
      );
      // 100000 + (50000 * 1.05 = 52500) + (20000 * 1.27 = 25400)
      expect(result.totalCents, 100000 + 52500 + 25400);
      expect(result.isComplete, isTrue);
    });

    test('liabilities (negative balances) convert with the same rate', () {
      // A €100k EUR mortgage at -10,000,000 cents, display USD.
      // EUR→USD 1.08 → -10,800,000 cents on the converted side.
      final result = multiCurrencyNetWorth(
        accounts: [
          _a(balance: 500000, currency: 'USD', id: 'us-checking'),
          _a(
            balance: -10000000,
            currency: 'EUR',
            id: 'eu-mortgage',
            type: AccountType.mortgage,
          ),
        ],
        displayCurrency: 'USD',
        ratesToDisplay: const {'EUR': 1.08},
      );
      expect(result.totalCents, 500000 + (-10800000));
    });

    test('empty account list returns zero totals across the board', () {
      final result = multiCurrencyNetWorth(
        accounts: const [],
        displayCurrency: 'USD',
        ratesToDisplay: const {},
      );
      expect(result.totalCents, 0);
      expect(result.perCurrencyCents, isEmpty);
      expect(result.isComplete, isTrue);
    });

    test('credit-card debt (negative balance) is signed-summed, not '
        'abs-subtracted — pins the scenarios provider against drift', () {
      // scenarios_provider used to special-case credit cards with
      // `sum - currentBalance.abs()`, which either no-ops or
      // double-subtracts depending on whether the convention (CC
      // balances stored as negative cents) actually held. The fix
      // routes through multiCurrencyNetWorth; this test makes sure
      // a mixed checking + credit-card + brokerage portfolio sums
      // to the plain signed total the dashboard reports.
      final result = multiCurrencyNetWorth(
        accounts: [
          _a(balance: 250000, type: AccountType.checking, id: 'ck'),
          // Convention: stored as negative cents.
          _a(balance: -120000, type: AccountType.creditCard, id: 'cc'),
          _a(balance: 800000, type: AccountType.brokerage, id: 'bk'),
        ],
        displayCurrency: 'USD',
        ratesToDisplay: const {},
      );
      // 2500 + (-1200) + 8000 = 9300 dollars.
      expect(result.totalCents, 930000);
    });
  });
}
