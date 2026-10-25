// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_line_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReceiptLineItem {

 String get id; String get receiptId; String get description;/// Amount in cents (always positive; sign determined by [isDiscount]).
 int get amount;/// Optional quantity for unit-priced items (e.g. 2.0 lbs of produce).
 double? get quantity;/// Unit price in cents (amount / quantity, when available from OCR).
 int? get unitPrice; String? get categoryId;/// True if this line represents sales tax.
 bool get isTax;/// True if this line represents a tip/gratuity.
 bool get isTip;/// True if this line is a discount (coupon, promo, etc.) — negative value.
 bool get isDiscount; int get sortOrder;/// Per-line OCR confidence in basis points (0–10000, where 10000
/// == 1.00). Null when no recognizer ran (user typed the line in
/// manually). The "Review uncertain OCR lines" surface filters
/// on this; user edits don't update the value, so a row the user
/// already corrected won't keep resurfacing for review.
 int? get ocrConfidenceBp;
/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptLineItemCopyWith<ReceiptLineItem> get copyWith => _$ReceiptLineItemCopyWithImpl<ReceiptLineItem>(this as ReceiptLineItem, _$identity);

  /// Serializes this ReceiptLineItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptLineItem&&(identical(other.id, id) || other.id == id)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isTax, isTax) || other.isTax == isTax)&&(identical(other.isTip, isTip) || other.isTip == isTip)&&(identical(other.isDiscount, isDiscount) || other.isDiscount == isDiscount)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.ocrConfidenceBp, ocrConfidenceBp) || other.ocrConfidenceBp == ocrConfidenceBp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,receiptId,description,amount,quantity,unitPrice,categoryId,isTax,isTip,isDiscount,sortOrder,ocrConfidenceBp);

@override
String toString() {
  return 'ReceiptLineItem(id: $id, receiptId: $receiptId, description: $description, amount: $amount, quantity: $quantity, unitPrice: $unitPrice, categoryId: $categoryId, isTax: $isTax, isTip: $isTip, isDiscount: $isDiscount, sortOrder: $sortOrder, ocrConfidenceBp: $ocrConfidenceBp)';
}


}

/// @nodoc
abstract mixin class $ReceiptLineItemCopyWith<$Res>  {
  factory $ReceiptLineItemCopyWith(ReceiptLineItem value, $Res Function(ReceiptLineItem) _then) = _$ReceiptLineItemCopyWithImpl;
@useResult
$Res call({
 String id, String receiptId, String description, int amount, double? quantity, int? unitPrice, String? categoryId, bool isTax, bool isTip, bool isDiscount, int sortOrder, int? ocrConfidenceBp
});




}
/// @nodoc
class _$ReceiptLineItemCopyWithImpl<$Res>
    implements $ReceiptLineItemCopyWith<$Res> {
  _$ReceiptLineItemCopyWithImpl(this._self, this._then);

  final ReceiptLineItem _self;
  final $Res Function(ReceiptLineItem) _then;

/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? receiptId = null,Object? description = null,Object? amount = null,Object? quantity = freezed,Object? unitPrice = freezed,Object? categoryId = freezed,Object? isTax = null,Object? isTip = null,Object? isDiscount = null,Object? sortOrder = null,Object? ocrConfidenceBp = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isTax: null == isTax ? _self.isTax : isTax // ignore: cast_nullable_to_non_nullable
as bool,isTip: null == isTip ? _self.isTip : isTip // ignore: cast_nullable_to_non_nullable
as bool,isDiscount: null == isDiscount ? _self.isDiscount : isDiscount // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,ocrConfidenceBp: freezed == ocrConfidenceBp ? _self.ocrConfidenceBp : ocrConfidenceBp // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptLineItem].
extension ReceiptLineItemPatterns on ReceiptLineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptLineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptLineItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptLineItem value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptLineItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptLineItem value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptLineItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String receiptId,  String description,  int amount,  double? quantity,  int? unitPrice,  String? categoryId,  bool isTax,  bool isTip,  bool isDiscount,  int sortOrder,  int? ocrConfidenceBp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptLineItem() when $default != null:
return $default(_that.id,_that.receiptId,_that.description,_that.amount,_that.quantity,_that.unitPrice,_that.categoryId,_that.isTax,_that.isTip,_that.isDiscount,_that.sortOrder,_that.ocrConfidenceBp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String receiptId,  String description,  int amount,  double? quantity,  int? unitPrice,  String? categoryId,  bool isTax,  bool isTip,  bool isDiscount,  int sortOrder,  int? ocrConfidenceBp)  $default,) {final _that = this;
switch (_that) {
case _ReceiptLineItem():
return $default(_that.id,_that.receiptId,_that.description,_that.amount,_that.quantity,_that.unitPrice,_that.categoryId,_that.isTax,_that.isTip,_that.isDiscount,_that.sortOrder,_that.ocrConfidenceBp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String receiptId,  String description,  int amount,  double? quantity,  int? unitPrice,  String? categoryId,  bool isTax,  bool isTip,  bool isDiscount,  int sortOrder,  int? ocrConfidenceBp)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptLineItem() when $default != null:
return $default(_that.id,_that.receiptId,_that.description,_that.amount,_that.quantity,_that.unitPrice,_that.categoryId,_that.isTax,_that.isTip,_that.isDiscount,_that.sortOrder,_that.ocrConfidenceBp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReceiptLineItem implements ReceiptLineItem {
  const _ReceiptLineItem({required this.id, required this.receiptId, required this.description, required this.amount, this.quantity, this.unitPrice, this.categoryId, required this.isTax, required this.isTip, required this.isDiscount, required this.sortOrder, this.ocrConfidenceBp});
  factory _ReceiptLineItem.fromJson(Map<String, dynamic> json) => _$ReceiptLineItemFromJson(json);

@override final  String id;
@override final  String receiptId;
@override final  String description;
/// Amount in cents (always positive; sign determined by [isDiscount]).
@override final  int amount;
/// Optional quantity for unit-priced items (e.g. 2.0 lbs of produce).
@override final  double? quantity;
/// Unit price in cents (amount / quantity, when available from OCR).
@override final  int? unitPrice;
@override final  String? categoryId;
/// True if this line represents sales tax.
@override final  bool isTax;
/// True if this line represents a tip/gratuity.
@override final  bool isTip;
/// True if this line is a discount (coupon, promo, etc.) — negative value.
@override final  bool isDiscount;
@override final  int sortOrder;
/// Per-line OCR confidence in basis points (0–10000, where 10000
/// == 1.00). Null when no recognizer ran (user typed the line in
/// manually). The "Review uncertain OCR lines" surface filters
/// on this; user edits don't update the value, so a row the user
/// already corrected won't keep resurfacing for review.
@override final  int? ocrConfidenceBp;

/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptLineItemCopyWith<_ReceiptLineItem> get copyWith => __$ReceiptLineItemCopyWithImpl<_ReceiptLineItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptLineItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptLineItem&&(identical(other.id, id) || other.id == id)&&(identical(other.receiptId, receiptId) || other.receiptId == receiptId)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.isTax, isTax) || other.isTax == isTax)&&(identical(other.isTip, isTip) || other.isTip == isTip)&&(identical(other.isDiscount, isDiscount) || other.isDiscount == isDiscount)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.ocrConfidenceBp, ocrConfidenceBp) || other.ocrConfidenceBp == ocrConfidenceBp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,receiptId,description,amount,quantity,unitPrice,categoryId,isTax,isTip,isDiscount,sortOrder,ocrConfidenceBp);

@override
String toString() {
  return 'ReceiptLineItem(id: $id, receiptId: $receiptId, description: $description, amount: $amount, quantity: $quantity, unitPrice: $unitPrice, categoryId: $categoryId, isTax: $isTax, isTip: $isTip, isDiscount: $isDiscount, sortOrder: $sortOrder, ocrConfidenceBp: $ocrConfidenceBp)';
}


}

/// @nodoc
abstract mixin class _$ReceiptLineItemCopyWith<$Res> implements $ReceiptLineItemCopyWith<$Res> {
  factory _$ReceiptLineItemCopyWith(_ReceiptLineItem value, $Res Function(_ReceiptLineItem) _then) = __$ReceiptLineItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String receiptId, String description, int amount, double? quantity, int? unitPrice, String? categoryId, bool isTax, bool isTip, bool isDiscount, int sortOrder, int? ocrConfidenceBp
});




}
/// @nodoc
class __$ReceiptLineItemCopyWithImpl<$Res>
    implements _$ReceiptLineItemCopyWith<$Res> {
  __$ReceiptLineItemCopyWithImpl(this._self, this._then);

  final _ReceiptLineItem _self;
  final $Res Function(_ReceiptLineItem) _then;

/// Create a copy of ReceiptLineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? receiptId = null,Object? description = null,Object? amount = null,Object? quantity = freezed,Object? unitPrice = freezed,Object? categoryId = freezed,Object? isTax = null,Object? isTip = null,Object? isDiscount = null,Object? sortOrder = null,Object? ocrConfidenceBp = freezed,}) {
  return _then(_ReceiptLineItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,receiptId: null == receiptId ? _self.receiptId : receiptId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,quantity: freezed == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as double?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as int?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,isTax: null == isTax ? _self.isTax : isTax // ignore: cast_nullable_to_non_nullable
as bool,isTip: null == isTip ? _self.isTip : isTip // ignore: cast_nullable_to_non_nullable
as bool,isDiscount: null == isDiscount ? _self.isDiscount : isDiscount // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,ocrConfidenceBp: freezed == ocrConfidenceBp ? _self.ocrConfidenceBp : ocrConfidenceBp // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
