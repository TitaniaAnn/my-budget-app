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

int _txCounter = 0;

Transaction _tx({
  required int amountCents,
  required DateTime date,
  String? merchant,
  String description = 'TEST',
  String currency = 'USD',
  String accountId = 'a',
  String? transferId,
}) {
  // Monotonic counter so multiple test rows sharing a date still get
  // unique ids — the rule under test groups by merchant + month, but
  // having duplicate ids in a List<Transaction> is a footgun the
  // dashboard's downstream getters could hit.
  _txCounter += 1;
  return Transaction(
    id: 'tx-$_txCounter',
    householdId: 'h',
    accountId: accountId,
    amount: amountCents,
    currency: currency,
    description: description,
    merchant: merchant,
    transactionDate: date,
    pending: false,
    source: 'manual',
    createdAt: date,
    updatedAt: date,
    transferId: transferId,
  );
}

/// Builds DashboardData such that monthlySpending equals [spendCents].
/// Spending is "expenses only, as positive cents" so the test seeds a
/// single negative-amount transaction with the desired magnitude.
DashboardData _data({
  required List<Account> accounts,
  required int spendCents,
  int ytdRothContributionsCents = 0,
  List<Transaction> extraTxs = const [],
}) {
  final txs = <Transaction>[
    if (spendCents > 0) _tx(amountCents: -spendCents, date: _now()),
    ...extraTxs,
  ];
  return DashboardData(
    accounts: accounts,
    recentTransactions90d: txs,
    recentTransactions: txs,
    ytdRothContributionsCents: ytdRothContributionsCents,
  );
}

/// Builds DashboardData with an arbitrary [recent90d] list — for
/// rules that read the transaction history rather than the derived
/// monthly-spend number.
DashboardData _dataWithTxs(List<Transaction> recent90d) {
  return DashboardData(
    accounts: const [],
    recentTransactions90d: recent90d,
    recentTransactions: const [],
  );
}

/// Date inside calendar month [m] months ago (0 = current). Mid-
/// month so the test doesn't accidentally straddle the month
/// boundary when run on the 1st or last day.
DateTime _monthsAgo(int m) {
  final now = DateTime.now();
  return DateTime(now.year, now.month - m, 15);
}

/// Builds DashboardData with an arbitrary monthly net-worth series.
/// The list is interpreted oldest-first per [DashboardData.monthlyNetWorth].
DashboardData _dataWithNetWorth(List<int> balancesByMonth) {
  final now = DateTime.now();
  final series = <({DateTime monthEnd, int balanceCents})>[];
  // balancesByMonth.first is the oldest month; .last is current.
  for (var i = 0; i < balancesByMonth.length; i++) {
    final monthsBack = balancesByMonth.length - 1 - i;
    final monthEnd = monthsBack == 0
        ? now
        // Last day of the target month.
        : DateTime(now.year, now.month - monthsBack + 1, 0);
    series.add((monthEnd: monthEnd, balanceCents: balancesByMonth[i]));
  }
  return DashboardData(
    accounts: const [],
    recentTransactions90d: const [],
    recentTransactions: const [],
    monthlyNetWorth: series,
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
      // Approximation flag: the user should know the number is
      // inclusive of dividend reinvestments, not strict IRS
      // contributions.
      expect(s.detail.toLowerCase(), contains('includes dividends'));
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

    test('still fires inside the dividend tolerance band', () {
      // The dashboard provider over-counts "contributions" because
      // dividend reinvestments look like positive transactions.
      // The rule's silence threshold is 1.5x the IRS limit so a
      // user with heavy dividends doesn't lose the nudge when they
      // haven't actually maxed out. YTD just past the strict limit
      // ($8,000 on the $7,000 cap) must still fire.
      final data = _data(
        accounts: [
          _account(type: AccountType.iraRoth, currentBalance: 1500000),
        ],
        spendCents: 100000,
        ytdRothContributionsCents:
            RothIraUnderusedRule.annualLimitCents + 100000,
      );
      final s = const RothIraUnderusedRule().evaluate(data);
      expect(
        s,
        isNotNull,
        reason:
            'YTD just past the strict limit must still fire — the rule '
            'gives a 1.5x tolerance band because contributions are '
            'over-counted by dividend reinvestments.',
      );
      // No negative dollar-amount in the text — gap is non-positive
      // here.
      expect(s!.detail, isNot(contains('-')));
    });

    test('stays silent only when contributions exceed 1.5x the limit', () {
      // Below the silence threshold: fire. At/above: silent.
      final fires = _data(
        accounts: [
          _account(type: AccountType.iraRoth, currentBalance: 1500000),
        ],
        spendCents: 100000,
        // Just under 1.5x ($10,499 on a $7,000 limit).
        ytdRothContributionsCents:
            (RothIraUnderusedRule.annualLimitCents * 1.5).round() - 100,
      );
      expect(const RothIraUnderusedRule().evaluate(fires), isNotNull);

      final silenced = _data(
        accounts: [
          _account(type: AccountType.iraRoth, currentBalance: 1500000),
        ],
        spendCents: 100000,
        ytdRothContributionsCents: (RothIraUnderusedRule.annualLimitCents * 1.5)
            .round(),
      );
      expect(
        const RothIraUnderusedRule().evaluate(silenced),
        isNull,
        reason:
            'at 1.5x the limit, even a heavy-dividend account is '
            'almost certainly maxed; further nudging would be noise.',
      );
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

  group('SubscriptionDriftRule', () {
    test('fires when current month recurring spend > 20% above prior avg', () {
      // "Spotify" $15 last month and 2 months ago, $30 this month
      // → 100% increase over a $15 prior-months average. Fires.
      final data = _dataWithTxs([
        _tx(amountCents: -1500, date: _monthsAgo(2), merchant: 'Spotify'),
        _tx(amountCents: -1500, date: _monthsAgo(1), merchant: 'Spotify'),
        _tx(amountCents: -3000, date: _monthsAgo(0), merchant: 'Spotify'),
      ]);
      final s = const SubscriptionDriftRule().evaluate(data);
      expect(s, isNotNull);
      expect(s!.severity, SuggestionSeverity.info);
      expect(s.id, 'subscription_drift');
      // Detail surfaces both numbers so the user doesn't have to do
      // mental math to know the magnitude.
      expect(s.detail, contains(r'$30'));
      expect(s.detail, contains(r'$15'));
      expect(s.detail, contains('100%'));
    });

    test('stays silent when growth is below the 20% threshold', () {
      // Steady $20 a month with a tiny $22 bump this month → 10%
      // increase. The rule should accept normal-noise variance and
      // not nag.
      final data = _dataWithTxs([
        _tx(amountCents: -2000, date: _monthsAgo(2), merchant: 'Spotify'),
        _tx(amountCents: -2000, date: _monthsAgo(1), merchant: 'Spotify'),
        _tx(amountCents: -2200, date: _monthsAgo(0), merchant: 'Spotify'),
      ]);
      expect(const SubscriptionDriftRule().evaluate(data), isNull);
    });

    test('ignores one-off merchants (not recurring)', () {
      // A single $500 purchase in the current month from a merchant
      // that never appeared before. Shouldn't trigger drift — it's
      // not a subscription pattern.
      final data = _dataWithTxs([
        _tx(amountCents: -2000, date: _monthsAgo(2), merchant: 'Spotify'),
        _tx(amountCents: -2000, date: _monthsAgo(1), merchant: 'Spotify'),
        _tx(amountCents: -2000, date: _monthsAgo(0), merchant: 'Spotify'),
        // One-off — flat $500 to a unique merchant.
        _tx(
          amountCents: -50000,
          date: _monthsAgo(0),
          merchant: 'BIG ONE-OFF PURCHASE',
        ),
      ]);
      // Recurring spend is steady ($20/$20/$20), one-off doesn't
      // count because it appears in only one month.
      expect(const SubscriptionDriftRule().evaluate(data), isNull);
    });

    test('stays silent when no prior months have recurring spend', () {
      // A merchant that just started appearing this month + last
      // month — two months total. Recurring? Yes. But prior to the
      // current month, only one month of history, which is the
      // baseline. The rule still needs a comparison so it goes by
      // that single prior month: $10 → $30 = 200% increase. Should
      // fire here, actually. Use a different shape: brand-new
      // recurring merchant that ONLY appears this month.
      final data = _dataWithTxs([
        _tx(amountCents: -1000, date: _monthsAgo(0), merchant: 'Spotify'),
        _tx(amountCents: -2000, date: _monthsAgo(0), merchant: 'Spotify'),
      ]);
      // Spotify only in current month — not recurring (only one
      // distinct month), no comparison possible. Silent.
      expect(const SubscriptionDriftRule().evaluate(data), isNull);
    });

    test('ignores positive-amount transactions (income / refunds)', () {
      // A refund credit shouldn't pull the "recurring spend"
      // baseline down or fake-trigger growth. The rule must filter
      // by sign.
      final data = _dataWithTxs([
        // Recurring expense baseline.
        _tx(amountCents: -2000, date: _monthsAgo(2), merchant: 'Spotify'),
        _tx(amountCents: -2000, date: _monthsAgo(1), merchant: 'Spotify'),
        _tx(amountCents: -2000, date: _monthsAgo(0), merchant: 'Spotify'),
        // Big positive transaction on a recurring merchant — must
        // be ignored, otherwise the rule would emit confusing
        // "spending crept up" suggestions on refund-heavy months.
        _tx(amountCents: 99999, date: _monthsAgo(0), merchant: 'Spotify'),
      ]);
      expect(const SubscriptionDriftRule().evaluate(data), isNull);
    });

    test('groups merchants case-insensitively', () {
      // "spotify" vs "Spotify" — same vendor as far as drift is
      // concerned. Without case-folding the rule would treat them
      // as separate merchants and miss the recurring signal.
      final data = _dataWithTxs([
        _tx(amountCents: -1500, date: _monthsAgo(2), merchant: 'spotify'),
        _tx(amountCents: -1500, date: _monthsAgo(1), merchant: 'SPOTIFY'),
        _tx(amountCents: -3000, date: _monthsAgo(0), merchant: 'Spotify'),
      ]);
      final s = const SubscriptionDriftRule().evaluate(data);
      expect(s, isNotNull);
    });

    test(
      'foreign-currency rows convert via ratesToDisplay before grouping',
      () {
        // €10 EUR Spotify for two months, then €20 EUR this month
        // at 1.10 → $11 baseline, $22 current. 100% growth, fires.
        // Without conversion the rule would compare raw 1000 cents
        // with display-currency rows and mis-grow the totals.
        final data = DashboardData(
          accounts: const [],
          recentTransactions: const [],
          recentTransactions90d: [
            _tx(
              amountCents: -1000,
              date: _monthsAgo(2),
              merchant: 'Spotify',
              currency: 'EUR',
            ),
            _tx(
              amountCents: -1000,
              date: _monthsAgo(1),
              merchant: 'Spotify',
              currency: 'EUR',
            ),
            _tx(
              amountCents: -2000,
              date: _monthsAgo(0),
              merchant: 'Spotify',
              currency: 'EUR',
            ),
          ],
          ratesToDisplay: const {'EUR': 1.10},
        );
        final s = const SubscriptionDriftRule().evaluate(data);
        expect(s, isNotNull);
        expect(s!.detail, contains('100%'));
      },
    );

    test('missing-rate rows are excluded from the drift comparison', () {
      // Spotify in EUR with no rate, plus Netflix in USD that
      // recurs but isn't growing. Without the exclusion the
      // EUR rows would mix into the recurring total at face
      // value and create phantom growth.
      final data = DashboardData(
        accounts: const [],
        recentTransactions: const [],
        recentTransactions90d: [
          _tx(
            amountCents: -10000,
            date: _monthsAgo(2),
            merchant: 'EU-Spotify',
            currency: 'EUR',
          ),
          _tx(
            amountCents: -10000,
            date: _monthsAgo(0),
            merchant: 'EU-Spotify',
            currency: 'EUR',
          ),
          _tx(amountCents: -1500, date: _monthsAgo(2), merchant: 'Netflix'),
          _tx(amountCents: -1500, date: _monthsAgo(0), merchant: 'Netflix'),
        ],
        // No EUR rate.
        ratesToDisplay: const {},
      );
      final s = const SubscriptionDriftRule().evaluate(data);
      expect(
        s,
        isNull,
        reason:
            'EU-Spotify rows are excluded for lack of rate; '
            'Netflix at \$15/month is steady, so no drift signal '
            'remains — the rule stays silent.',
      );
    });
  });

  group('NetWorthTrajectoryRule', () {
    test('fires INFO when the last 3 months sit below the rolling avg', () {
      // 8 months total — first 5 ramping up, last 3 dropping below
      // the 6-month rolling average. Numbers chosen so each of the
      // last 3 months is strictly less than the mean of its 6-
      // month window.
      final data = _dataWithNetWorth([
        100000, 105000, 110000, 115000, 120000, // ramp up
        105000, 100000, 95000, // 3-month decline
      ]);
      final s = const NetWorthTrajectoryRule().evaluate(data);
      expect(s, isNotNull);
      expect(s!.severity, SuggestionSeverity.info);
      expect(s.id, 'net_worth_trajectory');
      // Detail surfaces a dollar-amount gap so the user knows the
      // size of the drift, not just "trending down".
      expect(s.detail, contains(r'$'));
      expect(s.detail.toLowerCase(), contains('below'));
    });

    test('stays silent when only the most recent month is below avg', () {
      // 5 stable months, then a single dip. A one-month dip isn't
      // a trend — could be a renewal or a market wobble.
      final data = _dataWithNetWorth([
        100000,
        100000,
        100000,
        100000,
        100000,
        90000,
      ]);
      expect(const NetWorthTrajectoryRule().evaluate(data), isNull);
    });

    test('stays silent when net worth is rising', () {
      // Steady upward trend — the most-recent month is above its
      // rolling average. Rule must not fire on the way up.
      final data = _dataWithNetWorth([
        100000,
        105000,
        110000,
        115000,
        120000,
        125000,
        130000,
      ]);
      expect(const NetWorthTrajectoryRule().evaluate(data), isNull);
    });

    test('stays silent for short histories (fewer than 4 months)', () {
      // Below the baseline floor — even a clearly-falling 3-month
      // series doesn't qualify because the rolling average for the
      // earliest month would compare it to itself.
      final data = _dataWithNetWorth([100000, 90000, 80000]);
      expect(const NetWorthTrajectoryRule().evaluate(data), isNull);
    });

    test('stays silent when only 2 of the last 3 are below avg', () {
      // Drop, recover slightly, drop again. The middle of the
      // last three months sits above the rolling avg — not a
      // sustained trend.
      final data = _dataWithNetWorth([
        100000, 110000, 120000, 130000, 140000, // strong rising baseline
        100000, 200000, 100000, // dip-recover-dip
      ]);
      expect(const NetWorthTrajectoryRule().evaluate(data), isNull);
    });
  });

  group('SavingsRateRule', () {
    test('fires a warning when rate is below 10%', () {
      // $1,000 income, $950 spending → 5% savings rate.
      final data = _data(
        accounts: const [],
        spendCents: 95000,
        extraTxs: [
          _tx(amountCents: 100000, date: _now(), description: 'Paycheck'),
        ],
      );
      final s = const SavingsRateRule().evaluate(data);
      expect(s, isNotNull);
      expect(s!.severity, SuggestionSeverity.warning);
      expect(s.title, 'Savings rate looks low');
      expect(s.detail, contains('5%'));
    });

    test('stays silent at exactly 10% — the threshold is strict-less-than', () {
      // $1,000 income, $900 spending → 10% rate. Inside the floor,
      // so no nag. Choosing "not <" not "<=" keeps the educational
      // 50/30/20 framing — 10% is the bottom of the acceptable
      // range, not below it.
      final data = _data(
        accounts: const [],
        spendCents: 90000,
        extraTxs: [_tx(amountCents: 100000, date: _now())],
      );
      expect(const SavingsRateRule().evaluate(data), isNull);
    });

    test('stays silent at a healthy savings rate', () {
      // 30% rate — comfortably above the floor.
      final data = _data(
        accounts: const [],
        spendCents: 70000,
        extraTxs: [_tx(amountCents: 100000, date: _now())],
      );
      expect(const SavingsRateRule().evaluate(data), isNull);
    });

    test('fires the urgent "spending more than you earn" variant when '
        'spending exceeds income', () {
      // $1,000 income, $1,500 spending → gap of $500/month. The
      // "rate -50%" framing would be confusing; the rule's special
      // case phrases this as a positive dollar gap.
      final data = _data(
        accounts: const [],
        spendCents: 150000,
        extraTxs: [_tx(amountCents: 100000, date: _now())],
      );
      final s = const SavingsRateRule().evaluate(data);
      expect(s, isNotNull);
      expect(s!.title, 'Spending more than you earn');
      expect(s.detail, contains(r'$500'));
    });

    test('stays silent when monthly income is zero', () {
      // Brand-new household with no paycheck transactions. We can't
      // compute a rate, so don't pretend. The other no-data rules
      // (EmergencyFund, IdleCash) gate on monthlySpending the same
      // way; this rule gates on income because that's the
      // divide-by-zero risk here.
      final data = _data(accounts: const [], spendCents: 50000);
      expect(const SavingsRateRule().evaluate(data), isNull);
    });

    test(
      'stays silent when income exists but spending is zero (rate=100%)',
      () {
        // Edge case: income with no spending. Could be a fresh
        // install where transactions haven't all been categorised
        // yet, or a household with a one-off paycheck and no expenses
        // for the month. Either way, 100% > 10% → silent.
        final data = _data(
          accounts: const [],
          spendCents: 0,
          extraTxs: [_tx(amountCents: 100000, date: _now())],
        );
        expect(const SavingsRateRule().evaluate(data), isNull);
      },
    );
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

    test('stays silent when the user has contributed to investments '
        'in the last 90 days', () {
      // Cash level would normally fire (20 months); the qualifier
      // suppresses the suggestion because there's a positive
      // contribution on the brokerage account in the recent window.
      final brokerage = _account(
        type: AccountType.brokerage,
        currentBalance: 100000,
      );
      final data = _data(
        accounts: [
          _account(type: AccountType.savings, currentBalance: 2000000),
          brokerage,
        ],
        spendCents: 100000,
        extraTxs: [
          _tx(
            amountCents: 50000,
            date: _now().subtract(const Duration(days: 14)),
            accountId: brokerage.id,
            description: 'Auto-invest',
          ),
        ],
      );
      expect(
        const IdleCashRule().evaluate(data),
        isNull,
        reason:
            'an active investor with idle cash has likely chosen '
            'the cash level deliberately (savings goal, big purchase) '
            '— the nag would be noise.',
      );
    });

    test('still fires when the recent investment movement is an OUTFLOW', () {
      // A withdrawal from a brokerage doesn't qualify as a
      // contribution. The rule must still fire.
      final brokerage = _account(
        type: AccountType.brokerage,
        currentBalance: 100000,
      );
      final data = _data(
        accounts: [
          _account(type: AccountType.savings, currentBalance: 2000000),
          brokerage,
        ],
        spendCents: 100000,
        extraTxs: [
          _tx(
            amountCents: -50000, // withdrawal
            date: _now().subtract(const Duration(days: 14)),
            accountId: brokerage.id,
            description: 'Withdrawal',
          ),
        ],
      );
      final s = const IdleCashRule().evaluate(data);
      expect(
        s,
        isNotNull,
        reason:
            'outflows from an investment account are the OPPOSITE '
            'of contributing; they should not suppress the rule.',
      );
    });

    test('still fires when the user has no investment accounts at all', () {
      // Edge case: no investment accounts → no possible
      // contributions → qualifier vacuously passes → rule fires.
      // The suggestion text "Consider moving the excess into
      // investments" is the right nudge for this user.
      final data = _data(
        accounts: [
          _account(type: AccountType.savings, currentBalance: 2000000),
        ],
        spendCents: 100000,
      );
      expect(const IdleCashRule().evaluate(data), isNotNull);
    });

    test(
      'still fires when investment contribution is on an INACTIVE account',
      () {
        // Inactive accounts are excluded from the investmentAccountIds
        // set, so a positive tx on an archived brokerage is just noise.
        final dead = _account(
          type: AccountType.brokerage,
          currentBalance: 0,
          isActive: false,
        );
        final data = _data(
          accounts: [
            _account(type: AccountType.savings, currentBalance: 2000000),
            dead,
          ],
          spendCents: 100000,
          extraTxs: [
            _tx(
              amountCents: 50000,
              date: _now(),
              accountId: dead.id,
              description: 'Closing entry',
            ),
          ],
        );
        expect(
          const IdleCashRule().evaluate(data),
          isNotNull,
          reason:
              'a contribution to a closed account doesn\'t signal active '
              'investing — the user can\'t access that money anyway.',
        );
      },
    );
  });

  group('AccountFeesRule', () {
    test('fires opportunity when annualised fees exceed the threshold', () {
      // 3 overdraft fees of $35 each in 90 days = $105.
      // Annualised: ~$425. Well above the $100 threshold.
      final checking = _account(
        type: AccountType.checking,
        currentBalance: 100000,
      );
      final fees = [
        for (var i = 0; i < 3; i++)
          _tx(
            amountCents: -3500,
            date: _now().subtract(Duration(days: i * 25)),
            accountId: checking.id,
            merchant: 'BANK OF SOMEWHERE',
            description: 'OVERDRAFT FEE',
          ),
      ];
      final data = _data(accounts: [checking], spendCents: 0, extraTxs: fees);
      final s = const AccountFeesRule().evaluate(data);
      expect(s, isNotNull);
      expect(s!.severity, SuggestionSeverity.opportunity);
      expect(s.title, 'Bank fees adding up');
      // 10500 * 365 / 90 = 42583 cents → $425.83 → "$426".
      expect(s.detail, contains(r'$426'));
    });

    test(
      r'stays silent when fees fall below the $100 annualised threshold',
      () {
        // One $5 ATM fee in 90 days → ~$20/yr — below threshold.
        final checking = _account(
          type: AccountType.checking,
          currentBalance: 100000,
        );
        final data = _data(
          accounts: [checking],
          spendCents: 0,
          extraTxs: [
            _tx(
              amountCents: -500,
              date: _now(),
              accountId: checking.id,
              description: 'ATM FEE - OUT OF NETWORK',
            ),
          ],
        );
        expect(const AccountFeesRule().evaluate(data), isNull);
      },
    );

    test('ignores fee-like transactions on credit cards', () {
      // The user paid a credit card late fee. That's a different
      // conversation — switching banks doesn't help. The rule
      // must only count banking-group accounts.
      final card = _account(
        type: AccountType.creditCard,
        currentBalance: -100000,
      );
      final data = _data(
        accounts: [card],
        spendCents: 0,
        extraTxs: [
          for (var i = 0; i < 4; i++)
            _tx(
              amountCents: -3500,
              date: _now().subtract(Duration(days: i * 20)),
              accountId: card.id,
              description: 'LATE FEE',
            ),
        ],
      );
      expect(
        const AccountFeesRule().evaluate(data),
        isNull,
        reason:
            'credit-card late fees and annual fees are out of '
            'scope; this rule targets avoidable bank charges only.',
      );
    });

    test('ignores positive transactions even with fee keywords', () {
      // A fee REFUND ("overdraft fee waived") shows up as a
      // positive amount with a matching description. The rule
      // must skip these — they're the BANK paying the user back,
      // not a fee being charged.
      final checking = _account(
        type: AccountType.checking,
        currentBalance: 100000,
      );
      final data = _data(
        accounts: [checking],
        spendCents: 0,
        extraTxs: [
          _tx(
            amountCents: 10500,
            date: _now(),
            accountId: checking.id,
            description: 'OVERDRAFT FEE REFUND',
          ),
        ],
      );
      expect(const AccountFeesRule().evaluate(data), isNull);
    });

    test('ignores transfer-leg transactions even on banking accounts', () {
      // Banks sometimes book wire-transfer fees as a separate entry.
      // The wire itself is a transfer leg (transfer_id set); the
      // fee, if any, is a SEPARATE row without transfer_id. A leg
      // whose description happens to contain a fee keyword must
      // NOT count, or every recurring transfer would falsely trip.
      final checking = _account(
        type: AccountType.checking,
        currentBalance: 100000,
      );
      final data = _data(
        accounts: [checking],
        spendCents: 0,
        extraTxs: [
          _tx(
            amountCents: -100000,
            date: _now(),
            accountId: checking.id,
            description: 'WIRE FEE',
            transferId: 'xfer1',
          ),
        ],
      );
      expect(
        const AccountFeesRule().evaluate(data),
        isNull,
        reason:
            "transfer legs are pure cash movement; counting them "
            "would double-charge against any real fee row.",
      );
    });

    test(
      'matches the keyword set case-insensitively across multiple variants',
      () {
        // Each pattern with a different casing + position to confirm
        // the substring match works regardless of where the keyword
        // appears in merchant or description.
        final checking = _account(
          type: AccountType.checking,
          currentBalance: 100000,
        );
        final data = _data(
          accounts: [checking],
          spendCents: 0,
          extraTxs: [
            _tx(
              amountCents: -3500,
              date: _now(),
              accountId: checking.id,
              merchant: 'Bank XYZ',
              description: 'Monthly Maintenance Fee',
            ),
            _tx(
              amountCents: -3500,
              date: _now().subtract(const Duration(days: 30)),
              accountId: checking.id,
              merchant: 'NSF CHARGE',
              description: 'returned item',
            ),
            _tx(
              amountCents: -3500,
              date: _now().subtract(const Duration(days: 60)),
              accountId: checking.id,
              description: 'service charge - low balance',
            ),
          ],
        );
        final s = const AccountFeesRule().evaluate(data);
        expect(
          s,
          isNotNull,
          reason:
              'each fee keyword should match regardless of casing '
              'or which field it appears in.',
        );
      },
    );
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
