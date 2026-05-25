import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/utils/money.dart' as money;

void main() {
  group('formatCurrency', () {
    test('formats positive cents with currency symbol', () {
      expect(money.formatCurrency(1234), '\$12.34');
    });

    test('formats zero', () {
      expect(money.formatCurrency(0), '\$0.00');
    });

    test('formats negative cents with leading minus', () {
      expect(money.formatCurrency(-50000), '-\$500.00');
    });

    test('renders single-cent values', () {
      expect(money.formatCurrency(1), '\$0.01');
    });

    // ── C1 (multi-currency display): the `currency` parameter must
    // route to the right ICU symbol; before the fix it was ignored
    // and every render said "$" regardless of the household's
    // displayCurrency.
    test('honours the currency parameter for EUR', () {
      expect(money.formatCurrency(1234, currency: 'EUR'), '€12.34');
    });

    test('honours the currency parameter for GBP', () {
      expect(money.formatCurrency(1234, currency: 'GBP'), '£12.34');
    });

    test('honours the currency parameter for JPY (no minor units)', () {
      // JPY's "natural" decimal-digit count is 0, but our formatter
      // forces 2 to keep alignment with the cents-storage contract.
      // The symbol must still resolve to '¥'.
      expect(money.formatCurrency(123400, currency: 'JPY'), startsWith('¥'));
    });

    test('falls back to the ISO code for an unknown currency', () {
      // ICU returns the code itself when it doesn't recognise the
      // currency — the right "fail visible" behaviour vs. silently
      // dropping back to '$'.
      final out = money.formatCurrency(1234, currency: 'XYZ');
      expect(out, contains('XYZ'));
      expect(out, isNot(contains(r'$')));
    });
  });

  group('currencySymbol', () {
    test('returns the locale-aware symbol for known ISO codes', () {
      expect(money.currencySymbol('USD'), '\$');
      expect(money.currencySymbol('EUR'), '€');
      expect(money.currencySymbol('GBP'), '£');
    });

    test('falls back to the ISO code for unknown currencies', () {
      expect(money.currencySymbol('XYZ'), 'XYZ');
    });
  });

  group('centsToString', () {
    test('produces a fixed two-decimal string without symbol', () {
      expect(money.centsToString(1234), '12.34');
      expect(money.centsToString(0), '0.00');
      expect(money.centsToString(-1234), '-12.34');
    });
  });

  group('parseToCents', () {
    test('handles plain numeric input', () {
      expect(money.parseToCents('12.34'), 1234);
    });

    test('strips currency symbols and whitespace', () {
      expect(money.parseToCents('  \$12.34 '), 1234);
    });

    test('preserves negative sign', () {
      // Regression: previously the regex stripped the minus, returning 1234.
      expect(money.parseToCents('-12.34'), -1234);
      expect(money.parseToCents('-\$12.34'), -1234);
    });

    test('returns 0 for empty / non-numeric input', () {
      expect(money.parseToCents(''), 0);
      expect(money.parseToCents('abc'), 0);
    });

    test('rounds half away from zero on the cent boundary', () {
      expect(money.parseToCents('12.345'), 1235);
    });

    test('handles whole-dollar input without a decimal point', () {
      expect(money.parseToCents('500'), 50000);
    });
  });

  group('creditUtilization', () {
    test('returns percentage of limit used', () {
      expect(money.creditUtilization(50000, 100000), 50.0);
    });

    test('uses absolute value of balance', () {
      // Liability balances may be stored as negative cents.
      expect(money.creditUtilization(-25000, 100000), 25.0);
    });

    test('returns 0 when limit is zero', () {
      expect(money.creditUtilization(50000, 0), 0);
    });

    test('clamps to a sensible upper bound when over-limit', () {
      expect(money.creditUtilization(2000000, 100000), lessThanOrEqualTo(999));
    });
  });

  group('isDebit / isPositive', () {
    test('classify by sign', () {
      expect(money.isDebit(-100), isTrue);
      expect(money.isDebit(100), isFalse);
      expect(money.isDebit(0), isFalse);
      expect(money.isPositive(0), isTrue);
      expect(money.isPositive(100), isTrue);
      expect(money.isPositive(-1), isFalse);
    });
  });
}
