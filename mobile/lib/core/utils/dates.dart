// Centralized DateFormat constants — pre-built singletons for the
// formats that repeat across the app.
//
// `DateFormat` instances are immutable but their constructor parses
// the pattern string on every call, so reusing one per format saves
// the parse on hot paths (transactions list, dashboard cards). The
// audit also flagged ~30 sites instantiating these inline; this
// file gives them one definition to share.
//
// Only the patterns that repeat live here. One-off formats
// ('EEEE, MMMM d' on the day-grouped transactions header,
// 'MMMM' on the dashboard greeting) stay inline at their use site
// since extracting them into named constants would just add a layer
// of indirection without any reuse.
//
// Audit 2026-05-26 I2: every constant pins `locale: 'en_US'` so a
// non-en system locale doesn't crash through the missing
// `initializeDateFormatting` call. Localised variants land via
// `<format>For(locale)` once a non-en locale is supported (see
// l10n.yaml / the userLocaleProvider).

import 'package:intl/intl.dart';

const String _kDefaultLocale = 'en_US';

/// `2026-05-24` — ISO 8601 date. Used for DB DATE columns,
/// file-name slugs, and anywhere a sortable lexical date is wanted.
/// Locale-invariant (digits-only) but pinned anyway for symmetry.
final DateFormat kIsoDate = DateFormat('yyyy-MM-dd', _kDefaultLocale);

/// `May 24, 2026` — UI-facing long date for forms and detail
/// screens.
final DateFormat kLongDate = DateFormat('MMM d, yyyy', _kDefaultLocale);

/// `May 2026` — month + year for chart axes and per-month summary
/// labels (scenario charts, payoff projections).
final DateFormat kMonthYear = DateFormat('MMM yyyy', _kDefaultLocale);

/// `May 24` — compact date for list rows where the year is
/// implicit (transactions feed, review queue).
final DateFormat kShortDate = DateFormat('MMM d', _kDefaultLocale);

/// Localised builder. When a future locale ships, callers in
/// widgets read `userLocaleProvider` and pass the string here
/// instead of using the bare singletons above. Each new
/// DateFormat is cheap to construct (parses the pattern once
/// per build); the singletons remain the hot-path default.
DateFormat longDateFor(String locale) => DateFormat('MMM d, yyyy', locale);
DateFormat shortDateFor(String locale) => DateFormat('MMM d', locale);
DateFormat monthYearFor(String locale) => DateFormat('MMM yyyy', locale);
