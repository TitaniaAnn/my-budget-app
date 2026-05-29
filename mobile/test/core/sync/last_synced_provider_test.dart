// Tests for the offline banner's "X ago" pretty-printer.
// Pure-function tests — no Riverpod, no drift, no widgets.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/sync/last_synced_provider.dart';

void main() {
  final now = DateTime.utc(2026, 5, 28, 12, 0, 0);

  group('formatLastSynced', () {
    test('null timestamp → "never synced"', () {
      expect(formatLastSynced(null, now), 'never synced');
    });

    test('within last 60 seconds → "just now"', () {
      expect(
        formatLastSynced(now.subtract(const Duration(seconds: 5)), now),
        'just now',
      );
      expect(
        formatLastSynced(now.subtract(const Duration(seconds: 59)), now),
        'just now',
      );
    });

    test('1 minute → "1 min ago" (singular)', () {
      expect(
        formatLastSynced(now.subtract(const Duration(minutes: 1)), now),
        '1 min ago',
      );
    });

    test('multiple minutes → "N min ago"', () {
      expect(
        formatLastSynced(now.subtract(const Duration(minutes: 12)), now),
        '12 min ago',
      );
      expect(
        formatLastSynced(now.subtract(const Duration(minutes: 59)), now),
        '59 min ago',
      );
    });

    test('1 hour → "1 hr ago" (singular)', () {
      expect(
        formatLastSynced(now.subtract(const Duration(hours: 1)), now),
        '1 hr ago',
      );
    });

    test('multiple hours → "N hr ago"', () {
      expect(
        formatLastSynced(now.subtract(const Duration(hours: 5)), now),
        '5 hr ago',
      );
      expect(
        formatLastSynced(now.subtract(const Duration(hours: 23)), now),
        '23 hr ago',
      );
    });

    test('exactly 24 hours / 1 day → "yesterday"', () {
      expect(
        formatLastSynced(now.subtract(const Duration(days: 1)), now),
        'yesterday',
      );
    });

    test('2-6 days → "N days ago"', () {
      expect(
        formatLastSynced(now.subtract(const Duration(days: 3)), now),
        '3 days ago',
      );
      expect(
        formatLastSynced(now.subtract(const Duration(days: 6)), now),
        '6 days ago',
      );
    });

    test('7+ days → explicit YYYY-MM-DD calendar date', () {
      // Pick a stamp 10 days back from 2026-05-28 → 2026-05-18.
      final tenDaysAgo = DateTime.utc(2026, 5, 18, 14, 30);
      // The function formats in LOCAL time; in this test environment
      // toLocal() may shift the date by a few hours, but the
      // formatter just picks the local calendar day. We assert the
      // shape (matches YYYY-MM-DD).
      final formatted = formatLastSynced(tenDaysAgo, now);
      expect(
        formatted,
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')),
      );
    });

    test('input in UTC vs local: comparison is timezone-safe', () {
      // The "now" reference is converted to UTC internally. A
      // UTC-marked stamp and a local-marked stamp at the same
      // instant should produce the same label.
      final stampUtc = now.subtract(const Duration(minutes: 30));
      final stampLocal = stampUtc.toLocal();
      expect(
        formatLastSynced(stampUtc, now),
        formatLastSynced(stampLocal, now),
      );
    });
  });
}
