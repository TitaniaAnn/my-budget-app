// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'target_allocation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TargetAllocation _$TargetAllocationFromJson(Map<String, dynamic> json) {
  return _TargetAllocation.fromJson(json);
}

/// @nodoc
mixin _$TargetAllocation {
  String get householdId => throw _privateConstructorUsedError;
  AssetClass get assetClass => throw _privateConstructorUsedError;

  /// Target weight in basis points (0–10000). The setter UI gates
  /// the full household sum to 100% before saving; individual rows
  /// don't carry that invariant — a partial set (stocks + bonds
  /// defined, no cash row) is valid and treated as 0% for the
  /// undefined classes.
  int get targetPctBp => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TargetAllocation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TargetAllocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TargetAllocationCopyWith<TargetAllocation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TargetAllocationCopyWith<$Res> {
  factory $TargetAllocationCopyWith(
    TargetAllocation value,
    $Res Function(TargetAllocation) then,
  ) = _$TargetAllocationCopyWithImpl<$Res, TargetAllocation>;
  @useResult
  $Res call({
    String householdId,
    AssetClass assetClass,
    int targetPctBp,
    String? createdBy,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$TargetAllocationCopyWithImpl<$Res, $Val extends TargetAllocation>
    implements $TargetAllocationCopyWith<$Res> {
  _$TargetAllocationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TargetAllocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? householdId = null,
    Object? assetClass = null,
    Object? targetPctBp = null,
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
            assetClass: null == assetClass
                ? _value.assetClass
                : assetClass // ignore: cast_nullable_to_non_nullable
                      as AssetClass,
            targetPctBp: null == targetPctBp
                ? _value.targetPctBp
                : targetPctBp // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$TargetAllocationImplCopyWith<$Res>
    implements $TargetAllocationCopyWith<$Res> {
  factory _$$TargetAllocationImplCopyWith(
    _$TargetAllocationImpl value,
    $Res Function(_$TargetAllocationImpl) then,
  ) = __$$TargetAllocationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String householdId,
    AssetClass assetClass,
    int targetPctBp,
    String? createdBy,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$TargetAllocationImplCopyWithImpl<$Res>
    extends _$TargetAllocationCopyWithImpl<$Res, _$TargetAllocationImpl>
    implements _$$TargetAllocationImplCopyWith<$Res> {
  __$$TargetAllocationImplCopyWithImpl(
    _$TargetAllocationImpl _value,
    $Res Function(_$TargetAllocationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TargetAllocation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? householdId = null,
    Object? assetClass = null,
    Object? targetPctBp = null,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$TargetAllocationImpl(
        householdId: null == householdId
            ? _value.householdId
            : householdId // ignore: cast_nullable_to_non_nullable
                  as String,
        assetClass: null == assetClass
            ? _value.assetClass
            : assetClass // ignore: cast_nullable_to_non_nullable
                  as AssetClass,
        targetPctBp: null == targetPctBp
            ? _value.targetPctBp
            : targetPctBp // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$TargetAllocationImpl implements _TargetAllocation {
  const _$TargetAllocationImpl({
    required this.householdId,
    required this.assetClass,
    required this.targetPctBp,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$TargetAllocationImpl.fromJson(Map<String, dynamic> json) =>
      _$$TargetAllocationImplFromJson(json);

  @override
  final String householdId;
  @override
  final AssetClass assetClass;

  /// Target weight in basis points (0–10000). The setter UI gates
  /// the full household sum to 100% before saving; individual rows
  /// don't carry that invariant — a partial set (stocks + bonds
  /// defined, no cash row) is valid and treated as 0% for the
  /// undefined classes.
  @override
  final int targetPctBp;
  @override
  final String? createdBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'TargetAllocation(householdId: $householdId, assetClass: $assetClass, targetPctBp: $targetPctBp, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TargetAllocationImpl &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.assetClass, assetClass) ||
                other.assetClass == assetClass) &&
            (identical(other.targetPctBp, targetPctBp) ||
                other.targetPctBp == targetPctBp) &&
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
    assetClass,
    targetPctBp,
    createdBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of TargetAllocation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TargetAllocationImplCopyWith<_$TargetAllocationImpl> get copyWith =>
      __$$TargetAllocationImplCopyWithImpl<_$TargetAllocationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TargetAllocationImplToJson(this);
  }
}

abstract class _TargetAllocation implements TargetAllocation {
  const factory _TargetAllocation({
    required final String householdId,
    required final AssetClass assetClass,
    required final int targetPctBp,
    final String? createdBy,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$TargetAllocationImpl;

  factory _TargetAllocation.fromJson(Map<String, dynamic> json) =
      _$TargetAllocationImpl.fromJson;

  @override
  String get householdId;
  @override
  AssetClass get assetClass;

  /// Target weight in basis points (0–10000). The setter UI gates
  /// the full household sum to 100% before saving; individual rows
  /// don't carry that invariant — a partial set (stocks + bonds
  /// defined, no cash row) is valid and treated as 0% for the
  /// undefined classes.
  @override
  int get targetPctBp;
  @override
  String? get createdBy;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of TargetAllocation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TargetAllocationImplCopyWith<_$TargetAllocationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
