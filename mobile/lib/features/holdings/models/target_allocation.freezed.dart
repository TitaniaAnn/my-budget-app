// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'target_allocation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TargetAllocation {

 String get householdId; AssetClass get assetClass;/// Target weight in basis points (0–10000). The setter UI gates
/// the full household sum to 100% before saving; individual rows
/// don't carry that invariant — a partial set (stocks + bonds
/// defined, no cash row) is valid and treated as 0% for the
/// undefined classes.
 int get targetPctBp; String? get createdBy; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of TargetAllocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TargetAllocationCopyWith<TargetAllocation> get copyWith => _$TargetAllocationCopyWithImpl<TargetAllocation>(this as TargetAllocation, _$identity);

  /// Serializes this TargetAllocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TargetAllocation&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.assetClass, assetClass) || other.assetClass == assetClass)&&(identical(other.targetPctBp, targetPctBp) || other.targetPctBp == targetPctBp)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,householdId,assetClass,targetPctBp,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'TargetAllocation(householdId: $householdId, assetClass: $assetClass, targetPctBp: $targetPctBp, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TargetAllocationCopyWith<$Res>  {
  factory $TargetAllocationCopyWith(TargetAllocation value, $Res Function(TargetAllocation) _then) = _$TargetAllocationCopyWithImpl;
@useResult
$Res call({
 String householdId, AssetClass assetClass, int targetPctBp, String? createdBy, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$TargetAllocationCopyWithImpl<$Res>
    implements $TargetAllocationCopyWith<$Res> {
  _$TargetAllocationCopyWithImpl(this._self, this._then);

  final TargetAllocation _self;
  final $Res Function(TargetAllocation) _then;

/// Create a copy of TargetAllocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? householdId = null,Object? assetClass = null,Object? targetPctBp = null,Object? createdBy = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,assetClass: null == assetClass ? _self.assetClass : assetClass // ignore: cast_nullable_to_non_nullable
as AssetClass,targetPctBp: null == targetPctBp ? _self.targetPctBp : targetPctBp // ignore: cast_nullable_to_non_nullable
as int,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TargetAllocation].
extension TargetAllocationPatterns on TargetAllocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TargetAllocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TargetAllocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TargetAllocation value)  $default,){
final _that = this;
switch (_that) {
case _TargetAllocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TargetAllocation value)?  $default,){
final _that = this;
switch (_that) {
case _TargetAllocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String householdId,  AssetClass assetClass,  int targetPctBp,  String? createdBy,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TargetAllocation() when $default != null:
return $default(_that.householdId,_that.assetClass,_that.targetPctBp,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String householdId,  AssetClass assetClass,  int targetPctBp,  String? createdBy,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TargetAllocation():
return $default(_that.householdId,_that.assetClass,_that.targetPctBp,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String householdId,  AssetClass assetClass,  int targetPctBp,  String? createdBy,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TargetAllocation() when $default != null:
return $default(_that.householdId,_that.assetClass,_that.targetPctBp,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TargetAllocation implements TargetAllocation {
  const _TargetAllocation({required this.householdId, required this.assetClass, required this.targetPctBp, this.createdBy, required this.createdAt, required this.updatedAt});
  factory _TargetAllocation.fromJson(Map<String, dynamic> json) => _$TargetAllocationFromJson(json);

@override final  String householdId;
@override final  AssetClass assetClass;
/// Target weight in basis points (0–10000). The setter UI gates
/// the full household sum to 100% before saving; individual rows
/// don't carry that invariant — a partial set (stocks + bonds
/// defined, no cash row) is valid and treated as 0% for the
/// undefined classes.
@override final  int targetPctBp;
@override final  String? createdBy;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of TargetAllocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TargetAllocationCopyWith<_TargetAllocation> get copyWith => __$TargetAllocationCopyWithImpl<_TargetAllocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TargetAllocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TargetAllocation&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.assetClass, assetClass) || other.assetClass == assetClass)&&(identical(other.targetPctBp, targetPctBp) || other.targetPctBp == targetPctBp)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,householdId,assetClass,targetPctBp,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'TargetAllocation(householdId: $householdId, assetClass: $assetClass, targetPctBp: $targetPctBp, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TargetAllocationCopyWith<$Res> implements $TargetAllocationCopyWith<$Res> {
  factory _$TargetAllocationCopyWith(_TargetAllocation value, $Res Function(_TargetAllocation) _then) = __$TargetAllocationCopyWithImpl;
@override @useResult
$Res call({
 String householdId, AssetClass assetClass, int targetPctBp, String? createdBy, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$TargetAllocationCopyWithImpl<$Res>
    implements _$TargetAllocationCopyWith<$Res> {
  __$TargetAllocationCopyWithImpl(this._self, this._then);

  final _TargetAllocation _self;
  final $Res Function(_TargetAllocation) _then;

/// Create a copy of TargetAllocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? householdId = null,Object? assetClass = null,Object? targetPctBp = null,Object? createdBy = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TargetAllocation(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,assetClass: null == assetClass ? _self.assetClass : assetClass // ignore: cast_nullable_to_non_nullable
as AssetClass,targetPctBp: null == targetPctBp ? _self.targetPctBp : targetPctBp // ignore: cast_nullable_to_non_nullable
as int,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
