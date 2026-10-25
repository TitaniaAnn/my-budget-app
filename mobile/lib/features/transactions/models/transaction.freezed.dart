// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transaction {

 String get id; String get householdId; String get accountId;/// Amount in cents. Negative = debit/expense, positive = credit/income.
 int get amount; String get currency;/// Raw description from the bank statement or user entry.
 String get description;/// Cleaned merchant name (may differ from description).
 String? get merchant; String? get categoryId;/// The date the transaction occurred (not the processing date).
 DateTime get transactionDate;/// The date the transaction cleared the account (may lag transactionDate).
 DateTime? get postedDate; bool get pending;/// How the transaction was created: 'manual', 'import', or 'plaid'.
 String get source; String? get enteredBy; String? get receiptId; String? get rateId; String? get notes;/// Bank-assigned dedup key. Prevents re-importing the same statement twice.
 String? get externalId;/// Shared id linking the two legs of an account-to-account transfer
/// (migration 030). Non-null on both legs, null on every other
/// transaction. Aggregations that treat transfers as cash movement
/// rather than income/expense gate on this.
 String? get transferId;/// Top-class probability from the ML categorizer in basis points
/// (0–10000, where 10000 == 1.00). Populated only when
/// `category_assigned_by == 'ml_model'`; null otherwise. The "Review
/// uncertain" surface filters on this field to surface near-misses.
 int? get mlModelConfidence; DateTime get createdAt; DateTime get updatedAt;/// Eagerly-loaded category row (null if uncategorized or not joined).
 Category? get category;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.description, description) || other.description == description)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.postedDate, postedDate) || other.postedDate == postedDate)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.source, source) || other.source == source)&&(identical(other.enteredBy, enteredBy) || other.enteredBy == enteredBy)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.rateId, rateId) || other.rateId == rateId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.transferId, transferId) || other.transferId == transferId)&&(identical(other.mlModelConfidence, mlModelConfidence) || other.mlModelConfidence == mlModelConfidence)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,householdId,accountId,amount,currency,description,merchant,categoryId,transactionDate,postedDate,pending,source,enteredBy,receiptId,rateId,notes,externalId,transferId,mlModelConfidence,createdAt,updatedAt,category]);

@override
String toString() {
  return 'Transaction(id: $id, householdId: $householdId, accountId: $accountId, amount: $amount, currency: $currency, description: $description, merchant: $merchant, categoryId: $categoryId, transactionDate: $transactionDate, postedDate: $postedDate, pending: $pending, source: $source, enteredBy: $enteredBy, receiptId: $receiptId, rateId: $rateId, notes: $notes, externalId: $externalId, transferId: $transferId, mlModelConfidence: $mlModelConfidence, createdAt: $createdAt, updatedAt: $updatedAt, category: $category)';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String accountId, int amount, String currency, String description, String? merchant, String? categoryId, DateTime transactionDate, DateTime? postedDate, bool pending, String source, String? enteredBy, String? receiptId, String? rateId, String? notes, String? externalId, String? transferId, int? mlModelConfidence, DateTime createdAt, DateTime updatedAt, Category? category
});


$CategoryCopyWith<$Res>? get category;

}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? accountId = null,Object? amount = null,Object? currency = null,Object? description = null,Object? merchant = freezed,Object? categoryId = freezed,Object? transactionDate = null,Object? postedDate = freezed,Object? pending = null,Object? source = null,Object? enteredBy = freezed,Object? receiptId = freezed,Object? rateId = freezed,Object? notes = freezed,Object? externalId = freezed,Object? transferId = freezed,Object? mlModelConfidence = freezed,Object? createdAt = null,Object? updatedAt = null,Object? category = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,postedDate: freezed == postedDate ? _self.postedDate : postedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,enteredBy: freezed == enteredBy ? _self.enteredBy : enteredBy // ignore: cast_nullable_to_non_nullable
as String?,receiptId: freezed == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String?,rateId: freezed == rateId ? _self.rateId : rateId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,transferId: freezed == transferId ? _self.transferId : transferId // ignore: cast_nullable_to_non_nullable
as String?,mlModelConfidence: freezed == mlModelConfidence ? _self.mlModelConfidence : mlModelConfidence // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category?,
  ));
}
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String accountId,  int amount,  String currency,  String description,  String? merchant,  String? categoryId,  DateTime transactionDate,  DateTime? postedDate,  bool pending,  String source,  String? enteredBy,  String? receiptId,  String? rateId,  String? notes,  String? externalId,  String? transferId,  int? mlModelConfidence,  DateTime createdAt,  DateTime updatedAt,  Category? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.householdId,_that.accountId,_that.amount,_that.currency,_that.description,_that.merchant,_that.categoryId,_that.transactionDate,_that.postedDate,_that.pending,_that.source,_that.enteredBy,_that.receiptId,_that.rateId,_that.notes,_that.externalId,_that.transferId,_that.mlModelConfidence,_that.createdAt,_that.updatedAt,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String accountId,  int amount,  String currency,  String description,  String? merchant,  String? categoryId,  DateTime transactionDate,  DateTime? postedDate,  bool pending,  String source,  String? enteredBy,  String? receiptId,  String? rateId,  String? notes,  String? externalId,  String? transferId,  int? mlModelConfidence,  DateTime createdAt,  DateTime updatedAt,  Category? category)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.householdId,_that.accountId,_that.amount,_that.currency,_that.description,_that.merchant,_that.categoryId,_that.transactionDate,_that.postedDate,_that.pending,_that.source,_that.enteredBy,_that.receiptId,_that.rateId,_that.notes,_that.externalId,_that.transferId,_that.mlModelConfidence,_that.createdAt,_that.updatedAt,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String accountId,  int amount,  String currency,  String description,  String? merchant,  String? categoryId,  DateTime transactionDate,  DateTime? postedDate,  bool pending,  String source,  String? enteredBy,  String? receiptId,  String? rateId,  String? notes,  String? externalId,  String? transferId,  int? mlModelConfidence,  DateTime createdAt,  DateTime updatedAt,  Category? category)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.householdId,_that.accountId,_that.amount,_that.currency,_that.description,_that.merchant,_that.categoryId,_that.transactionDate,_that.postedDate,_that.pending,_that.source,_that.enteredBy,_that.receiptId,_that.rateId,_that.notes,_that.externalId,_that.transferId,_that.mlModelConfidence,_that.createdAt,_that.updatedAt,_that.category);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transaction implements Transaction {
  const _Transaction({required this.id, required this.householdId, required this.accountId, required this.amount, required this.currency, required this.description, this.merchant, this.categoryId, required this.transactionDate, this.postedDate, required this.pending, required this.source, this.enteredBy, this.receiptId, this.rateId, this.notes, this.externalId, this.transferId, this.mlModelConfidence, required this.createdAt, required this.updatedAt, this.category});
  factory _Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

@override final  String id;
@override final  String householdId;
@override final  String accountId;
/// Amount in cents. Negative = debit/expense, positive = credit/income.
@override final  int amount;
@override final  String currency;
/// Raw description from the bank statement or user entry.
@override final  String description;
/// Cleaned merchant name (may differ from description).
@override final  String? merchant;
@override final  String? categoryId;
/// The date the transaction occurred (not the processing date).
@override final  DateTime transactionDate;
/// The date the transaction cleared the account (may lag transactionDate).
@override final  DateTime? postedDate;
@override final  bool pending;
/// How the transaction was created: 'manual', 'import', or 'plaid'.
@override final  String source;
@override final  String? enteredBy;
@override final  String? receiptId;
@override final  String? rateId;
@override final  String? notes;
/// Bank-assigned dedup key. Prevents re-importing the same statement twice.
@override final  String? externalId;
/// Shared id linking the two legs of an account-to-account transfer
/// (migration 030). Non-null on both legs, null on every other
/// transaction. Aggregations that treat transfers as cash movement
/// rather than income/expense gate on this.
@override final  String? transferId;
/// Top-class probability from the ML categorizer in basis points
/// (0–10000, where 10000 == 1.00). Populated only when
/// `category_assigned_by == 'ml_model'`; null otherwise. The "Review
/// uncertain" surface filters on this field to surface near-misses.
@override final  int? mlModelConfidence;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Eagerly-loaded category row (null if uncategorized or not joined).
@override final  Category? category;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.description, description) || other.description == description)&&(identical(other.merchant, merchant) || other.merchant == merchant)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.transactionDate, transactionDate) || other.transactionDate == transactionDate)&&(identical(other.postedDate, postedDate) || other.postedDate == postedDate)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.source, source) || other.source == source)&&(identical(other.enteredBy, enteredBy) || other.enteredBy == enteredBy)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.rateId, rateId) || other.rateId == rateId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.externalId, externalId) || other.externalId == externalId)&&(identical(other.transferId, transferId) || other.transferId == transferId)&&(identical(other.mlModelConfidence, mlModelConfidence) || other.mlModelConfidence == mlModelConfidence)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.category, category) || other.category == category));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,householdId,accountId,amount,currency,description,merchant,categoryId,transactionDate,postedDate,pending,source,enteredBy,receiptId,rateId,notes,externalId,transferId,mlModelConfidence,createdAt,updatedAt,category]);

@override
String toString() {
  return 'Transaction(id: $id, householdId: $householdId, accountId: $accountId, amount: $amount, currency: $currency, description: $description, merchant: $merchant, categoryId: $categoryId, transactionDate: $transactionDate, postedDate: $postedDate, pending: $pending, source: $source, enteredBy: $enteredBy, receiptId: $receiptId, rateId: $rateId, notes: $notes, externalId: $externalId, transferId: $transferId, mlModelConfidence: $mlModelConfidence, createdAt: $createdAt, updatedAt: $updatedAt, category: $category)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String accountId, int amount, String currency, String description, String? merchant, String? categoryId, DateTime transactionDate, DateTime? postedDate, bool pending, String source, String? enteredBy, String? receiptId, String? rateId, String? notes, String? externalId, String? transferId, int? mlModelConfidence, DateTime createdAt, DateTime updatedAt, Category? category
});


@override $CategoryCopyWith<$Res>? get category;

}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? accountId = null,Object? amount = null,Object? currency = null,Object? description = null,Object? merchant = freezed,Object? categoryId = freezed,Object? transactionDate = null,Object? postedDate = freezed,Object? pending = null,Object? source = null,Object? enteredBy = freezed,Object? receiptId = freezed,Object? rateId = freezed,Object? notes = freezed,Object? externalId = freezed,Object? transferId = freezed,Object? mlModelConfidence = freezed,Object? createdAt = null,Object? updatedAt = null,Object? category = freezed,}) {
  return _then(_Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,merchant: freezed == merchant ? _self.merchant : merchant // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,transactionDate: null == transactionDate ? _self.transactionDate : transactionDate // ignore: cast_nullable_to_non_nullable
as DateTime,postedDate: freezed == postedDate ? _self.postedDate : postedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as bool,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,enteredBy: freezed == enteredBy ? _self.enteredBy : enteredBy // ignore: cast_nullable_to_non_nullable
as String?,receiptId: freezed == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String?,rateId: freezed == rateId ? _self.rateId : rateId // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,externalId: freezed == externalId ? _self.externalId : externalId // ignore: cast_nullable_to_non_nullable
as String?,transferId: freezed == transferId ? _self.transferId : transferId // ignore: cast_nullable_to_non_nullable
as String?,mlModelConfidence: freezed == mlModelConfidence ? _self.mlModelConfidence : mlModelConfidence // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category?,
  ));
}

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
