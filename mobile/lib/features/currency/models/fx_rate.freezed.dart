// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fx_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FxRate {

 String get householdId; String get fromCurrency; String get toCurrency; DateTime get asOfDate;/// Multiplier. amountInTo = amountInFrom × rate. Stored as
/// NUMERIC(18,8) in the DB; Postgres returns NUMERIC as a
/// string on the JSON wire to avoid float loss in transit, so
/// [_rateFromJson] coerces it to a double here. The math
/// downstream uses plain `num` multipliers.
@JsonKey(fromJson: _rateFromJson) double get rate; String? get createdBy; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of FxRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FxRateCopyWith<FxRate> get copyWith => _$FxRateCopyWithImpl<FxRate>(this as FxRate, _$identity);

  /// Serializes this FxRate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FxRate&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.fromCurrency, fromCurrency) || other.fromCurrency == fromCurrency)&&(identical(other.toCurrency, toCurrency) || other.toCurrency == toCurrency)&&(identical(other.asOfDate, asOfDate) || other.asOfDate == asOfDate)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,householdId,fromCurrency,toCurrency,asOfDate,rate,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'FxRate(householdId: $householdId, fromCurrency: $fromCurrency, toCurrency: $toCurrency, asOfDate: $asOfDate, rate: $rate, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $FxRateCopyWith<$Res>  {
  factory $FxRateCopyWith(FxRate value, $Res Function(FxRate) _then) = _$FxRateCopyWithImpl;
@useResult
$Res call({
 String householdId, String fromCurrency, String toCurrency, DateTime asOfDate,@JsonKey(fromJson: _rateFromJson) double rate, String? createdBy, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$FxRateCopyWithImpl<$Res>
    implements $FxRateCopyWith<$Res> {
  _$FxRateCopyWithImpl(this._self, this._then);

  final FxRate _self;
  final $Res Function(FxRate) _then;

/// Create a copy of FxRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? householdId = null,Object? fromCurrency = null,Object? toCurrency = null,Object? asOfDate = null,Object? rate = null,Object? createdBy = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,fromCurrency: null == fromCurrency ? _self.fromCurrency : fromCurrency // ignore: cast_nullable_to_non_nullable
as String,toCurrency: null == toCurrency ? _self.toCurrency : toCurrency // ignore: cast_nullable_to_non_nullable
as String,asOfDate: null == asOfDate ? _self.asOfDate : asOfDate // ignore: cast_nullable_to_non_nullable
as DateTime,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FxRate].
extension FxRatePatterns on FxRate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FxRate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FxRate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FxRate value)  $default,){
final _that = this;
switch (_that) {
case _FxRate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FxRate value)?  $default,){
final _that = this;
switch (_that) {
case _FxRate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String householdId,  String fromCurrency,  String toCurrency,  DateTime asOfDate, @JsonKey(fromJson: _rateFromJson)  double rate,  String? createdBy,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FxRate() when $default != null:
return $default(_that.householdId,_that.fromCurrency,_that.toCurrency,_that.asOfDate,_that.rate,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String householdId,  String fromCurrency,  String toCurrency,  DateTime asOfDate, @JsonKey(fromJson: _rateFromJson)  double rate,  String? createdBy,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _FxRate():
return $default(_that.householdId,_that.fromCurrency,_that.toCurrency,_that.asOfDate,_that.rate,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String householdId,  String fromCurrency,  String toCurrency,  DateTime asOfDate, @JsonKey(fromJson: _rateFromJson)  double rate,  String? createdBy,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _FxRate() when $default != null:
return $default(_that.householdId,_that.fromCurrency,_that.toCurrency,_that.asOfDate,_that.rate,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FxRate implements FxRate {
  const _FxRate({required this.householdId, required this.fromCurrency, required this.toCurrency, required this.asOfDate, @JsonKey(fromJson: _rateFromJson) required this.rate, this.createdBy, required this.createdAt, required this.updatedAt});
  factory _FxRate.fromJson(Map<String, dynamic> json) => _$FxRateFromJson(json);

@override final  String householdId;
@override final  String fromCurrency;
@override final  String toCurrency;
@override final  DateTime asOfDate;
/// Multiplier. amountInTo = amountInFrom × rate. Stored as
/// NUMERIC(18,8) in the DB; Postgres returns NUMERIC as a
/// string on the JSON wire to avoid float loss in transit, so
/// [_rateFromJson] coerces it to a double here. The math
/// downstream uses plain `num` multipliers.
@override@JsonKey(fromJson: _rateFromJson) final  double rate;
@override final  String? createdBy;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of FxRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FxRateCopyWith<_FxRate> get copyWith => __$FxRateCopyWithImpl<_FxRate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FxRateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FxRate&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.fromCurrency, fromCurrency) || other.fromCurrency == fromCurrency)&&(identical(other.toCurrency, toCurrency) || other.toCurrency == toCurrency)&&(identical(other.asOfDate, asOfDate) || other.asOfDate == asOfDate)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,householdId,fromCurrency,toCurrency,asOfDate,rate,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'FxRate(householdId: $householdId, fromCurrency: $fromCurrency, toCurrency: $toCurrency, asOfDate: $asOfDate, rate: $rate, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$FxRateCopyWith<$Res> implements $FxRateCopyWith<$Res> {
  factory _$FxRateCopyWith(_FxRate value, $Res Function(_FxRate) _then) = __$FxRateCopyWithImpl;
@override @useResult
$Res call({
 String householdId, String fromCurrency, String toCurrency, DateTime asOfDate,@JsonKey(fromJson: _rateFromJson) double rate, String? createdBy, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$FxRateCopyWithImpl<$Res>
    implements _$FxRateCopyWith<$Res> {
  __$FxRateCopyWithImpl(this._self, this._then);

  final _FxRate _self;
  final $Res Function(_FxRate) _then;

/// Create a copy of FxRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? householdId = null,Object? fromCurrency = null,Object? toCurrency = null,Object? asOfDate = null,Object? rate = null,Object? createdBy = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_FxRate(
householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,fromCurrency: null == fromCurrency ? _self.fromCurrency : fromCurrency // ignore: cast_nullable_to_non_nullable
as String,toCurrency: null == toCurrency ? _self.toCurrency : toCurrency // ignore: cast_nullable_to_non_nullable
as String,asOfDate: null == asOfDate ? _self.asOfDate : asOfDate // ignore: cast_nullable_to_non_nullable
as DateTime,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as double,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
