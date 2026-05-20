// Integration tests for DevicePushTokensRepository (migration 033).
//
// The local-notifications engine that already ships works without
// these tokens — they exist for the future server-side delivery
// path. Pinning the access contract now means slice 2 doesn't have
// to rediscover it.
//
// Pinned here:
//   * registerToken is idempotent on (user_id, token) — re-running
//     the same registration only refreshes last_seen_at, never
//     creates a duplicate row;
//   * a re-register with a different `platform` UPDATES the row
//     (a device that switched providers shouldn't leave a stale
//     entry behind);
//   * removeToken deletes only the row matching the token,
//     leaving other registrations alone;
//   * listMine returns the caller's tokens ordered newest-first.
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY
// env vars aren't set.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/notifications/models/device_push_token.dart';
import 'package:mybudget/features/notifications/repositories/device_push_tokens_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('DevicePushTokensRepository (integration)', () {
    late Harness harness;
    late DevicePushTokensRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'device-tokens');
      repo = DevicePushTokensRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    // Each test wants a clean slate so the listMine ordering
    // assertion isn't sensitive to sibling tests.
    setUp(() async {
      if (reason != null) return;
      await harness.client
          .from('device_push_tokens')
          .delete()
          .eq('user_id', harness.userId);
    });

    test(
      'registerToken inserts on first call, refreshes last_seen on re-call',
      () async {
        await repo.registerToken(
          userId: harness.userId,
          householdId: harness.householdId,
          token: 'fcm-token-A',
          platform: DevicePushPlatform.fcmAndroid,
        );
        final first = (await repo.listMine()).single;
        final firstSeen = first.lastSeenAt;

        // Small sleep so the second `last_seen_at` is strictly later
        // — the wire round-trip already gives us tens of ms in
        // practice, but pinning it explicitly avoids a flaky
        // millisecond-equality test.
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await repo.registerToken(
          userId: harness.userId,
          householdId: harness.householdId,
          token: 'fcm-token-A',
          platform: DevicePushPlatform.fcmAndroid,
        );

        final all = await repo.listMine();
        expect(
          all,
          hasLength(1),
          reason:
              'idempotent upsert on (user_id, token) — re-registering '
              'the same token must NOT create a duplicate row.',
        );
        expect(
          all.single.lastSeenAt.isAfter(firstSeen),
          isTrue,
          reason: 'last_seen_at must advance on every register so the '
              'server-side pruner can tell live tokens from stale ones.',
        );
      },
      skip: reason,
    );

    test(
      'registering the same token with a different platform UPDATES '
      'the existing row',
      () async {
        await repo.registerToken(
          userId: harness.userId,
          householdId: harness.householdId,
          token: 'fcm-token-B',
          platform: DevicePushPlatform.fcmAndroid,
        );
        await repo.registerToken(
          userId: harness.userId,
          householdId: harness.householdId,
          token: 'fcm-token-B',
          platform: DevicePushPlatform.fcmIos,
        );

        final all = await repo.listMine();
        expect(all, hasLength(1));
        expect(
          all.single.platform,
          DevicePushPlatform.fcmIos,
          reason: 'a device that switches providers must overwrite the '
              'stored platform — otherwise the server-side push job '
              'would send to the wrong FCM topic.',
        );
      },
      skip: reason,
    );

    test(
      'removeToken deletes only the matching row',
      () async {
        await repo.registerToken(
          userId: harness.userId,
          householdId: harness.householdId,
          token: 'keep-me',
          platform: DevicePushPlatform.fcmAndroid,
        );
        await repo.registerToken(
          userId: harness.userId,
          householdId: harness.householdId,
          token: 'doomed',
          platform: DevicePushPlatform.fcmAndroid,
        );

        await repo.removeToken('doomed');

        final remaining = await repo.listMine();
        expect(remaining.map((t) => t.token), ['keep-me']);
      },
      skip: reason,
    );

    test(
      'listMine orders newest last_seen_at first',
      () async {
        await repo.registerToken(
          userId: harness.userId,
          householdId: harness.householdId,
          token: 'older',
          platform: DevicePushPlatform.fcmAndroid,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await repo.registerToken(
          userId: harness.userId,
          householdId: harness.householdId,
          token: 'newer',
          platform: DevicePushPlatform.fcmAndroid,
        );

        final all = await repo.listMine();
        expect(all.map((t) => t.token), ['newer', 'older']);
      },
      skip: reason,
    );
  });
}
