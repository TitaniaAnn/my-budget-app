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
      expect(money.creditUtilization(2000000, 100000),
          lessThanOrEqualTo(999));
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
