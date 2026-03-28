// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scenario.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Scenario _$ScenarioFromJson(Map<String, dynamic> json) {
  return _Scenario.fromJson(json);
}

/// @nodoc
mixin _$Scenario {
  String get id => throw _privateConstructorUsedError;
  String get householdId => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;

  /// Optional parent scenario this was branched from.
  String? get parentId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// The date from which projection starts (usually today or a future date).
  DateTime get baseDate => throw _privateConstructorUsedError;

  /// True when this scenario represents the unmodified baseline (no events).
  bool get isBaseline => throw _privateConstructorUsedError;

  /// Hex color for the chart line and card accent (e.g. "#6366F1").
  String? get color => throw _privateConstructorUsedError;

  /// When true this scenario is tracked as a financial goal.
  bool get isGoal => throw _privateConstructorUsedError;

  /// Target net-worth in cents the user wants to reach (goals only).
  int? get targetAmount => throw _privateConstructorUsedError;

  /// Deadline for hitting [targetAmount] (goals only).
  DateTime? get targetDate => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Scenario to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Scenario
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScenarioCopyWith<Scenario> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioCopyWith<$Res> {
  factory $ScenarioCopyWith(Scenario value, $Res Function(Scenario) then) =
      _$ScenarioCopyWithImpl<$Res, Scenario>;
  @useResult
  $Res call({
    String id,
    String householdId,
    String createdBy,
    String? parentId,
    String name,
    String? description,
    DateTime baseDate,
    bool isBaseline,
    String? color,
    bool isGoal,
    int? targetAmount,
    DateTime? targetDate,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$ScenarioCopyWithImpl<$Res, $Val extends Scenario>
    implements $ScenarioCopyWith<$Res> {
  _$ScenarioCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Scenario
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? createdBy = null,
    Object? parentId = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? baseDate = null,
    Object? isBaseline = null,
    Object? color = freezed,
    Object? isGoal = null,
    Object? targetAmount = freezed,
    Object? targetDate = freezed,
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
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            parentId: freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            baseDate: null == baseDate
                ? _value.baseDate
                : baseDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            isBaseline: null == isBaseline
                ? _value.isBaseline
                : isBaseline // ignore: cast_nullable_to_non_nullable
                      as bool,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            isGoal: null == isGoal
                ? _value.isGoal
                : isGoal // ignore: cast_nullable_to_non_nullable
                      as bool,
            targetAmount: freezed == targetAmount
                ? _value.targetAmount
                : targetAmount // ignore: cast_nullable_to_non_nullable
                      as int?,
            targetDate: freezed == targetDate
                ? _value.targetDate
                : targetDate // ignore: cast_nullable_to_non_nullable
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
abstract class _$$ScenarioImplCopyWith<$Res>
    implements $ScenarioCopyWith<$Res> {
  factory _$$ScenarioImplCopyWith(
    _$ScenarioImpl value,
    $Res Function(_$ScenarioImpl) then,
  ) = __$$ScenarioImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String householdId,
    String createdBy,
    String? parentId,
    String name,
    String? description,
    DateTime baseDate,
    bool isBaseline,
    String? color,
    bool isGoal,
    int? targetAmount,
    DateTime? targetDate,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$ScenarioImplCopyWithImpl<$Res>
    extends _$ScenarioCopyWithImpl<$Res, _$ScenarioImpl>
    implements _$$ScenarioImplCopyWith<$Res> {
  __$$ScenarioImplCopyWithImpl(
    _$ScenarioImpl _value,
    $Res Function(_$ScenarioImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Scenario
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? createdBy = null,
    Object? parentId = freezed,
    Object? name = null,
    Object? description = freezed,
    Object? baseDate = null,
    Object? isBaseline = null,
    Object? color = freezed,
    Object? isGoal = null,
    Object? targetAmount = freezed,
    Object? targetDate = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ScenarioImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        householdId: null == householdId
            ? _value.householdId
            : householdId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        parentId: freezed == parentId
            ? _value.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        baseDate: null == baseDate
            ? _value.baseDate
            : baseDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        isBaseline: null == isBaseline
            ? _value.isBaseline
            : isBaseline // ignore: cast_nullable_to_non_nullable
                  as bool,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        isGoal: null == isGoal
            ? _value.isGoal
            : isGoal // ignore: cast_nullable_to_non_nullable
                  as bool,
        targetAmount: freezed == targetAmount
            ? _value.targetAmount
            : targetAmount // ignore: cast_nullable_to_non_nullable
                  as int?,
        targetDate: freezed == targetDate
            ? _value.targetDate
            : targetDate // ignore: cast_nullable_to_non_nullable
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
class _$ScenarioImpl implements _Scenario {
  const _$ScenarioImpl({
    required this.id,
    required this.householdId,
    required this.createdBy,
    this.parentId,
    required this.name,
    this.description,
    required this.baseDate,
    required this.isBaseline,
    this.color,
    required this.isGoal,
    this.targetAmount,
    this.targetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$ScenarioImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioImplFromJson(json);

  @override
  final String id;
  @override
  final String householdId;
  @override
  final String createdBy;

  /// Optional parent scenario this was branched from.
  @override
  final String? parentId;
  @override
  final String name;
  @override
  final String? description;

  /// The date from which projection starts (usually today or a future date).
  @override
  final DateTime baseDate;

  /// True when this scenario represents the unmodified baseline (no events).
  @override
  final bool isBaseline;

  /// Hex color for the chart line and card accent (e.g. "#6366F1").
  @override
  final String? color;

  /// When true this scenario is tracked as a financial goal.
  @override
  final bool isGoal;

  /// Target net-worth in cents the user wants to reach (goals only).
  @override
  final int? targetAmount;

  /// Deadline for hitting [targetAmount] (goals only).
  @override
  final DateTime? targetDate;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Scenario(id: $id, householdId: $householdId, createdBy: $createdBy, parentId: $parentId, name: $name, description: $description, baseDate: $baseDate, isBaseline: $isBaseline, color: $color, isGoal: $isGoal, targetAmount: $targetAmount, targetDate: $targetDate, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.baseDate, baseDate) ||
                other.baseDate == baseDate) &&
            (identical(other.isBaseline, isBaseline) ||
                other.isBaseline == isBaseline) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isGoal, isGoal) || other.isGoal == isGoal) &&
            (identical(other.targetAmount, targetAmount) ||
                other.targetAmount == targetAmount) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
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
    createdBy,
    parentId,
    name,
    description,
    baseDate,
    isBaseline,
    color,
    isGoal,
    targetAmount,
    targetDate,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Scenario
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioImplCopyWith<_$ScenarioImpl> get copyWith =>
      __$$ScenarioImplCopyWithImpl<_$ScenarioImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioImplToJson(this);
  }
}

abstract class _Scenario implements Scenario {
  const factory _Scenario({
    required final String id,
    required final String householdId,
    required final String createdBy,
    final String? parentId,
    required final String name,
    final String? description,
    required final DateTime baseDate,
    required final bool isBaseline,
    final String? color,
    required final bool isGoal,
    final int? targetAmount,
    final DateTime? targetDate,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$ScenarioImpl;

  factory _Scenario.fromJson(Map<String, dynamic> json) =
      _$ScenarioImpl.fromJson;

  @override
  String get id;
  @override
  String get householdId;
  @override
  String get createdBy;

  /// Optional parent scenario this was branched from.
  @override
  String? get parentId;
  @override
  String get name;
  @override
  String? get description;

  /// The date from which projection starts (usually today or a future date).
  @override
  DateTime get baseDate;

  /// True when this scenario represents the unmodified baseline (no events).
  @override
  bool get isBaseline;

  /// Hex color for the chart line and card accent (e.g. "#6366F1").
  @override
  String? get color;

  /// When true this scenario is tracked as a financial goal.
  @override
  bool get isGoal;

  /// Target net-worth in cents the user wants to reach (goals only).
  @override
  int? get targetAmount;

  /// Deadline for hitting [targetAmount] (goals only).
  @override
  DateTime? get targetDate;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Scenario
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScenarioImplCopyWith<_$ScenarioImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
