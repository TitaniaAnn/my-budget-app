// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fx_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FxRate _$FxRateFromJson(Map<String, dynamic> json) {
  return _FxRate.fromJson(json);
}

/// @nodoc
mixin _$FxRate {
  String get householdId => throw _privateConstructorUsedError;
  String get fromCurrency => throw _privateConstructorUsedError;
  String get toCurrency => throw _privateConstructorUsedError;
  DateTime get asOfDate => throw _privateConstructorUsedError;

  /// Multiplier. amountInTo = amountInFrom × rate. Stored as
  /// NUMERIC(18,8) in the DB; Postgres returns NUMERIC as a
  /// string on the JSON wire to avoid float loss in transit, so
  /// [_rateFromJson] coerces it to a double here. The math
  /// downstream uses plain `num` multipliers.
  @JsonKey(fromJson: _rateFromJson)
  double get rate => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FxRate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FxRate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FxRateCopyWith<FxRate> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FxRateCopyWith<$Res> {
  factory $FxRateCopyWith(FxRate value, $Res Function(FxRate) then) =
      _$FxRateCopyWithImpl<$Res, FxRate>;
  @useResult
  $Res call({
    String householdId,
    String fromCurrency,
    String toCurrency,
    DateTime asOfDate,
    @JsonKey(fromJson: _rateFromJson) double rate,
    String? createdBy,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$FxRateCopyWithImpl<$Res, $Val extends FxRate>
    implements $FxRateCopyWith<$Res> {
  _$FxRateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FxRate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? householdId = null,
    Object? fromCurrency = null,
    Object? toCurrency = null,
    Object? asOfDate = null,
    Object? rate = null,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            householdId: null == householdId
                ? _value.householdId
                : householdId // ignore: cast_nullable_to_non_nullable
                      as String,
            fromCurrency: null == fromCurrency
                ? _value.fromCurrency
                : fromCurrency // ignore: cast_nullable_to_non_nullable
                      as String,
            toCurrency: null == toCurrency
                ? _value.toCurrency
                : toCurrency // ignore: cast_nullable_to_non_nullable
                      as String,
            asOfDate: null == asOfDate
                ? _value.asOfDate
                : asOfDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            rate: null == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$FxRateImplCopyWith<$Res> implements $FxRateCopyWith<$Res> {
  factory _$$FxRateImplCopyWith(
    _$FxRateImpl value,
    $Res Function(_$FxRateImpl) then,
  ) = __$$FxRateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String householdId,
    String fromCurrency,
    String toCurrency,
    DateTime asOfDate,
    @JsonKey(fromJson: _rateFromJson) double rate,
    String? createdBy,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$FxRateImplCopyWithImpl<$Res>
    extends _$FxRateCopyWithImpl<$Res, _$FxRateImpl>
    implements _$$FxRateImplCopyWith<$Res> {
  __$$FxRateImplCopyWithImpl(
    _$FxRateImpl _value,
    $Res Function(_$FxRateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FxRate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? householdId = null,
    Object? fromCurrency = null,
    Object? toCurrency = null,
    Object? asOfDate = null,
    Object? rate = null,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$FxRateImpl(
        householdId: null == householdId
            ? _value.householdId
            : householdId // ignore: cast_nullable_to_non_nullable
                  as String,
        fromCurrency: null == fromCurrency
            ? _value.fromCurrency
            : fromCurrency // ignore: cast_nullable_to_non_nullable
                  as String,
        toCurrency: null == toCurrency
            ? _value.toCurrency
            : toCurrency // ignore: cast_nullable_to_non_nullable
                  as String,
        asOfDate: null == asOfDate
            ? _value.asOfDate
            : asOfDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        rate: null == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$FxRateImpl implements _FxRate {
  const _$FxRateImpl({
    required this.householdId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.asOfDate,
    @JsonKey(fromJson: _rateFromJson) required this.rate,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$FxRateImpl.fromJson(Map<String, dynamic> json) =>
      _$$FxRateImplFromJson(json);

  @override
  final String householdId;
  @override
  final String fromCurrency;
  @override
  final String toCurrency;
  @override
  final DateTime asOfDate;

  /// Multiplier. amountInTo = amountInFrom × rate. Stored as
  /// NUMERIC(18,8) in the DB; Postgres returns NUMERIC as a
  /// string on the JSON wire to avoid float loss in transit, so
  /// [_rateFromJson] coerces it to a double here. The math
  /// downstream uses plain `num` multipliers.
  @override
  @JsonKey(fromJson: _rateFromJson)
  final double rate;
  @override
  final String? createdBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'FxRate(householdId: $householdId, fromCurrency: $fromCurrency, toCurrency: $toCurrency, asOfDate: $asOfDate, rate: $rate, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FxRateImpl &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.fromCurrency, fromCurrency) ||
                other.fromCurrency == fromCurrency) &&
            (identical(other.toCurrency, toCurrency) ||
                other.toCurrency == toCurrency) &&
            (identical(other.asOfDate, asOfDate) ||
                other.asOfDate == asOfDate) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    householdId,
    fromCurrency,
    toCurrency,
    asOfDate,
    rate,
    createdBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of FxRate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FxRateImplCopyWith<_$FxRateImpl> get copyWith =>
      __$$FxRateImplCopyWithImpl<_$FxRateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FxRateImplToJson(this);
  }
}

abstract class _FxRate implements FxRate {
  const factory _FxRate({
    required final String householdId,
    required final String fromCurrency,
    required final String toCurrency,
    required final DateTime asOfDate,
    @JsonKey(fromJson: _rateFromJson) required final double rate,
    final String? createdBy,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$FxRateImpl;

  factory _FxRate.fromJson(Map<String, dynamic> json) = _$FxRateImpl.fromJson;

  @override
  String get householdId;
  @override
  String get fromCurrency;
  @override
  String get toCurrency;
  @override
  DateTime get asOfDate;

  /// Multiplier. amountInTo = amountInFrom × rate. Stored as
  /// NUMERIC(18,8) in the DB; Postgres returns NUMERIC as a
  /// string on the JSON wire to avoid float loss in transit, so
  /// [_rateFromJson] coerces it to a double here. The math
  /// downstream uses plain `num` multipliers.
  @override
  @JsonKey(fromJson: _rateFromJson)
  double get rate;
  @override
  String? get createdBy;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of FxRate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FxRateImplCopyWith<_$FxRateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
