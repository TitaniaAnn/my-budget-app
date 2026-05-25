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

import 'package:intl/intl.dart';

/// `2026-05-24` — ISO 8601 date. Used for DB DATE columns,
/// file-name slugs, and anywhere a sortable lexical date is wanted.
final DateFormat kIsoDate = DateFormat('yyyy-MM-dd');

/// `May 24, 2026` — UI-facing long date for forms and detail
/// screens.
final DateFormat kLongDate = DateFormat('MMM d, yyyy');

/// `May 2026` — month + year for chart axes and per-month summary
/// labels (scenario charts, payoff projections).
final DateFormat kMonthYear = DateFormat('MMM yyyy');

/// `May 24` — compact date for list rows where the year is
/// implicit (transactions feed, review queue).
final DateFormat kShortDate = DateFormat('MMM d');
