// Verifies that every Dart enum variant maps to the exact string stored in
// its corresponding Postgres enum type. This file is the front-line defense
// against the kind of bug we hit when CreditRateType.cashAdvance was being
// serialised as "cashAdvance" instead of "cash_advance".

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/accounts/models/account.dart';
import 'package:mybudget/features/accounts/models/credit_card_rate.dart';
import 'package:mybudget/features/budget/models/budget.dart';

void main() {
  group('AccountType.dbValue', () {
    // These values MUST match the strings in the Postgres `account_type`
    // enum defined in supabase/migrations/001_initial_schema.sql + 012.
    const expected = {
      AccountType.checking: 'checking',
      AccountType.savings: 'savings',
      AccountType.creditCard: 'credit_card',
      AccountType.brokerage: 'brokerage',
      AccountType.iraTraditional: 'ira_traditional',
      AccountType.iraRoth: 'ira_roth',
      AccountType.retirement401k: 'retirement_401k',
      AccountType.retirement403b: 'retirement_403b',
      AccountType.hsa: 'hsa',
      AccountType.college529: 'college_529',
      AccountType.cash: 'cash',
      AccountType.mortgage: 'mortgage',
    };

    test('every variant maps to the expected DB string', () {
      for (final entry in expected.entries) {
        expect(entry.key.dbValue, entry.value,
            reason: '${entry.key} should serialise as ${entry.value}');
      }
    });

    test('every enum variant has a mapping', () {
      // Guards against forgetting to update this test when a new variant
      // is added.
      expect(expected.keys.toSet(), AccountType.values.toSet());
    });
  });

  group('CreditRateType.dbValue', () {
    const expected = {
      CreditRateType.purchase: 'purchase',
      CreditRateType.cashAdvance: 'cash_advance',
      CreditRateType.balanceTransfer: 'balance_transfer',
      CreditRateType.penalty: 'penalty',
    };

    test('every variant maps to the snake_case DB string', () {
      for (final entry in expected.entries) {
        expect(entry.key.dbValue, entry.value,
            reason: '${entry.key} should serialise as ${entry.value}');
      }
    });

    test('cashAdvance is NOT serialised as the Dart identifier', () {
      // Regression guard: .name returns "cashAdvance" but the column is
      // "cash_advance"; using .name silently broke INSERTs.
      expect(CreditRateType.cashAdvance.dbValue,
          isNot(CreditRateType.cashAdvance.name));
    });

    test('every enum variant has a mapping', () {
      expect(expected.keys.toSet(), CreditRateType.values.toSet());
    });
  });

  group('BudgetPeriod.dbValue', () {
    const expected = {
      BudgetPeriod.weekly: 'weekly',
      BudgetPeriod.biweekly: 'biweekly',
      BudgetPeriod.monthly: 'monthly',
      BudgetPeriod.semiannual: 'semiannual',
      BudgetPeriod.annual: 'annual',
    };

    test('every variant maps to the expected DB string', () {
      for (final entry in expected.entries) {
        expect(entry.key.dbValue, entry.value);
      }
    });

    test('every enum variant has a mapping', () {
      expect(expected.keys.toSet(), BudgetPeriod.values.toSet());
    });
  });

  group('AccountType.group', () {
    test('groups account types into the four UI buckets', () {
      expect(AccountType.checking.group, AccountGroup.banking);
      expect(AccountType.savings.group, AccountGroup.banking);
      expect(AccountType.cash.group, AccountGroup.banking);
      expect(AccountType.creditCard.group, AccountGroup.creditCards);
      expect(AccountType.mortgage.group, AccountGroup.loans);
      expect(AccountType.brokerage.group, AccountGroup.investments);
      expect(AccountType.iraTraditional.group, AccountGroup.investments);
      expect(AccountType.iraRoth.group, AccountGroup.investments);
      expect(AccountType.retirement401k.group, AccountGroup.investments);
      expect(AccountType.retirement403b.group, AccountGroup.investments);
      expect(AccountType.hsa.group, AccountGroup.investments);
      expect(AccountType.college529.group, AccountGroup.investments);
    });
  });
}
