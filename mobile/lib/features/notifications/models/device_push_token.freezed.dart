// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_push_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DevicePushToken _$DevicePushTokenFromJson(Map<String, dynamic> json) {
  return _DevicePushToken.fromJson(json);
}

/// @nodoc
mixin _$DevicePushToken {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get householdId => throw _privateConstructorUsedError;
  DevicePushPlatform get platform => throw _privateConstructorUsedError;
  String get token => throw _privateConstructorUsedError;
  DateTime get lastSeenAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this DevicePushToken to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DevicePushToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DevicePushTokenCopyWith<DevicePushToken> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DevicePushTokenCopyWith<$Res> {
  factory $DevicePushTokenCopyWith(
    DevicePushToken value,
    $Res Function(DevicePushToken) then,
  ) = _$DevicePushTokenCopyWithImpl<$Res, DevicePushToken>;
  @useResult
  $Res call({
    String id,
    String userId,
    String householdId,
    DevicePushPlatform platform,
    String token,
    DateTime lastSeenAt,
    DateTime createdAt,
  });
}

/// @nodoc
class _$DevicePushTokenCopyWithImpl<$Res, $Val extends DevicePushToken>
    implements $DevicePushTokenCopyWith<$Res> {
  _$DevicePushTokenCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DevicePushToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? householdId = null,
    Object? platform = null,
    Object? token = null,
    Object? lastSeenAt = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            householdId: null == householdId
                ? _value.householdId
                : householdId // ignore: cast_nullable_to_non_nullable
                      as String,
            platform: null == platform
                ? _value.platform
                : platform // ignore: cast_nullable_to_non_nullable
                      as DevicePushPlatform,
            token: null == token
                ? _value.token
                : token // ignore: cast_nullable_to_non_nullable
                      as String,
            lastSeenAt: null == lastSeenAt
                ? _value.lastSeenAt
                : lastSeenAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DevicePushTokenImplCopyWith<$Res>
    implements $DevicePushTokenCopyWith<$Res> {
  factory _$$DevicePushTokenImplCopyWith(
    _$DevicePushTokenImpl value,
    $Res Function(_$DevicePushTokenImpl) then,
  ) = __$$DevicePushTokenImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String householdId,
    DevicePushPlatform platform,
    String token,
    DateTime lastSeenAt,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$DevicePushTokenImplCopyWithImpl<$Res>
    extends _$DevicePushTokenCopyWithImpl<$Res, _$DevicePushTokenImpl>
    implements _$$DevicePushTokenImplCopyWith<$Res> {
  __$$DevicePushTokenImplCopyWithImpl(
    _$DevicePushTokenImpl _value,
    $Res Function(_$DevicePushTokenImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DevicePushToken
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? householdId = null,
    Object? platform = null,
    Object? token = null,
    Object? lastSeenAt = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$DevicePushTokenImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        householdId: null == householdId
            ? _value.householdId
            : householdId // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as DevicePushPlatform,
        token: null == token
            ? _value.token
            : token // ignore: cast_nullable_to_non_nullable
                  as String,
        lastSeenAt: null == lastSeenAt
            ? _value.lastSeenAt
            : lastSeenAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DevicePushTokenImpl implements _DevicePushToken {
  const _$DevicePushTokenImpl({
    required this.id,
    required this.userId,
    required this.householdId,
    required this.platform,
    required this.token,
    required this.lastSeenAt,
    required this.createdAt,
  });

  factory _$DevicePushTokenImpl.fromJson(Map<String, dynamic> json) =>
      _$$DevicePushTokenImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String householdId;
  @override
  final DevicePushPlatform platform;
  @override
  final String token;
  @override
  final DateTime lastSeenAt;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'DevicePushToken(id: $id, userId: $userId, householdId: $householdId, platform: $platform, token: $token, lastSeenAt: $lastSeenAt, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DevicePushTokenImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.lastSeenAt, lastSeenAt) ||
                other.lastSeenAt == lastSeenAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    householdId,
    platform,
    token,
    lastSeenAt,
    createdAt,
  );

  /// Create a copy of DevicePushToken
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DevicePushTokenImplCopyWith<_$DevicePushTokenImpl> get copyWith =>
      __$$DevicePushTokenImplCopyWithImpl<_$DevicePushTokenImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DevicePushTokenImplToJson(this);
  }
}

abstract class _DevicePushToken implements DevicePushToken {
  const factory _DevicePushToken({
    required final String id,
    required final String userId,
    required final String householdId,
    required final DevicePushPlatform platform,
    required final String token,
    required final DateTime lastSeenAt,
    required final DateTime createdAt,
  }) = _$DevicePushTokenImpl;

  factory _DevicePushToken.fromJson(Map<String, dynamic> json) =
      _$DevicePushTokenImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get householdId;
  @override
  DevicePushPlatform get platform;
  @override
  String get token;
  @override
  DateTime get lastSeenAt;
  @override
  DateTime get createdAt;

  /// Create a copy of DevicePushToken
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DevicePushTokenImplCopyWith<_$DevicePushTokenImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
