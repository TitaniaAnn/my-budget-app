// Pure-function tests for evaluateNotifications — the engine that
// decides what local notifications fire on each dashboard load.
//
// Contracts pinned:
//   * master toggle off → empty list regardless of triggers;
//   * per-trigger toggles silence one kind without affecting the
//     other;
//   * dedup honors keys in lastFiredByKey (so a previously-fired
//     event doesn't spam on every pass);
//   * budget-over key is namespaced by period so a NEW period of
//     the same budget fires again;
//   * large-tx is gated on a 24-hour created_at window so a fresh
//     install doesn't dump months of historical notifications;
//   * transfer legs and below-threshold tx don't trigger;
//   * budget-over has a $1 noise floor so $0.01-over edge cases
//     don't fire.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/budget/models/budget.dart';
import 'package:mybudget/features/budget/providers/budget_provider.dart';
import 'package:mybudget/features/notifications/models/notification_settings.dart';
import 'package:mybudget/features/notifications/services/notification_engine.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';

BudgetWithSpending _bws({
  String id = 'b1',
  required int budgetCents,
  required int spentCents,
  DateTime? periodFrom,
  DateTime? periodTo,
  String categoryName = 'Groceries',
}) {
  final from = periodFrom ?? DateTime(2026, 5, 1);
  final to = periodTo ?? DateTime(2026, 5, 31);
  return BudgetWithSpending(
    budget: Budget(
      id: id,
      householdId: 'h',
      categoryId: 'c',
      amount: budgetCents,
      period: BudgetPeriod.monthly,
      startDate: from,
      createdBy: 'u',
    ),
    spentCents: spentCents,
    projectedCents: spentCents,
    periodFrom: from,
    periodTo: to,
    categoryName: categoryName,
    categoryColor: null,
    categoryIcon: null,
    // Single-currency default — the notification engine doesn't
    // exercise the multi-currency conversion path directly; it
    // sees the already-converted spent + cap from upstream.
    capCents: budgetCents,
  );
}

Transaction _tx({
  required int amount,
  String id = 't1',
  String merchant = 'Costco',
  String? transferId,
  DateTime? createdAt,
}) {
  final ts = createdAt ?? DateTime(2026, 5, 20, 12);
  return Transaction(
    id: id,
    householdId: 'h',
    accountId: 'a',
    amount: amount,
    currency: 'USD',
    description: 'desc',
    merchant: merchant,
    transactionDate: ts,
    pending: false,
    source: 'manual',
    createdAt: ts,
    updatedAt: ts,
    transferId: transferId,
  );
}

void main() {
  // Anchor "now" so the 24-hour large-tx window is deterministic.
  final now = DateTime(2026, 5, 20, 18);

  group('evaluateNotifications — master toggle', () {
    test('returns empty when settings.enabled is false', () {
      final result = evaluateNotifications(
        settings: const NotificationSettings(enabled: false),
        budgets: [_bws(budgetCents: 10000, spentCents: 50000)],
        recentTransactions: [_tx(amount: -50000, createdAt: now)],
        lastFiredByKey: const {},
        now: now,
      );
      expect(
        result,
        isEmpty,
        reason: 'master toggle off must short-circuit everything — that\'s '
            'the "silence in one tap" promise.',
      );
    });
  });

  group('evaluateNotifications — budget over', () {
    test('fires when actual > budget and the per-trigger toggle is on', () {
      final result = evaluateNotifications(
        settings: const NotificationSettings(enabled: true),
        budgets: [_bws(budgetCents: 10000, spentCents: 15000)],
        recentTransactions: const [],
        lastFiredByKey: const {},
        now: now,
      );
      expect(result, hasLength(1));
      expect(result.single.title, contains('Over budget'));
      expect(result.single.body, contains(r'$50.00 over'));
    });

    test('per-trigger toggle silences ONLY the budget-over path', () {
      final result = evaluateNotifications(
        settings: const NotificationSettings(
          enabled: true,
          budgetOverEnabled: false,
          // largeTxEnabled defaults true — verify large-tx still fires.
        ),
        budgets: [_bws(budgetCents: 10000, spentCents: 15000)],
        recentTransactions: [
          _tx(amount: -50000, id: 'large', createdAt: now),
        ],
        lastFiredByKey: const {},
        now: now,
      );
      // Only the large-tx notification — budget-over is muted.
      expect(result.map((n) => n.key), [contains('large_tx')]);
    });

    test('a budget at exactly the limit does NOT fire', () {
      final result = evaluateNotifications(
        settings: const NotificationSettings(enabled: true),
        budgets: [_bws(budgetCents: 10000, spentCents: 10000)],
        recentTransactions: const [],
        lastFiredByKey: const {},
        now: now,
      );
      expect(
        result,
        isEmpty,
        reason: 'isOverBudget is strict — spent must EXCEED amount, '
            'not equal it. Hitting the cap exactly is on-budget.',
      );
    });

    test(r'$1 noise floor: a $0.01-over budget does NOT fire', () {
      final result = evaluateNotifications(
        settings: const NotificationSettings(enabled: true),
        budgets: [_bws(budgetCents: 10000, spentCents: 10001)],
        recentTransactions: const [],
        lastFiredByKey: const {},
        now: now,
      );
      expect(
        result,
        isEmpty,
        reason: 'a one-cent rounding miss isn\'t worth a notification; '
            'the floor avoids spamming on the kind of edge that comes '
            'from refund-then-recharge events.',
      );
    });

    test('dedup: a previously-fired budget+period key is skipped', () {
      // Same budget, same period — lastFiredByKey says we already
      // fired earlier today. Must not re-fire.
      final periodFrom = DateTime(2026, 5, 1);
      final result = evaluateNotifications(
        settings: const NotificationSettings(enabled: true),
        budgets: [
          _bws(
            id: 'b1',
            budgetCents: 10000,
            spentCents: 15000,
            periodFrom: periodFrom,
          ),
        ],
        recentTransactions: const [],
        lastFiredByKey: {
          'budget_over:b1:2026-05-01': now.subtract(const Duration(hours: 2)),
        },
        now: now,
      );
      expect(result, isEmpty);
    });

    test('a new period of the same budget DOES fire again', () {
      // June 1 period — different period_from from May 1, so a
      // distinct key.
      final result = evaluateNotifications(
        settings: const NotificationSettings(enabled: true),
        budgets: [
          _bws(
            id: 'b1',
            budgetCents: 10000,
            spentCents: 15000,
            periodFrom: DateTime(2026, 6, 1),
            periodTo: DateTime(2026, 6, 30),
          ),
        ],
        recentTransactions: const [],
        // May's already-fired entry must NOT mask June's.
        lastFiredByKey: {
          'budget_over:b1:2026-05-01': DateTime(2026, 5, 5),
        },
        now: DateTime(2026, 6, 10),
      );
      expect(result, hasLength(1));
      expect(result.single.key, 'budget_over:b1:2026-06-01');
    });
  });

  group('evaluateNotifications — large transaction', () {
    test('fires for |amount| >= threshold within the recent window', () {
      final result = evaluateNotifications(
        settings: const NotificationSettings(
          enabled: true,
          largeTxThresholdCents: 20000,
        ),
        budgets: const [],
        recentTransactions: [
          _tx(amount: -25000, id: 't1', merchant: 'Costco', createdAt: now),
        ],
        lastFiredByKey: const {},
        now: now,
      );
      expect(result, hasLength(1));
      expect(result.single.body, contains('Costco'));
      expect(result.single.body, contains(r'-$250.00'));
    });

    test('below-threshold tx does not fire', () {
      final result = evaluateNotifications(
        settings: const NotificationSettings(
          enabled: true,
          largeTxThresholdCents: 20000,
        ),
        budgets: const [],
        recentTransactions: [_tx(amount: -19999, createdAt: now)],
        lastFiredByKey: const {},
        now: now,
      );
      expect(result, isEmpty);
    });

    test('transfer legs are excluded even when above threshold', () {
      // A $500 checking → savings transfer would otherwise trip the
      // large-tx rule and scare the user about money they meant to
      // move. Transfer legs are pure cash movement, not spending.
      final result = evaluateNotifications(
        settings: const NotificationSettings(
          enabled: true,
          largeTxThresholdCents: 20000,
        ),
        budgets: const [],
        recentTransactions: [
          _tx(amount: -50000, id: 't1', transferId: 'X', createdAt: now),
        ],
        lastFiredByKey: const {},
        now: now,
      );
      expect(result, isEmpty);
    });

    test(
      'old transactions (outside the 24h window) do NOT fire — fresh-install '
      'grace',
      () {
        final result = evaluateNotifications(
          settings: const NotificationSettings(
            enabled: true,
            largeTxThresholdCents: 20000,
          ),
          budgets: const [],
          recentTransactions: [
            _tx(
              amount: -50000,
              id: 't1',
              // 2 days ago. Outside the 24h created_at gate.
              createdAt: now.subtract(const Duration(days: 2)),
            ),
          ],
          lastFiredByKey: const {},
          now: now,
        );
        expect(
          result,
          isEmpty,
          reason: 'without this gate a fresh install with months of '
              'imported history would fire dozens of notifications in '
              'a single dashboard load.',
        );
      },
    );

    test('dedup: a previously-fired tx id is skipped', () {
      final result = evaluateNotifications(
        settings: const NotificationSettings(
          enabled: true,
          largeTxThresholdCents: 20000,
        ),
        budgets: const [],
        recentTransactions: [_tx(amount: -50000, id: 't1', createdAt: now)],
        lastFiredByKey: {
          'large_tx:t1': now.subtract(const Duration(hours: 1)),
        },
        now: now,
      );
      expect(result, isEmpty);
    });

    test('positive (income) large transactions also fire', () {
      // A $5,000 paycheck deposit is just as worth surfacing as a
      // $5,000 outflow — the user might want to know an unusual
      // inflow landed (or that a customer paid them).
      final result = evaluateNotifications(
        settings: const NotificationSettings(
          enabled: true,
          largeTxThresholdCents: 20000,
        ),
        budgets: const [],
        recentTransactions: [
          _tx(amount: 500000, id: 'income', merchant: 'Employer', createdAt: now),
        ],
        lastFiredByKey: const {},
        now: now,
      );
      expect(result, hasLength(1));
      expect(result.single.body, contains(r'+$5000.00'));
    });
  });
}
