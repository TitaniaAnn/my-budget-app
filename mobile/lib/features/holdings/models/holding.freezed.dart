// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'holding.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Holding _$HoldingFromJson(Map<String, dynamic> json) {
  return _Holding.fromJson(json);
}

/// @nodoc
mixin _$Holding {
  String get id => throw _privateConstructorUsedError;
  String get householdId => throw _privateConstructorUsedError;
  String get accountId => throw _privateConstructorUsedError;

  /// Ticker / fund symbol / short crypto code.
  String get symbol => throw _privateConstructorUsedError;

  /// Optional human-readable name; the symbol is the source of
  /// truth for "which security."
  String? get description => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;

  /// Total cost basis in cents. Null = unknown (e.g. backfilled
  /// position without a purchase history).
  int? get costBasis => throw _privateConstructorUsedError;

  /// Current value in cents. User-entered — no price feed in v1.
  int get currentValue => throw _privateConstructorUsedError;
  AssetClass? get assetClass => throw _privateConstructorUsedError;

  /// Wall-clock of the last user-entered [currentValue]. Powers a
  /// future "stale" indicator; null when never priced.
  DateTime? get lastPricedAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Holding to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Holding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HoldingCopyWith<Holding> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HoldingCopyWith<$Res> {
  factory $HoldingCopyWith(Holding value, $Res Function(Holding) then) =
      _$HoldingCopyWithImpl<$Res, Holding>;
  @useResult
  $Res call({
    String id,
    String householdId,
    String accountId,
    String symbol,
    String? description,
    double quantity,
    int? costBasis,
    int currentValue,
    AssetClass? assetClass,
    DateTime? lastPricedAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$HoldingCopyWithImpl<$Res, $Val extends Holding>
    implements $HoldingCopyWith<$Res> {
  _$HoldingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Holding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? accountId = null,
    Object? symbol = null,
    Object? description = freezed,
    Object? quantity = null,
    Object? costBasis = freezed,
    Object? currentValue = null,
    Object? assetClass = freezed,
    Object? lastPricedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
            accountId: null == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String,
            symbol: null == symbol
                ? _value.symbol
                : symbol // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            quantity: null == quantity
                ? _value.quantity
                : quantity // ignore: cast_nullable_to_non_nullable
                      as double,
            costBasis: freezed == costBasis
                ? _value.costBasis
                : costBasis // ignore: cast_nullable_to_non_nullable
                      as int?,
            currentValue: null == currentValue
                ? _value.currentValue
                : currentValue // ignore: cast_nullable_to_non_nullable
                      as int,
            assetClass: freezed == assetClass
                ? _value.assetClass
                : assetClass // ignore: cast_nullable_to_non_nullable
                      as AssetClass?,
            lastPricedAt: freezed == lastPricedAt
                ? _value.lastPricedAt
                : lastPricedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HoldingImplCopyWith<$Res> implements $HoldingCopyWith<$Res> {
  factory _$$HoldingImplCopyWith(
    _$HoldingImpl value,
    $Res Function(_$HoldingImpl) then,
  ) = __$$HoldingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String householdId,
    String accountId,
    String symbol,
    String? description,
    double quantity,
    int? costBasis,
    int currentValue,
    AssetClass? assetClass,
    DateTime? lastPricedAt,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$HoldingImplCopyWithImpl<$Res>
    extends _$HoldingCopyWithImpl<$Res, _$HoldingImpl>
    implements _$$HoldingImplCopyWith<$Res> {
  __$$HoldingImplCopyWithImpl(
    _$HoldingImpl _value,
    $Res Function(_$HoldingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Holding
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? accountId = null,
    Object? symbol = null,
    Object? description = freezed,
    Object? quantity = null,
    Object? costBasis = freezed,
    Object? currentValue = null,
    Object? assetClass = freezed,
    Object? lastPricedAt = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$HoldingImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        householdId: null == householdId
            ? _value.householdId
            : householdId // ignore: cast_nullable_to_non_nullable
                  as String,
        accountId: null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
        symbol: null == symbol
            ? _value.symbol
            : symbol // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: null == quantity
            ? _value.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as double,
        costBasis: freezed == costBasis
            ? _value.costBasis
            : costBasis // ignore: cast_nullable_to_non_nullable
                  as int?,
        currentValue: null == currentValue
            ? _value.currentValue
            : currentValue // ignore: cast_nullable_to_non_nullable
                  as int,
        assetClass: freezed == assetClass
            ? _value.assetClass
            : assetClass // ignore: cast_nullable_to_non_nullable
                  as AssetClass?,
        lastPricedAt: freezed == lastPricedAt
            ? _value.lastPricedAt
            : lastPricedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HoldingImpl implements _Holding {
  const _$HoldingImpl({
    required this.id,
    required this.householdId,
    required this.accountId,
    required this.symbol,
    this.description,
    required this.quantity,
    this.costBasis,
    required this.currentValue,
    this.assetClass,
    this.lastPricedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$HoldingImpl.fromJson(Map<String, dynamic> json) =>
      _$$HoldingImplFromJson(json);

  @override
  final String id;
  @override
  final String householdId;
  @override
  final String accountId;

  /// Ticker / fund symbol / short crypto code.
  @override
  final String symbol;

  /// Optional human-readable name; the symbol is the source of
  /// truth for "which security."
  @override
  final String? description;
  @override
  final double quantity;

  /// Total cost basis in cents. Null = unknown (e.g. backfilled
  /// position without a purchase history).
  @override
  final int? costBasis;

  /// Current value in cents. User-entered — no price feed in v1.
  @override
  final int currentValue;
  @override
  final AssetClass? assetClass;

  /// Wall-clock of the last user-entered [currentValue]. Powers a
  /// future "stale" indicator; null when never priced.
  @override
  final DateTime? lastPricedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Holding(id: $id, householdId: $householdId, accountId: $accountId, symbol: $symbol, description: $description, quantity: $quantity, costBasis: $costBasis, currentValue: $currentValue, assetClass: $assetClass, lastPricedAt: $lastPricedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HoldingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.costBasis, costBasis) ||
                other.costBasis == costBasis) &&
            (identical(other.currentValue, currentValue) ||
                other.currentValue == currentValue) &&
            (identical(other.assetClass, assetClass) ||
                other.assetClass == assetClass) &&
            (identical(other.lastPricedAt, lastPricedAt) ||
                other.lastPricedAt == lastPricedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    householdId,
    accountId,
    symbol,
    description,
    quantity,
    costBasis,
    currentValue,
    assetClass,
    lastPricedAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Holding
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HoldingImplCopyWith<_$HoldingImpl> get copyWith =>
      __$$HoldingImplCopyWithImpl<_$HoldingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HoldingImplToJson(this);
  }
}

abstract class _Holding implements Holding {
  const factory _Holding({
    required final String id,
    required final String householdId,
    required final String accountId,
    required final String symbol,
    final String? description,
    required final double quantity,
    final int? costBasis,
    required final int currentValue,
    final AssetClass? assetClass,
    final DateTime? lastPricedAt,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$HoldingImpl;

  factory _Holding.fromJson(Map<String, dynamic> json) = _$HoldingImpl.fromJson;

  @override
  String get id;
  @override
  String get householdId;
  @override
  String get accountId;

  /// Ticker / fund symbol / short crypto code.
  @override
  String get symbol;

  /// Optional human-readable name; the symbol is the source of
  /// truth for "which security."
  @override
  String? get description;
  @override
  double get quantity;

  /// Total cost basis in cents. Null = unknown (e.g. backfilled
  /// position without a purchase history).
  @override
  int? get costBasis;

  /// Current value in cents. User-entered — no price feed in v1.
  @override
  int get currentValue;
  @override
  AssetClass? get assetClass;

  /// Wall-clock of the last user-entered [currentValue]. Powers a
  /// future "stale" indicator; null when never priced.
  @override
  DateTime? get lastPricedAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Holding
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HoldingImplCopyWith<_$HoldingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
