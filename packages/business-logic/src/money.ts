/**
 * Money utilities.
 * All internal values are integer cents (e.g. $12.34 = 1234).
 * Use Decimal.js for any arithmetic to avoid floating-point errors.
 */
import Decimal from "decimal.js";

Decimal.set({ precision: 20, rounding: Decimal.ROUND_HALF_UP });

/** Add two cent values safely */
export function addCents(a: number, b: number): number {
  return new Decimal(a).plus(new Decimal(b)).toNumber();
}

/** Subtract cent values safely */
export function subtractCents(a: number, b: number): number {
  return new Decimal(a).minus(new Decimal(b)).toNumber();
}

/** Multiply cents by a rate (e.g. for interest calculations) */
export function multiplyCents(cents: number, rate: number): number {
  return new Decimal(cents).times(new Decimal(rate)).toDecimalPlaces(0).toNumber();
}

/** Format cents as a locale currency string: 1234 → "$12.34" */
export function formatCurrency(
  cents: number,
  currency = "USD",
  locale = "en-US"
): string {
  return new Intl.NumberFormat(locale, {
    style: "currency",
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(cents / 100);
}

/** Format cents as a plain decimal string: 1234 → "12.34" */
export function centsToString(cents: number): string {
  return (cents / 100).toFixed(2);
}

/** Parse a user-entered string to cents: "12.34" → 1234 */
export function parseToCents(value: string): number {
  const cleaned = value.replace(/[^0-9.-]/g, "");
  return new Decimal(cleaned).times(100).toDecimalPlaces(0).toNumber();
}

/** Calculate credit utilization as a percentage (0–100) */
export function creditUtilization(balance: number, limit: number): number {
  if (limit === 0) return 0;
  return new Decimal(Math.abs(balance))
    .div(new Decimal(limit))
    .times(100)
    .toDecimalPlaces(1)
    .toNumber();
}

/** Calculate simple monthly interest in cents */
export function monthlyInterest(balanceCents: number, aprPercent: number): number {
  const monthlyRate = new Decimal(aprPercent).div(100).div(12);
  return new Decimal(Math.abs(balanceCents))
    .times(monthlyRate)
    .toDecimalPlaces(0)
    .toNumber();
}
