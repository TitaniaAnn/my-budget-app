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
// Scope of v1: three rules that need nothing beyond accounts +
// last-30-day transactions. Rules that need YTD totals (Roth
// underused), 6-month history (subscription drift), or net-worth
// time series are deliberately deferred — each would either bloat
// the dashboard data fetch or require a new RPC, and the engine's
// value is mostly in the first few good rules.

import '../../accounts/models/account.dart';
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
    RothIraUnderusedRule(),
    IdleCashRule(),
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

/// Cash so far above the emergency-fund target that the excess is
/// almost certainly idle. The audit pairs this with a
/// "no-investment-contributions in 90 days" qualifier, but the
/// dashboard only loads 30 days of transactions in v1 — so this
/// rule's v1 version skips the qualifier and just flags the cash
/// level. Worst-case false positive is suggesting a move the user
/// has already made, which is fine for an observation framed as a
/// question.
///
/// Threshold: cash > 12 × monthly spending. A year of expenses in
/// checking is the cutoff between "comfortable cushion" and "this is
/// a savings-rate problem in disguise."
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

/// Roth IRA contribution headroom for the current calendar year.
///
/// Fires an OPPORTUNITY when the household has at least one active
/// Roth IRA account AND year-to-date contributions are below the IRS
/// annual limit. The detail names the dollar gap so the user can
/// decide whether topping up is feasible without doing the math.
///
/// IRS contribution limit for tax year 2026 is $7,000 (under age 50);
/// the over-50 catch-up of $1,000 isn't applied because the schema
/// doesn't carry the account holder's age. A 50+ user will see this
/// rule fire when they're between $7k and $8k contributed; the
/// suggestion is observational ("look low") rather than prescriptive,
/// so that's an acceptable over-fire.
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

  @override
  String get id => 'roth_ira_underused';

  @override
  GrowthSuggestion? evaluate(DashboardData data) {
    final hasRoth = data.accounts.any(
      (a) => a.isActive && a.accountType == AccountType.iraRoth,
    );
    if (!hasRoth) return null;

    final contributed = data.ytdRothContributionsCents;
    // Already maxed (or over — generous, but stay silent rather than
    // emit a "you contributed too much" warning we can't act on).
    if (contributed >= annualLimitCents) return null;

    final gap = annualLimitCents - contributed;
    final contributedStr = _formatDollars(contributed);
    final limitStr = _formatDollars(annualLimitCents);
    final gapStr = _formatDollars(gap);
    return GrowthSuggestion(
      id: id,
      severity: SuggestionSeverity.opportunity,
      title: 'Roth IRA contributions look low',
      detail:
          '$contributedStr of the $limitStr Roth IRA limit used this '
          'year — $gapStr left before the deadline.',
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
