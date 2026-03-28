// Dashboard data provider.
//
// Rather than issuing many small Supabase queries, a single provider assembles
// all the data the dashboard needs so the screen has one loading state and one
// error boundary.
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

  /// Transactions from the current calendar month.
  final List<Transaction> monthTransactions;

  /// The 5 most recent transactions across all accounts.
  final List<Transaction> recentTransactions;

  const DashboardData({
    required this.accounts,
    required this.monthTransactions,
    required this.recentTransactions,
  });

  /// Net worth = sum of all balances, minus credit card balances (they're debt).
  int get netWorth => accounts.fold<int>(0, (sum, a) {
        if (a.accountType == AccountType.creditCard) {
          return sum - a.currentBalance.abs();
        }
        return sum + a.currentBalance;
      });

  /// Total money that left accounts this month (expenses only, as positive cents).
  int get monthlySpending => monthTransactions
      .where((t) => t.amount < 0)
      .fold<int>(0, (sum, t) => sum + t.amount.abs());

  /// Total money that entered accounts this month.
  int get monthlyIncome => monthTransactions
      .where((t) => t.amount > 0)
      .fold<int>(0, (sum, t) => sum + t.amount);

  /// Top spending categories this month, sorted by total descending.
  /// Uncategorized transactions are grouped under a single "Uncategorized" entry.
  List<({String name, String? color, int totalCents})> get topCategories {
    final totals = <String, ({String name, String? color, int totalCents})>{};

    for (final tx in monthTransactions.where((t) => t.amount < 0)) {
      final key = tx.categoryId ?? '__none__';
      final name = tx.category?.name ?? 'Uncategorized';
      final color = tx.category?.color;
      final existing = totals[key];
      totals[key] = (
        name: name,
        color: color,
        totalCents: (existing?.totalCents ?? 0) + tx.amount.abs(),
      );
    }

    final sorted = totals.values.toList()
      ..sort((a, b) => b.totalCents.compareTo(a.totalCents));

    // Show at most 5 categories to keep the dashboard scannable.
    return sorted.take(5).toList();
  }
}

/// Fetches all dashboard data in parallel using [Future.wait] to minimise
/// total round-trip time. Watches [householdIdProvider] so it refreshes
/// automatically if the user somehow switches household.
@riverpod
Future<DashboardData> dashboardData(DashboardDataRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) {
    return const DashboardData(
      accounts: [],
      monthTransactions: [],
      recentTransactions: [],
    );
  }

  final accountsRepo = ref.read(accountsRepositoryProvider);
  final txRepo = ref.read(transactionsRepositoryProvider);

  // Current month boundaries for the spending/income summary.
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0); // last day of month

  // Fire all three queries in parallel.
  final results = await Future.wait([
    accountsRepo.fetchAccounts(householdId),
    txRepo.fetchTransactionsForDashboard(
      householdId: householdId,
      from: monthStart,
      to: monthEnd,
    ),
    txRepo.fetchTransactions(householdId: householdId, limit: 5),
  ]);

  return DashboardData(
    accounts: results[0] as List<Account>,
    monthTransactions: results[1] as List<Transaction>,
    recentTransactions: results[2] as List<Transaction>,
  );
}
