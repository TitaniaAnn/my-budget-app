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
import '../../transactions/models/category.dart';
import '../../transactions/models/transaction.dart';
import '../../transactions/repositories/transactions_repository.dart';

part 'dashboard_provider.g.dart';

/// All data the dashboard screen needs, assembled in one async call.
class DashboardData {
  /// All active household accounts.
  final List<Account> accounts;

  /// Transactions from the last 30 days (used for sparkline + monthly summary).
  final List<Transaction> recentTransactions30d;

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

  const DashboardData({
    required this.accounts,
    required this.recentTransactions30d,
    required this.recentTransactions,
    this.spendingByCategory = const {},
    this.categoryLookup = const {},
  });

  // ── Monthly summary (current calendar month) ──────────────────────────────

  DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  List<Transaction> get _monthTransactions => recentTransactions30d
      .where((t) => !t.transactionDate.isBefore(_monthStart))
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
  List<({String name, String? color, int totalCents})> get topCategories {
    final entries = <({String name, String? color, int totalCents})>[];
    for (final entry in spendingByCategory.entries) {
      // The RPC reports refund-exceeds-spend categories as negative
      // net_cents; the budget UI clamps those to 0 spent, and the
      // top-N widget shouldn't surface them at all.
      if (entry.value <= 0) continue;
      final cat = categoryLookup[entry.key];
      if (cat == null) continue;
      entries.add((name: cat.name, color: cat.color, totalCents: entry.value));
    }

    final uncategorizedCents = _monthTransactions
        .where(
          (t) => t.amount < 0 && t.categoryId == null && t.receiptId == null,
        )
        .fold<int>(0, (sum, t) => sum + t.amount.abs());
    if (uncategorizedCents > 0) {
      entries.add((
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
    for (final tx in recentTransactions30d.where((t) => t.amount < 0)) {
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
      recentTransactions30d: [],
      recentTransactions: [],
    );
  }

  final accountsRepo = ref.read(accountsRepositoryProvider);
  final txRepo = ref.read(transactionsRepositoryProvider);
  final budgetRepo = ref.read(budgetRepositoryProvider);

  final now = DateTime.now();
  final thirtyDaysAgo = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 29));
  final today = DateTime(now.year, now.month, now.day);
  // The Suggestions / Top Categories rollup operates on calendar-month
  // boundaries (matches monthlySpending/monthlyIncome), so the RPC
  // window is "first of this month → today". Using thirtyDaysAgo here
  // would let mid-late-month spend leak from the previous month.
  final monthStart = DateTime(now.year, now.month, 1);

  final (accounts, recent30d, recent5, spendByCat, categories) = await (
    accountsRepo.fetchAccounts(householdId),
    txRepo.fetchTransactionsForDashboard(
      householdId: householdId,
      from: thirtyDaysAgo,
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

  return DashboardData(
    accounts: accounts,
    recentTransactions30d: recent30d,
    recentTransactions: recent5,
    spendingByCategory: spendByCat,
    categoryLookup: {for (final c in categories) c.id: c},
  );
}
