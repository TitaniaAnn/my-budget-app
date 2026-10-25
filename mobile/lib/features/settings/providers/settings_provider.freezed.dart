// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserProfile {

 String get userId; String get displayName;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayName);

@override
String toString() {
  return 'UserProfile(userId: $userId, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.userId,_that.displayName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.userId,_that.displayName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.userId,_that.displayName);case _:
  return null;

}
}

}

/// @nodoc


class _UserProfile implements UserProfile {
  const _UserProfile({required this.userId, required this.displayName});
  

@override final  String userId;
@override final  String displayName;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayName);

@override
String toString() {
  return 'UserProfile(userId: $userId, displayName: $displayName)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,}) {
  return _then(_UserProfile(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$HouseholdMember {

 String get userId; String get displayName; String get role; bool get isCurrentUser;
/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdMemberCopyWith<HouseholdMember> get copyWith => _$HouseholdMemberCopyWithImpl<HouseholdMember>(this as HouseholdMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.isCurrentUser, isCurrentUser) || other.isCurrentUser == isCurrentUser));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayName,role,isCurrentUser);

@override
String toString() {
  return 'HouseholdMember(userId: $userId, displayName: $displayName, role: $role, isCurrentUser: $isCurrentUser)';
}


}

/// @nodoc
abstract mixin class $HouseholdMemberCopyWith<$Res>  {
  factory $HouseholdMemberCopyWith(HouseholdMember value, $Res Function(HouseholdMember) _then) = _$HouseholdMemberCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, String role, bool isCurrentUser
});




}
/// @nodoc
class _$HouseholdMemberCopyWithImpl<$Res>
    implements $HouseholdMemberCopyWith<$Res> {
  _$HouseholdMemberCopyWithImpl(this._self, this._then);

  final HouseholdMember _self;
  final $Res Function(HouseholdMember) _then;

/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? role = null,Object? isCurrentUser = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isCurrentUser: null == isCurrentUser ? _self.isCurrentUser : isCurrentUser // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdMember].
extension HouseholdMemberPatterns on HouseholdMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdMember value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdMember value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  String role,  bool isCurrentUser)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.role,_that.isCurrentUser);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  String role,  bool isCurrentUser)  $default,) {final _that = this;
switch (_that) {
case _HouseholdMember():
return $default(_that.userId,_that.displayName,_that.role,_that.isCurrentUser);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  String role,  bool isCurrentUser)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.role,_that.isCurrentUser);case _:
  return null;

}
}

}

/// @nodoc


class _HouseholdMember implements HouseholdMember {
  const _HouseholdMember({required this.userId, required this.displayName, required this.role, required this.isCurrentUser});
  

@override final  String userId;
@override final  String displayName;
@override final  String role;
@override final  bool isCurrentUser;

/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdMemberCopyWith<_HouseholdMember> get copyWith => __$HouseholdMemberCopyWithImpl<_HouseholdMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.role, role) || other.role == role)&&(identical(other.isCurrentUser, isCurrentUser) || other.isCurrentUser == isCurrentUser));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayName,role,isCurrentUser);

@override
String toString() {
  return 'HouseholdMember(userId: $userId, displayName: $displayName, role: $role, isCurrentUser: $isCurrentUser)';
}


}

/// @nodoc
abstract mixin class _$HouseholdMemberCopyWith<$Res> implements $HouseholdMemberCopyWith<$Res> {
  factory _$HouseholdMemberCopyWith(_HouseholdMember value, $Res Function(_HouseholdMember) _then) = __$HouseholdMemberCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, String role, bool isCurrentUser
});




}
/// @nodoc
class __$HouseholdMemberCopyWithImpl<$Res>
    implements _$HouseholdMemberCopyWith<$Res> {
  __$HouseholdMemberCopyWithImpl(this._self, this._then);

  final _HouseholdMember _self;
  final $Res Function(_HouseholdMember) _then;

/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? role = null,Object? isCurrentUser = null,}) {
  return _then(_HouseholdMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isCurrentUser: null == isCurrentUser ? _self.isCurrentUser : isCurrentUser // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$HouseholdInfo {

 String get householdId; String get householdName; bool get isOwner; List<HouseholdMember> get members;/// Currency the dashboard's aggregations are shown in
/// (migration 036). Defaults to 'USD' on every existing row;
/// changed via [SettingsRepository.updateDisplayCurrency].
 String get displayCurrency;
/// Create a copy of HouseholdInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdInfoCopyWith<HouseholdInfo> get copyWith => _$HouseholdInfoCopyWithImpl<HouseholdInfo>(this as HouseholdInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdInfo&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.householdName, householdName) || other.householdName == householdName)&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.displayCurrency, displayCurrency) || other.displayCurrency == displayCurrency));
}


@override
int get hashCode => Object.hash(runtimeType,householdId,householdName,isOwner,const DeepCollectionEquality().hash(members),displayCurrency);

@override
String toString() {
  return 'HouseholdInfo(householdId: $householdId, householdName: $householdName, isOwner: $isOwner, members: $members, displayCurrency: $displayCurrency)';
}


}

/// @nodoc
abstract mixin class $HouseholdInfoCopyWith<$Res>  {
  factory $HouseholdInfoCopyWith(HouseholdInfo value, $Res Function(HouseholdInfo) _then) = _$HouseholdInfoCopyWithImpl;
@useResult
$Res call({
 String householdId, String householdName, bool isOwner, List<HouseholdMember> members, String displayCurrency
});




}
/// @nodoc
class _$HouseholdInfoCopyWithImpl<$Res>
    implements $HouseholdInfoCopyWith<$Res> {
  _$HouseholdInfoCopyWithImpl(this._self, this._then);

  final HouseholdInfo _self;
  final $Res Function(HouseholdInfo) _then;

/// Create a copy of HouseholdInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? householdId = null,Object? householdName = null,Object? isOwner = null,Object? members = null,Object? displayCurrency = null,}) {
  return _then(_self.copyWith(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,householdName: null == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<HouseholdMember>,displayCurrency: null == displayCurrency ? _self.displayCurrency : displayCurrency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdInfo].
extension HouseholdInfoPatterns on HouseholdInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdInfo value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdInfo value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String householdId,  String householdName,  bool isOwner,  List<HouseholdMember> members,  String displayCurrency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdInfo() when $default != null:
return $default(_that.householdId,_that.householdName,_that.isOwner,_that.members,_that.displayCurrency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String householdId,  String householdName,  bool isOwner,  List<HouseholdMember> members,  String displayCurrency)  $default,) {final _that = this;
switch (_that) {
case _HouseholdInfo():
return $default(_that.householdId,_that.householdName,_that.isOwner,_that.members,_that.displayCurrency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String householdId,  String householdName,  bool isOwner,  List<HouseholdMember> members,  String displayCurrency)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdInfo() when $default != null:
return $default(_that.householdId,_that.householdName,_that.isOwner,_that.members,_that.displayCurrency);case _:
  return null;

}
}

}

/// @nodoc


class _HouseholdInfo implements HouseholdInfo {
  const _HouseholdInfo({required this.householdId, required this.householdName, required this.isOwner, required final  List<HouseholdMember> members, this.displayCurrency = 'USD'}): _members = members;
  

@override final  String householdId;
@override final  String householdName;
@override final  bool isOwner;
 final  List<HouseholdMember> _members;
@override List<HouseholdMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

/// Currency the dashboard's aggregations are shown in
/// (migration 036). Defaults to 'USD' on every existing row;
/// changed via [SettingsRepository.updateDisplayCurrency].
@override@JsonKey() final  String displayCurrency;

/// Create a copy of HouseholdInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdInfoCopyWith<_HouseholdInfo> get copyWith => __$HouseholdInfoCopyWithImpl<_HouseholdInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdInfo&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.householdName, householdName) || other.householdName == householdName)&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.displayCurrency, displayCurrency) || other.displayCurrency == displayCurrency));
}


@override
int get hashCode => Object.hash(runtimeType,householdId,householdName,isOwner,const DeepCollectionEquality().hash(_members),displayCurrency);

@override
String toString() {
  return 'HouseholdInfo(householdId: $householdId, householdName: $householdName, isOwner: $isOwner, members: $members, displayCurrency: $displayCurrency)';
}


}

/// @nodoc
abstract mixin class _$HouseholdInfoCopyWith<$Res> implements $HouseholdInfoCopyWith<$Res> {
  factory _$HouseholdInfoCopyWith(_HouseholdInfo value, $Res Function(_HouseholdInfo) _then) = __$HouseholdInfoCopyWithImpl;
@override @useResult
$Res call({
 String householdId, String householdName, bool isOwner, List<HouseholdMember> members, String displayCurrency
});




}
/// @nodoc
class __$HouseholdInfoCopyWithImpl<$Res>
    implements _$HouseholdInfoCopyWith<$Res> {
  __$HouseholdInfoCopyWithImpl(this._self, this._then);

  final _HouseholdInfo _self;
  final $Res Function(_HouseholdInfo) _then;

/// Create a copy of HouseholdInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? householdId = null,Object? householdName = null,Object? isOwner = null,Object? members = null,Object? displayCurrency = null,}) {
  return _then(_HouseholdInfo(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,householdName: null == householdName ? _self.householdName : householdName // ignore: cast_nullable_to_non_nullable
as String,isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<HouseholdMember>,displayCurrency: null == displayCurrency ? _self.displayCurrency : displayCurrency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
