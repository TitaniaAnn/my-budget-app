// Per-account balance reconstruction at a fixed past date.
//
// `accounts.current_balance` is authoritative for "right now". The
// monthly report needs balance AS OF the report's month-end, which
// for any month except the current one is in the past. The math is
// the same backward-walk pattern as
// [`reconstructHistoricalNetWorth`](../../scenarios/repositories/scenarios_repository.dart),
// adapted to a single snapshot instead of a series and to per-account
// rather than household-wide:
//
//   balance(account, monthEnd) =
//     current_balance(account) − SUM(t.amount
//       FOR t in transactions WHERE account = account
//                               AND transaction_date > monthEnd)
//
// Transactions dated ON the month-end day are part of that month's
// closing balance, hence the strict `>`.
//
// Pure function for the usual reason: the math sits behind a network
// boundary in the screen, but the math itself is easier to trust if
// it can be unit-tested without one.

import '../../transactions/models/transaction.dart';
import '../models/monthly_report_data.dart';
import '../../accounts/models/account.dart';

/// Returns per-account closing balances at [closingAsOf], computed by
/// undoing the [transactionsAfterClose] from each account's
/// [Account.currentBalance].
///
/// [transactionsAfterClose] must already be filtered to rows with
/// `transaction_date > closingAsOf`. The function is intentionally
/// strict about this — sanity-checking the filter here would mask a
/// bug in the caller. Transfer legs are kept (their amounts move
/// money between two of the household's own accounts, so the
/// walkback subtracts them and the balances net out).
///
/// Sort: descending by `|balanceCents|`. Households with mixed
/// liabilities and assets see the biggest absolute positions first
/// — for someone with a $500k mortgage and a $1k checking balance,
/// the mortgage is more interesting at a glance than the checking.
List<MonthlyReportAccountBalance> closingBalancesAtMonthEnd({
  required List<Account> accounts,
  required List<Transaction> transactionsAfterClose,
  required DateTime closingAsOf,
}) {
  // Index transactions by account so we don't scan the full list per
  // account. A household with N accounts and T transactions in the
  // post-close window would otherwise be O(N·T); now it's O(T+N).
  final deltasByAccount = <String, int>{};
  for (final t in transactionsAfterClose) {
    deltasByAccount.update(
      t.accountId,
      (sum) => sum + t.amount,
      ifAbsent: () => t.amount,
    );
  }

  final rows = <MonthlyReportAccountBalance>[];
  for (final a in accounts) {
    final delta = deltasByAccount[a.id] ?? 0;
    rows.add(
      MonthlyReportAccountBalance(
        accountName: a.name,
        accountType: a.accountType,
        balanceCents: a.currentBalance - delta,
        // Carry the account's own currency through so the renderer
        // formats each row in its native units. A multi-currency
        // household sees "Checking: $1,234.56 / Savings: €567.89"
        // rather than a misleading aggregated USD figure per row.
        nativeCurrency: a.currency,
      ),
    );
  }

  rows.sort((a, b) => b.balanceCents.abs().compareTo(a.balanceCents.abs()));
  return rows;
}
