// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credit_card_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreditCardRate {

 String get id; String get accountId; CreditRateType get rateType;/// Annual rate as a decimal (e.g. 0.2499 = 24.99%).
 double get rate; bool get isIntro; DateTime? get introEndsOn; bool get isActive; String? get label; DateTime get createdAt;
/// Create a copy of CreditCardRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditCardRateCopyWith<CreditCardRate> get copyWith => _$CreditCardRateCopyWithImpl<CreditCardRate>(this as CreditCardRate, _$identity);

  /// Serializes this CreditCardRate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCardRate&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.rateType, rateType) || other.rateType == rateType)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.isIntro, isIntro) || other.isIntro == isIntro)&&(identical(other.introEndsOn, introEndsOn) || other.introEndsOn == introEndsOn)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountId,rateType,rate,isIntro,introEndsOn,isActive,label,createdAt);

@override
String toString() {
  return 'CreditCardRate(id: $id, accountId: $accountId, rateType: $rateType, rate: $rate, isIntro: $isIntro, introEndsOn: $introEndsOn, isActive: $isActive, label: $label, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CreditCardRateCopyWith<$Res>  {
  factory $CreditCardRateCopyWith(CreditCardRate value, $Res Function(CreditCardRate) _then) = _$CreditCardRateCopyWithImpl;
@useResult
$Res call({
 String id, String accountId, CreditRateType rateType, double rate, bool isIntro, DateTime? introEndsOn, bool isActive, String? label, DateTime createdAt
});




}
/// @nodoc
class _$CreditCardRateCopyWithImpl<$Res>
    implements $CreditCardRateCopyWith<$Res> {
  _$CreditCardRateCopyWithImpl(this._self, this._then);

  final CreditCardRate _self;
  final $Res Function(CreditCardRate) _then;

/// Create a copy of CreditCardRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountId = null,Object? rateType = null,Object? rate = null,Object? isIntro = null,Object? introEndsOn = freezed,Object? isActive = null,Object? label = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,rateType: null == rateType ? _self.rateType : rateType // ignore: cast_nullable_to_non_nullable
as CreditRateType,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,isIntro: null == isIntro ? _self.isIntro : isIntro // ignore: cast_nullable_to_non_nullable
as bool,introEndsOn: freezed == introEndsOn ? _self.introEndsOn : introEndsOn // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CreditCardRate].
extension CreditCardRatePatterns on CreditCardRate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreditCardRate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreditCardRate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreditCardRate value)  $default,){
final _that = this;
switch (_that) {
case _CreditCardRate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreditCardRate value)?  $default,){
final _that = this;
switch (_that) {
case _CreditCardRate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountId,  CreditRateType rateType,  double rate,  bool isIntro,  DateTime? introEndsOn,  bool isActive,  String? label,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreditCardRate() when $default != null:
return $default(_that.id,_that.accountId,_that.rateType,_that.rate,_that.isIntro,_that.introEndsOn,_that.isActive,_that.label,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountId,  CreditRateType rateType,  double rate,  bool isIntro,  DateTime? introEndsOn,  bool isActive,  String? label,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _CreditCardRate():
return $default(_that.id,_that.accountId,_that.rateType,_that.rate,_that.isIntro,_that.introEndsOn,_that.isActive,_that.label,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountId,  CreditRateType rateType,  double rate,  bool isIntro,  DateTime? introEndsOn,  bool isActive,  String? label,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CreditCardRate() when $default != null:
return $default(_that.id,_that.accountId,_that.rateType,_that.rate,_that.isIntro,_that.introEndsOn,_that.isActive,_that.label,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreditCardRate implements CreditCardRate {
  const _CreditCardRate({required this.id, required this.accountId, required this.rateType, required this.rate, required this.isIntro, this.introEndsOn, required this.isActive, this.label, required this.createdAt});
  factory _CreditCardRate.fromJson(Map<String, dynamic> json) => _$CreditCardRateFromJson(json);

@override final  String id;
@override final  String accountId;
@override final  CreditRateType rateType;
/// Annual rate as a decimal (e.g. 0.2499 = 24.99%).
@override final  double rate;
@override final  bool isIntro;
@override final  DateTime? introEndsOn;
@override final  bool isActive;
@override final  String? label;
@override final  DateTime createdAt;

/// Create a copy of CreditCardRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreditCardRateCopyWith<_CreditCardRate> get copyWith => __$CreditCardRateCopyWithImpl<_CreditCardRate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreditCardRateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreditCardRate&&(identical(other.id, id) || other.id == id)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.rateType, rateType) || other.rateType == rateType)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.isIntro, isIntro) || other.isIntro == isIntro)&&(identical(other.introEndsOn, introEndsOn) || other.introEndsOn == introEndsOn)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.label, label) || other.label == label)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,accountId,rateType,rate,isIntro,introEndsOn,isActive,label,createdAt);

@override
String toString() {
  return 'CreditCardRate(id: $id, accountId: $accountId, rateType: $rateType, rate: $rate, isIntro: $isIntro, introEndsOn: $introEndsOn, isActive: $isActive, label: $label, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CreditCardRateCopyWith<$Res> implements $CreditCardRateCopyWith<$Res> {
  factory _$CreditCardRateCopyWith(_CreditCardRate value, $Res Function(_CreditCardRate) _then) = __$CreditCardRateCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountId, CreditRateType rateType, double rate, bool isIntro, DateTime? introEndsOn, bool isActive, String? label, DateTime createdAt
});




}
/// @nodoc
class __$CreditCardRateCopyWithImpl<$Res>
    implements _$CreditCardRateCopyWith<$Res> {
  __$CreditCardRateCopyWithImpl(this._self, this._then);

  final _CreditCardRate _self;
  final $Res Function(_CreditCardRate) _then;

/// Create a copy of CreditCardRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountId = null,Object? rateType = null,Object? rate = null,Object? isIntro = null,Object? introEndsOn = freezed,Object? isActive = null,Object? label = freezed,Object? createdAt = null,}) {
  return _then(_CreditCardRate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,rateType: null == rateType ? _self.rateType : rateType // ignore: cast_nullable_to_non_nullable
as CreditRateType,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,isIntro: null == isIntro ? _self.isIntro : isIntro // ignore: cast_nullable_to_non_nullable
as bool,introEndsOn: freezed == introEndsOn ? _self.introEndsOn : introEndsOn // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
