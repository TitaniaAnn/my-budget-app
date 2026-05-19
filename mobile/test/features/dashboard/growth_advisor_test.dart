// Unit tests for [GrowthAdvisor] and its rules. Pure Dart — no
// Supabase, no widget tree. Each rule is exercised in isolation via
// [GrowthAdvisor(rules: [...])] so a regression in one doesn't
// cascade into others' assertions.
//
// The rules read [DashboardData] which exposes monthlySpending as a
// computed getter over transactions in the current calendar month.
// Tests construct transactions dated `DateTime.now()` so they always
// land inside that window, regardless of when the suite runs.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/accounts/models/account.dart';
import 'package:mybudget/features/dashboard/providers/dashboard_provider.dart';
import 'package:mybudget/features/dashboard/services/growth_advisor.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';

DateTime _now() => DateTime.now();

Account _account({
  required AccountType type,
  required int currentBalance,
  double? interestRate,
  bool isActive = true,
  String name = 'Test account',
}) {
  return Account(
    id: 'a-${type.dbValue}-$currentBalance',
    householdId: 'h',
    ownerUserId: 'u',
    name: name,
    accountType: type,
    currency: 'USD',
    currentBalance: currentBalance,
    isActive: isActive,
    interestRate: interestRate,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

Transaction _tx({required int amountCents, required DateTime date}) {
  return Transaction(
    id: 'tx-$amountCents-${date.microsecondsSinceEpoch}',
    householdId: 'h',
    accountId: 'a',
    amount: amountCents,
    currency: 'USD',
    description: 'TEST',
    transactionDate: date,
    pending: false,
    source: 'manual',
    createdAt: date,
    updatedAt: date,
  );
}

/// Builds DashboardData such that monthlySpending equals [spendCents].
/// Spending is "expenses only, as positive cents" so the test seeds a
/// single negative-amount transaction with the desired magnitude.
DashboardData _data({
  required List<Account> accounts,
  required int spendCents,
  int ytdRothContributionsCents = 0,
}) {
  final txs = spendCents > 0
      ? [_tx(amountCents: -spendCents, date: _now())]
      : <Transaction>[];
  return DashboardData(
    accounts: accounts,
    recentTransactions30d: txs,
    recentTransactions: txs,
    ytdRothContributionsCents: ytdRothContributionsCents,
  );
}

void main() {
  group('EmergencyFundRule', () {
    test('fires a warning when liquid covers fewer than 3 months', () {
      // $1,000 liquid against $500/month spending → 2 months.
      final data = _data(
        accounts: [
          _account(type: AccountType.checking, currentBalance: 100000),
        ],
        spendCents: 50000,
      );
      final s = const EmergencyFundRule().evaluate(data);
      expect(s, isNotNull);
      expect(s!.severity, SuggestionSeverity.warning);
      expect(s.id, 'emergency_fund');
      expect(s.detail, contains('2.0 months'));
    });

    test('stays silent at exactly 3 months of coverage', () {
      // The rule must use `>= 3` as the silence threshold so the
      // industry boundary ("3–6") isn't flagged on its lower edge.
      final data = _data(
        accounts: [_account(type: AccountType.savings, currentBalance: 150000)],
        spendCents: 50000,
      );
      expect(const EmergencyFundRule().evaluate(data), isNull);
    });

    test('stays silent when monthly spending is zero', () {
      // Brand-new household with no transactions — we can't compute
      // a months-of-spending ratio, so no suggestion. Otherwise the
      // rule would imply every dollar saved is "1 month of coverage"
      // and never fire, OR divide by zero. Easier to gate up front.
      final data = _data(
        accounts: [_account(type: AccountType.checking, currentBalance: 50000)],
        spendCents: 0,
      );
      expect(const EmergencyFundRule().evaluate(data), isNull);
    });

    test('ignores inactive banking accounts', () {
      // The inactive checking would push coverage over 3 months if
      // counted; the rule must skip it and still flag the gap.
      final data = _data(
        accounts: [
          _account(
            type: AccountType.checking,
            currentBalance: 100000,
            isActive: false,
          ),
          _account(type: AccountType.savings, currentBalance: 50000),
        ],
        spendCents: 50000,
      );
      final s = const EmergencyFundRule().evaluate(data);
      expect(s, isNotNull, reason: 'inactive accounts must not count.');
    });

    test('ignores non-banking accounts', () {
      // Brokerage / IRA / 401k are not liquid emergency funds — the
      // rule must exclude them even when their balances are large.
      final data = _data(
        accounts: [
          _account(type: AccountType.brokerage, currentBalance: 1000000),
          _account(type: AccountType.checking, currentBalance: 50000),
        ],
        spendCents: 50000,
      );
      final s = const EmergencyFundRule().evaluate(data);
      expect(
        s,
        isNotNull,
        reason: 'brokerage holdings must not satisfy emergency fund.',
      );
    });
  });

  group('CreditCardCarryRule', () {
    test('fires when a card carries at >= 10% APR', () {
      // $2,000 carried at 22% APR.
      final data = _data(
        accounts: [
          _account(
            type: AccountType.creditCard,
            currentBalance: -200000,
            interestRate: 0.22,
            name: 'Visa',
          ),
        ],
        spendCents: 100000,
      );
      final s = const CreditCardCarryRule().evaluate(data);
      expect(s, isNotNull);
      expect(s!.severity, SuggestionSeverity.warning);
      expect(s.title, contains('22.0%'));
      expect(s.detail, contains('Visa'));
      expect(s.detail, contains(r'$2,000'));
    });

    test('stays silent when APR is below 10%', () {
      // Promotional 0% balance transfer — not what this rule flags.
      final data = _data(
        accounts: [
          _account(
            type: AccountType.creditCard,
            currentBalance: -500000,
            interestRate: 0.0,
          ),
        ],
        spendCents: 100000,
      );
      expect(const CreditCardCarryRule().evaluate(data), isNull);
    });

    test('stays silent when balance is zero or paid in full', () {
      // Card is active and high APR, but nothing is being carried.
      final data = _data(
        accounts: [
          _account(
            type: AccountType.creditCard,
            currentBalance: 0,
            interestRate: 0.22,
          ),
        ],
        spendCents: 100000,
      );
      expect(const CreditCardCarryRule().evaluate(data), isNull);
    });

    test('picks the biggest balance when multiple cards carry', () {
      // The advisor surfaces one suggestion at a time so the user
      // sees the highest-leverage one first.
      final data = _data(
        accounts: [
          _account(
            type: AccountType.creditCard,
            currentBalance: -50000,
            interestRate: 0.18,
            name: 'Small card',
          ),
          _account(
            type: AccountType.creditCard,
            currentBalance: -500000,
            interestRate: 0.18,
            name: 'Big card',
          ),
        ],
        spendCents: 100000,
      );
      final s = const CreditCardCarryRule().evaluate(data);
      expect(s, isNotNull);
      expect(
        s!.detail,
        contains('Big card'),
        reason:
            'when multiple cards carry, the rule must surface the '
            'larger balance — that\'s the highest-leverage one.',
      );
    });

    test('ignores credit cards with no interest_rate set', () {
      // Some accounts don't record an interest rate; the rule must
      // tolerate that rather than crashing or treating null as zero.
      final data = _data(
        accounts: [
          _account(
            type: AccountType.creditCard,
            currentBalance: -200000,
            interestRate: null,
          ),
        ],
        spendCents: 100000,
      );
      expect(const CreditCardCarryRule().evaluate(data), isNull);
    });
  });

  group('RothIraUnderusedRule', () {
    test('fires when a Roth IRA exists and YTD < the annual limit', () {
      // $3,000 contributed against the $7,000 limit → $4,000 gap.
      final data = _data(
        accounts: [
          _account(type: AccountType.iraRoth, currentBalance: 1500000),
        ],
        spendCents: 100000,
        ytdRothContributionsCents: 300000,
      );
      final s = const RothIraUnderusedRule().evaluate(data);
      expect(s, isNotNull);
      expect(s!.severity, SuggestionSeverity.opportunity);
      expect(s.id, 'roth_ira_underused');
      // Detail must surface both the headline numbers so the user
      // doesn't have to open the account to know the gap.
      expect(s.detail, contains(r'$3,000'));
      expect(s.detail, contains(r'$7,000'));
      expect(s.detail, contains(r'$4,000'));
    });

    test('stays silent when the household has no Roth IRA account', () {
      // No Roth → nothing to suggest. The rule must not fire just
      // because contributions are at zero — that would always fire
      // for households that don't use this account type at all.
      final data = _data(
        accounts: [
          _account(type: AccountType.brokerage, currentBalance: 5000000),
          _account(type: AccountType.iraTraditional, currentBalance: 5000000),
        ],
        spendCents: 100000,
        ytdRothContributionsCents: 0,
      );
      expect(const RothIraUnderusedRule().evaluate(data), isNull);
    });

    test('stays silent when contributions are at or above the limit', () {
      // Already maxed — silent. Even slightly over (50+ catch-up
      // territory) shouldn't emit a warning we can't act on.
      for (final ytd in [
        RothIraUnderusedRule.annualLimitCents,
        RothIraUnderusedRule.annualLimitCents + 100000,
      ]) {
        final data = _data(
          accounts: [
            _account(type: AccountType.iraRoth, currentBalance: 1500000),
          ],
          spendCents: 100000,
          ytdRothContributionsCents: ytd,
        );
        expect(
          const RothIraUnderusedRule().evaluate(data),
          isNull,
          reason: 'YTD=$ytd cents should be considered maxed.',
        );
      }
    });

    test('ignores inactive Roth IRA accounts', () {
      // A closed/archived Roth doesn't qualify — the user has
      // signalled they're no longer using it, so nagging about
      // unused contribution room would be noise.
      final data = _data(
        accounts: [
          _account(
            type: AccountType.iraRoth,
            currentBalance: 0,
            isActive: false,
          ),
        ],
        spendCents: 100000,
        ytdRothContributionsCents: 0,
      );
      expect(const RothIraUnderusedRule().evaluate(data), isNull);
    });
  });

  group('IdleCashRule', () {
    test('fires an opportunity when cash exceeds 12 months of spend', () {
      // $20,000 cash against $1,000/month → 20 months.
      final data = _data(
        accounts: [
          _account(type: AccountType.savings, currentBalance: 2000000),
        ],
        spendCents: 100000,
      );
      final s = const IdleCashRule().evaluate(data);
      expect(s, isNotNull);
      expect(s!.severity, SuggestionSeverity.opportunity);
      expect(s.detail, contains(r'$20,000'));
    });

    test('stays silent at exactly 12 months of coverage', () {
      // The threshold is "> 12", not "≥ 12" — 12 months exactly is
      // still inside the comfortable cushion range.
      final data = _data(
        accounts: [
          _account(type: AccountType.checking, currentBalance: 1200000),
        ],
        spendCents: 100000,
      );
      expect(const IdleCashRule().evaluate(data), isNull);
    });

    test('stays silent when monthly spending is zero', () {
      final data = _data(
        accounts: [
          _account(type: AccountType.savings, currentBalance: 5000000),
        ],
        spendCents: 0,
      );
      expect(const IdleCashRule().evaluate(data), isNull);
    });
  });

  group('GrowthAdvisor.evaluate', () {
    test('returns suggestions in rule order', () {
      // Construct a scenario where both EmergencyFund and
      // CreditCardCarry fire — the defaultRules list has them in
      // that order, so the suggestion list should mirror it.
      final data = _data(
        accounts: [
          _account(type: AccountType.checking, currentBalance: 50000),
          _account(
            type: AccountType.creditCard,
            currentBalance: -200000,
            interestRate: 0.22,
          ),
        ],
        spendCents: 100000,
      );
      final ids = const GrowthAdvisor()
          .evaluate(data)
          .map((s) => s.id)
          .toList();
      expect(ids, ['emergency_fund', 'credit_card_carry']);
    });

    test('returns empty when no rule fires', () {
      // A household with healthy cash, no credit card, no idle excess.
      // $5,000 against $1,000/month → 5 months coverage. Not flagged.
      final data = _data(
        accounts: [_account(type: AccountType.savings, currentBalance: 500000)],
        spendCents: 100000,
      );
      expect(const GrowthAdvisor().evaluate(data), isEmpty);
    });
  });
}
