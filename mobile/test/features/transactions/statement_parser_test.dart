// Tests for the CSV statement parser.
//
// Pins three previously-broken behaviours:
//   1. Refund descriptions ("PAYMENT REFUND") are signed positive even when
//      both deposit AND withdrawal keywords are present (credit wins).
//   2. Split debit/credit-column statements (Wells Fargo, some Capital One)
//      no longer drop one of the columns.
//   3. Dedup keys are stable across casing/whitespace differences in the
//      description, so re-importing after the bank cleans up its export
//      doesn't double-insert.
//
// Plus general coverage of single-amount parsing, accounting parens,
// duplicate-row occurrence suffixes, and graceful skipping of bad rows.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/services/statement_parser.dart';

void main() {
  group('parseStatementCsv — single signed amount column', () {
    test('parses a basic three-column statement', () {
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,STARBUCKS #123,-4.50\n'
          '01/16/2026,PAYROLL DEPOSIT,2500.00\n';
      final result = parseStatementCsv(csv);
      expect(result.rows, hasLength(2));
      expect(result.skipped, isEmpty);
      expect(result.rows[0].amountCents, -450);
      expect(result.rows[0].description, 'STARBUCKS #123');
      expect(result.rows[0].date, DateTime(2026, 1, 15));
      expect(result.rows[1].amountCents, 250000);
    });

    test('uses Decimal arithmetic so 19.99 → 1999, not 1998', () {
      // double((19.99) * 100) is 1998.9999999999998. Decimal-then-round
      // gives the right answer; this test pins the cents invariant.
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,WIDGET,-19.99\n'
          '01/15/2026,WIDGET2,-0.10\n';
      final result = parseStatementCsv(csv);
      expect(result.rows[0].amountCents, -1999);
      expect(result.rows[1].amountCents, -10);
    });

    test('handles accounting-style parens as negative', () {
      const csv = 'Date,Description,Amount\n01/15/2026,PURCHASE,(12.34)\n';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.amountCents, -1234);
    });

    test('strips currency symbols and commas', () {
      const csv = 'Date,Description,Amount\n01/15/2026,DEPOSIT,"\$1,234.56"\n';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.amountCents, 123456);
    });
  });

  group('parseStatementCsv — sign inference for unsigned exports', () {
    test('infers negative from withdrawal keywords', () {
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,WITHDRAWAL ATM,40.00\n'
          '01/15/2026,DEBIT CARD PURCHASE,12.50\n';
      final result = parseStatementCsv(csv);
      expect(result.rows[0].amountCents, -4000);
      expect(result.rows[1].amountCents, -1250);
    });

    test('infers positive from deposit keywords', () {
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,DIRECT DEPOSIT,2500.00\n';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.amountCents, 250000);
    });

    test('credit keyword wins on overlap (REFUND beats PAYMENT)', () {
      // Regression for the original mis-signed-refund bug. The old code
      // checked debit keywords first, so "PAYMENT REFUND" came out as -ve.
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,PAYMENT REFUND TO CARD,25.00\n'
          '01/15/2026,DEBIT REVERSAL,15.00\n';
      final result = parseStatementCsv(csv);
      expect(result.rows[0].amountCents, 2500);
      expect(result.rows[1].amountCents, 1500);
    });

    test('explicit sign on the value is always trusted over keywords', () {
      // Negative value with a deposit keyword → still negative. The bank's
      // sign is more reliable than our heuristic.
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,DEPOSIT REVERSAL,-100.00\n';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.amountCents, -10000);
    });

    test('no keyword → positive (preview row prompts manual review)', () {
      const csv = 'Date,Description,Amount\n01/15/2026,XYZ CORP,42.00\n';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.amountCents, 4200);
    });
  });

  group('parseStatementCsv — split debit/credit columns', () {
    test('debit column → negative cents, credit column → positive cents', () {
      // Format: Wells Fargo–style two-column. Both columns positive.
      const csv =
          'Date,Description,Debit,Credit\n'
          '01/15/2026,STARBUCKS,4.50,\n'
          '01/16/2026,PAYROLL,,2500.00\n';
      final result = parseStatementCsv(csv);
      expect(result.skipped, isEmpty);
      expect(result.rows[0].amountCents, -450);
      expect(result.rows[1].amountCents, 250000);
    });

    test('matches "Withdrawal" / "Deposit" header synonyms', () {
      const csv =
          'Date,Description,Withdrawal,Deposit\n'
          '01/15/2026,ATM,40.00,\n'
          '01/16/2026,REFUND,,12.34\n';
      final result = parseStatementCsv(csv);
      expect(result.rows[0].amountCents, -4000);
      expect(result.rows[1].amountCents, 1234);
    });

    test('skips rows where both debit and credit are empty', () {
      const csv =
          'Date,Description,Debit,Credit\n'
          '01/15/2026,EMPTY ROW,,\n';
      final result = parseStatementCsv(csv);
      expect(result.rows, isEmpty);
      expect(result.skipped, hasLength(1));
      expect(
        result.skipped.single,
        contains('debit and credit columns both empty'),
      );
    });

    test('imports both-non-zero rows with a warning, preferring credit', () {
      // A well-formed statement shouldn't have both columns filled, but
      // refund pairs occasionally land this way. Don't drop the row —
      // import using the credit value and surface the anomaly so the
      // user can sanity-check before confirming.
      const csv =
          'Date,Description,Debit,Credit\n'
          '01/15/2026,REFUND PAIR,4.50,4.50\n';
      final result = parseStatementCsv(csv);
      expect(result.rows, hasLength(1));
      expect(result.rows.single.amountCents, 450);
      expect(result.skipped, isEmpty);
      expect(result.warnings, hasLength(1));
      expect(result.warnings.single, contains('Row 2'));
      expect(result.warnings.single, contains('non-zero'));
    });

    test('single Amount column takes precedence over split columns', () {
      // Banks that include all three columns (Amount + zero-stub Debit/
      // Credit) parse via the signed Amount path.
      const csv =
          'Date,Description,Amount,Debit,Credit\n'
          '01/15/2026,STARBUCKS,-4.50,,\n';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.amountCents, -450);
    });
  });

  group('parseStatementCsv — header detection', () {
    test('prefers "Transaction Date" over a generic "Date" column', () {
      // If a CSV has both "Posting Date" and "Transaction Date", we want
      // the latter (the date the user perceives the transaction occurring).
      const csv =
          'Posting Date,Transaction Date,Description,Amount\n'
          '01/16/2026,01/15/2026,STARBUCKS,-4.50\n';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.date, DateTime(2026, 1, 15));
    });

    test('matches Description, Payee, Merchant, Memo, or Name', () {
      const csv = 'Date,Memo,Amount\n01/15/2026,STARBUCKS,-4.50\n';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.description, 'STARBUCKS');
    });

    test('throws FormatException when required columns are missing', () {
      const csv = 'When,What\n01/15/2026,STARBUCKS\n';
      expect(() => parseStatementCsv(csv), throwsA(isA<FormatException>()));
    });

    test('throws when the file has only a header (or is empty)', () {
      expect(
        () => parseStatementCsv('Date,Description,Amount\n'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('parseStatementCsv — dedup keys (externalId)', () {
    test('normalises description case and whitespace', () {
      // Same logical row, two formatting variants. Their externalIds
      // (minus the occurrence suffix) must match — that's how server-side
      // dedup catches the second import.
      const csv1 =
          'Date,Description,Amount\n'
          '01/15/2026,WALMART  #123,-12.34\n';
      const csv2 =
          'Date,Description,Amount\n'
          '01/15/2026,Walmart #123,-12.34\n';
      final a = parseStatementCsv(csv1).rows.single.externalId;
      final b = parseStatementCsv(csv2).rows.single.externalId;
      expect(a, b);
    });

    test('appends an occurrence suffix for legitimate duplicate rows', () {
      // Two identical purchases on the same day must NOT collide on the
      // (account_id, external_id) UNIQUE constraint server-side.
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,STARBUCKS,-4.50\n'
          '01/15/2026,STARBUCKS,-4.50\n';
      final ids = parseStatementCsv(csv).rows.map((r) => r.externalId).toList();
      expect(ids[0], isNot(ids[1]));
      // Suffixes are 1 and 2 (deterministic, useful for debugging dedup).
      expect(ids[0].endsWith('_1'), isTrue);
      expect(ids[1].endsWith('_2'), isTrue);
    });

    test('different signs produce different externalIds', () {
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,STARBUCKS,-4.50\n'
          '01/15/2026,STARBUCKS,4.50\n';
      final ids = parseStatementCsv(csv).rows.map((r) => r.externalId).toList();
      // Different cents → different baseKey → fresh occurrence counter
      // per baseKey, so both end at _1.
      expect(ids[0], isNot(ids[1]));
    });
  });

  group('parseStatementCsv — date format flexibility', () {
    test('accepts MM/dd/yyyy, M/d/yy, and yyyy-MM-dd', () {
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,A,-1.00\n'
          '1/15/26,B,-1.00\n'
          '2026-01-15,C,-1.00\n';
      final result = parseStatementCsv(csv);
      expect(result.rows, hasLength(3));
      for (final r in result.rows) {
        expect(r.date, DateTime(2026, 1, 15));
      }
    });

    test('skips rows with an unrecognised date', () {
      const csv =
          'Date,Description,Amount\n'
          '15-Jan-2026,STARBUCKS,-4.50\n';
      final result = parseStatementCsv(csv);
      expect(result.rows, isEmpty);
      expect(result.skipped.single, contains('unrecognised date format'));
    });
  });

  group('parseStatementCsv — bad-row handling', () {
    test('skips short rows without aborting the rest', () {
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,STARBUCKS,-4.50\n'
          ',,\n'
          '01/16/2026,VALID,-2.00\n';
      final result = parseStatementCsv(csv);
      expect(result.rows, hasLength(2));
      expect(result.skipped, hasLength(1));
    });

    test('skips a row with non-numeric amount', () {
      const csv =
          'Date,Description,Amount\n'
          '01/15/2026,STARBUCKS,whoops\n';
      final result = parseStatementCsv(csv);
      expect(result.rows, isEmpty);
      expect(result.skipped.single, contains('no numeric value'));
    });
  });

  group('parseStatementCsv — line endings', () {
    test('handles CRLF (Windows) line endings', () {
      const csv =
          'Date,Description,Amount\r\n'
          '01/15/2026,STARBUCKS,-4.50\r\n';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.amountCents, -450);
    });
  });
}
