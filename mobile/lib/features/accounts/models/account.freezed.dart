// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Account {

 String get id; String get householdId;/// The family member who owns this account (may differ from the logged-in user).
 String get ownerUserId; String get name; AccountType get accountType; String? get institution;/// Last 4 digits of the account/card number for display purposes.
 String? get lastFour; String get currency;/// Balance in cents before any tracked transactions.
/// current_balance = starting_balance + sum(transactions).
 int get startingBalance;/// Current balance in cents. Negative values indicate debt (credit cards).
 int get currentBalance;/// Credit limit in cents. Only set for [AccountType.creditCard].
 int? get creditLimit; bool get isActive;/// Optional hex color for the account card (e.g. "#3B82F6").
 String? get color;/// Annual interest rate as a decimal (e.g. 0.2499 = 24.99% APR).
/// Null means not applicable (e.g. checking, cash).
 double? get interestRate; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountCopyWith<Account> get copyWith => _$AccountCopyWithImpl<Account>(this as Account, _$identity);

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Account&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.ownerUserId, ownerUserId) || other.ownerUserId == ownerUserId)&&(identical(other.name, name) || other.name == name)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.institution, institution) || other.institution == institution)&&(identical(other.lastFour, lastFour) || other.lastFour == lastFour)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.startingBalance, startingBalance) || other.startingBalance == startingBalance)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.color, color) || other.color == color)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,ownerUserId,name,accountType,institution,lastFour,currency,startingBalance,currentBalance,creditLimit,isActive,color,interestRate,createdAt,updatedAt);

@override
String toString() {
  return 'Account(id: $id, householdId: $householdId, ownerUserId: $ownerUserId, name: $name, accountType: $accountType, institution: $institution, lastFour: $lastFour, currency: $currency, startingBalance: $startingBalance, currentBalance: $currentBalance, creditLimit: $creditLimit, isActive: $isActive, color: $color, interestRate: $interestRate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AccountCopyWith<$Res>  {
  factory $AccountCopyWith(Account value, $Res Function(Account) _then) = _$AccountCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String ownerUserId, String name, AccountType accountType, String? institution, String? lastFour, String currency, int startingBalance, int currentBalance, int? creditLimit, bool isActive, String? color, double? interestRate, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$AccountCopyWithImpl<$Res>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._self, this._then);

  final Account _self;
  final $Res Function(Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? ownerUserId = null,Object? name = null,Object? accountType = null,Object? institution = freezed,Object? lastFour = freezed,Object? currency = null,Object? startingBalance = null,Object? currentBalance = null,Object? creditLimit = freezed,Object? isActive = null,Object? color = freezed,Object? interestRate = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,ownerUserId: null == ownerUserId ? _self.ownerUserId : ownerUserId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as AccountType,institution: freezed == institution ? _self.institution : institution // ignore: cast_nullable_to_non_nullable
as String?,lastFour: freezed == lastFour ? _self.lastFour : lastFour // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,startingBalance: null == startingBalance ? _self.startingBalance : startingBalance // ignore: cast_nullable_to_non_nullable
as int,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as int,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Account].
extension AccountPatterns on Account {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Account value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Account value)  $default,){
final _that = this;
switch (_that) {
case _Account():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Account value)?  $default,){
final _that = this;
switch (_that) {
case _Account() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String ownerUserId,  String name,  AccountType accountType,  String? institution,  String? lastFour,  String currency,  int startingBalance,  int currentBalance,  int? creditLimit,  bool isActive,  String? color,  double? interestRate,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.householdId,_that.ownerUserId,_that.name,_that.accountType,_that.institution,_that.lastFour,_that.currency,_that.startingBalance,_that.currentBalance,_that.creditLimit,_that.isActive,_that.color,_that.interestRate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String ownerUserId,  String name,  AccountType accountType,  String? institution,  String? lastFour,  String currency,  int startingBalance,  int currentBalance,  int? creditLimit,  bool isActive,  String? color,  double? interestRate,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Account():
return $default(_that.id,_that.householdId,_that.ownerUserId,_that.name,_that.accountType,_that.institution,_that.lastFour,_that.currency,_that.startingBalance,_that.currentBalance,_that.creditLimit,_that.isActive,_that.color,_that.interestRate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String ownerUserId,  String name,  AccountType accountType,  String? institution,  String? lastFour,  String currency,  int startingBalance,  int currentBalance,  int? creditLimit,  bool isActive,  String? color,  double? interestRate,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Account() when $default != null:
return $default(_that.id,_that.householdId,_that.ownerUserId,_that.name,_that.accountType,_that.institution,_that.lastFour,_that.currency,_that.startingBalance,_that.currentBalance,_that.creditLimit,_that.isActive,_that.color,_that.interestRate,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Account implements Account {
  const _Account({required this.id, required this.householdId, required this.ownerUserId, required this.name, required this.accountType, this.institution, this.lastFour, required this.currency, this.startingBalance = 0, required this.currentBalance, this.creditLimit, required this.isActive, this.color, this.interestRate, required this.createdAt, required this.updatedAt});
  factory _Account.fromJson(Map<String, dynamic> json) => _$AccountFromJson(json);

@override final  String id;
@override final  String householdId;
/// The family member who owns this account (may differ from the logged-in user).
@override final  String ownerUserId;
@override final  String name;
@override final  AccountType accountType;
@override final  String? institution;
/// Last 4 digits of the account/card number for display purposes.
@override final  String? lastFour;
@override final  String currency;
/// Balance in cents before any tracked transactions.
/// current_balance = starting_balance + sum(transactions).
@override@JsonKey() final  int startingBalance;
/// Current balance in cents. Negative values indicate debt (credit cards).
@override final  int currentBalance;
/// Credit limit in cents. Only set for [AccountType.creditCard].
@override final  int? creditLimit;
@override final  bool isActive;
/// Optional hex color for the account card (e.g. "#3B82F6").
@override final  String? color;
/// Annual interest rate as a decimal (e.g. 0.2499 = 24.99% APR).
/// Null means not applicable (e.g. checking, cash).
@override final  double? interestRate;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountCopyWith<_Account> get copyWith => __$AccountCopyWithImpl<_Account>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Account&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.ownerUserId, ownerUserId) || other.ownerUserId == ownerUserId)&&(identical(other.name, name) || other.name == name)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.institution, institution) || other.institution == institution)&&(identical(other.lastFour, lastFour) || other.lastFour == lastFour)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.startingBalance, startingBalance) || other.startingBalance == startingBalance)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.creditLimit, creditLimit) || other.creditLimit == creditLimit)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.color, color) || other.color == color)&&(identical(other.interestRate, interestRate) || other.interestRate == interestRate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,ownerUserId,name,accountType,institution,lastFour,currency,startingBalance,currentBalance,creditLimit,isActive,color,interestRate,createdAt,updatedAt);

@override
String toString() {
  return 'Account(id: $id, householdId: $householdId, ownerUserId: $ownerUserId, name: $name, accountType: $accountType, institution: $institution, lastFour: $lastFour, currency: $currency, startingBalance: $startingBalance, currentBalance: $currentBalance, creditLimit: $creditLimit, isActive: $isActive, color: $color, interestRate: $interestRate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccountCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$AccountCopyWith(_Account value, $Res Function(_Account) _then) = __$AccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String ownerUserId, String name, AccountType accountType, String? institution, String? lastFour, String currency, int startingBalance, int currentBalance, int? creditLimit, bool isActive, String? color, double? interestRate, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$AccountCopyWithImpl<$Res>
    implements _$AccountCopyWith<$Res> {
  __$AccountCopyWithImpl(this._self, this._then);

  final _Account _self;
  final $Res Function(_Account) _then;

/// Create a copy of Account
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? ownerUserId = null,Object? name = null,Object? accountType = null,Object? institution = freezed,Object? lastFour = freezed,Object? currency = null,Object? startingBalance = null,Object? currentBalance = null,Object? creditLimit = freezed,Object? isActive = null,Object? color = freezed,Object? interestRate = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Account(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,ownerUserId: null == ownerUserId ? _self.ownerUserId : ownerUserId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as AccountType,institution: freezed == institution ? _self.institution : institution // ignore: cast_nullable_to_non_nullable
as String?,lastFour: freezed == lastFour ? _self.lastFour : lastFour // ignore: cast_nullable_to_non_nullable
as String?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,startingBalance: null == startingBalance ? _self.startingBalance : startingBalance // ignore: cast_nullable_to_non_nullable
as int,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as int,creditLimit: freezed == creditLimit ? _self.creditLimit : creditLimit // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,interestRate: freezed == interestRate ? _self.interestRate : interestRate // ignore: cast_nullable_to_non_nullable
as double?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
