// Pure-Dart CSV serialization for a list of transactions.
//
// Designed for tax-time export: one row per transaction with the
// columns a tax preparer or spreadsheet would want — date, what was
// bought, where, the category, signed dollar amount, the account
// it came from, and any tags. Tag filtering is up to the caller;
// this function just serializes what it's handed.
//
// Kept as a top-level function (not a class) so the export-action
// callsite can pass everything in and the function does no IO.
// Unit-testable without a Supabase stack — see
// transactions_csv_test.dart.

import 'package:csv/csv.dart';

import '../../../core/utils/dates.dart';
import '../../accounts/models/account.dart';
import '../models/transaction.dart';
import '../models/transaction_tag.dart';

/// Header row order. Documented as a constant so the unit test can
/// assert column positions and call sites don't have to guess.
const List<String> transactionsCsvHeader = [
  'Date',
  'Description',
  'Merchant',
  'Category',
  'Amount',
  'Account',
  'Tags',
];

/// Serializes [transactions] as a CSV string with [transactionsCsvHeader]
/// as the first row.
///
/// - [accountsById] and [tagsById] resolve account/tag ids to names.
///   Unknown ids render as empty strings, not "Unknown" — a spreadsheet
///   filter on missing accounts shouldn't false-match a literal label.
/// - [tagAssignments] is the same shape the transactions screen uses
///   (`txId → Set<tagId>`). Tags are joined into a single comma-
///   separated cell; the CSV layer already escapes commas via field
///   quoting so this doesn't create injection.
/// - Amount is rendered as a signed decimal in dollars (e.g.
///   "-12.34"). Negative = debit, positive = credit, matching the
///   rest of the app's convention. Cents kept in the conversion so
///   "0.10" doesn't become "0.1" on locales with a different
///   decimal separator (we force '.' regardless).
String transactionsToCsv({
  required List<Transaction> transactions,
  required Map<String, Account> accountsById,
  required Map<String, TransactionTag> tagsById,
  required Map<String, Set<String>> tagAssignments,
}) {
  final dateFmt = kIsoDate;

  final rows = <List<String>>[
    transactionsCsvHeader,
    for (final t in transactions)
      [
        dateFmt.format(t.transactionDate),
        t.description,
        t.merchant ?? '',
        t.category?.name ?? '',
        _formatAmount(t.amount),
        accountsById[t.accountId]?.name ?? '',
        _joinTags(tagAssignments[t.id], tagsById),
      ],
  ];

  // Default field delimiter is comma, default eol is \r\n. Forcing
  // an explicit CRLF here so Excel on Windows opens the export
  // without quirks; macOS / Linux readers tolerate it fine.
  return const ListToCsvConverter(eol: '\r\n').convert(rows);
}

/// Renders [cents] as a signed dollar amount with two decimal places.
/// Forces '.' as the decimal separator regardless of locale so a CSV
/// generated on a comma-locale device still imports cleanly into
/// Excel's "Text Import Wizard" with US settings.
String _formatAmount(int cents) {
  final negative = cents < 0;
  final magnitude = cents.abs();
  final dollars = magnitude ~/ 100;
  final remainder = magnitude % 100;
  final remainderStr = remainder.toString().padLeft(2, '0');
  return '${negative ? '-' : ''}$dollars.$remainderStr';
}

/// Joins the tag names for a transaction into "tagA, tagB". Returns
/// empty string when there are no tags. Names alphabetized for
/// stable output — otherwise the CSV order would shift on every
/// regen as Postgres returns rows in arbitrary join order.
String _joinTags(Set<String>? tagIds, Map<String, TransactionTag> tagsById) {
  if (tagIds == null || tagIds.isEmpty) return '';
  final names = <String>[];
  for (final id in tagIds) {
    final tag = tagsById[id];
    if (tag != null) names.add(tag.name);
  }
  names.sort();
  return names.join(', ');
}
