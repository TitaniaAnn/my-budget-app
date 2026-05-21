// Rules-based net-worth growth advisor.
//
// Reads only data already on the dashboard — no migrations, no
// external API. Each rule is a pure function over [DashboardData]:
// observe a pattern, ask a question, never instruct. The README's
// lowercase-confidence brand voice applies — "Roth contributions
// look low" not "you should max your Roth".
//
// Suggestions are intentionally rule-shaped (one finding per rule)
// rather than free-form ML output: every rule can be unit-tested in
// isolation, and removing a noisy rule is a one-line change.
//
// Rules read from [DashboardData], which carries 90 days of
// transactions, a YTD Roth-contribution rollup, and a monthly
// net-worth series. Adding a new rule that needs other data should
// expand DashboardData and the dashboard provider together — the
// rule itself stays a pure function.

import '../../accounts/models/account.dart';
import '../../transactions/models/transaction.dart';
import '../providers/dashboard_provider.dart';

/// Severity of a growth suggestion. Controls the chip color in the
/// dashboard surface.
///
/// - [info]: observational. "Here's a number you may not have
///   noticed." No urgency.
/// - [opportunity]: a quantified upside. The user could plausibly act
///   on this and grow net worth as a result.
/// - [warning]: a quantified downside. Money is currently bleeding,
///   and the suggestion explains how to stop it.
enum SuggestionSeverity { info, opportunity, warning }

/// One observation from the growth advisor. Phrased neutrally —
/// suggest, don't prescribe.
class GrowthSuggestion {
  const GrowthSuggestion({
    required this.id,
    required this.severity,
    required this.title,
    required this.detail,
  });

  /// Stable id for the rule that produced this suggestion. Used by
  /// the UI for keys and by future "dismiss this rule" plumbing.
  final String id;

  final SuggestionSeverity severity;

  /// Short headline (≤ ~50 chars).
  final String title;

  /// One-sentence body explaining the evidence behind the title.
  final String detail;
}

/// Pure function that may produce a [GrowthSuggestion] from
/// [DashboardData]. A null return means "this rule didn't trigger,"
/// not "the rule errored" — rules should never throw.
abstract class GrowthRule {
  String get id;
  GrowthSuggestion? evaluate(DashboardData data);
}

/// Composes a fixed list of rules and runs them all. Order of
/// suggestions in the output matches the order of rules in the
/// constructor — most-important-first works for v1 because the
/// dashboard renders all of them anyway.
class GrowthAdvisor {
  const GrowthAdvisor({this.rules = defaultRules});

  final List<GrowthRule> rules;

  /// Default rule set. Pure list rather than a factory so a test can
  /// reach in and substitute one. Add new rules at the end so
  /// existing snapshots stay stable.
  static const List<GrowthRule> defaultRules = [
    EmergencyFundRule(),
    CreditCardCarryRule(),
    SavingsRateRule(),
    RothIraUnderusedRule(),
    SubscriptionDriftRule(),
    NetWorthTrajectoryRule(),
    IdleCashRule(),
    AccountFeesRule(),
  ];

  List<GrowthSuggestion> evaluate(DashboardData data) {
    final out = <GrowthSuggestion>[];
    for (final rule in rules) {
      final s = rule.evaluate(data);
      if (s != null) out.add(s);
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// Rules
// ---------------------------------------------------------------------------

/// Liquid savings as a multiple of monthly spending. Industry rule
/// of thumb is 3–6 months of spending in cash equivalents; below 3
/// is the threshold we flag.
///
/// Edge cases:
/// - When monthly spending is zero (new user, no transactions
///   imported yet) we can't compute a months-of-spending ratio, so
///   the rule stays silent rather than emitting a divide-by-zero
///   suggestion.
/// - "Liquid" here is the banking group (checking + savings + cash);
///   credit availability does not count.
class EmergencyFundRule implements GrowthRule {
  const EmergencyFundRule();

  @override
  String get id => 'emergency_fund';

  @override
  GrowthSuggestion? evaluate(DashboardData data) {
    if (data.monthlySpending <= 0) return null;

    final liquid = data.accounts
        .where((a) => a.isActive && a.accountType.group == AccountGroup.banking)
        .fold<int>(0, (sum, a) => sum + a.currentBalance);
    if (liquid <= 0) return null;

    final months = liquid / data.monthlySpending;
    if (months >= 3) return null;

    final monthsStr = months.toStringAsFixed(1);
    return GrowthSuggestion(
      id: id,
      severity: SuggestionSeverity.warning,
      title: 'Emergency fund looks thin',
      detail:
          'Liquid savings cover $monthsStr months of spending. '
          'Industry rule of thumb is 3–6.',
    );
  }
}

/// Any active credit card carrying a balance at 10%+ APR. Paying
/// these down beats the long-run market return after tax, so it's
/// the highest-leverage "next dollar" the engine can suggest.
///
/// Treats each card independently — a household with two high-APR
/// cards gets one suggestion for the bigger one. (Listing them all
/// would clutter the dashboard, and "pay down debt" is one decision
/// from the user's standpoint.)
///
/// Credit-card balances are stored as negative cents (the standard
/// debt convention used elsewhere in this app). We compare against
/// the magnitude.
class CreditCardCarryRule implements GrowthRule {
  const CreditCardCarryRule();

  @override
  String get id => 'credit_card_carry';

  @override
  GrowthSuggestion? evaluate(DashboardData data) {
    const minApr = 0.10;
    Account? worst;
    int worstBalance = 0;
    for (final a in data.accounts) {
      if (!a.isActive) continue;
      if (a.accountType != AccountType.creditCard) continue;
      final rate = a.interestRate;
      if (rate == null || rate < minApr) continue;
      if (a.currentBalance >= 0) continue;
      // Magnitude: -1234 → 1234. We compare on magnitude so the
      // biggest carry wins regardless of sign convention.
      final magnitude = -a.currentBalance;
      if (magnitude > worstBalance) {
        worstBalance = magnitude;
        worst = a;
      }
    }
    if (worst == null) return null;

    final aprPct = (worst.interestRate! * 100).toStringAsFixed(1);
    final dollars = _formatDollars(worstBalance);
    return GrowthSuggestion(
      id: id,
      severity: SuggestionSeverity.warning,
      title: 'Credit card balance at $aprPct% APR',
      detail:
          '${worst.name} is carrying $dollars at $aprPct%. '
          'Paying this down beats most investment returns.',
    );
  }
}

/// Monthly savings as a fraction of monthly income. The classic
/// 50/30/20 budgeting rule lands savings at 20%; under 10% is the
/// structural-risk threshold this rule flags. Below that even a
/// modest emergency-fund target takes years, and retirement saving
/// barely keeps up with inflation.
///
/// Two cases produce a suggestion:
///   * spending exceeds income (rate <= 0) — the urgent case, named
///     out as "spending more than you earn" rather than "savings rate
///     is -7%" since the negative framing reads cleaner;
///   * 0 < rate < 0.10 — the structural-warning case.
///
/// Edge cases:
/// - No income (brand-new household, no paychecks imported) → silent.
///   Computing a rate from zero income would either divide by zero
///   or pretend everything is fine.
/// - Income with zero spending → rate is 100%, silent. Probably
///   means transactions haven't all been categorised yet, but
///   it's the same outcome either way.
///
/// `monthlyIncome` and `monthlySpending` are already in display
/// currency on DashboardData (the FX-conversion happens upstream),
/// so this rule is currency-symmetric without doing its own math.
class SavingsRateRule implements GrowthRule {
  const SavingsRateRule();

  /// Below this fraction we fire the warning. 10% is more lenient
  /// than the 20% of "50/30/20" — meant as a floor, not a target.
  static const double _floor = 0.10;

  @override
  String get id => 'savings_rate';

  @override
  GrowthSuggestion? evaluate(DashboardData data) {
    final income = data.monthlyIncome;
    final spending = data.monthlySpending;
    if (income <= 0) return null;

    if (spending >= income) {
      // Net negative cash flow — the most urgent flavour of this
      // rule. Phrased in dollars rather than rate so the user
      // sees the actual hole.
      final gap = spending - income;
      return GrowthSuggestion(
        id: id,
        severity: SuggestionSeverity.warning,
        title: 'Spending more than you earn',
        detail:
            'This month\'s spending is ${_formatDollars(gap)} above '
            'income. Closing the gap is the first lever before any '
            'investing strategy.',
      );
    }

    final rate = (income - spending) / income;
    if (rate >= _floor) return null;

    final pct = (rate * 100).toStringAsFixed(0);
    return GrowthSuggestion(
      id: id,
      severity: SuggestionSeverity.warning,
      title: 'Savings rate looks low',
      detail:
          'Saving about $pct% of monthly income. The 50/30/20 rule '
          'aims for 20%; under 10% leaves little room for emergencies '
          'or retirement progress.',
    );
  }
}

/// Cash so far above the emergency-fund target that the excess is
/// almost certainly idle.
///
/// Threshold: cash > 12 × monthly spending. A year of expenses in
/// checking is the cutoff between "comfortable cushion" and "this is
/// a savings-rate problem in disguise."
///
/// Qualifier: stays silent when the household has been moving money
/// into investments in the last 90 days. A user who's already
/// contributing regularly has likely chosen the cash level
/// deliberately (savings goal, big purchase coming, market timing).
/// Flagging them would be noise — the original audit called this
/// out as the "no-investment-contributions in 90 days" guard, now
/// implemented here.
///
/// "Contribution" = any positive transaction on an investment
/// account in the last 90 days. This deliberately matches the Roth
/// rule's broader definition: it counts dividend reinvestments and
/// capital-gains distributions as contributions too. The
/// over-counting cuts the other way for this rule (it makes the
/// guard MORE forgiving — easier to suppress the nag), which is the
/// right bias when the alternative is annoying a passive investor.
class IdleCashRule implements GrowthRule {
  const IdleCashRule();

  @override
  String get id => 'idle_cash';

  @override
  GrowthSuggestion? evaluate(DashboardData data) {
    if (data.monthlySpending <= 0) return null;

    final liquid = data.accounts
        .where((a) => a.isActive && a.accountType.group == AccountGroup.banking)
        .fold<int>(0, (sum, a) => sum + a.currentBalance);
    if (liquid <= 0) return null;

    final months = liquid / data.monthlySpending;
    if (months <= 12) return null;

    // No-investment-contributions qualifier. recentTransactions90d
    // covers the 90-day window the audit specified.
    final investmentAccountIds = {
      for (final a in data.accounts)
        if (a.isActive && a.accountType.group == AccountGroup.investments) a.id,
    };
    final hasRecentContribution = data.recentTransactions90d.any(
      (t) => t.amount > 0 && investmentAccountIds.contains(t.accountId),
    );
    if (hasRecentContribution) return null;

    final dollars = _formatDollars(liquid);
    return GrowthSuggestion(
      id: id,
      severity: SuggestionSeverity.opportunity,
      title: 'A lot of cash sitting in the bank',
      detail:
          '$dollars in checking and savings is more than a year of '
          'expenses. Consider moving the excess into investments.',
    );
  }
}

/// Bank fees adding up on banking-group accounts (overdraft,
/// maintenance, ATM, NSF, service charges). Detected by keyword
/// matching on transaction merchant + description in the 90-day
/// window, then annualised. Fires an opportunity when the implied
/// annual drag exceeds [_annualThresholdCents].
///
/// Why a separate rule from SubscriptionDriftRule: subscription
/// drift looks for merchant-level recurring patterns ("Spotify went
/// up 20%"). Bank fees often arrive as one-off charges from the
/// bank itself, with descriptions like "OVERDRAFT FEE" — they don't
/// look like a recurring merchant pattern, so the drift rule misses
/// them entirely.
///
/// Why banking-group only: credit-card annual fees and late fees
/// are different conversations (the user's signed up for the card,
/// or they need to pay on time — switching banks doesn't help).
/// This rule targets the avoidable drag the user can act on by
/// changing accounts, setting up direct deposit, or opting out of
/// overdraft protection.
///
/// Keywords chosen to minimise false positives. "Fee" alone would
/// match too much (Uber's "service fee" line, a restaurant's
/// "split-bill fee"). The match is case-insensitive, substring-based.
class AccountFeesRule implements GrowthRule {
  const AccountFeesRule();

  /// Annualised fee total (cents) at or above which the rule fires.
  /// $100/yr ≈ one $25 overdraft per quarter — actionable, but
  /// above the noise of one-off legitimate charges.
  static const int _annualThresholdCents = 10000;

  /// Substring patterns that identify a bank fee. All matched
  /// case-insensitively against both merchant and description.
  static const List<String> _patterns = [
    'overdraft',
    'maintenance fee',
    'monthly fee',
    'service charge',
    'atm fee',
    'wire fee',
    'nsf',
    'returned check',
    'inactivity fee',
  ];

  @override
  String get id => 'account_fees';

  @override
  GrowthSuggestion? evaluate(DashboardData data) {
    if (data.recentTransactions90d.isEmpty) return null;

    final bankingAccountIds = {
      for (final a in data.accounts)
        if (a.isActive && a.accountType.group == AccountGroup.banking) a.id,
    };
    if (bankingAccountIds.isEmpty) return null;

    var feeSpend = 0;
    for (final t in data.recentTransactions90d) {
      // Fees are negative (debits) on banking accounts. Transfers
      // are separate rows from any wire fees the bank charges, so
      // exclude transfer legs to avoid double-counting.
      if (t.amount >= 0) continue;
      if (t.transferId != null) continue;
      if (!bankingAccountIds.contains(t.accountId)) continue;
      if (!_looksLikeFee(t)) continue;
      final converted = _convertedAmount(t, data);
      if (converted == null) continue;
      feeSpend += converted.abs();
    }
    if (feeSpend <= 0) return null;

    // 90 days → annualise to a calendar year. ~4.06x is the exact
    // ratio; rounding to 4 keeps the suggestion text honest about
    // the approximation.
    final annualised = (feeSpend * 365) ~/ 90;
    if (annualised < _annualThresholdCents) return null;

    final dollars = _formatDollars(annualised);
    return GrowthSuggestion(
      id: id,
      severity: SuggestionSeverity.opportunity,
      title: 'Bank fees adding up',
      detail:
          'On pace for about $dollars/year in account fees. Many of '
          'these are avoidable — switching banks, setting up direct '
          'deposit, or opting out of overdraft can eliminate them.',
    );
  }

  static bool _looksLikeFee(Transaction t) {
    final haystack = ('${t.merchant ?? ''} ${t.description}').toLowerCase();
    for (final p in _patterns) {
      if (haystack.contains(p)) return true;
    }
    return false;
  }
}

/// Roth IRA contribution headroom for the current calendar year.
///
/// Fires an OPPORTUNITY when the household has at least one active
/// Roth IRA account AND year-to-date "contributions" are below the
/// IRS annual limit. The detail names the dollar gap so the user
/// can decide whether topping up is feasible without doing the math.
///
/// IRS contribution limit for tax year 2026 is $7,000 (under age
/// 50); the over-50 catch-up of $1,000 isn't applied because the
/// schema doesn't carry the account holder's age.
///
/// Caveat — "contributions" is over-counted. The dashboard provider
/// computes it as SUM(positive amounts on Roth IRA accounts since
/// Jan 1). That includes dividend reinvestments, capital gains
/// distributions, and any other internal inflow — not just external
/// contributions the way the IRS defines them. We don't have a
/// schema-level "transfer source" to tell external dollars apart.
///
/// To avoid silencing the rule for a user with heavy dividends, the
/// silence threshold is [_silenceFactor] × the annual limit (i.e.
/// 1.5× = $10,500 on the $7,000 limit). Below that the rule still
/// fires — and the suggestion text flags the approximation so the
/// user isn't misled. Above that we silence: we can't tell whether
/// the user is maxed-and-also-dividend-rich, or under-contributing
/// at a heavily-reinvested account.
///
/// Verify the limit annually against IRS guidance. The constant is a
/// deliberate hardcoded number (not pulled from a config service)
/// because the contribution-limit shift is exactly the kind of
/// change that warrants a code review and a fresh test pass.
class RothIraUnderusedRule implements GrowthRule {
  const RothIraUnderusedRule();

  /// 2026 IRS Roth IRA contribution limit (under 50), in cents.
  /// Update annually.
  static const int annualLimitCents = 700000;

  /// How much over the annual limit the "contributions" tally has
  /// to be before we silence the rule. >1 because the dashboard
  /// over-counts dividend reinvestments as contributions; we'd
  /// rather over-fire than silence a user who's actually under.
  static const double _silenceFactor = 1.5;

  @override
  String get id => 'roth_ira_underused';

  @override
  GrowthSuggestion? evaluate(DashboardData data) {
    final hasRoth = data.accounts.any(
      (a) => a.isActive && a.accountType == AccountType.iraRoth,
    );
    if (!hasRoth) return null;

    final contributed = data.ytdRothContributionsCents;
    // Silence only when we're confident the user has truly maxed —
    // i.e. even after the over-count from dividends, they're 50%
    // past the limit. Inside that band, we still fire so a heavy-
    // dividend account doesn't mute the suggestion.
    if (contributed >= annualLimitCents * _silenceFactor) return null;

    final gap = annualLimitCents - contributed;
    // Don't render a negative gap when contributed is between the
    // hard limit and the silence threshold — read as "you've used
    // ~the full limit" instead.
    final gapStr = gap > 0
        ? '${_formatDollars(gap)} left before the deadline'
        : 'roughly at the limit';
    final contributedStr = _formatDollars(contributed);
    final limitStr = _formatDollars(annualLimitCents);
    return GrowthSuggestion(
      id: id,
      severity: SuggestionSeverity.opportunity,
      title: 'Roth IRA contributions look low',
      // "Approximate" flag in the body: the user sees the limitation
      // up front rather than puzzling over why the number looks
      // higher than what they think they contributed.
      detail:
          '~$contributedStr of the $limitStr Roth IRA limit used '
          'this year (includes dividends) — $gapStr.',
    );
  }
}

/// Drift in recurring spend across the last few calendar months.
///
/// A merchant counts as "recurring" if the household paid them in two
/// or more distinct calendar months out of the trailing 3-month
/// window. That's a deliberately loose definition — a quarterly bill
/// or a paused-then-resumed subscription still trips it. Tightening
/// the definition (e.g. "appears every month") would silence the
/// drift on the merchants users most need to notice.
///
/// Once the recurring set is established, sum its spend per calendar
/// month. The rule fires INFO when the current month's recurring
/// total exceeds the prior months' average by [_flagPctIncrease].
/// Information-only severity, not warning: a one-month bump can be a
/// renewal or a tier change — the brand voice observes, not nags.
///
/// Reads `DashboardData.recentTransactions90d`. Requires the prior 2
/// months to have at least one recurring tx between them, otherwise
/// there's no baseline to compare against and the rule stays silent.
class SubscriptionDriftRule implements GrowthRule {
  const SubscriptionDriftRule();

  /// How much higher the current month must be vs the prior-months
  /// average to fire. 0.20 == 20% per the audit's wording.
  static const double _flagPctIncrease = 0.20;

  @override
  String get id => 'subscription_drift';

  /// Year-month bucket key in `YYYY-MM` form. Sortable as a string.
  static String _ym(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  @override
  GrowthSuggestion? evaluate(DashboardData data) {
    if (data.recentTransactions90d.isEmpty) return null;

    // Group expense transactions by (merchant, year-month). Use the
    // merchant column when present, falling back to description so a
    // hand-entered "Spotify" without a cleaned merchant still groups
    // with its peers.
    //
    // Amounts are converted to the household's display currency via
    // ratesToDisplay so a multi-currency household compares like with
    // like. Foreign-currency rows with no rate are EXCLUDED — the
    // alternative (treating them at rate=1) would manufacture noise
    // by mixing currencies inside the same monthly bucket.
    final spendByMerchantByMonth = <String, Map<String, int>>{};
    for (final t in data.recentTransactions90d) {
      if (t.amount >= 0) continue;
      // Transfer legs (migration 030) aren't real spending — a recurring
      // checking → savings sweep would otherwise look like a subscription.
      if (t.transferId != null) continue;
      final converted = _convertedAmount(t, data);
      if (converted == null) continue;
      final raw = (t.merchant ?? t.description).trim();
      if (raw.isEmpty) continue;
      final key = raw.toLowerCase();
      final ym = _ym(t.transactionDate);
      // Hoist into a non-nullable local — Dart's flow analysis
      // doesn't carry the null-check on `converted` into the
      // closures below.
      final abs = converted.abs();
      final months = spendByMerchantByMonth.putIfAbsent(key, () => {});
      months.update(ym, (v) => v + abs, ifAbsent: () => abs);
    }

    // Recurring: appears in ≥ 2 distinct months in the window.
    final recurringMerchants = spendByMerchantByMonth.entries
        .where((e) => e.value.length >= 2)
        .map((e) => e.key)
        .toSet();
    if (recurringMerchants.isEmpty) return null;

    // Sum recurring spend per calendar month.
    final monthlyTotals = <String, int>{};
    for (final m in recurringMerchants) {
      spendByMerchantByMonth[m]!.forEach((ym, cents) {
        monthlyTotals.update(ym, (v) => v + cents, ifAbsent: () => cents);
      });
    }

    // Current month vs the average of any other month in the window.
    // Need at least one prior month with non-zero recurring spend to
    // have a baseline.
    final now = DateTime.now();
    final currentYm = _ym(now);
    final currentSpend = monthlyTotals[currentYm];
    if (currentSpend == null || currentSpend <= 0) return null;

    final priorTotals = monthlyTotals.entries
        .where((e) => e.key != currentYm)
        .map((e) => e.value)
        .toList();
    if (priorTotals.isEmpty) return null;

    final priorAvg = priorTotals.reduce((a, b) => a + b) ~/ priorTotals.length;
    if (priorAvg <= 0) return null;

    final growth = (currentSpend - priorAvg) / priorAvg;
    if (growth < _flagPctIncrease) return null;

    final pctStr = (growth * 100).toStringAsFixed(0);
    final currentStr = _formatDollars(currentSpend);
    final priorStr = _formatDollars(priorAvg);
    return GrowthSuggestion(
      id: id,
      severity: SuggestionSeverity.info,
      title: 'Recurring spend ticked up',
      detail:
          'Recurring merchants cost $currentStr this month — up '
          '$pctStr% from a prior-months average of $priorStr.',
    );
  }
}

/// Net worth has been below its trailing 6-month rolling average
/// for the past 3+ consecutive months.
///
/// The signal is "trend over the last quarter, judged against the
/// half-year baseline" — a recent dip below the half-year average
/// becomes a finding when it persists. Single-month dips don't
/// fire (could be a one-off bill or a market wobble); a sustained
/// drop is what gets surfaced. The audit calls for INFO severity
/// here, not warning — the brand voice is observation.
///
/// Rolling average uses up to 6 prior months PLUS the month in
/// question. Earlier months in a fresh household see a shorter
/// window naturally; the rule needs at least 4 months of history
/// to have anything meaningful to compare against, and stays
/// silent below that threshold.
///
/// Reads `DashboardData.monthlyNetWorth` (oldest first). Empty or
/// short series → silent.
class NetWorthTrajectoryRule implements GrowthRule {
  const NetWorthTrajectoryRule();

  /// Minimum data points (including the current month) before the
  /// rule will even attempt to evaluate. Below this the rolling
  /// average for the current month would essentially compare the
  /// value to itself.
  static const int _minMonthsForBaseline = 4;

  /// How many consecutive months at the end of the series must each
  /// sit below their own rolling average for the rule to fire. Per
  /// the audit: "3+ months". Three months of decline is the
  /// shortest run that distinguishes a trend from noise.
  static const int _consecutiveBelow = 3;

  /// Window for the rolling average, in months (inclusive of the
  /// point being evaluated).
  static const int _rollingWindowMonths = 6;

  @override
  String get id => 'net_worth_trajectory';

  @override
  GrowthSuggestion? evaluate(DashboardData data) {
    final series = data.monthlyNetWorth;
    if (series.length < _minMonthsForBaseline) return null;
    if (series.length < _consecutiveBelow) return null;

    // For each of the last [_consecutiveBelow] months, compute
    // the trailing rolling average (using up to
    // [_rollingWindowMonths] prior points inclusive of the current
    // one). Fire only when every one of them sits below its own
    // window average.
    for (var offset = 0; offset < _consecutiveBelow; offset++) {
      final i = series.length - 1 - offset;
      final windowStart = (i + 1 - _rollingWindowMonths).clamp(0, i);
      // Need at least 2 points in the window to have a non-trivial
      // comparison (the average of one point IS that point).
      if (i - windowStart < 1) return null;
      var sum = 0;
      for (var j = windowStart; j <= i; j++) {
        sum += series[j].balanceCents;
      }
      final avg = sum ~/ (i - windowStart + 1);
      if (series[i].balanceCents >= avg) return null;
    }

    // All three checks passed — surface the headline numbers.
    final current = series.last.balanceCents;
    // 6-month average across the full available window (up to 6
    // points ending at the current month), used as the headline
    // baseline for the suggestion text.
    final baselineStart = (series.length - _rollingWindowMonths).clamp(
      0,
      series.length - 1,
    );
    var baselineSum = 0;
    for (var j = baselineStart; j < series.length; j++) {
      baselineSum += series[j].balanceCents;
    }
    final baselineAvg = baselineSum ~/ (series.length - baselineStart);
    final gap = baselineAvg - current;
    final gapStr = _formatDollars(gap);
    return GrowthSuggestion(
      id: id,
      severity: SuggestionSeverity.info,
      title: 'Net worth has been drifting down',
      detail:
          'Past 3 months sat below the rolling 6-month average — '
          'currently $gapStr below.',
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Whole-dollar formatter for in-suggestion strings. Avoids decimals
/// because the suggestion text is observational, not exact accounting
/// — "$3,400" reads better than "$3,400.00" in a one-liner.
String _formatDollars(int cents) {
  final dollars = (cents / 100).round();
  // Comma-grouped manually so the engine doesn't pull in intl
  // formatting for a trivial transform. Negative inputs aren't
  // expected here (callers pass magnitudes); fall through if so.
  final negative = dollars < 0;
  final digits = dollars.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${negative ? '-' : ''}\$$buf';
}

/// Converts a transaction's signed amount into the household's
/// display currency, using the FX rates carried on the dashboard
/// data. Returns null when the row is in a foreign currency with
/// no rate available — callers EXCLUDE it from aggregations
/// rather than silently apply rate=1.
///
/// Mirrors the same contract `DashboardData` uses for its monthly
/// aggregations and `evaluateNotifications` doesn't need (it
/// reads `t.amount` directly because notifications fire on a per-
/// transaction basis, not in aggregate).
int? _convertedAmount(Transaction t, DashboardData data) {
  if (t.currency == data.displayCurrency) return t.amount;
  final rate = data.ratesToDisplay[t.currency];
  if (rate == null) return null;
  return (t.amount * rate).round();
}
