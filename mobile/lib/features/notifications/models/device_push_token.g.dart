// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_push_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DevicePushTokenImpl _$$DevicePushTokenImplFromJson(
  Map<String, dynamic> json,
) => _$DevicePushTokenImpl(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  householdId: json['household_id'] as String,
  platform: $enumDecode(_$DevicePushPlatformEnumMap, json['platform']),
  token: json['token'] as String,
  lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$DevicePushTokenImplToJson(
  _$DevicePushTokenImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'household_id': instance.householdId,
  'platform': _$DevicePushPlatformEnumMap[instance.platform]!,
  'token': instance.token,
  'last_seen_at': instance.lastSeenAt.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

const _$DevicePushPlatformEnumMap = {
  DevicePushPlatform.fcmAndroid: 'fcm_android',
  DevicePushPlatform.fcmIos: 'fcm_ios',
  DevicePushPlatform.webPush: 'web_push',
};
