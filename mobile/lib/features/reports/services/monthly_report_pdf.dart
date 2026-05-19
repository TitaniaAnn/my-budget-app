// Renders a [MonthlyReportData] into a single-page PDF document.
//
// The pdf package's `pw.*` widget tree is a separate render tree
// from Flutter's — sharing colors and labels but not Material
// widgets. Kept as a pure function returning Uint8List bytes so the
// caller (screen) doesn't have to know about PageFormat etc.
//
// Money is formatted as `$X,XXX.XX` here (not via the app's money
// utility) because the PDF runs outside the widget tree and intl's
// NumberFormat is the natural pick. The format is identical to what
// money.dart produces.

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/monthly_report_data.dart';

Future<Uint8List> renderMonthlyReportPdf(MonthlyReportData data) async {
  final doc = pw.Document();
  final money = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
  final monthLabel = DateFormat.yMMMM().format(data.monthStart);
  final generatedAt = DateFormat.yMMMd().add_jm().format(DateTime.now());

  String fmt(int cents) => money.format(cents / 100.0);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(48, 56, 48, 56),
      build: (context) => [
        // ── Header ─────────────────────────────────────────────
        pw.Text(
          monthLabel,
          style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          data.householdName,
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Generated $generatedAt',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
        ),
        pw.SizedBox(height: 24),

        // ── Summary block ─────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _summaryCell('Income', fmt(data.incomeCents), PdfColors.green800),
              _summaryCell(
                'Expenses',
                fmt(data.expensesCents),
                PdfColors.red800,
              ),
              _summaryCell(
                'Net change',
                fmt(data.netChangeCents),
                data.netChangeCents >= 0
                    ? PdfColors.green800
                    : PdfColors.red800,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 24),

        // ── By category ───────────────────────────────────────
        pw.Text(
          'Spending by category',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (data.byCategory.isEmpty)
          pw.Text(
            'No spending this month.',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          )
        else
          pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(16),
              1: pw.FlexColumnWidth(),
              2: pw.IntrinsicColumnWidth(),
            },
            children: [
              for (final row in data.byCategory)
                pw.TableRow(
                  children: [
                    pw.Container(
                      width: 10,
                      height: 10,
                      margin: const pw.EdgeInsets.only(top: 6, right: 6),
                      decoration: pw.BoxDecoration(
                        color: _parseHex(row.colorHex) ?? PdfColors.grey400,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(row.name),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(
                        fmt(row.cents),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        pw.SizedBox(height: 20),

        // ── Footnotes ─────────────────────────────────────────
        if (data.transferLegCount > 0)
          pw.Text(
            'Transfers excluded: ${data.transferLegCount} '
            'account-to-account transaction legs were left out '
            'of income and expense totals.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _summaryCell(String label, String value, PdfColor valueColor) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: valueColor,
        ),
      ),
    ],
  );
}

/// Parses "#RRGGBB" / "RRGGBB" into a PdfColor. Returns null on
/// malformed input so the renderer can fall back to a neutral colour.
PdfColor? _parseHex(String? hex) {
  if (hex == null) return null;
  final stripped = hex.startsWith('#') ? hex.substring(1) : hex;
  if (stripped.length != 6) return null;
  final value = int.tryParse(stripped, radix: 16);
  if (value == null) return null;
  return PdfColor.fromInt(0xFF000000 | value);
}
