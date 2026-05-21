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

  // ── ColumnMapping override (manual matching path) ────────────────────────
  //
  // The auto-detect heuristic doesn't catch every bank. When it fails, the
  // import UI surfaces an override sheet that lets the user pick columns
  // manually; the parser accepts that mapping verbatim. Pinned here:
  //   * a mapping passed in skips auto-detection (headers that wouldn't
  //     have matched still parse cleanly);
  //   * ColumnDetectionFailure carries the headers (the override sheet
  //     needs them to populate dropdowns) and IS-A FormatException so
  //     existing callers catching FormatException keep working;
  //   * headerFingerprint is stable across casing + whitespace differences
  //     (a "Date " vs "date" round-trip mustn't invalidate a saved preset).

  group('parseStatementCsv — manual column mapping override', () {
    test('skips auto-detect and parses headers the heuristic would reject', () {
      // Header row uses non-standard names that the auto-detect
      // candidate lists wouldn't match. With a manual mapping the
      // parser should still produce rows.
      const csv =
          'when,who,how_much\n'
          '2026-05-01,COFFEE SHOP,-4.50\n'
          '2026-05-02,PAYDAY,2500.00\n';
      const mapping = ColumnMapping.signed(
        dateIdx: 0,
        descIdx: 1,
        amountIdx: 2,
      );
      final result = parseStatementCsv(csv, mapping: mapping);
      expect(result.rows, hasLength(2));
      expect(result.rows.first.description, 'COFFEE SHOP');
      expect(result.rows.first.amountCents, -450);
      expect(result.rows.last.amountCents, 250000);
    });

    test('mapping override path also handles the split-debit/credit shape', () {
      const csv =
          'd,desc,out,in\n'
          '2026-05-01,GROCERIES,42.10,\n'
          '2026-05-02,REFUND,,15.00\n';
      const mapping = ColumnMapping.split(
        dateIdx: 0,
        descIdx: 1,
        debitIdx: 2,
        creditIdx: 3,
      );
      final result = parseStatementCsv(csv, mapping: mapping);
      expect(result.rows.map((r) => r.amountCents), [-4210, 1500]);
    });

    test('ColumnDetectionFailure exposes headers and is a FormatException', () {
      // Headers the heuristic can't lock onto. The exception must
      // carry the parsed headers so the override sheet can populate
      // its dropdowns from them.
      const csv =
          'when,who,how_much\n'
          '2026-05-01,COFFEE SHOP,-4.50\n';
      ColumnDetectionFailure? caught;
      try {
        parseStatementCsv(csv);
      } on ColumnDetectionFailure catch (e) {
        caught = e;
      }
      expect(caught, isNotNull);
      expect(caught!.headers, ['when', 'who', 'how_much']);
      expect(
        caught,
        isA<FormatException>(),
        reason:
            'subclassing FormatException keeps existing callers '
            'catching FormatException working; this is the bridge '
            'between the old single-error API and the new '
            'headers-aware override flow.',
      );
    });
  });

  group('headerFingerprint', () {
    test('stable across casing + whitespace differences', () {
      // The lookup key for saved overrides has to survive cosmetic
      // header changes between exports, otherwise a saved preset
      // would silently miss when the bank capitalises a header.
      final a = headerFingerprint(['Date', 'Description', 'Amount']);
      final b = headerFingerprint(['date', 'description ', ' amount']);
      expect(a, b);
    });

    test('different headers produce different fingerprints', () {
      final a = headerFingerprint(['date', 'description', 'amount']);
      final b = headerFingerprint(['date', 'description', 'debit', 'credit']);
      expect(a, isNot(b));
    });

    test('header reorder produces a different fingerprint', () {
      // Column order matters — a CSV with the same headers in a
      // different order has a different shape from the parser's
      // perspective.
      final a = headerFingerprint(['date', 'description', 'amount']);
      final b = headerFingerprint(['amount', 'description', 'date']);
      expect(a, isNot(b));
    });
  });

  group('detectColumnMapping', () {
    test('returns a signed mapping when amount column is present', () {
      final m = detectColumnMapping(['date', 'description', 'amount']);
      expect(m, isNotNull);
      expect(m!.isSplit, isFalse);
      expect(m.amountIdx, 2);
    });

    test(
      'returns a split mapping when only debit/credit columns are present',
      () {
        final m = detectColumnMapping([
          'date',
          'description',
          'debit',
          'credit',
        ]);
        expect(m, isNotNull);
        expect(m!.isSplit, isTrue);
        expect(m.debitIdx, 2);
        expect(m.creditIdx, 3);
      },
    );

    test('returns null when the heuristic can\'t lock on', () {
      // Missing description column — the auto-detect can't proceed.
      // The UI uses this null to know it needs the override sheet.
      final m = detectColumnMapping(['when', 'who', 'how_much']);
      expect(m, isNull);
    });
  });

  group('extractHeaders', () {
    test('returns lowercased + trimmed headers from the first row', () {
      // The UI's override sheet uses this to populate its dropdowns
      // and to feed headerFingerprint for preset lookup. Casing /
      // whitespace MUST be normalised so the fingerprint stays
      // stable across re-exports of the same statement.
      const csv = ' Date , Description , Amount\n01/15/2026,X,1.00\n';
      expect(extractHeaders(csv), ['date', 'description', 'amount']);
    });

    test('handles a file with only a header row (no data)', () {
      // An empty statement export is rare but legal — header line
      // with nothing under it. The UI still wants the header list
      // for the override sheet.
      expect(extractHeaders('Date,Description,Amount\n'), [
        'date',
        'description',
        'amount',
      ]);
    });

    test('returns empty list when the file is totally empty', () {
      expect(extractHeaders(''), isEmpty);
    });

    test('normalises CRLF line endings before extracting', () {
      // Same Windows-CRLF case as the parser proper — the header
      // extractor must agree, otherwise the fingerprint could shift
      // between platforms.
      expect(extractHeaders('Date,Amount\r\n01/15/2026,1.00\r\n'), [
        'date',
        'amount',
      ]);
    });
  });

  group('parseStatementCsv — 2-digit year pivot', () {
    test('"01/15/26" pivots to 2026, not year 0026', () {
      // intl's M/d/yy happily parses "26" as year 0026 unless we
      // explicitly pivot. The parser shifts any sub-100 year up to
      // 20xx — bank statements never show pre-2000 dates. Without
      // this guard, transactions would land 2000 years in the past
      // and never appear in the recent-window queries.
      const csv = '''
Date,Description,Amount
01/15/26,Test,1.00
''';
      final result = parseStatementCsv(csv);
      expect(result.rows, hasLength(1));
      expect(result.rows.single.date, DateTime(2026, 1, 15));
    });

    test('"1/5/30" pivots to 2030 (single-digit M/d shape)', () {
      const csv = '''
Date,Description,Amount
1/5/30,Test,1.00
''';
      final result = parseStatementCsv(csv);
      expect(result.rows.single.date, DateTime(2030, 1, 5));
    });
  });

  group('parseStatementCsv — line endings', () {
    test('handles bare CR (old Mac / OFX-converted exports)', () {
      // Some legacy export pipelines use \r-only line endings. The
      // parser normalises CR → LF before handing to csv. Without
      // this the whole file looks like a single row to the CSV
      // tokenizer and the parser throws "appears empty".
      const csv =
          'Date,Description,Amount\r01/15/2026,A,1.00\r01/16/2026,B,2.00\r';
      final result = parseStatementCsv(csv);
      expect(result.rows, hasLength(2));
      expect(result.rows[0].description, 'A');
      expect(result.rows[1].description, 'B');
    });
  });

  group('parseStatementCsv — split-column edge cases', () {
    test('both columns present as "0" returns 0 cents (not skipped)', () {
      // A row with explicit zeros in both debit and credit columns
      // is rare but legal — e.g., a fee-waived placeholder posted
      // by some banks. The parser imports it as 0 cents so the
      // ledger still records the activity rather than silently
      // dropping it.
      const csv = '''
Date,Description,Debit,Credit
01/15/2026,Fee waived,0,0
''';
      final result = parseStatementCsv(csv);
      expect(result.rows, hasLength(1));
      expect(result.rows.single.amountCents, 0);
      expect(result.skipped, isEmpty);
    });
  });

  group('parseStatementCsv — whitespace-only field handling', () {
    test('row with whitespace-only date is skipped', () {
      // .trim() on the cell collapses " " to "", which the
      // empty-string guard catches. Pin so a future refactor that
      // moves the trim doesn't silently let bad rows through.
      const csv = '''
Date,Description,Amount
   ,Test,1.00
''';
      final result = parseStatementCsv(csv);
      expect(result.rows, isEmpty);
      expect(result.skipped.single, contains('empty date'));
    });

    test('row with whitespace-only description is skipped', () {
      const csv = '''
Date,Description,Amount
01/15/2026,   ,1.00
''';
      final result = parseStatementCsv(csv);
      expect(result.rows, isEmpty);
      expect(result.skipped.single, contains('empty date or description'));
    });
  });
}
