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
      expect(
        matcher.match('WALMART SUPERCENTER', isIncome: false),
        'id-Groceries',
      );
      expect(
        matcher.match('Trader Joe\'s 555', isIncome: false),
        'id-Groceries',
      );
    });

    test('matches gas stations', () {
      expect(matcher.match('SHELL OIL 7351', isIncome: false), 'id-Gas');
      expect(matcher.match('chevron #023', isIncome: false), 'id-Gas');
    });

    test('matches subscription services', () {
      expect(matcher.match('NETFLIX.COM', isIncome: false), 'id-Subscriptions');
      expect(matcher.match('SPOTIFY USA', isIncome: false), 'id-Subscriptions');
    });

    test('matches restaurants by chain name', () {
      expect(matcher.match('CHIPOTLE 0123', isIncome: false), 'id-Restaurants');
    });

    test('matches case-insensitively', () {
      expect(matcher.match('starbucks', isIncome: false), 'id-Coffee & Drinks');
      expect(matcher.match('STARBUCKS', isIncome: false), 'id-Coffee & Drinks');
    });

    test('returns null for unrecognised merchants', () {
      expect(
        matcher.match('TOTALLY UNKNOWN MERCHANT XYZ', isIncome: false),
        isNull,
      );
    });
  });

  group('income matching', () {
    test('matches payroll keywords', () {
      expect(matcher.match('PAYROLL DEPOSIT', isIncome: true), 'id-Salary');
      expect(matcher.match('ADP TX*PR', isIncome: true), 'id-Salary');
    });

    test('matches refunds as Other Income', () {
      expect(
        matcher.match('AMAZON REFUND 123', isIncome: true),
        'id-Other Income',
      );
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
      expect(
        matcher.match('ZELLE PAYMENT TO X', isIncome: false),
        'id-Transfer',
      );
    });

    test('"renters insurance" is Home Insurance, not Rent/Mortgage', () {
      // Regression: 'rent' used to be a substring keyword in Rent/Mortgage,
      // and Rent/Mortgage was checked before Home Insurance — so "RENTERS
      // INSURANCE PMT" was mis-categorised as Rent/Mortgage. Both the rule
      // ordering and the keyword specificity were tightened.
      expect(
        matcher.match('RENTERS INSURANCE PMT', isIncome: false),
        'id-Home Insurance',
      );
      expect(
        matcher.match('Renters Insurance — Lemonade', isIncome: false),
        'id-Home Insurance',
      );
    });

    test('genuine rent payments still match Rent / Mortgage', () {
      expect(
        matcher.match('RENT PAYMENT MARCH', isIncome: false),
        'id-Rent / Mortgage',
      );
      expect(
        matcher.match('APT RENT 0301', isIncome: false),
        'id-Rent / Mortgage',
      );
      expect(
        matcher.match('MORTGAGE PYMT WELLS FARGO', isIncome: false),
        'id-Rent / Mortgage',
      );
    });

    test('home insurance keywords match Home Insurance', () {
      expect(
        matcher.match('HOMEOWNER INSURANCE', isIncome: false),
        'id-Home Insurance',
      );
      expect(
        matcher.match('HOME INSURANCE PREMIUM', isIncome: false),
        'id-Home Insurance',
      );
    });
  });

  group('edge cases', () {
    test('empty description returns null', () {
      // A blank description hits no keywords in any rule. The matcher
      // must return null rather than crashing on the contains() loop.
      expect(matcher.match('', isIncome: false), isNull);
      expect(matcher.match('', isIncome: true), isNull);
    });

    test('whitespace-only description returns null', () {
      expect(matcher.match('   ', isIncome: false), isNull);
    });
  });

  group('income-side rule precedence', () {
    test(
      '"payroll refund" matches Salary (declared first), not Other Income',
      () {
        // Both 'payroll' (Salary) and 'refund' (Other Income) appear
        // in the description. Salary is declared first in _incomeRules,
        // so it wins. A future reorder of the income table would flip
        // this — pinning it makes the regression obvious.
        expect(
          matcher.match('PAYROLL REFUND ADJUSTMENT', isIncome: true),
          'id-Salary',
        );
      },
    );

    test('investment-income keywords beat the more generic "deposit" '
        'because there is no generic deposit rule', () {
      // Sanity check: 'fidelity dep' on the income side routes to
      // Investment Income, not Other Income. Pins that the more
      // specific keyword in the earlier rule wins.
      expect(
        matcher.match('FIDELITY DEPOSIT', isIncome: true),
        'id-Investment Income',
      );
    });
  });

  group('keyword specificity guards', () {
    test('plain "CVS" does NOT match Prescriptions — needs "cvs pharm"', () {
      // The Prescriptions rule has 'cvs pharm', not bare 'cvs', so
      // a CVS convenience-store transaction (snacks / household
      // items) doesn't get force-categorised as medical.
      expect(matcher.match('CVS #4521 PURCHASE', isIncome: false), isNull);
      // The pharmacy variant still does match.
      expect(
        matcher.match('CVS PHARMACY #4521', isIncome: false),
        'id-Prescriptions',
      );
    });

    test(
      'plain "walgreens" matches Prescriptions (the rule keyword IS bare)',
      () {
        // Contrast with CVS: walgreens is intentionally a bare keyword
        // because the chain is overwhelmingly pharmacy-led, so the
        // false-positive rate of categorising a snack purchase as
        // Prescriptions is judged acceptable.
        expect(
          matcher.match('WALGREENS #1234', isIncome: false),
          'id-Prescriptions',
        );
      },
    );

    test('AMAZON KINDLE STORE goes to Subscriptions, not Books — pinned', () {
      // 'kindle' is a Subscriptions keyword (Kindle Unlimited).
      // 'amazon kindle' is a Books keyword. Subscriptions is
      // declared first in _expenseRules, so the substring match
      // for 'kindle' fires before Books even gets evaluated.
      //
      // This is the kind of cross-rule ambiguity that's easy to
      // re-introduce by accident on a rule reorder. Pinned as the
      // current behavior so a future change has to acknowledge it.
      expect(
        matcher.match('AMAZON KINDLE STORE', isIncome: false),
        'id-Subscriptions',
      );
    });
  });

  group('income/expense routing of same-merchant strings', () {
    test('"schwab" on the income side is Investment Income', () {
      // The same broker name appears under Investment Income (income)
      // AND 401k/Retirement (expense). The matcher dispatches on
      // isIncome, so the user's transaction sign determines which
      // rule table is even consulted.
      expect(
        matcher.match('SCHWAB DIVIDEND 0123', isIncome: true),
        'id-Investment Income',
      );
    });

    test('"schwab" on the expense side is 401k / Retirement', () {
      expect(
        matcher.match('SCHWAB BUY VTI', isIncome: false),
        'id-401k / Retirement',
      );
    });
  });

  group('missing categories', () {
    test('returns null when the matched rule has no category in the list', () {
      // Build a matcher with only one category so rules that fire for other
      // names can't resolve to an id.
      final m = CategoryMatcher([
        Category(
          id: 'id-Transfer',
          name: 'Transfer',
          isIncome: false,
          sortOrder: 0,
        ),
      ]);
      // "shell" matches Gas — but Gas is absent.
      expect(m.match('SHELL OIL 7351', isIncome: false), isNull);
      // Transfer does exist, so this returns its id.
      expect(m.match('zelle payment', isIncome: false), 'id-Transfer');
    });
  });
}
