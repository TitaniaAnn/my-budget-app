import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/models/category.dart';
import 'package:mybudget/features/transactions/services/category_matcher.dart';

/// Builds a fake category list with stable ids that match each rule's name.
List<Category> _categories() {
  // Names listed here MUST match the keys used inside CategoryMatcher's
  // _incomeRules and _expenseRules tables.
  final names = [
    // Expense
    'Transfer',
    'Credit Card Payment',
    'Rent / Mortgage',
    'Utilities',
    'Internet / Phone',
    'Coffee & Drinks',
    'Takeout & Delivery',
    'Restaurants',
    'Groceries',
    'Rideshare / Parking',
    'Public Transit',
    'Car Insurance',
    'Car Payment',
    'Car Maintenance',
    'Gas',
    'Prescriptions',
    'Gym & Fitness',
    'Doctor / Dentist',
    'Health Insurance',
    'Vision & Dental',
    'Subscriptions',
    'Entertainment',
    'Personal Care',
    'Clothing',
    'Books & Education',
    'Hobbies',
    'Childcare',
    'School & Supplies',
    'Activities & Sports',
    'Charitable Donations',
    'Gifts',
    'Taxes',
    'Home Maintenance',
    'Home Insurance',
    'Student Loan',
    '401k / Retirement',
    'HSA Contribution',
    '529 / College Savings',
    // Income
    'Salary',
    'Freelance',
    'Investment Income',
    'Other Income',
  ];
  return [
    for (final n in names)
      Category(
        id: 'id-$n',
        name: n,
        isIncome: const {
          'Salary',
          'Freelance',
          'Investment Income',
          'Other Income',
        }.contains(n),
        sortOrder: 0,
      ),
  ];
}

void main() {
  late CategoryMatcher matcher;

  setUp(() {
    matcher = CategoryMatcher(_categories());
  });

  group('expense matching', () {
    test('matches grocery merchants', () {
      expect(matcher.match('WALMART SUPERCENTER', isIncome: false),
          'id-Groceries');
      expect(matcher.match('Trader Joe\'s 555', isIncome: false),
          'id-Groceries');
    });

    test('matches gas stations', () {
      expect(matcher.match('SHELL OIL 7351', isIncome: false), 'id-Gas');
      expect(matcher.match('chevron #023', isIncome: false), 'id-Gas');
    });

    test('matches subscription services', () {
      expect(matcher.match('NETFLIX.COM', isIncome: false),
          'id-Subscriptions');
      expect(matcher.match('SPOTIFY USA', isIncome: false),
          'id-Subscriptions');
    });

    test('matches restaurants by chain name', () {
      expect(matcher.match('CHIPOTLE 0123', isIncome: false),
          'id-Restaurants');
    });

    test('matches case-insensitively', () {
      expect(matcher.match('starbucks', isIncome: false),
          'id-Coffee & Drinks');
      expect(matcher.match('STARBUCKS', isIncome: false),
          'id-Coffee & Drinks');
    });

    test('returns null for unrecognised merchants', () {
      expect(matcher.match('TOTALLY UNKNOWN MERCHANT XYZ', isIncome: false),
          isNull);
    });
  });

  group('income matching', () {
    test('matches payroll keywords', () {
      expect(matcher.match('PAYROLL DEPOSIT', isIncome: true), 'id-Salary');
      expect(matcher.match('ADP TX*PR', isIncome: true), 'id-Salary');
    });

    test('matches refunds as Other Income', () {
      expect(matcher.match('AMAZON REFUND 123', isIncome: true),
          'id-Other Income');
    });

    test('does not match expense rules when isIncome=true', () {
      // "starbucks" is in the expense rules but not the income rules.
      expect(matcher.match('starbucks', isIncome: true), isNull);
    });

    test('does not match income rules when isIncome=false', () {
      expect(matcher.match('payroll deposit', isIncome: false), isNull);
    });
  });

  group('rule precedence', () {
    test('Transfer beats more general matches', () {
      // "ZELLE" is in Transfer; the matcher iterates rules in declared order
      // and Transfer is first.
      expect(matcher.match('ZELLE PAYMENT TO X', isIncome: false),
          'id-Transfer');
    });
  });

  group('missing categories', () {
    test('returns null when the matched rule has no category in the list', () {
      // Build a matcher with only one category so rules that fire for other
      // names can't resolve to an id.
      final m = CategoryMatcher([
        Category(id: 'id-Transfer', name: 'Transfer', isIncome: false, sortOrder: 0),
      ]);
      // "shell" matches Gas — but Gas is absent.
      expect(m.match('SHELL OIL 7351', isIncome: false), isNull);
      // Transfer does exist, so this returns its id.
      expect(m.match('zelle payment', isIncome: false), 'id-Transfer');
    });
  });
}
