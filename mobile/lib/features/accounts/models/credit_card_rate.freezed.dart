// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credit_card_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CreditCardRate _$CreditCardRateFromJson(Map<String, dynamic> json) {
  return _CreditCardRate.fromJson(json);
}

/// @nodoc
mixin _$CreditCardRate {
  String get id => throw _privateConstructorUsedError;
  String get accountId => throw _privateConstructorUsedError;
  CreditRateType get rateType => throw _privateConstructorUsedError;

  /// Annual rate as a decimal (e.g. 0.2499 = 24.99%).
  double get rate => throw _privateConstructorUsedError;
  bool get isIntro => throw _privateConstructorUsedError;
  DateTime? get introEndsOn => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  String? get label => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this CreditCardRate to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CreditCardRate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreditCardRateCopyWith<CreditCardRate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreditCardRateCopyWith<$Res> {
  factory $CreditCardRateCopyWith(
    CreditCardRate value,
    $Res Function(CreditCardRate) then,
  ) = _$CreditCardRateCopyWithImpl<$Res, CreditCardRate>;
  @useResult
  $Res call({
    String id,
    String accountId,
    CreditRateType rateType,
    double rate,
    bool isIntro,
    DateTime? introEndsOn,
    bool isActive,
    String? label,
    DateTime createdAt,
  });
}

/// @nodoc
class _$CreditCardRateCopyWithImpl<$Res, $Val extends CreditCardRate>
    implements $CreditCardRateCopyWith<$Res> {
  _$CreditCardRateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreditCardRate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountId = null,
    Object? rateType = null,
    Object? rate = null,
    Object? isIntro = null,
    Object? introEndsOn = freezed,
    Object? isActive = null,
    Object? label = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            accountId: null == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String,
            rateType: null == rateType
                ? _value.rateType
                : rateType // ignore: cast_nullable_to_non_nullable
                      as CreditRateType,
            rate: null == rate
                ? _value.rate
                : rate // ignore: cast_nullable_to_non_nullable
                      as double,
            isIntro: null == isIntro
                ? _value.isIntro
                : isIntro // ignore: cast_nullable_to_non_nullable
                      as bool,
            introEndsOn: freezed == introEndsOn
                ? _value.introEndsOn
                : introEndsOn // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreditCardRateImplCopyWith<$Res>
    implements $CreditCardRateCopyWith<$Res> {
  factory _$$CreditCardRateImplCopyWith(
    _$CreditCardRateImpl value,
    $Res Function(_$CreditCardRateImpl) then,
  ) = __$$CreditCardRateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String accountId,
    CreditRateType rateType,
    double rate,
    bool isIntro,
    DateTime? introEndsOn,
    bool isActive,
    String? label,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$CreditCardRateImplCopyWithImpl<$Res>
    extends _$CreditCardRateCopyWithImpl<$Res, _$CreditCardRateImpl>
    implements _$$CreditCardRateImplCopyWith<$Res> {
  __$$CreditCardRateImplCopyWithImpl(
    _$CreditCardRateImpl _value,
    $Res Function(_$CreditCardRateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreditCardRate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountId = null,
    Object? rateType = null,
    Object? rate = null,
    Object? isIntro = null,
    Object? introEndsOn = freezed,
    Object? isActive = null,
    Object? label = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$CreditCardRateImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        accountId: null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
        rateType: null == rateType
            ? _value.rateType
            : rateType // ignore: cast_nullable_to_non_nullable
                  as CreditRateType,
        rate: null == rate
            ? _value.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as double,
        isIntro: null == isIntro
            ? _value.isIntro
            : isIntro // ignore: cast_nullable_to_non_nullable
                  as bool,
        introEndsOn: freezed == introEndsOn
            ? _value.introEndsOn
            : introEndsOn // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreditCardRateImpl implements _CreditCardRate {
  const _$CreditCardRateImpl({
    required this.id,
    required this.accountId,
    required this.rateType,
    required this.rate,
    required this.isIntro,
    this.introEndsOn,
    required this.isActive,
    this.label,
    required this.createdAt,
  });

  factory _$CreditCardRateImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreditCardRateImplFromJson(json);

  @override
  final String id;
  @override
  final String accountId;
  @override
  final CreditRateType rateType;

  /// Annual rate as a decimal (e.g. 0.2499 = 24.99%).
  @override
  final double rate;
  @override
  final bool isIntro;
  @override
  final DateTime? introEndsOn;
  @override
  final bool isActive;
  @override
  final String? label;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'CreditCardRate(id: $id, accountId: $accountId, rateType: $rateType, rate: $rate, isIntro: $isIntro, introEndsOn: $introEndsOn, isActive: $isActive, label: $label, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreditCardRateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.rateType, rateType) ||
                other.rateType == rateType) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.isIntro, isIntro) || other.isIntro == isIntro) &&
            (identical(other.introEndsOn, introEndsOn) ||
                other.introEndsOn == introEndsOn) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    accountId,
    rateType,
    rate,
    isIntro,
    introEndsOn,
    isActive,
    label,
    createdAt,
  );

  /// Create a copy of CreditCardRate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreditCardRateImplCopyWith<_$CreditCardRateImpl> get copyWith =>
      __$$CreditCardRateImplCopyWithImpl<_$CreditCardRateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CreditCardRateImplToJson(this);
  }
}

abstract class _CreditCardRate implements CreditCardRate {
  const factory _CreditCardRate({
    required final String id,
    required final String accountId,
    required final CreditRateType rateType,
    required final double rate,
    required final bool isIntro,
    final DateTime? introEndsOn,
    required final bool isActive,
    final String? label,
    required final DateTime createdAt,
  }) = _$CreditCardRateImpl;

  factory _CreditCardRate.fromJson(Map<String, dynamic> json) =
      _$CreditCardRateImpl.fromJson;

  @override
  String get id;
  @override
  String get accountId;
  @override
  CreditRateType get rateType;

  /// Annual rate as a decimal (e.g. 0.2499 = 24.99%).
  @override
  double get rate;
  @override
  bool get isIntro;
  @override
  DateTime? get introEndsOn;
  @override
  bool get isActive;
  @override
  String? get label;
  @override
  DateTime get createdAt;

  /// Create a copy of CreditCardRate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreditCardRateImplCopyWith<_$CreditCardRateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
