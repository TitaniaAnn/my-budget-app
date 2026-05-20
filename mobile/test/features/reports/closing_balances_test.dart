// Pure-function tests for closingBalancesAtMonthEnd — the
// per-account walkback that powers the monthly report's closing-
// balance table.
//
// Contracts pinned here:
//   * an account with zero post-close activity reports its
//     current_balance unchanged;
//   * each post-close transaction's signed amount is subtracted
//     (credits walk the balance DOWN to the past, debits walk it UP)
//     so the math goes the right direction;
//   * transfer legs are NOT excluded from the walkback — each leg
//     genuinely moves money between accounts, and skipping them
//     would mis-report both sides;
//   * rows sort by |balance| descending so a $500k mortgage outranks
//     a $1k checking balance even though the mortgage is negative;
//   * an account not referenced by any transaction still appears in
//     the output (a household that didn't touch its 529 plan last
//     month still has a 529 balance worth showing).

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/accounts/models/account.dart';
import 'package:mybudget/features/reports/services/closing_balances.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';

Account _acct({
  required String id,
  required String name,
  required int balance,
  AccountType type = AccountType.checking,
}) {
  final ts = DateTime(2026, 1, 1);
  return Account(
    id: id,
    householdId: 'h',
    ownerUserId: 'u',
    name: name,
    accountType: type,
    currency: 'USD',
    startingBalance: 0,
    currentBalance: balance,
    isActive: true,
    createdAt: ts,
    updatedAt: ts,
  );
}

Transaction _tx({
  required String accountId,
  required int amount,
  required DateTime date,
  String id = 't',
  String? transferId,
}) {
  final ts = DateTime(2026, 1, 1);
  return Transaction(
    id: id,
    householdId: 'h',
    accountId: accountId,
    amount: amount,
    currency: 'USD',
    description: 'desc',
    transactionDate: date,
    pending: false,
    source: 'manual',
    createdAt: ts,
    updatedAt: ts,
    transferId: transferId,
  );
}

void main() {
  final monthEnd = DateTime.utc(2026, 4, 30);
  final mayDay = DateTime.utc(2026, 5, 5);

  group('closingBalancesAtMonthEnd', () {
    test('no post-close activity → current_balance unchanged', () {
      final result = closingBalancesAtMonthEnd(
        accounts: [
          _acct(id: 'chk', name: 'Checking', balance: 250000),
        ],
        transactionsAfterClose: const [],
        closingAsOf: monthEnd,
      );
      expect(result, hasLength(1));
      expect(result.single.balanceCents, 250000);
    });

    test('post-close debit walks balance UP into the past', () {
      // Today's $2,500 balance after a $500 grocery debit in May
      // means the April-30 balance was $3,000.
      final result = closingBalancesAtMonthEnd(
        accounts: [_acct(id: 'chk', name: 'Checking', balance: 250000)],
        transactionsAfterClose: [
          _tx(accountId: 'chk', amount: -50000, date: mayDay),
        ],
        closingAsOf: monthEnd,
      );
      expect(
        result.single.balanceCents,
        300000,
        reason:
            'undoing a -\$500 debit moves the balance from \$2,500 back '
            'to \$3,000 — subtracting a negative amount adds.',
      );
    });

    test('post-close credit walks balance DOWN into the past', () {
      // Today's $3,000 balance after a $500 payday credit in May
      // means the April-30 balance was $2,500.
      final result = closingBalancesAtMonthEnd(
        accounts: [_acct(id: 'chk', name: 'Checking', balance: 300000)],
        transactionsAfterClose: [
          _tx(accountId: 'chk', amount: 50000, date: mayDay),
        ],
        closingAsOf: monthEnd,
      );
      expect(result.single.balanceCents, 250000);
    });

    test('transfer legs ARE included in the walkback', () {
      // A $500 Checking → Savings transfer dated May 1 means:
      //   * checking lost $500 in May → April-30 balance was $500 higher
      //   * savings gained $500 in May → April-30 balance was $500 lower
      // Excluding transfer legs (the way the dashboard income/
      // expense math does) would mis-report both sides.
      final result = closingBalancesAtMonthEnd(
        accounts: [
          _acct(id: 'chk', name: 'Checking', balance: 100000),
          _acct(id: 'sav', name: 'Savings', balance: 600000),
        ],
        transactionsAfterClose: [
          _tx(
            accountId: 'chk',
            amount: -50000,
            date: mayDay,
            id: 'leg-out',
            transferId: 'X',
          ),
          _tx(
            accountId: 'sav',
            amount: 50000,
            date: mayDay,
            id: 'leg-in',
            transferId: 'X',
          ),
        ],
        closingAsOf: monthEnd,
      );
      final byName = {for (final r in result) r.accountName: r.balanceCents};
      expect(byName['Checking'], 150000);
      expect(byName['Savings'], 550000);
    });

    test('rows sort by |balance| descending — biggest position first', () {
      // A negative mortgage outweighs a positive checking when the
      // user is scanning the table for "where does the money live."
      final result = closingBalancesAtMonthEnd(
        accounts: [
          _acct(id: 'chk', name: 'Checking', balance: 100000),
          _acct(
            id: 'mort',
            name: 'Mortgage',
            balance: -50000000, // -$500k
            type: AccountType.mortgage,
          ),
          _acct(id: 'sav', name: 'Savings', balance: 500000),
        ],
        transactionsAfterClose: const [],
        closingAsOf: monthEnd,
      );
      expect(
        result.map((r) => r.accountName),
        ['Mortgage', 'Savings', 'Checking'],
      );
    });

    test('accounts with no post-close activity still appear', () {
      // A 529 plan with no May activity still has an April-30
      // balance worth showing.
      final result = closingBalancesAtMonthEnd(
        accounts: [
          _acct(id: 'chk', name: 'Checking', balance: 100000),
          _acct(
            id: '529',
            name: '529 Plan',
            balance: 5000000,
            type: AccountType.college529,
          ),
        ],
        transactionsAfterClose: [
          // Only touches checking.
          _tx(accountId: 'chk', amount: -1000, date: mayDay),
        ],
        closingAsOf: monthEnd,
      );
      final names = result.map((r) => r.accountName).toSet();
      expect(names, containsAll(['Checking', '529 Plan']));
    });
  });
}
