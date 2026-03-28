// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_line_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReceiptLineItem _$ReceiptLineItemFromJson(Map<String, dynamic> json) {
  return _ReceiptLineItem.fromJson(json);
}

/// @nodoc
mixin _$ReceiptLineItem {
  String get id => throw _privateConstructorUsedError;
  String get receiptId => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// Amount in cents (always positive; sign determined by [isDiscount]).
  int get amount => throw _privateConstructorUsedError;

  /// Optional quantity for unit-priced items (e.g. 2.0 lbs of produce).
  double? get quantity => throw _privateConstructorUsedError;

  /// Unit price in cents (amount / quantity, when available from OCR).
  int? get unitPrice => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;

  /// True if this line represents sales tax.
  bool get isTax => throw _privateConstructorUsedError;

  /// True if this line represents a tip/gratuity.
  bool get isTip => throw _privateConstructorUsedError;

  /// True if this line is a discount (coupon, promo, etc.) — negative value.
  bool get isDiscount => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ReceiptLineItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReceiptLineItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReceiptLineItemCopyWith<ReceiptLineItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiptLineItemCopyWith<$Res> {
  factory $ReceiptLineItemCopyWith(
    ReceiptLineItem value,
    $Res Function(ReceiptLineItem) then,
  ) = _$ReceiptLineItemCopyWithImpl<$Res, ReceiptLineItem>;
  @useResult
  $Res call({
    String id,
    String receiptId,
    String description,
    int amount,
    double? quantity,
    int? unitPrice,
    String? categoryId,
    bool isTax,
    bool isTip,
    bool isDiscount,
    int sortOrder,
  });
}

/// @nodoc
class _$ReceiptLineItemCopyWithImpl<$Res, $Val extends ReceiptLineItem>
    implements $ReceiptLineItemCopyWith<$Res> {
  _$ReceiptLineItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReceiptLineItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? receiptId = null,
    Object? description = null,
    Object? amount = null,
    Object? quantity = freezed,
    Object? unitPrice = freezed,
    Object? categoryId = freezed,
    Object? isTax = null,
    Object? isTip = null,
    Object? isDiscount = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            receiptId: null == receiptId
                ? _value.receiptId
                : receiptId // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as int,
            quantity: freezed == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as double?,
            unitPrice: freezed == unitPrice
                ? _value.unitPrice
                : unitPrice // ignore: cast_nullable_to_non_nullable
                      as int?,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            isTax: null == isTax
                ? _value.isTax
                : isTax // ignore: cast_nullable_to_non_nullable
                      as bool,
            isTip: null == isTip
                ? _value.isTip
                : isTip // ignore: cast_nullable_to_non_nullable
                      as bool,
            isDiscount: null == isDiscount
                ? _value.isDiscount
                : isDiscount // ignore: cast_nullable_to_non_nullable
                      as bool,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReceiptLineItemImplCopyWith<$Res>
    implements $ReceiptLineItemCopyWith<$Res> {
  factory _$$ReceiptLineItemImplCopyWith(
    _$ReceiptLineItemImpl value,
    $Res Function(_$ReceiptLineItemImpl) then,
  ) = __$$ReceiptLineItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String receiptId,
    String description,
    int amount,
    double? quantity,
    int? unitPrice,
    String? categoryId,
    bool isTax,
    bool isTip,
    bool isDiscount,
    int sortOrder,
  });
}

/// @nodoc
class __$$ReceiptLineItemImplCopyWithImpl<$Res>
    extends _$ReceiptLineItemCopyWithImpl<$Res, _$ReceiptLineItemImpl>
    implements _$$ReceiptLineItemImplCopyWith<$Res> {
  __$$ReceiptLineItemImplCopyWithImpl(
    _$ReceiptLineItemImpl _value,
    $Res Function(_$ReceiptLineItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReceiptLineItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? receiptId = null,
    Object? description = null,
    Object? amount = null,
    Object? quantity = freezed,
    Object? unitPrice = freezed,
    Object? categoryId = freezed,
    Object? isTax = null,
    Object? isTip = null,
    Object? isDiscount = null,
    Object? sortOrder = null,
  }) {
    return _then(
      _$ReceiptLineItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        receiptId: null == receiptId
            ? _value.receiptId
            : receiptId // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        quantity: freezed == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as double?,
        unitPrice: freezed == unitPrice
            ? _value.unitPrice
            : unitPrice // ignore: cast_nullable_to_non_nullable
                  as int?,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        isTax: null == isTax
            ? _value.isTax
            : isTax // ignore: cast_nullable_to_non_nullable
                  as bool,
        isTip: null == isTip
            ? _value.isTip
            : isTip // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDiscount: null == isDiscount
            ? _value.isDiscount
            : isDiscount // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReceiptLineItemImpl implements _ReceiptLineItem {
  const _$ReceiptLineItemImpl({
    required this.id,
    required this.receiptId,
    required this.description,
    required this.amount,
    this.quantity,
    this.unitPrice,
    this.categoryId,
    required this.isTax,
    required this.isTip,
    required this.isDiscount,
    required this.sortOrder,
  });

  factory _$ReceiptLineItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReceiptLineItemImplFromJson(json);

  @override
  final String id;
  @override
  final String receiptId;
  @override
  final String description;

  /// Amount in cents (always positive; sign determined by [isDiscount]).
  @override
  final int amount;

  /// Optional quantity for unit-priced items (e.g. 2.0 lbs of produce).
  @override
  final double? quantity;

  /// Unit price in cents (amount / quantity, when available from OCR).
  @override
  final int? unitPrice;
  @override
  final String? categoryId;

  /// True if this line represents sales tax.
  @override
  final bool isTax;

  /// True if this line represents a tip/gratuity.
  @override
  final bool isTip;

  /// True if this line is a discount (coupon, promo, etc.) — negative value.
  @override
  final bool isDiscount;
  @override
  final int sortOrder;

  @override
  String toString() {
    return 'ReceiptLineItem(id: $id, receiptId: $receiptId, description: $description, amount: $amount, quantity: $quantity, unitPrice: $unitPrice, categoryId: $categoryId, isTax: $isTax, isTip: $isTip, isDiscount: $isDiscount, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceiptLineItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.receiptId, receiptId) ||
                other.receiptId == receiptId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.isTax, isTax) || other.isTax == isTax) &&
            (identical(other.isTip, isTip) || other.isTip == isTip) &&
            (identical(other.isDiscount, isDiscount) ||
                other.isDiscount == isDiscount) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    receiptId,
    description,
    amount,
    quantity,
    unitPrice,
    categoryId,
    isTax,
    isTip,
    isDiscount,
    sortOrder,
  );

  /// Create a copy of ReceiptLineItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceiptLineItemImplCopyWith<_$ReceiptLineItemImpl> get copyWith =>
      __$$ReceiptLineItemImplCopyWithImpl<_$ReceiptLineItemImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReceiptLineItemImplToJson(this);
  }
}

abstract class _ReceiptLineItem implements ReceiptLineItem {
  const factory _ReceiptLineItem({
    required final String id,
    required final String receiptId,
    required final String description,
    required final int amount,
    final double? quantity,
    final int? unitPrice,
    final String? categoryId,
    required final bool isTax,
    required final bool isTip,
    required final bool isDiscount,
    required final int sortOrder,
  }) = _$ReceiptLineItemImpl;

  factory _ReceiptLineItem.fromJson(Map<String, dynamic> json) =
      _$ReceiptLineItemImpl.fromJson;

  @override
  String get id;
  @override
  String get receiptId;
  @override
  String get description;

  /// Amount in cents (always positive; sign determined by [isDiscount]).
  @override
  int get amount;

  /// Optional quantity for unit-priced items (e.g. 2.0 lbs of produce).
  @override
  double? get quantity;

  /// Unit price in cents (amount / quantity, when available from OCR).
  @override
  int? get unitPrice;
  @override
  String? get categoryId;

  /// True if this line represents sales tax.
  @override
  bool get isTax;

  /// True if this line represents a tip/gratuity.
  @override
  bool get isTip;

  /// True if this line is a discount (coupon, promo, etc.) — negative value.
  @override
  bool get isDiscount;
  @override
  int get sortOrder;

  /// Create a copy of ReceiptLineItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReceiptLineItemImplCopyWith<_$ReceiptLineItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
