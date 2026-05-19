// Unit tests for [transactionsToCsv]. Pure Dart — exercises the
// formatter shape directly, no Supabase or widget tree involved.
//
// What's pinned:
//   * header row order matches [transactionsCsvHeader] (consumers
//     reading by position rely on this)
//   * amounts render as signed decimals with two places
//   * tag names are alphabetized within a cell for stable output
//   * empty optional fields render as empty cells, not "null" or
//     a literal placeholder string
//   * a comma in a transaction's description gets correctly quoted
//     by the CSV layer

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/accounts/models/account.dart';
import 'package:mybudget/features/transactions/models/category.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';
import 'package:mybudget/features/transactions/models/transaction_tag.dart';
import 'package:mybudget/features/transactions/services/transactions_csv.dart';

Account _account(String id, String name) {
  final ts = DateTime.utc(2026, 1, 1);
  return Account(
    id: id,
    householdId: 'h',
    ownerUserId: 'u',
    name: name,
    accountType: AccountType.checking,
    currency: 'USD',
    currentBalance: 0,
    isActive: true,
    createdAt: ts,
    updatedAt: ts,
  );
}

TransactionTag _tag(String id, String name) {
  return TransactionTag(
    id: id,
    householdId: 'h',
    name: name,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

Transaction _tx({
  required String id,
  required int amount,
  required DateTime date,
  required String accountId,
  String description = 'test',
  String? merchant,
  Category? category,
}) {
  final ts = DateTime.utc(2026, 1, 1);
  return Transaction(
    id: id,
    householdId: 'h',
    accountId: accountId,
    amount: amount,
    currency: 'USD',
    description: description,
    merchant: merchant,
    transactionDate: date,
    pending: false,
    source: 'manual',
    createdAt: ts,
    updatedAt: ts,
    categoryId: category?.id,
    category: category,
  );
}

void main() {
  group('transactionsToCsv', () {
    test('header row matches transactionsCsvHeader in order', () {
      final out = transactionsToCsv(
        transactions: const [],
        accountsById: const {},
        tagsById: const {},
        tagAssignments: const {},
      );
      final parsed = const CsvToListConverter(
        eol: '\r\n',
        shouldParseNumbers: false,
      ).convert(out);
      expect(parsed, hasLength(1));
      expect(parsed.first, transactionsCsvHeader);
    });

    test('renders amounts as signed two-place decimals', () {
      final tx = _tx(
        id: 't1',
        amount: -1234,
        date: DateTime.utc(2026, 3, 15),
        accountId: 'a1',
      );
      final out = transactionsToCsv(
        transactions: [tx],
        accountsById: {'a1': _account('a1', 'Checking')},
        tagsById: const {},
        tagAssignments: const {},
      );
      final parsed = const CsvToListConverter(
        eol: '\r\n',
        shouldParseNumbers: false,
      ).convert(out);
      // First data row, amount is at index 4 per the header order.
      expect(parsed[1][4], '-12.34');
    });

    test('renders single-digit cents with leading zero', () {
      // Regression: $0.10 dropping to "0.1" would misimport in
      // spreadsheets that auto-detect a one-decimal column as
      // integer-ish.
      final tx = _tx(
        id: 't1',
        amount: 10,
        date: DateTime.utc(2026, 1, 1),
        accountId: 'a1',
      );
      final out = transactionsToCsv(
        transactions: [tx],
        accountsById: {'a1': _account('a1', 'Checking')},
        tagsById: const {},
        tagAssignments: const {},
      );
      final parsed = const CsvToListConverter(
        eol: '\r\n',
        shouldParseNumbers: false,
      ).convert(out);
      expect(parsed[1][4], '0.10');
    });

    test('joins tag names alphabetically into one cell', () {
      // Two tags assigned in arbitrary set order; the CSV must
      // surface them alphabetized so repeated regenerations don't
      // diff every line.
      final tx = _tx(
        id: 't1',
        amount: -500,
        date: DateTime.utc(2026, 1, 1),
        accountId: 'a1',
      );
      final out = transactionsToCsv(
        transactions: [tx],
        accountsById: {'a1': _account('a1', 'Checking')},
        tagsById: {
          'tagB': _tag('tagB', 'zebra'),
          'tagA': _tag('tagA', 'aardvark'),
        },
        tagAssignments: const {
          't1': {'tagB', 'tagA'},
        },
      );
      final parsed = const CsvToListConverter(
        eol: '\r\n',
        shouldParseNumbers: false,
      ).convert(out);
      expect(parsed[1][6], 'aardvark, zebra');
    });

    test('quotes commas in descriptions so the CSV stays well-formed', () {
      // The csv package handles the quoting; this just confirms the
      // output round-trips through CsvToListConverter as a single
      // field, not two.
      final tx = _tx(
        id: 't1',
        amount: -100,
        date: DateTime.utc(2026, 1, 1),
        accountId: 'a1',
        description: 'Hello, world',
      );
      final out = transactionsToCsv(
        transactions: [tx],
        accountsById: {'a1': _account('a1', 'Checking')},
        tagsById: const {},
        tagAssignments: const {},
      );
      final parsed = const CsvToListConverter(
        eol: '\r\n',
        shouldParseNumbers: false,
      ).convert(out);
      // Description sits at column 1; "Hello, world" is one field.
      expect(parsed[1][1], 'Hello, world');
    });

    test('missing account / category / merchant render as empty cells', () {
      // None of these are required on a Transaction. The CSV must
      // not surface placeholder strings like "Unknown" because a
      // spreadsheet filter on missing data would false-match them.
      final tx = _tx(
        id: 't1',
        amount: -100,
        date: DateTime.utc(2026, 1, 1),
        accountId: 'a1', // not in accountsById below
      );
      final out = transactionsToCsv(
        transactions: [tx],
        accountsById: const {},
        tagsById: const {},
        tagAssignments: const {},
      );
      final parsed = const CsvToListConverter(
        eol: '\r\n',
        shouldParseNumbers: false,
      ).convert(out);
      // Merchant at 2, Category at 3, Account at 5.
      expect(parsed[1][2], '');
      expect(parsed[1][3], '');
      expect(parsed[1][5], '');
    });

    test('formats date as ISO yyyy-MM-dd', () {
      final tx = _tx(
        id: 't1',
        amount: -100,
        date: DateTime.utc(2026, 3, 5),
        accountId: 'a1',
      );
      final out = transactionsToCsv(
        transactions: [tx],
        accountsById: {'a1': _account('a1', 'Checking')},
        tagsById: const {},
        tagAssignments: const {},
      );
      final parsed = const CsvToListConverter(
        eol: '\r\n',
        shouldParseNumbers: false,
      ).convert(out);
      expect(parsed[1][0], '2026-03-05');
    });
  });
}
