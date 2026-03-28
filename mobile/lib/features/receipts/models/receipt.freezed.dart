// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Receipt _$ReceiptFromJson(Map<String, dynamic> json) {
  return _Receipt.fromJson(json);
}

/// @nodoc
mixin _$Receipt {
  String get id => throw _privateConstructorUsedError;
  String get householdId => throw _privateConstructorUsedError;
  String get uploadedBy => throw _privateConstructorUsedError;

  /// Path inside the `receipts` bucket: "{household_id}/{filename}"
  String get storagePath => throw _privateConstructorUsedError;
  String? get thumbnailPath => throw _privateConstructorUsedError;
  String? get merchantName => throw _privateConstructorUsedError;
  DateTime? get receiptDate => throw _privateConstructorUsedError;

  /// Total amount in cents, confirmed by user or extracted by OCR.
  int? get totalAmount => throw _privateConstructorUsedError;
  OcrStatus get ocrStatus => throw _privateConstructorUsedError;

  /// Raw JSON blob returned by the OCR provider (Cloud Vision).
  Map<String, dynamic>? get ocrRaw => throw _privateConstructorUsedError;
  DateTime get uploadedAt => throw _privateConstructorUsedError;

  /// Serializes this Receipt to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReceiptCopyWith<Receipt> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiptCopyWith<$Res> {
  factory $ReceiptCopyWith(Receipt value, $Res Function(Receipt) then) =
      _$ReceiptCopyWithImpl<$Res, Receipt>;
  @useResult
  $Res call({
    String id,
    String householdId,
    String uploadedBy,
    String storagePath,
    String? thumbnailPath,
    String? merchantName,
    DateTime? receiptDate,
    int? totalAmount,
    OcrStatus ocrStatus,
    Map<String, dynamic>? ocrRaw,
    DateTime uploadedAt,
  });
}

/// @nodoc
class _$ReceiptCopyWithImpl<$Res, $Val extends Receipt>
    implements $ReceiptCopyWith<$Res> {
  _$ReceiptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? uploadedBy = null,
    Object? storagePath = null,
    Object? thumbnailPath = freezed,
    Object? merchantName = freezed,
    Object? receiptDate = freezed,
    Object? totalAmount = freezed,
    Object? ocrStatus = null,
    Object? ocrRaw = freezed,
    Object? uploadedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            householdId: null == householdId
                ? _value.householdId
                : householdId // ignore: cast_nullable_to_non_nullable
                      as String,
            uploadedBy: null == uploadedBy
                ? _value.uploadedBy
                : uploadedBy // ignore: cast_nullable_to_non_nullable
                      as String,
            storagePath: null == storagePath
                ? _value.storagePath
                : storagePath // ignore: cast_nullable_to_non_nullable
                      as String,
            thumbnailPath: freezed == thumbnailPath
                ? _value.thumbnailPath
                : thumbnailPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            merchantName: freezed == merchantName
                ? _value.merchantName
                : merchantName // ignore: cast_nullable_to_non_nullable
                      as String?,
            receiptDate: freezed == receiptDate
                ? _value.receiptDate
                : receiptDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            totalAmount: freezed == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as int?,
            ocrStatus: null == ocrStatus
                ? _value.ocrStatus
                : ocrStatus // ignore: cast_nullable_to_non_nullable
                      as OcrStatus,
            ocrRaw: freezed == ocrRaw
                ? _value.ocrRaw
                : ocrRaw // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            uploadedAt: null == uploadedAt
                ? _value.uploadedAt
                : uploadedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReceiptImplCopyWith<$Res> implements $ReceiptCopyWith<$Res> {
  factory _$$ReceiptImplCopyWith(
    _$ReceiptImpl value,
    $Res Function(_$ReceiptImpl) then,
  ) = __$$ReceiptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String householdId,
    String uploadedBy,
    String storagePath,
    String? thumbnailPath,
    String? merchantName,
    DateTime? receiptDate,
    int? totalAmount,
    OcrStatus ocrStatus,
    Map<String, dynamic>? ocrRaw,
    DateTime uploadedAt,
  });
}

/// @nodoc
class __$$ReceiptImplCopyWithImpl<$Res>
    extends _$ReceiptCopyWithImpl<$Res, _$ReceiptImpl>
    implements _$$ReceiptImplCopyWith<$Res> {
  __$$ReceiptImplCopyWithImpl(
    _$ReceiptImpl _value,
    $Res Function(_$ReceiptImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? uploadedBy = null,
    Object? storagePath = null,
    Object? thumbnailPath = freezed,
    Object? merchantName = freezed,
    Object? receiptDate = freezed,
    Object? totalAmount = freezed,
    Object? ocrStatus = null,
    Object? ocrRaw = freezed,
    Object? uploadedAt = null,
  }) {
    return _then(
      _$ReceiptImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        householdId: null == householdId
            ? _value.householdId
            : householdId // ignore: cast_nullable_to_non_nullable
                  as String,
        uploadedBy: null == uploadedBy
            ? _value.uploadedBy
            : uploadedBy // ignore: cast_nullable_to_non_nullable
                  as String,
        storagePath: null == storagePath
            ? _value.storagePath
            : storagePath // ignore: cast_nullable_to_non_nullable
                  as String,
        thumbnailPath: freezed == thumbnailPath
            ? _value.thumbnailPath
            : thumbnailPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchantName: freezed == merchantName
            ? _value.merchantName
            : merchantName // ignore: cast_nullable_to_non_nullable
                  as String?,
        receiptDate: freezed == receiptDate
            ? _value.receiptDate
            : receiptDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        totalAmount: freezed == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as int?,
        ocrStatus: null == ocrStatus
            ? _value.ocrStatus
            : ocrStatus // ignore: cast_nullable_to_non_nullable
                  as OcrStatus,
        ocrRaw: freezed == ocrRaw
            ? _value._ocrRaw
            : ocrRaw // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        uploadedAt: null == uploadedAt
            ? _value.uploadedAt
            : uploadedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReceiptImpl implements _Receipt {
  const _$ReceiptImpl({
    required this.id,
    required this.householdId,
    required this.uploadedBy,
    required this.storagePath,
    this.thumbnailPath,
    this.merchantName,
    this.receiptDate,
    this.totalAmount,
    required this.ocrStatus,
    final Map<String, dynamic>? ocrRaw,
    required this.uploadedAt,
  }) : _ocrRaw = ocrRaw;

  factory _$ReceiptImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReceiptImplFromJson(json);

  @override
  final String id;
  @override
  final String householdId;
  @override
  final String uploadedBy;

  /// Path inside the `receipts` bucket: "{household_id}/{filename}"
  @override
  final String storagePath;
  @override
  final String? thumbnailPath;
  @override
  final String? merchantName;
  @override
  final DateTime? receiptDate;

  /// Total amount in cents, confirmed by user or extracted by OCR.
  @override
  final int? totalAmount;
  @override
  final OcrStatus ocrStatus;

  /// Raw JSON blob returned by the OCR provider (Cloud Vision).
  final Map<String, dynamic>? _ocrRaw;

  /// Raw JSON blob returned by the OCR provider (Cloud Vision).
  @override
  Map<String, dynamic>? get ocrRaw {
    final value = _ocrRaw;
    if (value == null) return null;
    if (_ocrRaw is EqualUnmodifiableMapView) return _ocrRaw;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime uploadedAt;

  @override
  String toString() {
    return 'Receipt(id: $id, householdId: $householdId, uploadedBy: $uploadedBy, storagePath: $storagePath, thumbnailPath: $thumbnailPath, merchantName: $merchantName, receiptDate: $receiptDate, totalAmount: $totalAmount, ocrStatus: $ocrStatus, ocrRaw: $ocrRaw, uploadedAt: $uploadedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceiptImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.uploadedBy, uploadedBy) ||
                other.uploadedBy == uploadedBy) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.thumbnailPath, thumbnailPath) ||
                other.thumbnailPath == thumbnailPath) &&
            (identical(other.merchantName, merchantName) ||
                other.merchantName == merchantName) &&
            (identical(other.receiptDate, receiptDate) ||
                other.receiptDate == receiptDate) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.ocrStatus, ocrStatus) ||
                other.ocrStatus == ocrStatus) &&
            const DeepCollectionEquality().equals(other._ocrRaw, _ocrRaw) &&
            (identical(other.uploadedAt, uploadedAt) ||
                other.uploadedAt == uploadedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    householdId,
    uploadedBy,
    storagePath,
    thumbnailPath,
    merchantName,
    receiptDate,
    totalAmount,
    ocrStatus,
    const DeepCollectionEquality().hash(_ocrRaw),
    uploadedAt,
  );

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceiptImplCopyWith<_$ReceiptImpl> get copyWith =>
      __$$ReceiptImplCopyWithImpl<_$ReceiptImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReceiptImplToJson(this);
  }
}

abstract class _Receipt implements Receipt {
  const factory _Receipt({
    required final String id,
    required final String householdId,
    required final String uploadedBy,
    required final String storagePath,
    final String? thumbnailPath,
    final String? merchantName,
    final DateTime? receiptDate,
    final int? totalAmount,
    required final OcrStatus ocrStatus,
    final Map<String, dynamic>? ocrRaw,
    required final DateTime uploadedAt,
  }) = _$ReceiptImpl;

  factory _Receipt.fromJson(Map<String, dynamic> json) = _$ReceiptImpl.fromJson;

  @override
  String get id;
  @override
  String get householdId;
  @override
  String get uploadedBy;

  /// Path inside the `receipts` bucket: "{household_id}/{filename}"
  @override
  String get storagePath;
  @override
  String? get thumbnailPath;
  @override
  String? get merchantName;
  @override
  DateTime? get receiptDate;

  /// Total amount in cents, confirmed by user or extracted by OCR.
  @override
  int? get totalAmount;
  @override
  OcrStatus get ocrStatus;

  /// Raw JSON blob returned by the OCR provider (Cloud Vision).
  @override
  Map<String, dynamic>? get ocrRaw;
  @override
  DateTime get uploadedAt;

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReceiptImplCopyWith<_$ReceiptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
