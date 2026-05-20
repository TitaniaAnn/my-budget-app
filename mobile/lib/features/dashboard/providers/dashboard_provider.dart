// Dashboard data provider.
//
// Loads all data the dashboard needs in parallel. Transaction history covers
// the last 30 days so both the monthly summary and the spending sparkline are
// served from a single query; the monthly figures are derived by filtering in
// Dart to >= the 1st of the current month.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../../accounts/models/account.dart';
import '../../accounts/repositories/accounts_repository.dart';
import '../../budget/repositories/budget_repository.dart';
import '../../notifications/providers/notification_runner_provider.dart';
import '../../recurring/providers/recurring_scheduler_provider.dart';
import '../../scenarios/repositories/scenarios_repository.dart';
import '../../transactions/models/category.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/repositories/transactions_repository.dart';
import '../services/month_end_aggregator.dart';

part 'dashboard_provider.g.dart';

/// All data the dashboard screen needs, assembled in one async call.
class DashboardData {
  /// All active household accounts.
  final List<Account> accounts;

  /// Transactions from the last 90 days. The window is wide enough to
  /// support the [SubscriptionDriftRule] (which needs 3+ months of
  /// merchant history) while the per-getter date filters below still
  /// narrow to current-month / 30-day views for the existing widgets.
  final List<Transaction> recentTransactions90d;

  /// The 5 most recent transactions across all accounts.
  final List<Transaction> recentTransactions;

  /// Net spending per category for the current calendar month, sourced
  /// from `get_category_spending` (migration 026). Already applies the
  /// Option B rollup: a paired transaction's category is "filing only"
  /// and the spend comes from its receipt line items. The RPC returns
  /// only categorized rows — the "Uncategorized" bucket on
  /// [topCategories] is computed separately.
  final Map<String, int> spendingByCategory;

  /// Categories keyed by id, used by [topCategories] to resolve names
  /// and colors without re-fetching. Kept as a snapshot so the getter
  /// stays pure — the widget tree never has to thread two providers
  /// together at render time.
  final Map<String, Category> categoryLookup;

  /// Year-to-date Roth IRA contributions in cents. Sum of positive-
  /// amount transactions on iraRoth accounts dated >= Jan 1 of the
  /// current year. Used by [RothIraUnderusedRule]; defaults to 0 so
  /// the rule stays silent for households that don't have a Roth IRA
  /// account (and so existing tests don't have to set it).
  final int ytdRothContributionsCents;

  /// One end-of-month net-worth point per calendar month over the
  /// trajectory lookback (180 days). Oldest first. Used by
  /// [NetWorthTrajectoryRule]; defaults to const [] so existing
  /// tests don't have to populate it.
  final List<({DateTime monthEnd, int balanceCents})> monthlyNetWorth;

  const DashboardData({
    required this.accounts,
    required this.recentTransactions90d,
    required this.recentTransactions,
    this.spendingByCategory = const {},
    this.categoryLookup = const {},
    this.ytdRothContributionsCents = 0,
    this.monthlyNetWorth = const [],
  });

  // ── Monthly summary (current calendar month) ──────────────────────────────

  DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Transactions in the current calendar month, with transfer legs
  /// filtered out. Transfers (migration 030) are pure cash movement
  /// between two of the household's own accounts — counting their
  /// legs in [monthlyIncome] / [monthlySpending] would inflate both
  /// by the same amount and misrepresent the actual cash flow.
  List<Transaction> get _monthTransactions => recentTransactions90d
      .where((t) => !t.transactionDate.isBefore(_monthStart))
      .where((t) => t.transferId == null)
      .toList();

  /// Net worth = sum of every account's signed balance.
  ///
  /// All balances are stored signed: assets are positive, liabilities
  /// (credit_card, mortgage) are negative — so a plain sum is correct
  /// without any per-type special-casing.
  int get netWorth => accounts.fold<int>(0, (sum, a) => sum + a.currentBalance);

  /// Total spending this month (expenses only, as positive cents).
  int get monthlySpending => _monthTransactions
      .where((t) => t.amount < 0)
      .fold<int>(0, (sum, t) => sum + t.amount.abs());

  /// Total income this month.
  int get monthlyIncome => _monthTransactions
      .where((t) => t.amount > 0)
      .fold<int>(0, (sum, t) => sum + t.amount);

  /// Top 5 spending categories this month, sorted by total descending.
  ///
  /// Reads from [spendingByCategory] (server-aggregated under Option B,
  /// so a paired transaction's spend already flows through its receipt
  /// line items) and joins names + colors from [categoryLookup].
  /// Categories that aren't in the lookup are skipped — a stale id
  /// shouldn't render as an empty pill.
  ///
  /// The RPC excludes uncategorized rows by construction, so we still
  /// add an "Uncategorized" bucket here from the in-memory 30-day
  /// data: unpaired transactions in the current month with no
  /// category. Paired-but-uncategorized are intentionally excluded —
  /// under Option B their spending is line-item-shaped, not
  /// transaction-shaped, so attributing them to "Uncategorized" would
  /// double-count once line item categories are filled in.
  /// Rows surfaced in the dashboard's Top Categories card. [id] is
  /// null for the synthesised "Uncategorized" bucket and present for
  /// real categories — the dashboard tile uses [id] to deep-link into
  /// the transactions screen with the category filter pre-applied.
  List<({String? id, String name, String? color, int totalCents})>
  get topCategories {
    final entries =
        <({String? id, String name, String? color, int totalCents})>[];
    for (final entry in spendingByCategory.entries) {
      // The RPC reports refund-exceeds-spend categories as negative
      // net_cents; the budget UI clamps those to 0 spent, and the
      // top-N widget shouldn't surface them at all.
      if (entry.value <= 0) continue;
      final cat = categoryLookup[entry.key];
      if (cat == null) continue;
      entries.add((
        id: entry.key,
        name: cat.name,
        color: cat.color,
        totalCents: entry.value,
      ));
    }

    final uncategorizedCents = _monthTransactions
        .where(
          (t) => t.amount < 0 && t.categoryId == null && t.receiptId == null,
        )
        .fold<int>(0, (sum, t) => sum + t.amount.abs());
    if (uncategorizedCents > 0) {
      entries.add((
        // null id — no single category to drill into; the dashboard
        // tile renders this row non-tappable.
        id: null,
        name: 'Uncategorized',
        color: null,
        totalCents: uncategorizedCents,
      ));
    }

    entries.sort((a, b) => b.totalCents.compareTo(a.totalCents));
    return entries.take(5).toList();
  }

  // ── 30-day spending sparkline ──────────────────────────────────────────────

  /// Daily spending totals for the last 30 days.
  /// Index 0 = 29 days ago, index 29 = today. Missing days default to 0.
  List<int> get spendingByDay {
    final today = DateTime.now();
    final result = List<int>.filled(30, 0);
    for (final tx in recentTransactions90d.where(
      (t) => t.amount < 0 && t.transferId == null,
    )) {
      final daysAgo = today
          .difference(
            DateTime(
              tx.transactionDate.year,
              tx.transactionDate.month,
              tx.transactionDate.day,
            ),
          )
          .inDays;
      if (daysAgo >= 0 && daysAgo < 30) {
        result[29 - daysAgo] += tx.amount.abs();
      }
    }
    return result;
  }
}

/// Fetches all dashboard data in parallel. Watches [householdIdProvider] so
/// it refreshes automatically when the household changes.
@riverpod
Future<DashboardData> dashboardData(DashboardDataRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) {
    return const DashboardData(
      accounts: [],
      recentTransactions90d: [],
      recentTransactions: [],
    );
  }

  // Run the recurring scheduler before we fetch dashboard data so
  // any rules due today materialise into transactions FIRST —
  // otherwise the dashboard would show stale numbers for one frame
  // until the next refresh. Riverpod caches the result (keepAlive),
  // so this is effectively a one-shot per app process: the await
  // is free on subsequent dashboard loads.
  await ref.watch(runRecurringSchedulerProvider.future);

  // Trigger the notifications pass (budget-over + large-tx). Fire-
  // and-forget by design: the dashboard doesn't depend on its
  // result and shouldn't be blocked by a misbehaving plugin. The
  // provider is keepAlive so the engine still runs once per app
  // process even though we don't await.
  // ignore: unused_result
  ref.read(runNotificationsProvider.future);

  final accountsRepo = ref.read(accountsRepositoryProvider);
  final txRepo = ref.read(transactionsRepositoryProvider);
  final budgetRepo = ref.read(budgetRepositoryProvider);

  final now = DateTime.now();
  // 90-day window covers both the 30-day sparkline/monthly summary
  // (filtered in Dart) and the SubscriptionDriftRule which needs 3+
  // months of merchant history to establish a baseline. Wire payload
  // grows roughly 3x vs the prior 30-day fetch — still small for a
  // typical household.
  final ninetyDaysAgo = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 89));
  final today = DateTime(now.year, now.month, now.day);
  // The Suggestions / Top Categories rollup operates on calendar-month
  // boundaries (matches monthlySpending/monthlyIncome), so the RPC
  // window is "first of this month → today". Using thirtyDaysAgo here
  // would let mid-late-month spend leak from the previous month.
  final monthStart = DateTime(now.year, now.month, 1);

  final (accounts, recent90d, recent5, spendByCat, categories) = await (
    accountsRepo.fetchAccounts(householdId),
    txRepo.fetchTransactionsForDashboard(
      householdId: householdId,
      from: ninetyDaysAgo,
      to: today,
    ),
    txRepo.fetchTransactions(householdId: householdId, limit: 5),
    budgetRepo.fetchSpendingByCategory(
      householdId: householdId,
      from: monthStart,
      to: today,
    ),
    txRepo.fetchCategories(),
  ).wait;

  // Roth YTD contributions — sequential because it depends on the
  // accounts list to know which IDs are iraRoth. Cheap on
  // households with no Roth (skipped) and households with a Roth
  // (one focused query, ~12-26 rows). If/when more advisor rules
  // need per-account-type YTD rollups, replace the pair of queries
  // with a single RPC.
  final yearStart = DateTime(now.year, 1, 1);
  final rothAccountIds = accounts
      .where((a) => a.isActive && a.accountType == AccountType.iraRoth)
      .map((a) => a.id)
      .toList();
  final ytdRothContributions = await txRepo.sumPositiveAmountsForAccountsSince(
    accountIds: rothAccountIds,
    from: yearStart,
  );

  // Net-worth trajectory series. fetchHistoricalNetWorth walks
  // backward from today using transaction deltas, so it has to run
  // after accounts (currentNetWorth = SUM(currentBalance)). 180-day
  // lookback covers the rule's 6-month rolling window; widening to
  // a year would let the rule see slower trends but adds another
  // fetch on every dashboard load.
  final currentNetWorth = accounts.fold<int>(
    0,
    (sum, a) => sum + a.currentBalance,
  );
  final scenariosRepo = ref.read(scenariosRepositoryProvider);
  final dailyPoints = await scenariosRepo.fetchHistoricalNetWorth(
    householdId: householdId,
    currentNetWorth: currentNetWorth,
    lookbackDays: 180,
  );
  final monthlyNetWorth = aggregateMonthEndNetWorth(
    dailyPoints,
    now: now,
    currentBalanceCents: currentNetWorth,
  );

  return DashboardData(
    accounts: accounts,
    recentTransactions90d: recent90d,
    recentTransactions: recent5,
    spendingByCategory: spendByCat,
    categoryLookup: {for (final c in categories) c.id: c},
    ytdRothContributionsCents: ytdRothContributions,
    monthlyNetWorth: monthlyNetWorth,
  );
}
