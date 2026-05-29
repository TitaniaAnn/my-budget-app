// Tiny pluralization helper. Audit 2026-05-26 I3.
//
// The audit's I1 (flutter_localizations + .arb wiring) is the
// proper fix for non-English locales. Until then, replace ad-hoc
// `'$n transactions'` with `plural(n, 'transaction')` so a single
// future migration to `Intl.plural` only touches this file.
//
// English rule only: 1 → singular, everything else → +s. Locales
// with more nuanced plural categories (Russian, Arabic, Welsh)
// would override this — pick up Intl.plural at that point.

/// `plural(0, 'transaction')` → `'0 transactions'`.
/// `plural(1, 'transaction')` → `'1 transaction'`.
/// `plural(2, 'transaction')` → `'2 transactions'`.
///
/// [pluralForm] optional override for irregular plurals
/// (`plural(2, 'category', pluralForm: 'categories')`).
String plural(int n, String singular, {String? pluralForm}) {
  if (n == 1) return '$n $singular';
  return '$n ${pluralForm ?? "${singular}s"}';
}
