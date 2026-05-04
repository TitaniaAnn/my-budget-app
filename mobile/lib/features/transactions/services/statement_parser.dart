// Pure CSV statement parser. Extracted from import_statement_sheet.dart so
// the parsing logic is testable without spinning up a widget tree, and so
// the heavy work can be moved to a background isolate.
//
// What this owns:
//   • Heuristic header detection (date / description / amount / debit /
//     credit). Some banks export a single signed `amount` column; others
//     split debits and credits into two unsigned columns.
//   • Decimal-based amount → cents conversion (no IEEE-754 round-trip).
//   • Sign inference from the description for banks that export everything
//     positive — credit keywords win over debit keywords on overlap (so
//     "PAYMENT REFUND" is treated as a refund, not a payment).
//   • Stable per-row dedup key derived from a normalised description, ISO
//     date, and integer cents. The bank server-side UNIQUE constraint
//     ((account_id, external_id)) does the real dedup; this just makes the
//     key resilient to formatting changes between exports.

import 'package:csv/csv.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class ParsedStatementRow {
  const ParsedStatementRow({
    required this.date,
    required this.description,
    required this.amountCents,
    required this.externalId,
  });

  final DateTime date;
  final String description;
  final int amountCents;
  final String externalId;
}

class ParsedStatement {
  const ParsedStatement({required this.rows, required this.skipped});

  final List<ParsedStatementRow> rows;
  final List<String> skipped;
}

/// Top-level entry point. Suitable for `compute()` so a multi-MB statement
/// doesn't block the UI thread.
ParsedStatement parseStatementCsv(String content) {
  // Normalise line endings — bank CSVs commonly use \r\n (Windows).
  final normalised = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rows = const CsvToListConverter(eol: '\n').convert(normalised);
  if (rows.length < 2) {
    throw const FormatException('File appears empty');
  }

  final headers = rows.first
      .map((h) => h.toString().toLowerCase().trim())
      .toList();

  final dateIdx = _findCol(headers, const [
    'transaction date',
    'post date',
    'posted',
    'date',
  ]);
  final descIdx = _findCol(headers, const [
    'description',
    'payee',
    'merchant',
    'memo',
    'name',
  ]);
  // Single signed-amount column. Tried before split debit/credit so a bank
  // that exports both "Amount" and a stub "Debit" column still parses.
  final amountIdx = _findCol(headers, const ['amount']);
  // Some banks export debits and credits in separate unsigned columns.
  final debitIdx = _findCol(headers, const ['debit', 'withdrawal']);
  final creditIdx = _findCol(headers, const ['credit', 'deposit']);

  final hasSplit = amountIdx == -1 && debitIdx != -1 && creditIdx != -1;
  if (dateIdx == -1 || descIdx == -1 || (amountIdx == -1 && !hasSplit)) {
    throw FormatException(
      'Could not detect columns.\n'
      'Found: ${headers.join(', ')}\n'
      'Expected: date, description, amount '
      '(or separate debit and credit columns)',
    );
  }

  final out = <ParsedStatementRow>[];
  final skipped = <String>[];
  // Per-base-key occurrence counter so legitimate duplicate transactions on
  // the same day (same description and amount) get unique externalIds.
  final keyCounts = <String, int>{};

  for (final (i, row) in rows.skip(1).indexed) {
    final rowNum = i + 2; // 1-based, accounting for header
    final neededCols = hasSplit
        ? [dateIdx, descIdx, debitIdx, creditIdx]
        : [dateIdx, descIdx, amountIdx];
    final maxIdx = neededCols.reduce((a, b) => a > b ? a : b);
    if (row.length <= maxIdx) {
      skipped.add('Row $rowNum: too few columns (${row.length})');
      continue;
    }

    final dateStr = row[dateIdx].toString().trim();
    final desc = row[descIdx].toString().trim();
    if (dateStr.isEmpty || desc.isEmpty) {
      skipped.add('Row $rowNum: empty date or description');
      continue;
    }

    final date = _parseDate(dateStr);
    if (date == null) {
      skipped.add('Row $rowNum: unrecognised date format "$dateStr"');
      continue;
    }

    final int? cents;
    final amountErr = StringBuffer();
    if (hasSplit) {
      cents = _parseSplitAmount(
        debit: row[debitIdx].toString().trim(),
        credit: row[creditIdx].toString().trim(),
        err: amountErr,
      );
    } else {
      cents = _parseSingleAmount(
        raw: row[amountIdx].toString().trim(),
        description: desc,
        err: amountErr,
      );
    }
    if (cents == null) {
      skipped.add('Row $rowNum: ${amountErr.toString()}');
      continue;
    }

    final isoDate = date.toIso8601String().substring(0, 10);
    final baseKey = '${isoDate}_${_normaliseDesc(desc)}_$cents';
    final occurrence = keyCounts[baseKey] = (keyCounts[baseKey] ?? 0) + 1;
    final externalId = '${baseKey}_$occurrence';

    out.add(
      ParsedStatementRow(
        date: date,
        description: desc,
        amountCents: cents,
        externalId: externalId,
      ),
    );
  }

  return ParsedStatement(rows: out, skipped: skipped);
}

/// Returns the index of the first header containing any candidate substring.
/// -1 when none match. Candidates are tried left-to-right, so callers can
/// list the most-specific synonym first to avoid a less-specific match
/// (e.g. "transaction date" before "date" — otherwise a "Posting Date"
/// column wins over a "Transaction Date" column when both exist).
int _findCol(List<String> headers, List<String> candidates) {
  for (final c in candidates) {
    final idx = headers.indexWhere((h) => h.contains(c));
    if (idx != -1) return idx;
  }
  return -1;
}

DateTime? _parseDate(String s) {
  // intl's `y`/`yyyy` happily parses "26" as year 0026 — we always pivot
  // any sub-100 year up to 20xx. Bank statements never show pre-2000
  // dates, so we don't bother with the usual 1970 cutoff.
  const fmts = ['MM/dd/yyyy', 'M/d/yyyy', 'yyyy-MM-dd', 'MM/dd/yy', 'M/d/yy'];
  for (final f in fmts) {
    try {
      final dt = DateFormat(f).parseStrict(s);
      if (dt.year < 100) return DateTime(dt.year + 2000, dt.month, dt.day);
      return dt;
    } catch (_) {}
  }
  return null;
}

/// "WALMART  #123 " → "walmart #123".
/// Lowercased, internal whitespace runs collapsed, ends trimmed. Used only
/// for the dedup key — the original casing/spacing is preserved on the row.
String _normaliseDesc(String s) =>
    s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

/// Parses a string like "12.34", "-$12.34", or "(12.34)" to integer cents
/// using Decimal arithmetic. Returns null and writes a message to [err]
/// if the input has no numeric content.
int? _parseToCentsStrict(String raw, StringBuffer err) {
  final trimmed = raw.trim();
  // Accounting parens convention: "(12.34)" means -12.34.
  final parenNeg = trimmed.startsWith('(') && trimmed.endsWith(')');
  final inner = parenNeg ? trimmed.substring(1, trimmed.length - 1) : trimmed;
  final negative = parenNeg || inner.trimLeft().startsWith('-');
  final cleaned = inner.replaceAll(RegExp(r'[^\d.]'), '');
  if (cleaned.isEmpty) {
    err.write('no numeric value in amount "$raw"');
    return null;
  }
  try {
    final magnitude = (Decimal.parse(cleaned) * Decimal.fromInt(100))
        .round()
        .toBigInt()
        .toInt();
    return negative ? -magnitude : magnitude;
  } catch (_) {
    err.write('could not parse amount "$raw"');
    return null;
  }
}

/// Sign-inference order:
///   1. If the parsed value already has a sign, trust it (the bank knows).
///   2. Otherwise, check description keywords. Credit keywords win over
///      debit keywords on overlap — "PAYMENT REFUND" is a refund, not a
///      payment. Without this, the previous code mis-signed refunds because
///      the debit branch fired first.
///   3. No keyword hit: keep positive (the import preview row will look
///      odd and the user can correct it before confirming).
int? _parseSingleAmount({
  required String raw,
  required String description,
  required StringBuffer err,
}) {
  if (raw.isEmpty) {
    err.write('empty amount');
    return null;
  }
  final cents = _parseToCentsStrict(raw, err);
  if (cents == null) return null;

  if (cents != 0 && cents.isNegative) return cents;
  // Some banks always export positive — also covers the rare case of a
  // signed-zero or genuinely zero row (e.g. waived fee).
  if (cents > 0 && _signFromValue(raw) == _Sign.unsigned) {
    final inferred = _inferSignFromDescription(description);
    if (inferred == _Sign.negative) return -cents;
  }
  return cents;
}

/// One column has the magnitude, the other is empty. Some banks export
/// both as positive — debit becomes negative cents, credit stays positive.
int? _parseSplitAmount({
  required String debit,
  required String credit,
  required StringBuffer err,
}) {
  final hasDebit = debit.isNotEmpty;
  final hasCredit = credit.isNotEmpty;
  if (!hasDebit && !hasCredit) {
    err.write('debit and credit columns both empty');
    return null;
  }
  if (hasDebit && hasCredit) {
    // Defensive: a single transaction shouldn't have both columns filled.
    // Trust whichever is non-zero; if both are non-zero, prefer credit
    // (refunds posted as a debit/credit pair sometimes show up this way).
    final d = _parseToCentsStrict(debit, StringBuffer());
    final c = _parseToCentsStrict(credit, StringBuffer());
    if (c != null && c != 0) return c.abs();
    if (d != null && d != 0) return -d.abs();
    return 0;
  }
  if (hasDebit) {
    final v = _parseToCentsStrict(debit, err);
    return v == null ? null : -v.abs();
  }
  return _parseToCentsStrict(credit, err)?.abs();
}

enum _Sign { positive, negative, unsigned }

_Sign _signFromValue(String raw) {
  final trimmed = raw.trimLeft();
  if (trimmed.startsWith('-') ||
      (trimmed.startsWith('(') && trimmed.endsWith(')'))) {
    return _Sign.negative;
  }
  if (trimmed.startsWith('+')) return _Sign.positive;
  return _Sign.unsigned;
}

/// Returns negative when the description looks like money leaving the
/// account, positive when it looks like money arriving, unsigned otherwise.
/// Credit keywords are checked first — overlap (e.g. "PAYMENT REFUND")
/// resolves to credit because the user's intent is a refund.
_Sign _inferSignFromDescription(String description) {
  final upper = description.toUpperCase();
  const credit = [
    'REFUND',
    'CREDIT',
    'DEPOSIT',
    'TRANSFER IN',
    'REVERSAL',
    'CASHBACK',
    'INTEREST PAID',
  ];
  const debit = [
    'WITHDRAWAL',
    'DEBIT',
    'PAYMENT',
    'PURCHASE',
    'TRANSFER OUT',
    'FEE',
  ];
  for (final kw in credit) {
    if (upper.contains(kw)) return _Sign.positive;
  }
  for (final kw in debit) {
    if (upper.contains(kw)) return _Sign.negative;
  }
  return _Sign.unsigned;
}
