// Tests for DashboardData's derived getters: net worth, monthly aggregates,
// top categories, and the 30-day spending sparkline.
//
// Critically, after the migration to a signed-balance convention, net worth
// is just a plain SUM of currentBalance — these tests pin that contract so
// the credit-card-and-mortgage debt is correctly subtracted.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/accounts/models/account.dart';
import 'package:mybudget/features/dashboard/providers/dashboard_provider.dart';
import 'package:mybudget/features/transactions/models/category.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';

Account _account({
  required String id,
  required AccountType type,
  required int balance,
  int starting = 0,
}) {
  final ts = DateTime(2026, 1, 1);
  return Account(
    id: id,
    householdId: 'h',
    ownerUserId: 'u',
    name: id,
    accountType: type,
    currency: 'USD',
    startingBalance: starting,
    currentBalance: balance,
    isActive: true,
    createdAt: ts,
    updatedAt: ts,
  );
}

Transaction _tx({
  required int amount,
  required DateTime date,
  Category? category,
  String id = 't',
}) {
  final ts = DateTime(2026, 1, 1);
  return Transaction(
    id: id,
    householdId: 'h',
    accountId: 'a',
    amount: amount,
    currency: 'USD',
    description: 'desc',
    transactionDate: date,
    pending: false,
    source: 'manual',
    createdAt: ts,
    updatedAt: ts,
    // topCategories groups by categoryId (not by the joined object), so
    // mirror the live wire format where both fields agree.
    categoryId: category?.id,
    category: category,
  );
}

void main() {
  group('netWorth', () {
    test('plain sum of all signed balances', () {
      final data = DashboardData(
        accounts: [
          _account(id: 'checking', type: AccountType.checking, balance: 100000),
          _account(id: 'savings', type: AccountType.savings, balance: 500000),
        ],
        recentTransactions30d: const [],
        recentTransactions: const [],
      );
      expect(data.netWorth, 600000); // $6,000.00
    });

    test('subtracts credit-card debt (stored as negative cents)', () {
      final data = DashboardData(
        accounts: [
          _account(id: 'checking', type: AccountType.checking, balance: 100000),
          _account(
              id: 'card', type: AccountType.creditCard, balance: -50000),
        ],
        recentTransactions30d: const [],
        recentTransactions: const [],
      );
      expect(data.netWorth, 50000); // $500.00
    });

    test('subtracts mortgage balance (stored as negative cents)', () {
      // Regression: previously the dashboard ignored mortgages and
      // reported them as assets, inflating net worth.
      final data = DashboardData(
        accounts: [
          _account(id: 'checking', type: AccountType.checking, balance: 200000),
          _account(
              id: 'mortgage',
              type: AccountType.mortgage,
              balance: -30000000),
        ],
        recentTransactions30d: const [],
        recentTransactions: const [],
      );
      expect(data.netWorth, -29800000);
    });

    test('returns 0 for an empty account list', () {
      const data = DashboardData(
        accounts: [],
        recentTransactions30d: [],
        recentTransactions: [],
      );
      expect(data.netWorth, 0);
    });
  });

  group('monthlySpending and monthlyIncome', () {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final lastMonth = monthStart.subtract(const Duration(days: 5));

    test('spend sums absolute value of debits in the current month', () {
      final data = DashboardData(
        accounts: const [],
        recentTransactions30d: [
          _tx(amount: -1500, date: monthStart, id: 'a'),
          _tx(amount: -2500, date: monthStart, id: 'b'),
          _tx(amount: 1000, date: monthStart, id: 'c'), // income, ignored
        ],
        recentTransactions: const [],
      );
      expect(data.monthlySpending, 4000);
    });

    test('income sums positive transactions only', () {
      final data = DashboardData(
        accounts: const [],
        recentTransactions30d: [
          _tx(amount: 500000, date: monthStart, id: 'a'),
          _tx(amount: -1000, date: monthStart, id: 'b'), // debit, ignored
        ],
        recentTransactions: const [],
      );
      expect(data.monthlyIncome, 500000);
    });

    test('excludes transactions before the first of the month', () {
      final data = DashboardData(
        accounts: const [],
        recentTransactions30d: [
          _tx(amount: -1000, date: lastMonth, id: 'old'),
          _tx(amount: -500, date: monthStart, id: 'new'),
        ],
        recentTransactions: const [],
      );
      expect(data.monthlySpending, 500);
    });
  });

  group('topCategories', () {
    Category cat(String id, String name) => Category(
          id: id,
          name: name,
          isIncome: false,
          sortOrder: 0,
        );

    test('groups by category and sorts by total descending', () {
      final groceries = cat('g', 'Groceries');
      final gas = cat('p', 'Gas');
      final monthStart =
          DateTime(DateTime.now().year, DateTime.now().month, 1);

      final data = DashboardData(
        accounts: const [],
        recentTransactions30d: [
          _tx(amount: -2000, date: monthStart, category: groceries, id: '1'),
          _tx(amount: -3000, date: monthStart, category: groceries, id: '2'),
          _tx(amount: -1500, date: monthStart, category: gas, id: '3'),
        ],
        recentTransactions: const [],
      );
      final top = data.topCategories;
      expect(top, hasLength(2));
      expect(top.first.name, 'Groceries');
      expect(top.first.totalCents, 5000);
      expect(top.last.name, 'Gas');
      expect(top.last.totalCents, 1500);
    });

    test('groups uncategorised debits under "Uncategorized"', () {
      final monthStart =
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      final data = DashboardData(
        accounts: const [],
        recentTransactions30d: [
          _tx(amount: -1234, date: monthStart, id: '1'),
        ],
        recentTransactions: const [],
      );
      expect(data.topCategories.first.name, 'Uncategorized');
    });

    test('limits result to 5 entries', () {
      final monthStart =
          DateTime(DateTime.now().year, DateTime.now().month, 1);
      final txs = List.generate(
        7,
        (i) => _tx(
          amount: -((i + 1) * 100),
          date: monthStart,
          category: cat('c$i', 'Cat $i'),
          id: 't$i',
        ),
      );
      final data = DashboardData(
        accounts: const [],
        recentTransactions30d: txs,
        recentTransactions: const [],
      );
      expect(data.topCategories, hasLength(5));
    });
  });

  group('spendingByDay', () {
    test('places each debit in its days-ago bucket', () {
      final today = DateTime.now();
      final data = DashboardData(
        accounts: const [],
        recentTransactions30d: [
          _tx(
              amount: -1000,
              date: DateTime(today.year, today.month, today.day),
              id: 'today'),
          _tx(
              amount: -500,
              date: DateTime(today.year, today.month, today.day)
                  .subtract(const Duration(days: 5)),
              id: '5d'),
        ],
        recentTransactions: const [],
      );
      final buckets = data.spendingByDay;
      expect(buckets, hasLength(30));
      expect(buckets[29], 1000); // today
      expect(buckets[24], 500); // 5 days ago
    });

    test('ignores positive transactions (income)', () {
      final today = DateTime.now();
      final data = DashboardData(
        accounts: const [],
        recentTransactions30d: [
          _tx(
              amount: 50000,
              date: DateTime(today.year, today.month, today.day),
              id: 'income'),
        ],
        recentTransactions: const [],
      );
      expect(data.spendingByDay[29], 0);
    });

    test('ignores debits older than 30 days', () {
      final today = DateTime.now();
      final data = DashboardData(
        accounts: const [],
        recentTransactions30d: [
          _tx(
              amount: -1000,
              date: DateTime(today.year, today.month, today.day)
                  .subtract(const Duration(days: 45)),
              id: 'old'),
        ],
        recentTransactions: const [],
      );
      expect(data.spendingByDay.every((b) => b == 0), isTrue);
    });
  });
}
