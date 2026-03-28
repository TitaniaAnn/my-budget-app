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

  const DashboardData({
    required this.accounts,
    required this.recentTransactions30d,
    required this.recentTransactions,
  });

  // ── Monthly summary (current calendar month) ──────────────────────────────

  DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  List<Transaction> get _monthTransactions =>
      recentTransactions30d.where((t) => !t.transactionDate.isBefore(_monthStart)).toList();

  /// Net worth = assets minus credit card debt.
  int get netWorth => accounts.fold<int>(0, (sum, a) {
        if (a.accountType == AccountType.creditCard) {
          return sum - a.currentBalance.abs();
        }
        return sum + a.currentBalance;
      });

  /// Total spending this month (expenses only, as positive cents).
  int get monthlySpending => _monthTransactions
      .where((t) => t.amount < 0)
      .fold<int>(0, (sum, t) => sum + t.amount.abs());

  /// Total income this month.
  int get monthlyIncome => _monthTransactions
      .where((t) => t.amount > 0)
      .fold<int>(0, (sum, t) => sum + t.amount);

  /// Top 5 spending categories this month, sorted by total descending.
  List<({String name, String? color, int totalCents})> get topCategories {
    final totals = <String, ({String name, String? color, int totalCents})>{};
    for (final tx in _monthTransactions.where((t) => t.amount < 0)) {
      final key = tx.categoryId ?? '__none__';
      final existing = totals[key];
      totals[key] = (
        name: tx.category?.name ?? 'Uncategorized',
        color: tx.category?.color,
        totalCents: (existing?.totalCents ?? 0) + tx.amount.abs(),
      );
    }
    final sorted = totals.values.toList()
      ..sort((a, b) => b.totalCents.compareTo(a.totalCents));
    return sorted.take(5).toList();
  }

  // ── 30-day spending sparkline ──────────────────────────────────────────────

  /// Daily spending totals for the last 30 days.
  /// Index 0 = 29 days ago, index 29 = today. Missing days default to 0.
  List<int> get spendingByDay {
    final today = DateTime.now();
    final result = List<int>.filled(30, 0);
    for (final tx in recentTransactions30d.where((t) => t.amount < 0)) {
      final daysAgo = today
          .difference(DateTime(tx.transactionDate.year,
              tx.transactionDate.month, tx.transactionDate.day))
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

  final now = DateTime.now();
  final thirtyDaysAgo = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 29));
  final today = DateTime(now.year, now.month, now.day);

  final (accounts, recent30d, recent5) = await (
    accountsRepo.fetchAccounts(householdId),
    txRepo.fetchTransactionsForDashboard(
      householdId: householdId,
      from: thirtyDaysAgo,
      to: today,
    ),
    txRepo.fetchTransactions(householdId: householdId, limit: 5),
  ).wait;

  return DashboardData(
    accounts: accounts,
    recentTransactions30d: recent30d,
    recentTransactions: recent5,
  );
}
