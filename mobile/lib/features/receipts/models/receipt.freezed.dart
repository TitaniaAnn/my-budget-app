// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Receipt {

 String get id; String get householdId; String get uploadedBy;/// Path inside the `receipts` bucket: "{household_id}/{filename}"
 String get storagePath; String? get thumbnailPath; String? get merchantName; DateTime? get receiptDate;/// Total amount in cents, confirmed by user or extracted by OCR.
 int? get totalAmount; OcrStatus get ocrStatus;/// Raw JSON blob returned by the OCR provider (Cloud Vision).
 Map<String, dynamic>? get ocrRaw; DateTime get uploadedAt;
/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptCopyWith<Receipt> get copyWith => _$ReceiptCopyWithImpl<Receipt>(this as Receipt, _$identity);

  /// Serializes this Receipt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Receipt&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.merchantName, merchantName) || other.merchantName == merchantName)&&(identical(other.receiptDate, receiptDate) || other.receiptDate == receiptDate)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.ocrStatus, ocrStatus) || other.ocrStatus == ocrStatus)&&const DeepCollectionEquality().equals(other.ocrRaw, ocrRaw)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,uploadedBy,storagePath,thumbnailPath,merchantName,receiptDate,totalAmount,ocrStatus,const DeepCollectionEquality().hash(ocrRaw),uploadedAt);

@override
String toString() {
  return 'Receipt(id: $id, householdId: $householdId, uploadedBy: $uploadedBy, storagePath: $storagePath, thumbnailPath: $thumbnailPath, merchantName: $merchantName, receiptDate: $receiptDate, totalAmount: $totalAmount, ocrStatus: $ocrStatus, ocrRaw: $ocrRaw, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class $ReceiptCopyWith<$Res>  {
  factory $ReceiptCopyWith(Receipt value, $Res Function(Receipt) _then) = _$ReceiptCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String uploadedBy, String storagePath, String? thumbnailPath, String? merchantName, DateTime? receiptDate, int? totalAmount, OcrStatus ocrStatus, Map<String, dynamic>? ocrRaw, DateTime uploadedAt
});




}
/// @nodoc
class _$ReceiptCopyWithImpl<$Res>
    implements $ReceiptCopyWith<$Res> {
  _$ReceiptCopyWithImpl(this._self, this._then);

  final Receipt _self;
  final $Res Function(Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? uploadedBy = null,Object? storagePath = null,Object? thumbnailPath = freezed,Object? merchantName = freezed,Object? receiptDate = freezed,Object? totalAmount = freezed,Object? ocrStatus = null,Object? ocrRaw = freezed,Object? uploadedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,merchantName: freezed == merchantName ? _self.merchantName : merchantName // ignore: cast_nullable_to_non_nullable
as String?,receiptDate: freezed == receiptDate ? _self.receiptDate : receiptDate // ignore: cast_nullable_to_non_nullable
as DateTime?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int?,ocrStatus: null == ocrStatus ? _self.ocrStatus : ocrStatus // ignore: cast_nullable_to_non_nullable
as OcrStatus,ocrRaw: freezed == ocrRaw ? _self.ocrRaw : ocrRaw // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Receipt].
extension ReceiptPatterns on Receipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Receipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Receipt value)  $default,){
final _that = this;
switch (_that) {
case _Receipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Receipt value)?  $default,){
final _that = this;
switch (_that) {
case _Receipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String uploadedBy,  String storagePath,  String? thumbnailPath,  String? merchantName,  DateTime? receiptDate,  int? totalAmount,  OcrStatus ocrStatus,  Map<String, dynamic>? ocrRaw,  DateTime uploadedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.id,_that.householdId,_that.uploadedBy,_that.storagePath,_that.thumbnailPath,_that.merchantName,_that.receiptDate,_that.totalAmount,_that.ocrStatus,_that.ocrRaw,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String uploadedBy,  String storagePath,  String? thumbnailPath,  String? merchantName,  DateTime? receiptDate,  int? totalAmount,  OcrStatus ocrStatus,  Map<String, dynamic>? ocrRaw,  DateTime uploadedAt)  $default,) {final _that = this;
switch (_that) {
case _Receipt():
return $default(_that.id,_that.householdId,_that.uploadedBy,_that.storagePath,_that.thumbnailPath,_that.merchantName,_that.receiptDate,_that.totalAmount,_that.ocrStatus,_that.ocrRaw,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String uploadedBy,  String storagePath,  String? thumbnailPath,  String? merchantName,  DateTime? receiptDate,  int? totalAmount,  OcrStatus ocrStatus,  Map<String, dynamic>? ocrRaw,  DateTime uploadedAt)?  $default,) {final _that = this;
switch (_that) {
case _Receipt() when $default != null:
return $default(_that.id,_that.householdId,_that.uploadedBy,_that.storagePath,_that.thumbnailPath,_that.merchantName,_that.receiptDate,_that.totalAmount,_that.ocrStatus,_that.ocrRaw,_that.uploadedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Receipt implements Receipt {
  const _Receipt({required this.id, required this.householdId, required this.uploadedBy, required this.storagePath, this.thumbnailPath, this.merchantName, this.receiptDate, this.totalAmount, required this.ocrStatus, final  Map<String, dynamic>? ocrRaw, required this.uploadedAt}): _ocrRaw = ocrRaw;
  factory _Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);

@override final  String id;
@override final  String householdId;
@override final  String uploadedBy;
/// Path inside the `receipts` bucket: "{household_id}/{filename}"
@override final  String storagePath;
@override final  String? thumbnailPath;
@override final  String? merchantName;
@override final  DateTime? receiptDate;
/// Total amount in cents, confirmed by user or extracted by OCR.
@override final  int? totalAmount;
@override final  OcrStatus ocrStatus;
/// Raw JSON blob returned by the OCR provider (Cloud Vision).
 final  Map<String, dynamic>? _ocrRaw;
/// Raw JSON blob returned by the OCR provider (Cloud Vision).
@override Map<String, dynamic>? get ocrRaw {
  final value = _ocrRaw;
  if (value == null) return null;
  if (_ocrRaw is EqualUnmodifiableMapView) return _ocrRaw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  DateTime uploadedAt;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptCopyWith<_Receipt> get copyWith => __$ReceiptCopyWithImpl<_Receipt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReceiptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Receipt&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.merchantName, merchantName) || other.merchantName == merchantName)&&(identical(other.receiptDate, receiptDate) || other.receiptDate == receiptDate)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.ocrStatus, ocrStatus) || other.ocrStatus == ocrStatus)&&const DeepCollectionEquality().equals(other._ocrRaw, _ocrRaw)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,householdId,uploadedBy,storagePath,thumbnailPath,merchantName,receiptDate,totalAmount,ocrStatus,const DeepCollectionEquality().hash(_ocrRaw),uploadedAt);

@override
String toString() {
  return 'Receipt(id: $id, householdId: $householdId, uploadedBy: $uploadedBy, storagePath: $storagePath, thumbnailPath: $thumbnailPath, merchantName: $merchantName, receiptDate: $receiptDate, totalAmount: $totalAmount, ocrStatus: $ocrStatus, ocrRaw: $ocrRaw, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class _$ReceiptCopyWith<$Res> implements $ReceiptCopyWith<$Res> {
  factory _$ReceiptCopyWith(_Receipt value, $Res Function(_Receipt) _then) = __$ReceiptCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String uploadedBy, String storagePath, String? thumbnailPath, String? merchantName, DateTime? receiptDate, int? totalAmount, OcrStatus ocrStatus, Map<String, dynamic>? ocrRaw, DateTime uploadedAt
});




}
/// @nodoc
class __$ReceiptCopyWithImpl<$Res>
    implements _$ReceiptCopyWith<$Res> {
  __$ReceiptCopyWithImpl(this._self, this._then);

  final _Receipt _self;
  final $Res Function(_Receipt) _then;

/// Create a copy of Receipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? uploadedBy = null,Object? storagePath = null,Object? thumbnailPath = freezed,Object? merchantName = freezed,Object? receiptDate = freezed,Object? totalAmount = freezed,Object? ocrStatus = null,Object? ocrRaw = freezed,Object? uploadedAt = null,}) {
  return _then(_Receipt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,merchantName: freezed == merchantName ? _self.merchantName : merchantName // ignore: cast_nullable_to_non_nullable
as String?,receiptDate: freezed == receiptDate ? _self.receiptDate : receiptDate // ignore: cast_nullable_to_non_nullable
as DateTime?,totalAmount: freezed == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int?,ocrStatus: null == ocrStatus ? _self.ocrStatus : ocrStatus // ignore: cast_nullable_to_non_nullable
as OcrStatus,ocrRaw: freezed == ocrRaw ? _self._ocrRaw : ocrRaw // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
