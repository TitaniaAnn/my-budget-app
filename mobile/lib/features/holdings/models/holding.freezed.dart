// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'holding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Holding {

 String get id; String get householdId; String get accountId;/// Ticker / fund symbol / short crypto code.
 String get symbol;/// Optional human-readable name; the symbol is the source of
/// truth for "which security."
 String? get description; double get quantity;/// Total cost basis in cents. Null = unknown (e.g. backfilled
/// position without a purchase history).
 int? get costBasis;/// Current value in cents. User-entered — no price feed in v1.
 int get currentValue; AssetClass? get assetClass;/// Wall-clock of the last user-entered [currentValue]. Powers a
/// future "stale" indicator; null when never priced.
 DateTime? get lastPricedAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HoldingCopyWith<Holding> get copyWith => _$HoldingCopyWithImpl<Holding>(this as Holding, _$identity);

  /// Serializes this Holding to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Holding&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.description, description) || other.description == description)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.costBasis, costBasis) || other.costBasis == costBasis)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.assetClass, assetClass) || other.assetClass == assetClass)&&(identical(other.lastPricedAt, lastPricedAt) || other.lastPricedAt == lastPricedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,accountId,symbol,description,quantity,costBasis,currentValue,assetClass,lastPricedAt,createdAt,updatedAt);

@override
String toString() {
  return 'Holding(id: $id, householdId: $householdId, accountId: $accountId, symbol: $symbol, description: $description, quantity: $quantity, costBasis: $costBasis, currentValue: $currentValue, assetClass: $assetClass, lastPricedAt: $lastPricedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $HoldingCopyWith<$Res>  {
  factory $HoldingCopyWith(Holding value, $Res Function(Holding) _then) = _$HoldingCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String accountId, String symbol, String? description, double quantity, int? costBasis, int currentValue, AssetClass? assetClass, DateTime? lastPricedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$HoldingCopyWithImpl<$Res>
    implements $HoldingCopyWith<$Res> {
  _$HoldingCopyWithImpl(this._self, this._then);

  final Holding _self;
  final $Res Function(Holding) _then;

/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? accountId = null,Object? symbol = null,Object? description = freezed,Object? quantity = null,Object? costBasis = freezed,Object? currentValue = null,Object? assetClass = freezed,Object? lastPricedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,costBasis: freezed == costBasis ? _self.costBasis : costBasis // ignore: cast_nullable_to_non_nullable
as int?,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as int,assetClass: freezed == assetClass ? _self.assetClass : assetClass // ignore: cast_nullable_to_non_nullable
as AssetClass?,lastPricedAt: freezed == lastPricedAt ? _self.lastPricedAt : lastPricedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Holding].
extension HoldingPatterns on Holding {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Holding value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Holding() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Holding value)  $default,){
final _that = this;
switch (_that) {
case _Holding():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Holding value)?  $default,){
final _that = this;
switch (_that) {
case _Holding() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String accountId,  String symbol,  String? description,  double quantity,  int? costBasis,  int currentValue,  AssetClass? assetClass,  DateTime? lastPricedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Holding() when $default != null:
return $default(_that.id,_that.householdId,_that.accountId,_that.symbol,_that.description,_that.quantity,_that.costBasis,_that.currentValue,_that.assetClass,_that.lastPricedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String accountId,  String symbol,  String? description,  double quantity,  int? costBasis,  int currentValue,  AssetClass? assetClass,  DateTime? lastPricedAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Holding():
return $default(_that.id,_that.householdId,_that.accountId,_that.symbol,_that.description,_that.quantity,_that.costBasis,_that.currentValue,_that.assetClass,_that.lastPricedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String accountId,  String symbol,  String? description,  double quantity,  int? costBasis,  int currentValue,  AssetClass? assetClass,  DateTime? lastPricedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Holding() when $default != null:
return $default(_that.id,_that.householdId,_that.accountId,_that.symbol,_that.description,_that.quantity,_that.costBasis,_that.currentValue,_that.assetClass,_that.lastPricedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Holding implements Holding {
  const _Holding({required this.id, required this.householdId, required this.accountId, required this.symbol, this.description, required this.quantity, this.costBasis, required this.currentValue, this.assetClass, this.lastPricedAt, required this.createdAt, required this.updatedAt});
  factory _Holding.fromJson(Map<String, dynamic> json) => _$HoldingFromJson(json);

@override final  String id;
@override final  String householdId;
@override final  String accountId;
/// Ticker / fund symbol / short crypto code.
@override final  String symbol;
/// Optional human-readable name; the symbol is the source of
/// truth for "which security."
@override final  String? description;
@override final  double quantity;
/// Total cost basis in cents. Null = unknown (e.g. backfilled
/// position without a purchase history).
@override final  int? costBasis;
/// Current value in cents. User-entered — no price feed in v1.
@override final  int currentValue;
@override final  AssetClass? assetClass;
/// Wall-clock of the last user-entered [currentValue]. Powers a
/// future "stale" indicator; null when never priced.
@override final  DateTime? lastPricedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HoldingCopyWith<_Holding> get copyWith => __$HoldingCopyWithImpl<_Holding>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HoldingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Holding&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.description, description) || other.description == description)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.costBasis, costBasis) || other.costBasis == costBasis)&&(identical(other.currentValue, currentValue) || other.currentValue == currentValue)&&(identical(other.assetClass, assetClass) || other.assetClass == assetClass)&&(identical(other.lastPricedAt, lastPricedAt) || other.lastPricedAt == lastPricedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,accountId,symbol,description,quantity,costBasis,currentValue,assetClass,lastPricedAt,createdAt,updatedAt);

@override
String toString() {
  return 'Holding(id: $id, householdId: $householdId, accountId: $accountId, symbol: $symbol, description: $description, quantity: $quantity, costBasis: $costBasis, currentValue: $currentValue, assetClass: $assetClass, lastPricedAt: $lastPricedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HoldingCopyWith<$Res> implements $HoldingCopyWith<$Res> {
  factory _$HoldingCopyWith(_Holding value, $Res Function(_Holding) _then) = __$HoldingCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String accountId, String symbol, String? description, double quantity, int? costBasis, int currentValue, AssetClass? assetClass, DateTime? lastPricedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$HoldingCopyWithImpl<$Res>
    implements _$HoldingCopyWith<$Res> {
  __$HoldingCopyWithImpl(this._self, this._then);

  final _Holding _self;
  final $Res Function(_Holding) _then;

/// Create a copy of Holding
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? accountId = null,Object? symbol = null,Object? description = freezed,Object? quantity = null,Object? costBasis = freezed,Object? currentValue = null,Object? assetClass = freezed,Object? lastPricedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Holding(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,symbol: null == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double,costBasis: freezed == costBasis ? _self.costBasis : costBasis // ignore: cast_nullable_to_non_nullable
as int?,currentValue: null == currentValue ? _self.currentValue : currentValue // ignore: cast_nullable_to_non_nullable
as int,assetClass: freezed == assetClass ? _self.assetClass : assetClass // ignore: cast_nullable_to_non_nullable
as AssetClass?,lastPricedAt: freezed == lastPricedAt ? _self.lastPricedAt : lastPricedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
