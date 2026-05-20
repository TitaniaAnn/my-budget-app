// Data access layer for the user's device push tokens.
//
// Only the current user's rows are reachable through this repo —
// RLS gates that at the DB level, and we don't paper over it here.
// The future server-side delivery path will run as the service
// role to see across users; that code lives outside this repo and
// is intentionally not wired up here.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../models/device_push_token.dart';

part 'device_push_tokens_repository.g.dart';

@riverpod
DevicePushTokensRepository devicePushTokensRepository(
  DevicePushTokensRepositoryRef ref,
) {
  return DevicePushTokensRepository();
}

class DevicePushTokensRepository {
  /// Upserts the (user, token) row. Called on every app launch
  /// from a future FCM bootstrap path so `last_seen_at` stays
  /// fresh — UNIQUE (user_id, token) on the table makes this
  /// idempotent. Updates the platform + last_seen on conflict so
  /// a device that switches platforms (e.g. cleared app data) is
  /// captured without ending up with a stale row.
  Future<void> registerToken({
    required String userId,
    required String householdId,
    required String token,
    required DevicePushPlatform platform,
  }) async {
    await supabase
        .from('device_push_tokens')
        .upsert(
          {
            'user_id': userId,
            'household_id': householdId,
            'token': token,
            'platform': platform.dbValue,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id,token',
        );
  }

  /// Removes a specific token — called on logout and when FCM
  /// reports the token has been invalidated. Scoped through RLS
  /// to the current user, so a malicious caller can't unregister
  /// someone else's device.
  Future<void> removeToken(String token) async {
    await supabase.from('device_push_tokens').delete().eq('token', token);
  }

  /// Lists the calling user's own tokens. Used by a future
  /// "linked devices" surface in Settings; the production push
  /// delivery path doesn't go through Dart so this isn't on a hot
  /// query path.
  Future<List<DevicePushToken>> listMine() async {
    final data = await supabase
        .from('device_push_tokens')
        .select()
        .order('last_seen_at', ascending: false);
    return data.map<DevicePushToken>(DevicePushToken.fromJson).toList();
  }
}
