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

DebtPayoffTarget _$DebtPayoffTargetFromJson(Map<String, dynamic> json) {
  return _DebtPayoffTarget.fromJson(json);
}

/// @nodoc
mixin _$DebtPayoffTarget {
  /// References accounts.id. The simulator snapshots the
  /// account's current_balance at plan-creation time below;
  /// the account_id is kept so the UI can resolve the name +
  /// honour deletes (a target whose account is gone is
  /// silently dropped from the projection).
  @JsonKey(name: 'account_id')
  String get accountId => throw _privateConstructorUsedError;

  /// Minimum required payment per month (cents). Auto-computed
  /// at creation time from balance + APR; the user can override
  /// to match their actual statement minimum.
  @JsonKey(name: 'min_payment_cents')
  int get minPaymentCents => throw _privateConstructorUsedError;

  /// APR in basis points. Captured per-target so a saved plan
  /// stays stable if the account's interest_rate changes — same
  /// reasoning as scenario_events.payoff_apr_bps.
  @JsonKey(name: 'apr_bps')
  int get aprBps => throw _privateConstructorUsedError;

  /// For [DebtPayoffStrategy.custom]: extra-over-minimum to
  /// pay on this debt each month. Null/zero on avalanche or
  /// snowball strategies (the simulator computes extras itself).
  @JsonKey(name: 'extra_payment_cents')
  int? get extraPaymentCents => throw _privateConstructorUsedError;

  /// Serializes this DebtPayoffTarget to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DebtPayoffTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DebtPayoffTargetCopyWith<DebtPayoffTarget> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DebtPayoffTargetCopyWith<$Res> {
  factory $DebtPayoffTargetCopyWith(
    DebtPayoffTarget value,
    $Res Function(DebtPayoffTarget) then,
  ) = _$DebtPayoffTargetCopyWithImpl<$Res, DebtPayoffTarget>;
  @useResult
  $Res call({
    @JsonKey(name: 'account_id') String accountId,
    @JsonKey(name: 'min_payment_cents') int minPaymentCents,
    @JsonKey(name: 'apr_bps') int aprBps,
    @JsonKey(name: 'extra_payment_cents') int? extraPaymentCents,
  });
}

/// @nodoc
class _$DebtPayoffTargetCopyWithImpl<$Res, $Val extends DebtPayoffTarget>
    implements $DebtPayoffTargetCopyWith<$Res> {
  _$DebtPayoffTargetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DebtPayoffTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? minPaymentCents = null,
    Object? aprBps = null,
    Object? extraPaymentCents = freezed,
  }) {
    return _then(
      _value.copyWith(
            accountId: null == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String,
            minPaymentCents: null == minPaymentCents
                ? _value.minPaymentCents
                : minPaymentCents // ignore: cast_nullable_to_non_nullable
                      as int,
            aprBps: null == aprBps
                ? _value.aprBps
                : aprBps // ignore: cast_nullable_to_non_nullable
                      as int,
            extraPaymentCents: freezed == extraPaymentCents
                ? _value.extraPaymentCents
                : extraPaymentCents // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DebtPayoffTargetImplCopyWith<$Res>
    implements $DebtPayoffTargetCopyWith<$Res> {
  factory _$$DebtPayoffTargetImplCopyWith(
    _$DebtPayoffTargetImpl value,
    $Res Function(_$DebtPayoffTargetImpl) then,
  ) = __$$DebtPayoffTargetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'account_id') String accountId,
    @JsonKey(name: 'min_payment_cents') int minPaymentCents,
    @JsonKey(name: 'apr_bps') int aprBps,
    @JsonKey(name: 'extra_payment_cents') int? extraPaymentCents,
  });
}

/// @nodoc
class __$$DebtPayoffTargetImplCopyWithImpl<$Res>
    extends _$DebtPayoffTargetCopyWithImpl<$Res, _$DebtPayoffTargetImpl>
    implements _$$DebtPayoffTargetImplCopyWith<$Res> {
  __$$DebtPayoffTargetImplCopyWithImpl(
    _$DebtPayoffTargetImpl _value,
    $Res Function(_$DebtPayoffTargetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DebtPayoffTarget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? minPaymentCents = null,
    Object? aprBps = null,
    Object? extraPaymentCents = freezed,
  }) {
    return _then(
      _$DebtPayoffTargetImpl(
        accountId: null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
        minPaymentCents: null == minPaymentCents
            ? _value.minPaymentCents
            : minPaymentCents // ignore: cast_nullable_to_non_nullable
                  as int,
        aprBps: null == aprBps
            ? _value.aprBps
            : aprBps // ignore: cast_nullable_to_non_nullable
                  as int,
        extraPaymentCents: freezed == extraPaymentCents
            ? _value.extraPaymentCents
            : extraPaymentCents // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DebtPayoffTargetImpl implements _DebtPayoffTarget {
  const _$DebtPayoffTargetImpl({
    @JsonKey(name: 'account_id') required this.accountId,
    @JsonKey(name: 'min_payment_cents') required this.minPaymentCents,
    @JsonKey(name: 'apr_bps') required this.aprBps,
    @JsonKey(name: 'extra_payment_cents') this.extraPaymentCents,
  });

  factory _$DebtPayoffTargetImpl.fromJson(Map<String, dynamic> json) =>
      _$$DebtPayoffTargetImplFromJson(json);

  /// References accounts.id. The simulator snapshots the
  /// account's current_balance at plan-creation time below;
  /// the account_id is kept so the UI can resolve the name +
  /// honour deletes (a target whose account is gone is
  /// silently dropped from the projection).
  @override
  @JsonKey(name: 'account_id')
  final String accountId;

  /// Minimum required payment per month (cents). Auto-computed
  /// at creation time from balance + APR; the user can override
  /// to match their actual statement minimum.
  @override
  @JsonKey(name: 'min_payment_cents')
  final int minPaymentCents;

  /// APR in basis points. Captured per-target so a saved plan
  /// stays stable if the account's interest_rate changes — same
  /// reasoning as scenario_events.payoff_apr_bps.
  @override
  @JsonKey(name: 'apr_bps')
  final int aprBps;

  /// For [DebtPayoffStrategy.custom]: extra-over-minimum to
  /// pay on this debt each month. Null/zero on avalanche or
  /// snowball strategies (the simulator computes extras itself).
  @override
  @JsonKey(name: 'extra_payment_cents')
  final int? extraPaymentCents;

  @override
  String toString() {
    return 'DebtPayoffTarget(accountId: $accountId, minPaymentCents: $minPaymentCents, aprBps: $aprBps, extraPaymentCents: $extraPaymentCents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DebtPayoffTargetImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.minPaymentCents, minPaymentCents) ||
                other.minPaymentCents == minPaymentCents) &&
            (identical(other.aprBps, aprBps) || other.aprBps == aprBps) &&
            (identical(other.extraPaymentCents, extraPaymentCents) ||
                other.extraPaymentCents == extraPaymentCents));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    accountId,
    minPaymentCents,
    aprBps,
    extraPaymentCents,
  );

  /// Create a copy of DebtPayoffTarget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DebtPayoffTargetImplCopyWith<_$DebtPayoffTargetImpl> get copyWith =>
      __$$DebtPayoffTargetImplCopyWithImpl<_$DebtPayoffTargetImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$DebtPayoffTargetImplToJson(this);
  }
}

abstract class _DebtPayoffTarget implements DebtPayoffTarget {
  const factory _DebtPayoffTarget({
    @JsonKey(name: 'account_id') required final String accountId,
    @JsonKey(name: 'min_payment_cents') required final int minPaymentCents,
    @JsonKey(name: 'apr_bps') required final int aprBps,
    @JsonKey(name: 'extra_payment_cents') final int? extraPaymentCents,
  }) = _$DebtPayoffTargetImpl;

  factory _DebtPayoffTarget.fromJson(Map<String, dynamic> json) =
      _$DebtPayoffTargetImpl.fromJson;

  /// References accounts.id. The simulator snapshots the
  /// account's current_balance at plan-creation time below;
  /// the account_id is kept so the UI can resolve the name +
  /// honour deletes (a target whose account is gone is
  /// silently dropped from the projection).
  @override
  @JsonKey(name: 'account_id')
  String get accountId;

  /// Minimum required payment per month (cents). Auto-computed
  /// at creation time from balance + APR; the user can override
  /// to match their actual statement minimum.
  @override
  @JsonKey(name: 'min_payment_cents')
  int get minPaymentCents;

  /// APR in basis points. Captured per-target so a saved plan
  /// stays stable if the account's interest_rate changes — same
  /// reasoning as scenario_events.payoff_apr_bps.
  @override
  @JsonKey(name: 'apr_bps')
  int get aprBps;

  /// For [DebtPayoffStrategy.custom]: extra-over-minimum to
  /// pay on this debt each month. Null/zero on avalanche or
  /// snowball strategies (the simulator computes extras itself).
  @override
  @JsonKey(name: 'extra_payment_cents')
  int? get extraPaymentCents;

  /// Create a copy of DebtPayoffTarget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DebtPayoffTargetImplCopyWith<_$DebtPayoffTargetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

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

  /// Which kind of scenario this is. Defaults to general so
  /// existing rows (where the column has the SQL default) decode
  /// cleanly. See [ScenarioKind] for the semantics.
  ScenarioKind get kind => throw _privateConstructorUsedError;

  /// Debt-payoff target list. Null for kind=general. The freezed
  /// JSON converter handles the JSONB column directly.
  @JsonKey(name: 'debt_payoff_targets')
  List<DebtPayoffTarget>? get debtPayoffTargets =>
      throw _privateConstructorUsedError;

  /// Strategy for allocating extra-over-minimum payment across
  /// the targets. Null for kind=general.
  @JsonKey(name: 'debt_payoff_strategy')
  DebtPayoffStrategy? get debtPayoffStrategy =>
      throw _privateConstructorUsedError;

  /// Total monthly $ the user is committing across all debts in
  /// the plan (cents). Null for kind=general.
  @JsonKey(name: 'debt_payoff_monthly_budget_cents')
  int? get debtPayoffMonthlyBudgetCents => throw _privateConstructorUsedError;

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
    ScenarioKind kind,
    @JsonKey(name: 'debt_payoff_targets')
    List<DebtPayoffTarget>? debtPayoffTargets,
    @JsonKey(name: 'debt_payoff_strategy')
    DebtPayoffStrategy? debtPayoffStrategy,
    @JsonKey(name: 'debt_payoff_monthly_budget_cents')
    int? debtPayoffMonthlyBudgetCents,
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
    Object? kind = null,
    Object? debtPayoffTargets = freezed,
    Object? debtPayoffStrategy = freezed,
    Object? debtPayoffMonthlyBudgetCents = freezed,
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
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as ScenarioKind,
            debtPayoffTargets: freezed == debtPayoffTargets
                ? _value.debtPayoffTargets
                : debtPayoffTargets // ignore: cast_nullable_to_non_nullable
                      as List<DebtPayoffTarget>?,
            debtPayoffStrategy: freezed == debtPayoffStrategy
                ? _value.debtPayoffStrategy
                : debtPayoffStrategy // ignore: cast_nullable_to_non_nullable
                      as DebtPayoffStrategy?,
            debtPayoffMonthlyBudgetCents:
                freezed == debtPayoffMonthlyBudgetCents
                ? _value.debtPayoffMonthlyBudgetCents
                : debtPayoffMonthlyBudgetCents // ignore: cast_nullable_to_non_nullable
                      as int?,
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
    ScenarioKind kind,
    @JsonKey(name: 'debt_payoff_targets')
    List<DebtPayoffTarget>? debtPayoffTargets,
    @JsonKey(name: 'debt_payoff_strategy')
    DebtPayoffStrategy? debtPayoffStrategy,
    @JsonKey(name: 'debt_payoff_monthly_budget_cents')
    int? debtPayoffMonthlyBudgetCents,
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
    Object? kind = null,
    Object? debtPayoffTargets = freezed,
    Object? debtPayoffStrategy = freezed,
    Object? debtPayoffMonthlyBudgetCents = freezed,
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
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as ScenarioKind,
        debtPayoffTargets: freezed == debtPayoffTargets
            ? _value._debtPayoffTargets
            : debtPayoffTargets // ignore: cast_nullable_to_non_nullable
                  as List<DebtPayoffTarget>?,
        debtPayoffStrategy: freezed == debtPayoffStrategy
            ? _value.debtPayoffStrategy
            : debtPayoffStrategy // ignore: cast_nullable_to_non_nullable
                  as DebtPayoffStrategy?,
        debtPayoffMonthlyBudgetCents: freezed == debtPayoffMonthlyBudgetCents
            ? _value.debtPayoffMonthlyBudgetCents
            : debtPayoffMonthlyBudgetCents // ignore: cast_nullable_to_non_nullable
                  as int?,
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
    this.kind = ScenarioKind.general,
    @JsonKey(name: 'debt_payoff_targets')
    final List<DebtPayoffTarget>? debtPayoffTargets,
    @JsonKey(name: 'debt_payoff_strategy') this.debtPayoffStrategy,
    @JsonKey(name: 'debt_payoff_monthly_budget_cents')
    this.debtPayoffMonthlyBudgetCents,
  }) : _debtPayoffTargets = debtPayoffTargets;

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

  /// Which kind of scenario this is. Defaults to general so
  /// existing rows (where the column has the SQL default) decode
  /// cleanly. See [ScenarioKind] for the semantics.
  @override
  @JsonKey()
  final ScenarioKind kind;

  /// Debt-payoff target list. Null for kind=general. The freezed
  /// JSON converter handles the JSONB column directly.
  final List<DebtPayoffTarget>? _debtPayoffTargets;

  /// Debt-payoff target list. Null for kind=general. The freezed
  /// JSON converter handles the JSONB column directly.
  @override
  @JsonKey(name: 'debt_payoff_targets')
  List<DebtPayoffTarget>? get debtPayoffTargets {
    final value = _debtPayoffTargets;
    if (value == null) return null;
    if (_debtPayoffTargets is EqualUnmodifiableListView)
      return _debtPayoffTargets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Strategy for allocating extra-over-minimum payment across
  /// the targets. Null for kind=general.
  @override
  @JsonKey(name: 'debt_payoff_strategy')
  final DebtPayoffStrategy? debtPayoffStrategy;

  /// Total monthly $ the user is committing across all debts in
  /// the plan (cents). Null for kind=general.
  @override
  @JsonKey(name: 'debt_payoff_monthly_budget_cents')
  final int? debtPayoffMonthlyBudgetCents;

  @override
  String toString() {
    return 'Scenario(id: $id, householdId: $householdId, createdBy: $createdBy, parentId: $parentId, name: $name, description: $description, baseDate: $baseDate, isBaseline: $isBaseline, color: $color, isGoal: $isGoal, targetAmount: $targetAmount, targetDate: $targetDate, createdAt: $createdAt, updatedAt: $updatedAt, kind: $kind, debtPayoffTargets: $debtPayoffTargets, debtPayoffStrategy: $debtPayoffStrategy, debtPayoffMonthlyBudgetCents: $debtPayoffMonthlyBudgetCents)';
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
                other.updatedAt == updatedAt) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            const DeepCollectionEquality().equals(
              other._debtPayoffTargets,
              _debtPayoffTargets,
            ) &&
            (identical(other.debtPayoffStrategy, debtPayoffStrategy) ||
                other.debtPayoffStrategy == debtPayoffStrategy) &&
            (identical(
                  other.debtPayoffMonthlyBudgetCents,
                  debtPayoffMonthlyBudgetCents,
                ) ||
                other.debtPayoffMonthlyBudgetCents ==
                    debtPayoffMonthlyBudgetCents));
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
    kind,
    const DeepCollectionEquality().hash(_debtPayoffTargets),
    debtPayoffStrategy,
    debtPayoffMonthlyBudgetCents,
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
    final ScenarioKind kind,
    @JsonKey(name: 'debt_payoff_targets')
    final List<DebtPayoffTarget>? debtPayoffTargets,
    @JsonKey(name: 'debt_payoff_strategy')
    final DebtPayoffStrategy? debtPayoffStrategy,
    @JsonKey(name: 'debt_payoff_monthly_budget_cents')
    final int? debtPayoffMonthlyBudgetCents,
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

  /// Which kind of scenario this is. Defaults to general so
  /// existing rows (where the column has the SQL default) decode
  /// cleanly. See [ScenarioKind] for the semantics.
  @override
  ScenarioKind get kind;

  /// Debt-payoff target list. Null for kind=general. The freezed
  /// JSON converter handles the JSONB column directly.
  @override
  @JsonKey(name: 'debt_payoff_targets')
  List<DebtPayoffTarget>? get debtPayoffTargets;

  /// Strategy for allocating extra-over-minimum payment across
  /// the targets. Null for kind=general.
  @override
  @JsonKey(name: 'debt_payoff_strategy')
  DebtPayoffStrategy? get debtPayoffStrategy;

  /// Total monthly $ the user is committing across all debts in
  /// the plan (cents). Null for kind=general.
  @override
  @JsonKey(name: 'debt_payoff_monthly_budget_cents')
  int? get debtPayoffMonthlyBudgetCents;

  /// Create a copy of Scenario
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScenarioImplCopyWith<_$ScenarioImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
