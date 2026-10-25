// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringTransaction {

 String get id; String get householdId; String get accountId;/// Signed cents. Negative = outflow, positive = inflow.
/// Zero is rejected by the DB CHECK constraint.
 int get amountCents; String get currency; String get description; String? get merchant; String? get categoryId; RecurrenceCadence get cadence;/// Next date the scheduler should emit a transaction. Updated
/// by the (future) scheduler after each emission.
 DateTime get nextOccurrenceDate;/// Wall-clock of the last scheduler emission. Null until the
/// first emission — distinct from [nextOccurrenceDate] because
/// the scheduler may sit dormant for days and the audit trail
/// remains useful even then.
 DateTime? get lastEmittedAt;/// When set, the scheduler skips any occurrence whose date is
/// on or before this. Pauses a subscription without deleting
/// the rule. Null = no skip in effect.
 DateTime? get skippedUntilDate;/// Whether the scheduler should consider this row at all.
/// Easier than deleting when the user wants to keep history
/// of "we used to have this subscription."
 bool get isActive; String? get createdBy; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringTransactionCopyWith<RecurringTransaction> get copyWith => _$RecurringTransactionCopyWithImpl<RecurringTransaction>(this as RecurringTransaction, _$identity);

  /// Serializes this RecurringTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.description, description) || other.description == description)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.cadence, cadence) || other.cadence == cadence)&&(identical(other.nextOccurrenceDate, nextOccurrenceDate) || other.nextOccurrenceDate == nextOccurrenceDate)&&(identical(other.lastEmittedAt, lastEmittedAt) || other.lastEmittedAt == lastEmittedAt)&&(identical(other.skippedUntilDate, skippedUntilDate) || other.skippedUntilDate == skippedUntilDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,accountId,amountCents,currency,description,merchant,categoryId,cadence,nextOccurrenceDate,lastEmittedAt,skippedUntilDate,isActive,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'RecurringTransaction(id: $id, householdId: $householdId, accountId: $accountId, amountCents: $amountCents, currency: $currency, description: $description, merchant: $merchant, categoryId: $categoryId, cadence: $cadence, nextOccurrenceDate: $nextOccurrenceDate, lastEmittedAt: $lastEmittedAt, skippedUntilDate: $skippedUntilDate, isActive: $isActive, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RecurringTransactionCopyWith<$Res>  {
  factory $RecurringTransactionCopyWith(RecurringTransaction value, $Res Function(RecurringTransaction) _then) = _$RecurringTransactionCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String accountId, int amountCents, String currency, String description, String? merchant, String? categoryId, RecurrenceCadence cadence, DateTime nextOccurrenceDate, DateTime? lastEmittedAt, DateTime? skippedUntilDate, bool isActive, String? createdBy, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$RecurringTransactionCopyWithImpl<$Res>
    implements $RecurringTransactionCopyWith<$Res> {
  _$RecurringTransactionCopyWithImpl(this._self, this._then);

  final RecurringTransaction _self;
  final $Res Function(RecurringTransaction) _then;

/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? accountId = null,Object? amountCents = null,Object? currency = null,Object? description = null,Object? merchant = freezed,Object? categoryId = freezed,Object? cadence = null,Object? nextOccurrenceDate = null,Object? lastEmittedAt = freezed,Object? skippedUntilDate = freezed,Object? isActive = null,Object? createdBy = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,cadence: null == cadence ? _self.cadence : cadence // ignore: cast_nullable_to_non_nullable
as RecurrenceCadence,nextOccurrenceDate: null == nextOccurrenceDate ? _self.nextOccurrenceDate : nextOccurrenceDate // ignore: cast_nullable_to_non_nullable
as DateTime,lastEmittedAt: freezed == lastEmittedAt ? _self.lastEmittedAt : lastEmittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,skippedUntilDate: freezed == skippedUntilDate ? _self.skippedUntilDate : skippedUntilDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringTransaction].
extension RecurringTransactionPatterns on RecurringTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringTransaction value)  $default,){
final _that = this;
switch (_that) {
case _RecurringTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String accountId,  int amountCents,  String currency,  String description,  String? merchant,  String? categoryId,  RecurrenceCadence cadence,  DateTime nextOccurrenceDate,  DateTime? lastEmittedAt,  DateTime? skippedUntilDate,  bool isActive,  String? createdBy,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
return $default(_that.id,_that.householdId,_that.accountId,_that.amountCents,_that.currency,_that.description,_that.merchant,_that.categoryId,_that.cadence,_that.nextOccurrenceDate,_that.lastEmittedAt,_that.skippedUntilDate,_that.isActive,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String accountId,  int amountCents,  String currency,  String description,  String? merchant,  String? categoryId,  RecurrenceCadence cadence,  DateTime nextOccurrenceDate,  DateTime? lastEmittedAt,  DateTime? skippedUntilDate,  bool isActive,  String? createdBy,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RecurringTransaction():
return $default(_that.id,_that.householdId,_that.accountId,_that.amountCents,_that.currency,_that.description,_that.merchant,_that.categoryId,_that.cadence,_that.nextOccurrenceDate,_that.lastEmittedAt,_that.skippedUntilDate,_that.isActive,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String accountId,  int amountCents,  String currency,  String description,  String? merchant,  String? categoryId,  RecurrenceCadence cadence,  DateTime nextOccurrenceDate,  DateTime? lastEmittedAt,  DateTime? skippedUntilDate,  bool isActive,  String? createdBy,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecurringTransaction() when $default != null:
return $default(_that.id,_that.householdId,_that.accountId,_that.amountCents,_that.currency,_that.description,_that.merchant,_that.categoryId,_that.cadence,_that.nextOccurrenceDate,_that.lastEmittedAt,_that.skippedUntilDate,_that.isActive,_that.createdBy,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringTransaction implements RecurringTransaction {
  const _RecurringTransaction({required this.id, required this.householdId, required this.accountId, required this.amountCents, required this.currency, required this.description, this.merchant, this.categoryId, required this.cadence, required this.nextOccurrenceDate, this.lastEmittedAt, this.skippedUntilDate, required this.isActive, this.createdBy, required this.createdAt, required this.updatedAt});
  factory _RecurringTransaction.fromJson(Map<String, dynamic> json) => _$RecurringTransactionFromJson(json);

@override final  String id;
@override final  String householdId;
@override final  String accountId;
/// Signed cents. Negative = outflow, positive = inflow.
/// Zero is rejected by the DB CHECK constraint.
@override final  int amountCents;
@override final  String currency;
@override final  String description;
@override final  String? merchant;
@override final  String? categoryId;
@override final  RecurrenceCadence cadence;
/// Next date the scheduler should emit a transaction. Updated
/// by the (future) scheduler after each emission.
@override final  DateTime nextOccurrenceDate;
/// Wall-clock of the last scheduler emission. Null until the
/// first emission — distinct from [nextOccurrenceDate] because
/// the scheduler may sit dormant for days and the audit trail
/// remains useful even then.
@override final  DateTime? lastEmittedAt;
/// When set, the scheduler skips any occurrence whose date is
/// on or before this. Pauses a subscription without deleting
/// the rule. Null = no skip in effect.
@override final  DateTime? skippedUntilDate;
/// Whether the scheduler should consider this row at all.
/// Easier than deleting when the user wants to keep history
/// of "we used to have this subscription."
@override final  bool isActive;
@override final  String? createdBy;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringTransactionCopyWith<_RecurringTransaction> get copyWith => __$RecurringTransactionCopyWithImpl<_RecurringTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.description, description) || other.description == description)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.cadence, cadence) || other.cadence == cadence)&&(identical(other.nextOccurrenceDate, nextOccurrenceDate) || other.nextOccurrenceDate == nextOccurrenceDate)&&(identical(other.lastEmittedAt, lastEmittedAt) || other.lastEmittedAt == lastEmittedAt)&&(identical(other.skippedUntilDate, skippedUntilDate) || other.skippedUntilDate == skippedUntilDate)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,accountId,amountCents,currency,description,merchant,categoryId,cadence,nextOccurrenceDate,lastEmittedAt,skippedUntilDate,isActive,createdBy,createdAt,updatedAt);

@override
String toString() {
  return 'RecurringTransaction(id: $id, householdId: $householdId, accountId: $accountId, amountCents: $amountCents, currency: $currency, description: $description, merchant: $merchant, categoryId: $categoryId, cadence: $cadence, nextOccurrenceDate: $nextOccurrenceDate, lastEmittedAt: $lastEmittedAt, skippedUntilDate: $skippedUntilDate, isActive: $isActive, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RecurringTransactionCopyWith<$Res> implements $RecurringTransactionCopyWith<$Res> {
  factory _$RecurringTransactionCopyWith(_RecurringTransaction value, $Res Function(_RecurringTransaction) _then) = __$RecurringTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String accountId, int amountCents, String currency, String description, String? merchant, String? categoryId, RecurrenceCadence cadence, DateTime nextOccurrenceDate, DateTime? lastEmittedAt, DateTime? skippedUntilDate, bool isActive, String? createdBy, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$RecurringTransactionCopyWithImpl<$Res>
    implements _$RecurringTransactionCopyWith<$Res> {
  __$RecurringTransactionCopyWithImpl(this._self, this._then);

  final _RecurringTransaction _self;
  final $Res Function(_RecurringTransaction) _then;

/// Create a copy of RecurringTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? accountId = null,Object? amountCents = null,Object? currency = null,Object? description = null,Object? merchant = freezed,Object? categoryId = freezed,Object? cadence = null,Object? nextOccurrenceDate = null,Object? lastEmittedAt = freezed,Object? skippedUntilDate = freezed,Object? isActive = null,Object? createdBy = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_RecurringTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,cadence: null == cadence ? _self.cadence : cadence // ignore: cast_nullable_to_non_nullable
as RecurrenceCadence,nextOccurrenceDate: null == nextOccurrenceDate ? _self.nextOccurrenceDate : nextOccurrenceDate // ignore: cast_nullable_to_non_nullable
as DateTime,lastEmittedAt: freezed == lastEmittedAt ? _self.lastEmittedAt : lastEmittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,skippedUntilDate: freezed == skippedUntilDate ? _self.skippedUntilDate : skippedUntilDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
