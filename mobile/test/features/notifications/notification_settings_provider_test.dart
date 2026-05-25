// Tests for the SharedPreferences-backed `lastFiredByKey` helpers
// (recordFired / loadLastFired / clearLastFired). The runner test
// exercises them transitively via the happy path, but the
// 90-day-prune invariant — and a few of the corruption / round-trip
// edges — are easier to pin directly here.
//
// Contracts pinned:
//   * recordFired prunes entries older than _kLastFiredRetention
//     (90 days) on every write, so the JSON blob can't grow
//     unbounded across years of installs;
//   * a "fresh" entry (just inside the window) survives the prune;
//   * loadLastFired round-trips what recordFired wrote;
//   * loadLastFired returns an empty map (not null, not an error)
//     when the prefs key is missing OR the stored string is
//     malformed JSON — corrupt-store recovery is part of the
//     contract because the runner crashes without it;
//   * clearLastFired removes the key entirely (subsequent
//     loadLastFired sees no value, not a stale empty {}).

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/notifications/providers/notification_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Each test starts with empty prefs so a prior test's writes
    // don't pollute the read. SharedPreferences.setMockInitialValues
    // also resets the singleton, so loadLastFired in this test sees
    // the values we just set, not anything carried over.
    SharedPreferences.setMockInitialValues({});
  });

  group('recordFired prune', () {
    test('90-day-old entry is pruned; sub-90-day entry survives; new key '
        'is added — all in one write', () async {
      final now = DateTime.utc(2026, 6, 1);
      final stale = now.subtract(const Duration(days: 91));
      final fresh = now.subtract(const Duration(days: 30));

      await recordFired(
        existing: {'old-key': stale, 'recent-key': fresh},
        newKeys: ['just-fired'],
        now: now,
      );

      final loaded = await loadLastFired();
      expect(
        loaded.keys.toSet(),
        {'recent-key', 'just-fired'},
        reason:
            'old-key (91 days old) crosses the retention boundary '
            'and must be pruned; recent-key (30 days old) survives; '
            'just-fired is added with timestamp == now.',
      );
      expect(loaded['recent-key'], fresh);
      expect(loaded['just-fired'], now);
    });

    test('exactly-at-boundary entry is pruned (strict isAfter, not '
        'isAfterOrAtSameMomentAs)', () async {
      // Pinning the boundary semantics: an entry timestamped
      // exactly `now - 90 days` is NOT after the cutoff, so it
      // drops. Anything later (even a millisecond) survives.
      final now = DateTime.utc(2026, 6, 1);
      final atBoundary = now.subtract(const Duration(days: 90));
      final justAfter = atBoundary.add(const Duration(milliseconds: 1));

      await recordFired(
        existing: {'at-boundary': atBoundary, 'just-after-boundary': justAfter},
        newKeys: const [],
        now: now,
      );

      final loaded = await loadLastFired();
      expect(loaded.keys, {'just-after-boundary'});
    });

    test(
      'empty existing + empty newKeys writes an empty map (not a crash)',
      () async {
        // Defensive: the engine can fire with no pending alerts AND
        // no prior state on a fresh install. recordFired must handle
        // both empty without throwing.
        final now = DateTime.utc(2026, 6, 1);
        await recordFired(existing: const {}, newKeys: const [], now: now);
        expect(await loadLastFired(), isEmpty);
      },
    );

    test('a new key overrides a stale entry of the same name', () async {
      // If "budget_over:b1:2026-03-01" was fired in March and then
      // again in June (same period name only because the dedup
      // namespace happens to collide), the June fire's timestamp
      // wins. Otherwise the stale entry would falsely silence the
      // June fire on the next eval pass.
      final now = DateTime.utc(2026, 6, 1);
      final stale = now.subtract(const Duration(days: 40));
      await recordFired(existing: {'k': stale}, newKeys: ['k'], now: now);
      final loaded = await loadLastFired();
      expect(loaded['k'], now);
    });
  });

  group('loadLastFired corruption recovery', () {
    test('missing key returns an empty map', () async {
      expect(await loadLastFired(), isEmpty);
    });

    test('malformed JSON returns an empty map (not a throw)', () async {
      // Corruption recovery is load-bearing — without it, a single
      // garbled write would wedge the engine forever (it'd throw on
      // every load and the runner would never get past the first
      // line). The catch in loadLastFired hides the error and
      // returns empty.
      SharedPreferences.setMockInitialValues({
        'mybudget.notifications.lastFired': '{not valid json',
      });
      expect(await loadLastFired(), isEmpty);
    });

    test('mixed-shape JSON (right keys, wrong-typed values) returns empty '
        'rather than partially loading', () async {
      // jsonDecode would succeed but the cast to String for the
      // timestamp would throw inside the loop — the same catch
      // covers it.
      SharedPreferences.setMockInitialValues({
        'mybudget.notifications.lastFired':
            '{"some-key": 123, "other-key": null}',
      });
      expect(await loadLastFired(), isEmpty);
    });
  });

  group('clearLastFired', () {
    test(
      'removes the prefs key entirely — subsequent load returns empty',
      () async {
        final now = DateTime.utc(2026, 6, 1);
        await recordFired(existing: const {}, newKeys: ['k1', 'k2'], now: now);
        expect((await loadLastFired()).keys, isNotEmpty);

        await clearLastFired();
        expect(await loadLastFired(), isEmpty);
      },
    );
  });

  test(
    'round-trip: recordFired then loadLastFired returns the same map',
    () async {
      // Smoke test for the encode/decode pair — DateTime.parse(toIso8601String())
      // is identity-preserving for UTC instants, but pin it anyway so
      // a future change to the encoding doesn't silently lose precision.
      final now = DateTime.utc(2026, 6, 1, 12, 34, 56);
      final t1 = now.subtract(const Duration(days: 10));
      final t2 = now.subtract(const Duration(days: 5));

      await recordFired(existing: {'a': t1, 'b': t2}, newKeys: ['c'], now: now);
      final loaded = await loadLastFired();

      expect(loaded.length, 3);
      expect(loaded['a'], t1);
      expect(loaded['b'], t2);
      expect(loaded['c'], now);
    },
  );
}
