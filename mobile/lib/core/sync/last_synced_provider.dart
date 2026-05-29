// "Last synced" tracker for the offline banner. Audit L1 Phase 5a.
//
// Surfaces the most recent `cached_at` timestamp across every
// data cache table — a single scalar approximating "when did we
// last hear from the server about anything?" Used by the offline
// banner to render "showing data from X minutes ago".
//
// The provider is plain (not keepAlive) so each banner render
// gets a fresh read. The query reads only the per-table index
// (constant in the number of cached rows) so polling on every
// rebuild is cheap.

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database_provider.dart';

part 'last_synced_provider.g.dart';

@riverpod
Future<DateTime?> lastSyncedAt(LastSyncedAtRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.latestCacheTimestamp();
}

/// Pending-writes count for the Settings sync surface (Phase 5c).
/// Plain (not keepAlive) so each settings open gets a fresh read.
@riverpod
Future<int> pendingWritesCountValue(PendingWritesCountValueRef ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.pendingWritesCount();
}

/// Pretty-print a "X ago" string for the offline banner. Pure
/// function for testability. Buckets chosen to be informative
/// without thrashing — sub-minute is "just now"; sub-hour ticks
/// per minute; sub-day ticks per hour; otherwise the calendar
/// date.
String formatLastSynced(DateTime? lastSyncedUtc, DateTime now) {
  if (lastSyncedUtc == null) return 'never synced';
  final diff = now.toUtc().difference(lastSyncedUtc.toUtc());
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? '1 min ago' : '$m min ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? '1 hr ago' : '$h hr ago';
  }
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  // Anything older than a week: explicit calendar date. Format
  // locale-agnostic (YYYY-MM-DD) so the banner stays compact.
  final local = lastSyncedUtc.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Convenience widget the banner consumes. Kept small + plain
/// so the banner file stays focused on layout.
class LastSyncedLabel extends StatelessWidget {
  const LastSyncedLabel({
    super.key,
    required this.lastSyncedAt,
    this.style,
  });

  final DateTime? lastSyncedAt;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatLastSynced(lastSyncedAt, DateTime.now()),
      style: style,
    );
  }
}
