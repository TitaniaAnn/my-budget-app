// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionTag {

 String get id; String get householdId; String get name;/// Optional hex color (e.g. "#22C55E") for the chip background.
/// CHAR(7) in SQL so a 6-digit hex + leading '#' fits exactly.
 String? get color; DateTime get createdAt;
/// Create a copy of TransactionTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionTagCopyWith<TransactionTag> get copyWith => _$TransactionTagCopyWithImpl<TransactionTag>(this as TransactionTag, _$identity);

  /// Serializes this TransactionTag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionTag&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,name,color,createdAt);

@override
String toString() {
  return 'TransactionTag(id: $id, householdId: $householdId, name: $name, color: $color, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TransactionTagCopyWith<$Res>  {
  factory $TransactionTagCopyWith(TransactionTag value, $Res Function(TransactionTag) _then) = _$TransactionTagCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String name, String? color, DateTime createdAt
});




}
/// @nodoc
class _$TransactionTagCopyWithImpl<$Res>
    implements $TransactionTagCopyWith<$Res> {
  _$TransactionTagCopyWithImpl(this._self, this._then);

  final TransactionTag _self;
  final $Res Function(TransactionTag) _then;

/// Create a copy of TransactionTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? name = null,Object? color = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionTag].
extension TransactionTagPatterns on TransactionTag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionTag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionTag value)  $default,){
final _that = this;
switch (_that) {
case _TransactionTag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionTag value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionTag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String name,  String? color,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionTag() when $default != null:
return $default(_that.id,_that.householdId,_that.name,_that.color,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String name,  String? color,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _TransactionTag():
return $default(_that.id,_that.householdId,_that.name,_that.color,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String name,  String? color,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TransactionTag() when $default != null:
return $default(_that.id,_that.householdId,_that.name,_that.color,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransactionTag implements TransactionTag {
  const _TransactionTag({required this.id, required this.householdId, required this.name, this.color, required this.createdAt});
  factory _TransactionTag.fromJson(Map<String, dynamic> json) => _$TransactionTagFromJson(json);

@override final  String id;
@override final  String householdId;
@override final  String name;
/// Optional hex color (e.g. "#22C55E") for the chip background.
/// CHAR(7) in SQL so a 6-digit hex + leading '#' fits exactly.
@override final  String? color;
@override final  DateTime createdAt;

/// Create a copy of TransactionTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionTagCopyWith<_TransactionTag> get copyWith => __$TransactionTagCopyWithImpl<_TransactionTag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionTagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionTag&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.name, name) || other.name == name)&&(identical(other.color, color) || other.color == color)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,name,color,createdAt);

@override
String toString() {
  return 'TransactionTag(id: $id, householdId: $householdId, name: $name, color: $color, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TransactionTagCopyWith<$Res> implements $TransactionTagCopyWith<$Res> {
  factory _$TransactionTagCopyWith(_TransactionTag value, $Res Function(_TransactionTag) _then) = __$TransactionTagCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String name, String? color, DateTime createdAt
});




}
/// @nodoc
class __$TransactionTagCopyWithImpl<$Res>
    implements _$TransactionTagCopyWith<$Res> {
  __$TransactionTagCopyWithImpl(this._self, this._then);

  final _TransactionTag _self;
  final $Res Function(_TransactionTag) _then;

/// Create a copy of TransactionTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? name = null,Object? color = freezed,Object? createdAt = null,}) {
  return _then(_TransactionTag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
