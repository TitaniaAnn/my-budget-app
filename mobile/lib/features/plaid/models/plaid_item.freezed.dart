// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plaid_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaidItem {

 String get id; String get householdId; String get createdBy; String get plaidItemId; String? get plaidInstitutionId; String? get institutionName; PlaidEnvironment get environment; String? get syncCursor; DateTime? get lastSyncAt; String? get lastSyncError; DateTime? get consentExpiresAt; bool get isActive; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of PlaidItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaidItemCopyWith<PlaidItem> get copyWith => _$PlaidItemCopyWithImpl<PlaidItem>(this as PlaidItem, _$identity);

  /// Serializes this PlaidItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaidItem&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.plaidItemId, plaidItemId) || other.plaidItemId == plaidItemId)&&(identical(other.plaidInstitutionId, plaidInstitutionId) || other.plaidInstitutionId == plaidInstitutionId)&&(identical(other.institutionName, institutionName) || other.institutionName == institutionName)&&(identical(other.environment, environment) || other.environment == environment)&&(identical(other.syncCursor, syncCursor) || other.syncCursor == syncCursor)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.lastSyncError, lastSyncError) || other.lastSyncError == lastSyncError)&&(identical(other.consentExpiresAt, consentExpiresAt) || other.consentExpiresAt == consentExpiresAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,createdBy,plaidItemId,plaidInstitutionId,institutionName,environment,syncCursor,lastSyncAt,lastSyncError,consentExpiresAt,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'PlaidItem(id: $id, householdId: $householdId, createdBy: $createdBy, plaidItemId: $plaidItemId, plaidInstitutionId: $plaidInstitutionId, institutionName: $institutionName, environment: $environment, syncCursor: $syncCursor, lastSyncAt: $lastSyncAt, lastSyncError: $lastSyncError, consentExpiresAt: $consentExpiresAt, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PlaidItemCopyWith<$Res>  {
  factory $PlaidItemCopyWith(PlaidItem value, $Res Function(PlaidItem) _then) = _$PlaidItemCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String createdBy, String plaidItemId, String? plaidInstitutionId, String? institutionName, PlaidEnvironment environment, String? syncCursor, DateTime? lastSyncAt, String? lastSyncError, DateTime? consentExpiresAt, bool isActive, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$PlaidItemCopyWithImpl<$Res>
    implements $PlaidItemCopyWith<$Res> {
  _$PlaidItemCopyWithImpl(this._self, this._then);

  final PlaidItem _self;
  final $Res Function(PlaidItem) _then;

/// Create a copy of PlaidItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? createdBy = null,Object? plaidItemId = null,Object? plaidInstitutionId = freezed,Object? institutionName = freezed,Object? environment = null,Object? syncCursor = freezed,Object? lastSyncAt = freezed,Object? lastSyncError = freezed,Object? consentExpiresAt = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,plaidItemId: null == plaidItemId ? _self.plaidItemId : plaidItemId // ignore: cast_nullable_to_non_nullable
as String,plaidInstitutionId: freezed == plaidInstitutionId ? _self.plaidInstitutionId : plaidInstitutionId // ignore: cast_nullable_to_non_nullable
as String?,institutionName: freezed == institutionName ? _self.institutionName : institutionName // ignore: cast_nullable_to_non_nullable
as String?,environment: null == environment ? _self.environment : environment // ignore: cast_nullable_to_non_nullable
as PlaidEnvironment,syncCursor: freezed == syncCursor ? _self.syncCursor : syncCursor // ignore: cast_nullable_to_non_nullable
as String?,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSyncError: freezed == lastSyncError ? _self.lastSyncError : lastSyncError // ignore: cast_nullable_to_non_nullable
as String?,consentExpiresAt: freezed == consentExpiresAt ? _self.consentExpiresAt : consentExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaidItem].
extension PlaidItemPatterns on PlaidItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaidItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaidItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaidItem value)  $default,){
final _that = this;
switch (_that) {
case _PlaidItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaidItem value)?  $default,){
final _that = this;
switch (_that) {
case _PlaidItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String createdBy,  String plaidItemId,  String? plaidInstitutionId,  String? institutionName,  PlaidEnvironment environment,  String? syncCursor,  DateTime? lastSyncAt,  String? lastSyncError,  DateTime? consentExpiresAt,  bool isActive,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaidItem() when $default != null:
return $default(_that.id,_that.householdId,_that.createdBy,_that.plaidItemId,_that.plaidInstitutionId,_that.institutionName,_that.environment,_that.syncCursor,_that.lastSyncAt,_that.lastSyncError,_that.consentExpiresAt,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String createdBy,  String plaidItemId,  String? plaidInstitutionId,  String? institutionName,  PlaidEnvironment environment,  String? syncCursor,  DateTime? lastSyncAt,  String? lastSyncError,  DateTime? consentExpiresAt,  bool isActive,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PlaidItem():
return $default(_that.id,_that.householdId,_that.createdBy,_that.plaidItemId,_that.plaidInstitutionId,_that.institutionName,_that.environment,_that.syncCursor,_that.lastSyncAt,_that.lastSyncError,_that.consentExpiresAt,_that.isActive,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String createdBy,  String plaidItemId,  String? plaidInstitutionId,  String? institutionName,  PlaidEnvironment environment,  String? syncCursor,  DateTime? lastSyncAt,  String? lastSyncError,  DateTime? consentExpiresAt,  bool isActive,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlaidItem() when $default != null:
return $default(_that.id,_that.householdId,_that.createdBy,_that.plaidItemId,_that.plaidInstitutionId,_that.institutionName,_that.environment,_that.syncCursor,_that.lastSyncAt,_that.lastSyncError,_that.consentExpiresAt,_that.isActive,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaidItem implements PlaidItem {
  const _PlaidItem({required this.id, required this.householdId, required this.createdBy, required this.plaidItemId, this.plaidInstitutionId, this.institutionName, required this.environment, this.syncCursor, this.lastSyncAt, this.lastSyncError, this.consentExpiresAt, required this.isActive, required this.createdAt, required this.updatedAt});
  factory _PlaidItem.fromJson(Map<String, dynamic> json) => _$PlaidItemFromJson(json);

@override final  String id;
@override final  String householdId;
@override final  String createdBy;
@override final  String plaidItemId;
@override final  String? plaidInstitutionId;
@override final  String? institutionName;
@override final  PlaidEnvironment environment;
@override final  String? syncCursor;
@override final  DateTime? lastSyncAt;
@override final  String? lastSyncError;
@override final  DateTime? consentExpiresAt;
@override final  bool isActive;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of PlaidItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaidItemCopyWith<_PlaidItem> get copyWith => __$PlaidItemCopyWithImpl<_PlaidItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaidItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaidItem&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.plaidItemId, plaidItemId) || other.plaidItemId == plaidItemId)&&(identical(other.plaidInstitutionId, plaidInstitutionId) || other.plaidInstitutionId == plaidInstitutionId)&&(identical(other.institutionName, institutionName) || other.institutionName == institutionName)&&(identical(other.environment, environment) || other.environment == environment)&&(identical(other.syncCursor, syncCursor) || other.syncCursor == syncCursor)&&(identical(other.lastSyncAt, lastSyncAt) || other.lastSyncAt == lastSyncAt)&&(identical(other.lastSyncError, lastSyncError) || other.lastSyncError == lastSyncError)&&(identical(other.consentExpiresAt, consentExpiresAt) || other.consentExpiresAt == consentExpiresAt)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,createdBy,plaidItemId,plaidInstitutionId,institutionName,environment,syncCursor,lastSyncAt,lastSyncError,consentExpiresAt,isActive,createdAt,updatedAt);

@override
String toString() {
  return 'PlaidItem(id: $id, householdId: $householdId, createdBy: $createdBy, plaidItemId: $plaidItemId, plaidInstitutionId: $plaidInstitutionId, institutionName: $institutionName, environment: $environment, syncCursor: $syncCursor, lastSyncAt: $lastSyncAt, lastSyncError: $lastSyncError, consentExpiresAt: $consentExpiresAt, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PlaidItemCopyWith<$Res> implements $PlaidItemCopyWith<$Res> {
  factory _$PlaidItemCopyWith(_PlaidItem value, $Res Function(_PlaidItem) _then) = __$PlaidItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String createdBy, String plaidItemId, String? plaidInstitutionId, String? institutionName, PlaidEnvironment environment, String? syncCursor, DateTime? lastSyncAt, String? lastSyncError, DateTime? consentExpiresAt, bool isActive, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$PlaidItemCopyWithImpl<$Res>
    implements _$PlaidItemCopyWith<$Res> {
  __$PlaidItemCopyWithImpl(this._self, this._then);

  final _PlaidItem _self;
  final $Res Function(_PlaidItem) _then;

/// Create a copy of PlaidItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? createdBy = null,Object? plaidItemId = null,Object? plaidInstitutionId = freezed,Object? institutionName = freezed,Object? environment = null,Object? syncCursor = freezed,Object? lastSyncAt = freezed,Object? lastSyncError = freezed,Object? consentExpiresAt = freezed,Object? isActive = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_PlaidItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,plaidItemId: null == plaidItemId ? _self.plaidItemId : plaidItemId // ignore: cast_nullable_to_non_nullable
as String,plaidInstitutionId: freezed == plaidInstitutionId ? _self.plaidInstitutionId : plaidInstitutionId // ignore: cast_nullable_to_non_nullable
as String?,institutionName: freezed == institutionName ? _self.institutionName : institutionName // ignore: cast_nullable_to_non_nullable
as String?,environment: null == environment ? _self.environment : environment // ignore: cast_nullable_to_non_nullable
as PlaidEnvironment,syncCursor: freezed == syncCursor ? _self.syncCursor : syncCursor // ignore: cast_nullable_to_non_nullable
as String?,lastSyncAt: freezed == lastSyncAt ? _self.lastSyncAt : lastSyncAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSyncError: freezed == lastSyncError ? _self.lastSyncError : lastSyncError // ignore: cast_nullable_to_non_nullable
as String?,consentExpiresAt: freezed == consentExpiresAt ? _self.consentExpiresAt : consentExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
