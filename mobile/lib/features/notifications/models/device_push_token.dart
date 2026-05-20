// DevicePushToken — mirrors the `device_push_tokens` table
// (migration 033).
//
// One row per (user, token) pair. The Flutter app registers its
// FCM/APNS token on launch and keeps `last_seen_at` fresh; a
// future server-side Edge Function (slice 2) uses these rows to
// look up where to actually deliver a push.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_push_token.freezed.dart';
part 'device_push_token.g.dart';

/// Documented value set for the `platform` text column. Kept as a
/// Dart enum (not a Postgres enum) so the column can grow into
/// new push providers without a schema migration — the trade is
/// that the type contract is enforced only on the Dart side.
enum DevicePushPlatform {
  @JsonValue('fcm_android')
  fcmAndroid,
  @JsonValue('fcm_ios')
  fcmIos,
  @JsonValue('web_push')
  webPush;

  String get dbValue => switch (this) {
    DevicePushPlatform.fcmAndroid => 'fcm_android',
    DevicePushPlatform.fcmIos => 'fcm_ios',
    DevicePushPlatform.webPush => 'web_push',
  };
}

@freezed
class DevicePushToken with _$DevicePushToken {
  const factory DevicePushToken({
    required String id,
    required String userId,
    required String householdId,
    required DevicePushPlatform platform,
    required String token,
    required DateTime lastSeenAt,
    required DateTime createdAt,
  }) = _DevicePushToken;

  factory DevicePushToken.fromJson(Map<String, dynamic> json) =>
      _$DevicePushTokenFromJson(json);
}
