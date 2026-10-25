// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_push_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DevicePushToken {

 String get id; String get userId; String get householdId; DevicePushPlatform get platform; String get token; DateTime get lastSeenAt; DateTime get createdAt;
/// Create a copy of DevicePushToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DevicePushTokenCopyWith<DevicePushToken> get copyWith => _$DevicePushTokenCopyWithImpl<DevicePushToken>(this as DevicePushToken, _$identity);

  /// Serializes this DevicePushToken to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevicePushToken&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.token, token) || other.token == token)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,householdId,platform,token,lastSeenAt,createdAt);

@override
String toString() {
  return 'DevicePushToken(id: $id, userId: $userId, householdId: $householdId, platform: $platform, token: $token, lastSeenAt: $lastSeenAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $DevicePushTokenCopyWith<$Res>  {
  factory $DevicePushTokenCopyWith(DevicePushToken value, $Res Function(DevicePushToken) _then) = _$DevicePushTokenCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String householdId, DevicePushPlatform platform, String token, DateTime lastSeenAt, DateTime createdAt
});




}
/// @nodoc
class _$DevicePushTokenCopyWithImpl<$Res>
    implements $DevicePushTokenCopyWith<$Res> {
  _$DevicePushTokenCopyWithImpl(this._self, this._then);

  final DevicePushToken _self;
  final $Res Function(DevicePushToken) _then;

/// Create a copy of DevicePushToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? householdId = null,Object? platform = null,Object? token = null,Object? lastSeenAt = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as DevicePushPlatform,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DevicePushToken].
extension DevicePushTokenPatterns on DevicePushToken {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DevicePushToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DevicePushToken() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DevicePushToken value)  $default,){
final _that = this;
switch (_that) {
case _DevicePushToken():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DevicePushToken value)?  $default,){
final _that = this;
switch (_that) {
case _DevicePushToken() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String householdId,  DevicePushPlatform platform,  String token,  DateTime lastSeenAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DevicePushToken() when $default != null:
return $default(_that.id,_that.userId,_that.householdId,_that.platform,_that.token,_that.lastSeenAt,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String householdId,  DevicePushPlatform platform,  String token,  DateTime lastSeenAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _DevicePushToken():
return $default(_that.id,_that.userId,_that.householdId,_that.platform,_that.token,_that.lastSeenAt,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String householdId,  DevicePushPlatform platform,  String token,  DateTime lastSeenAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _DevicePushToken() when $default != null:
return $default(_that.id,_that.userId,_that.householdId,_that.platform,_that.token,_that.lastSeenAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DevicePushToken implements DevicePushToken {
  const _DevicePushToken({required this.id, required this.userId, required this.householdId, required this.platform, required this.token, required this.lastSeenAt, required this.createdAt});
  factory _DevicePushToken.fromJson(Map<String, dynamic> json) => _$DevicePushTokenFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String householdId;
@override final  DevicePushPlatform platform;
@override final  String token;
@override final  DateTime lastSeenAt;
@override final  DateTime createdAt;

/// Create a copy of DevicePushToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DevicePushTokenCopyWith<_DevicePushToken> get copyWith => __$DevicePushTokenCopyWithImpl<_DevicePushToken>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DevicePushTokenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DevicePushToken&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.token, token) || other.token == token)&&(identical(other.lastSeenAt, lastSeenAt) || other.lastSeenAt == lastSeenAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,householdId,platform,token,lastSeenAt,createdAt);

@override
String toString() {
  return 'DevicePushToken(id: $id, userId: $userId, householdId: $householdId, platform: $platform, token: $token, lastSeenAt: $lastSeenAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DevicePushTokenCopyWith<$Res> implements $DevicePushTokenCopyWith<$Res> {
  factory _$DevicePushTokenCopyWith(_DevicePushToken value, $Res Function(_DevicePushToken) _then) = __$DevicePushTokenCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String householdId, DevicePushPlatform platform, String token, DateTime lastSeenAt, DateTime createdAt
});




}
/// @nodoc
class __$DevicePushTokenCopyWithImpl<$Res>
    implements _$DevicePushTokenCopyWith<$Res> {
  __$DevicePushTokenCopyWithImpl(this._self, this._then);

  final _DevicePushToken _self;
  final $Res Function(_DevicePushToken) _then;

/// Create a copy of DevicePushToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? householdId = null,Object? platform = null,Object? token = null,Object? lastSeenAt = null,Object? createdAt = null,}) {
  return _then(_DevicePushToken(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as DevicePushPlatform,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,lastSeenAt: null == lastSeenAt ? _self.lastSeenAt : lastSeenAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
