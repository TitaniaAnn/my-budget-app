// Money utility functions.
//
// All monetary values in the database are stored as INTEGER CENTS to avoid
// floating-point rounding errors (e.g. $12.34 is stored as 1234).
// These helpers convert between cents and display-ready strings.
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Formats integer cents as a locale-aware currency string.
/// Example: 1234 → "$12.34"
String formatCurrency(int cents, {String currency = 'USD', String locale = 'en_US'}) {
  final formatter = NumberFormat.currency(locale: locale, symbol: r'$', decimalDigits: 2);
  return formatter.format(cents / 100);
}

/// Formats cents as a plain decimal string without a currency symbol.
/// Uses [Decimal] to avoid floating-point errors during division.
/// Example: 1234 → "12.34"
String centsToString(int cents) {
  return (Decimal.fromInt(cents) / Decimal.fromInt(100))
      .toDecimal(scaleOnInfinitePrecision: 2)
      .toStringAsFixed(2);
}

/// Parses a user-entered string (e.g. "$12.34" or "12.34") to integer cents.
/// Strips non-numeric characters before parsing so currency symbols are safe.
/// Example: "12.34" → 1234
int parseToCents(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
  if (cleaned.isEmpty) return 0;
  // Multiply by 100 using Decimal to avoid floating-point rounding, then
  // convert to BigInt before toInt() because Decimal doesn't expose toInt().
  final d = Decimal.parse(cleaned) * Decimal.fromInt(100);
  return d.round().toBigInt().toInt();
}

/// Returns credit utilization as a percentage (0–100+).
/// A result over 100 means the card is over its limit.
double creditUtilization(int balanceCents, int limitCents) {
  if (limitCents == 0) return 0;
  return (balanceCents.abs() / limitCents * 100).clamp(0, 999).toDouble();
}

/// Returns true if [cents] represents a debit (money leaving an account).
bool isDebit(int cents) => cents < 0;

/// Returns true if [cents] is zero or positive (income or zero balance).
bool isPositive(int cents) => cents >= 0;
