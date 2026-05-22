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
  const ParsedStatement({
    required this.rows,
    required this.skipped,
    this.warnings = const [],
  });

  final List<ParsedStatementRow> rows;

  /// Rows the parser couldn't make sense of (bad date, missing amount,
  /// too few columns). These never reach the import.
  final List<String> skipped;

  /// Anomalies on rows that *did* import. The user should see these
  /// before confirming — e.g. a split debit/credit row where both
  /// columns were non-zero, which is not legal but still parsed.
  final List<String> warnings;
}

/// Resolved column indices into a CSV's header row. Produced by
/// [detectColumnMapping] (heuristic auto-detect) or supplied by the
/// caller after a manual override. The parser treats either source
/// the same.
///
/// `amountIdx` and (`debitIdx`, `creditIdx`) are mutually exclusive
/// — banks export either a single signed-amount column OR two
/// unsigned debit/credit columns, never both meaningfully populated.
/// Use [ColumnMapping.signed] for the single-column shape and
/// [ColumnMapping.split] for the two-column shape.
class ColumnMapping {
  const ColumnMapping._({
    required this.dateIdx,
    required this.descIdx,
    required this.amountIdx,
    required this.debitIdx,
    required this.creditIdx,
  });

  /// Single signed-amount column.
  const ColumnMapping.signed({
    required int dateIdx,
    required int descIdx,
    required int amountIdx,
  }) : this._(
         dateIdx: dateIdx,
         descIdx: descIdx,
         amountIdx: amountIdx,
         debitIdx: -1,
         creditIdx: -1,
       );

  /// Split debit + credit columns. Both must be present; the parser
  /// rejects a half-split mapping at construction.
  const ColumnMapping.split({
    required int dateIdx,
    required int descIdx,
    required int debitIdx,
    required int creditIdx,
  }) : this._(
         dateIdx: dateIdx,
         descIdx: descIdx,
         amountIdx: -1,
         debitIdx: debitIdx,
         creditIdx: creditIdx,
       );

  final int dateIdx;
  final int descIdx;
  final int amountIdx;
  final int debitIdx;
  final int creditIdx;

  bool get isSplit => amountIdx == -1 && debitIdx != -1 && creditIdx != -1;
}

/// Exception thrown when [parseStatementCsv] can't auto-detect
/// columns. Carries the parsed header row so the UI can offer a
/// manual override picker without re-reading the file.
///
/// Subclasses [FormatException] so existing call-sites that catch
/// `FormatException` (the surface API up to migration of this
/// override path) keep working — they just don't get access to the
/// header list. New code can catch `ColumnDetectionFailure`
/// specifically and pull `.headers` off it.
class ColumnDetectionFailure extends FormatException {
  ColumnDetectionFailure(this.headers)
    : super(
        'Could not detect columns.\nFound: ${headers.join(', ')}\n'
        'Expected: date, description, amount '
        '(or separate debit and credit columns)',
      );
  final List<String> headers;
}

/// Stable per-file-shape identifier derived from the header row.
/// Used to look up a saved [ColumnMapping] preset so a re-import
/// from the same bank doesn't re-prompt. Lowercases and trims each
/// header before hashing so a "Date" / "date " round-trip doesn't
/// invalidate the preset.
///
/// Plain SHA-1 over a delimiter-joined string — cryptographic
/// strength is irrelevant here, we just want a short stable key
/// that's unlikely to collide across banks.
String headerFingerprint(List<String> headers) {
  final normalised = headers
      .map((h) => h.toLowerCase().trim())
      .join(''); // SOH delimiter — won't appear in real headers.
  // Lightweight hash: FNV-1a 32-bit, hex-encoded. Avoids a crypto
  // dependency for what's effectively just a dictionary key.
  var hash = 2166136261;
  for (final cu in normalised.codeUnits) {
    hash ^= cu;
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// Auto-detects column indices from [headers]. Returns null when
/// the heuristic can't lock onto date+desc+amount-or-split — the
/// caller's job to either consult a saved preset or surface the
/// override sheet.
ColumnMapping? detectColumnMapping(List<String> headers) {
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
  final amountIdx = _findCol(headers, const ['amount']);
  final debitIdx = _findCol(headers, const ['debit', 'withdrawal']);
  final creditIdx = _findCol(headers, const ['credit', 'deposit']);

  if (dateIdx == -1 || descIdx == -1) return null;
  if (amountIdx != -1) {
    return ColumnMapping.signed(
      dateIdx: dateIdx,
      descIdx: descIdx,
      amountIdx: amountIdx,
    );
  }
  if (debitIdx != -1 && creditIdx != -1) {
    return ColumnMapping.split(
      dateIdx: dateIdx,
      descIdx: descIdx,
      debitIdx: debitIdx,
      creditIdx: creditIdx,
    );
  }
  return null;
}

/// Top-level entry point. Suitable for `compute()` so a multi-MB statement
/// doesn't block the UI thread.
///
/// When [mapping] is supplied, the parser skips auto-detection and uses it
/// verbatim — the path the override sheet and the saved-preset lookup take.
/// When [mapping] is null, auto-detection runs and a
/// [ColumnDetectionFailure] is thrown when it can't find the columns.
/// Callers should catch that and either consult a saved preset by
/// [headerFingerprint] or surface the override sheet.
ParsedStatement parseStatementCsv(String content, {ColumnMapping? mapping}) {
  // Normalise line endings — bank CSVs commonly use \r\n (Windows).
  final normalised = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rows = const CsvToListConverter(eol: '\n').convert(normalised);
  if (rows.length < 2) {
    throw const FormatException('File appears empty');
  }

  final headers = rows.first
      .map((h) => h.toString().toLowerCase().trim())
      .toList();

  final resolved = mapping ?? detectColumnMapping(headers);
  if (resolved == null) {
    throw ColumnDetectionFailure(headers);
  }
  return _parseWithMapping(rows, resolved);
}

ParsedStatement _parseWithMapping(List<List<dynamic>> rows, ColumnMapping m) {
  final out = <ParsedStatementRow>[];
  final skipped = <String>[];
  final warnings = <String>[];
  // Per-base-key occurrence counter so legitimate duplicate transactions on
  // the same day (same description and amount) get unique externalIds.
  final keyCounts = <String, int>{};

  // Pre-scan: if ANY row in a single-amount-column file has an explicit
  // negative sign, treat the whole file as signed and skip the
  // description-keyword inference for positive amounts. Without this,
  // a Chase-style CC export (charges negative, payments positive) would
  // see its unsigned-positive payments routed through inference, where
  // the "PAYMENT" debit keyword would flip them to negative — making
  // every payment look like a second charge.
  //
  // Split debit/credit files don't have this ambiguity; the columns
  // already encode direction.
  var fileIsSigned = false;
  if (!m.isSplit) {
    for (final row in rows.skip(1)) {
      if (row.length <= m.amountIdx) continue;
      final raw = row[m.amountIdx].toString().trim();
      if (_signFromValue(raw) == _Sign.negative) {
        fileIsSigned = true;
        break;
      }
    }
  }

  for (final (i, row) in rows.skip(1).indexed) {
    final rowNum = i + 2; // 1-based, accounting for header
    final neededCols = m.isSplit
        ? [m.dateIdx, m.descIdx, m.debitIdx, m.creditIdx]
        : [m.dateIdx, m.descIdx, m.amountIdx];
    final maxIdx = neededCols.reduce((a, b) => a > b ? a : b);
    if (row.length <= maxIdx) {
      skipped.add('Row $rowNum: too few columns (${row.length})');
      continue;
    }

    final dateStr = row[m.dateIdx].toString().trim();
    final desc = row[m.descIdx].toString().trim();
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
    final amountWarn = StringBuffer();
    if (m.isSplit) {
      cents = _parseSplitAmount(
        debit: row[m.debitIdx].toString().trim(),
        credit: row[m.creditIdx].toString().trim(),
        err: amountErr,
        warn: amountWarn,
      );
    } else {
      cents = _parseSingleAmount(
        raw: row[m.amountIdx].toString().trim(),
        description: desc,
        err: amountErr,
        fileIsSigned: fileIsSigned,
      );
    }
    if (cents == null) {
      skipped.add('Row $rowNum: ${amountErr.toString()}');
      continue;
    }
    if (amountWarn.isNotEmpty) {
      warnings.add('Row $rowNum: ${amountWarn.toString()}');
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

  return ParsedStatement(rows: out, skipped: skipped, warnings: warnings);
}

/// Reads just the header row from [content]. Useful when the import UI
/// needs to compute a [headerFingerprint] or populate the override
/// sheet's dropdowns without re-running the full parser. Returns the
/// raw (lowercased, trimmed) header strings.
List<String> extractHeaders(String content) {
  final normalised = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final rows = const CsvToListConverter(eol: '\n').convert(normalised);
  if (rows.isEmpty) return const [];
  return rows.first.map((h) => h.toString().toLowerCase().trim()).toList();
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
///   2. If [fileIsSigned] is true (the file has at least one explicit
///      negative elsewhere), positive values are also trusted as-is —
///      they're "income" rows in a signed export, not unsigned-default
///      candidates for description inference. This is the path Chase
///      CC exports take: charges negative, payments positive, no leading
///      "+" on the positives.
///   3. Otherwise, check description keywords. Credit keywords win over
///      debit keywords on overlap — "PAYMENT REFUND" is a refund, not a
///      payment. Without this, the previous code mis-signed refunds
///      because the debit branch fired first.
///   4. No keyword hit: keep positive (the import preview row will look
///      odd and the user can correct it before confirming).
int? _parseSingleAmount({
  required String raw,
  required String description,
  required StringBuffer err,
  bool fileIsSigned = false,
}) {
  if (raw.isEmpty) {
    err.write('empty amount');
    return null;
  }
  final cents = _parseToCentsStrict(raw, err);
  if (cents == null) return null;

  if (cents != 0 && cents.isNegative) return cents;
  // Trust positive values when the file is detected as signed —
  // otherwise the "PAYMENT" keyword would flip Chase-style positive
  // payment rows to negative, double-counting them as charges.
  if (fileIsSigned) return cents;
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
///
/// When both columns hold non-zero values (which shouldn't happen for a
/// well-formed statement), a message is written to [warn] and the credit
/// value is preferred. The row still imports — the user sees the warning
/// in the import preview and can correct sign before confirming.
int? _parseSplitAmount({
  required String debit,
  required String credit,
  required StringBuffer err,
  required StringBuffer warn,
}) {
  final hasDebit = debit.isNotEmpty;
  final hasCredit = credit.isNotEmpty;
  if (!hasDebit && !hasCredit) {
    err.write('debit and credit columns both empty');
    return null;
  }
  if (hasDebit && hasCredit) {
    final d = _parseToCentsStrict(debit, StringBuffer());
    final c = _parseToCentsStrict(credit, StringBuffer());
    final dNonZero = d != null && d != 0;
    final cNonZero = c != null && c != 0;
    if (dNonZero && cNonZero) {
      // Both filled and both non-zero — surface to the caller. Refunds
      // posted as a debit/credit pair occasionally land here, so prefer
      // the credit value rather than skipping the row.
      warn.write(
        'both debit ($debit) and credit ($credit) columns are non-zero; '
        'used credit value (review sign before importing)',
      );
      return c.abs();
    }
    if (cNonZero) return c.abs();
    if (dNonZero) return -d.abs();
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
