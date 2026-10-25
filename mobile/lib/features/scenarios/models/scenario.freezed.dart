// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scenario.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OneOffPayment {

/// Calendar date the payment lands. The simulator buckets it
/// to the iteration whose monthEnd shares the same year+month.
 DateTime get date;/// Magnitude in cents (positive).
@JsonKey(name: 'amount_cents') int get amountCents;/// Optional — when set, the lump-sum pre-pays this specific
/// debt (bypasses strategy). Null = strategy-routed.
@JsonKey(name: 'account_id') String? get accountId;
/// Create a copy of OneOffPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OneOffPaymentCopyWith<OneOffPayment> get copyWith => _$OneOffPaymentCopyWithImpl<OneOffPayment>(this as OneOffPayment, _$identity);

  /// Serializes this OneOffPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OneOffPayment&&(identical(other.date, date) || other.date == date)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,amountCents,accountId);

@override
String toString() {
  return 'OneOffPayment(date: $date, amountCents: $amountCents, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class $OneOffPaymentCopyWith<$Res>  {
  factory $OneOffPaymentCopyWith(OneOffPayment value, $Res Function(OneOffPayment) _then) = _$OneOffPaymentCopyWithImpl;
@useResult
$Res call({
 DateTime date,@JsonKey(name: 'amount_cents') int amountCents,@JsonKey(name: 'account_id') String? accountId
});




}
/// @nodoc
class _$OneOffPaymentCopyWithImpl<$Res>
    implements $OneOffPaymentCopyWith<$Res> {
  _$OneOffPaymentCopyWithImpl(this._self, this._then);

  final OneOffPayment _self;
  final $Res Function(OneOffPayment) _then;

/// Create a copy of OneOffPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? amountCents = null,Object? accountId = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OneOffPayment].
extension OneOffPaymentPatterns on OneOffPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OneOffPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OneOffPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OneOffPayment value)  $default,){
final _that = this;
switch (_that) {
case _OneOffPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OneOffPayment value)?  $default,){
final _that = this;
switch (_that) {
case _OneOffPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date, @JsonKey(name: 'amount_cents')  int amountCents, @JsonKey(name: 'account_id')  String? accountId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OneOffPayment() when $default != null:
return $default(_that.date,_that.amountCents,_that.accountId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date, @JsonKey(name: 'amount_cents')  int amountCents, @JsonKey(name: 'account_id')  String? accountId)  $default,) {final _that = this;
switch (_that) {
case _OneOffPayment():
return $default(_that.date,_that.amountCents,_that.accountId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date, @JsonKey(name: 'amount_cents')  int amountCents, @JsonKey(name: 'account_id')  String? accountId)?  $default,) {final _that = this;
switch (_that) {
case _OneOffPayment() when $default != null:
return $default(_that.date,_that.amountCents,_that.accountId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OneOffPayment implements OneOffPayment {
  const _OneOffPayment({required this.date, @JsonKey(name: 'amount_cents') required this.amountCents, @JsonKey(name: 'account_id') this.accountId});
  factory _OneOffPayment.fromJson(Map<String, dynamic> json) => _$OneOffPaymentFromJson(json);

/// Calendar date the payment lands. The simulator buckets it
/// to the iteration whose monthEnd shares the same year+month.
@override final  DateTime date;
/// Magnitude in cents (positive).
@override@JsonKey(name: 'amount_cents') final  int amountCents;
/// Optional — when set, the lump-sum pre-pays this specific
/// debt (bypasses strategy). Null = strategy-routed.
@override@JsonKey(name: 'account_id') final  String? accountId;

/// Create a copy of OneOffPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OneOffPaymentCopyWith<_OneOffPayment> get copyWith => __$OneOffPaymentCopyWithImpl<_OneOffPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OneOffPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OneOffPayment&&(identical(other.date, date) || other.date == date)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.accountId, accountId) || other.accountId == accountId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,amountCents,accountId);

@override
String toString() {
  return 'OneOffPayment(date: $date, amountCents: $amountCents, accountId: $accountId)';
}


}

/// @nodoc
abstract mixin class _$OneOffPaymentCopyWith<$Res> implements $OneOffPaymentCopyWith<$Res> {
  factory _$OneOffPaymentCopyWith(_OneOffPayment value, $Res Function(_OneOffPayment) _then) = __$OneOffPaymentCopyWithImpl;
@override @useResult
$Res call({
 DateTime date,@JsonKey(name: 'amount_cents') int amountCents,@JsonKey(name: 'account_id') String? accountId
});




}
/// @nodoc
class __$OneOffPaymentCopyWithImpl<$Res>
    implements _$OneOffPaymentCopyWith<$Res> {
  __$OneOffPaymentCopyWithImpl(this._self, this._then);

  final _OneOffPayment _self;
  final $Res Function(_OneOffPayment) _then;

/// Create a copy of OneOffPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? amountCents = null,Object? accountId = freezed,}) {
  return _then(_OneOffPayment(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DebtPayoffTarget {

/// References accounts.id. The simulator snapshots the
/// account's current_balance at plan-creation time below;
/// the account_id is kept so the UI can resolve the name +
/// honour deletes (a target whose account is gone is
/// silently dropped from the projection).
@JsonKey(name: 'account_id') String get accountId;/// Minimum required payment per month (cents). Auto-computed
/// at creation time from balance + APR; the user can override
/// to match their actual statement minimum.
@JsonKey(name: 'min_payment_cents') int get minPaymentCents;/// APR in basis points. Captured per-target so a saved plan
/// stays stable if the account's interest_rate changes — same
/// reasoning as scenario_events.payoff_apr_bps.
@JsonKey(name: 'apr_bps') int get aprBps;/// For [DebtPayoffStrategy.custom]: extra-over-minimum to
/// pay on this debt each month. Null/zero on avalanche or
/// snowball strategies (the simulator computes extras itself).
@JsonKey(name: 'extra_payment_cents') int? get extraPaymentCents;
/// Create a copy of DebtPayoffTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtPayoffTargetCopyWith<DebtPayoffTarget> get copyWith => _$DebtPayoffTargetCopyWithImpl<DebtPayoffTarget>(this as DebtPayoffTarget, _$identity);

  /// Serializes this DebtPayoffTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DebtPayoffTarget&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.minPaymentCents, minPaymentCents) || other.minPaymentCents == minPaymentCents)&&(identical(other.aprBps, aprBps) || other.aprBps == aprBps)&&(identical(other.extraPaymentCents, extraPaymentCents) || other.extraPaymentCents == extraPaymentCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountId,minPaymentCents,aprBps,extraPaymentCents);

@override
String toString() {
  return 'DebtPayoffTarget(accountId: $accountId, minPaymentCents: $minPaymentCents, aprBps: $aprBps, extraPaymentCents: $extraPaymentCents)';
}


}

/// @nodoc
abstract mixin class $DebtPayoffTargetCopyWith<$Res>  {
  factory $DebtPayoffTargetCopyWith(DebtPayoffTarget value, $Res Function(DebtPayoffTarget) _then) = _$DebtPayoffTargetCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'min_payment_cents') int minPaymentCents,@JsonKey(name: 'apr_bps') int aprBps,@JsonKey(name: 'extra_payment_cents') int? extraPaymentCents
});




}
/// @nodoc
class _$DebtPayoffTargetCopyWithImpl<$Res>
    implements $DebtPayoffTargetCopyWith<$Res> {
  _$DebtPayoffTargetCopyWithImpl(this._self, this._then);

  final DebtPayoffTarget _self;
  final $Res Function(DebtPayoffTarget) _then;

/// Create a copy of DebtPayoffTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? minPaymentCents = null,Object? aprBps = null,Object? extraPaymentCents = freezed,}) {
  return _then(_self.copyWith(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,minPaymentCents: null == minPaymentCents ? _self.minPaymentCents : minPaymentCents // ignore: cast_nullable_to_non_nullable
as int,aprBps: null == aprBps ? _self.aprBps : aprBps // ignore: cast_nullable_to_non_nullable
as int,extraPaymentCents: freezed == extraPaymentCents ? _self.extraPaymentCents : extraPaymentCents // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DebtPayoffTarget].
extension DebtPayoffTargetPatterns on DebtPayoffTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DebtPayoffTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DebtPayoffTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DebtPayoffTarget value)  $default,){
final _that = this;
switch (_that) {
case _DebtPayoffTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DebtPayoffTarget value)?  $default,){
final _that = this;
switch (_that) {
case _DebtPayoffTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'min_payment_cents')  int minPaymentCents, @JsonKey(name: 'apr_bps')  int aprBps, @JsonKey(name: 'extra_payment_cents')  int? extraPaymentCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DebtPayoffTarget() when $default != null:
return $default(_that.accountId,_that.minPaymentCents,_that.aprBps,_that.extraPaymentCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'min_payment_cents')  int minPaymentCents, @JsonKey(name: 'apr_bps')  int aprBps, @JsonKey(name: 'extra_payment_cents')  int? extraPaymentCents)  $default,) {final _that = this;
switch (_that) {
case _DebtPayoffTarget():
return $default(_that.accountId,_that.minPaymentCents,_that.aprBps,_that.extraPaymentCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'account_id')  String accountId, @JsonKey(name: 'min_payment_cents')  int minPaymentCents, @JsonKey(name: 'apr_bps')  int aprBps, @JsonKey(name: 'extra_payment_cents')  int? extraPaymentCents)?  $default,) {final _that = this;
switch (_that) {
case _DebtPayoffTarget() when $default != null:
return $default(_that.accountId,_that.minPaymentCents,_that.aprBps,_that.extraPaymentCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DebtPayoffTarget implements DebtPayoffTarget {
  const _DebtPayoffTarget({@JsonKey(name: 'account_id') required this.accountId, @JsonKey(name: 'min_payment_cents') required this.minPaymentCents, @JsonKey(name: 'apr_bps') required this.aprBps, @JsonKey(name: 'extra_payment_cents') this.extraPaymentCents});
  factory _DebtPayoffTarget.fromJson(Map<String, dynamic> json) => _$DebtPayoffTargetFromJson(json);

/// References accounts.id. The simulator snapshots the
/// account's current_balance at plan-creation time below;
/// the account_id is kept so the UI can resolve the name +
/// honour deletes (a target whose account is gone is
/// silently dropped from the projection).
@override@JsonKey(name: 'account_id') final  String accountId;
/// Minimum required payment per month (cents). Auto-computed
/// at creation time from balance + APR; the user can override
/// to match their actual statement minimum.
@override@JsonKey(name: 'min_payment_cents') final  int minPaymentCents;
/// APR in basis points. Captured per-target so a saved plan
/// stays stable if the account's interest_rate changes — same
/// reasoning as scenario_events.payoff_apr_bps.
@override@JsonKey(name: 'apr_bps') final  int aprBps;
/// For [DebtPayoffStrategy.custom]: extra-over-minimum to
/// pay on this debt each month. Null/zero on avalanche or
/// snowball strategies (the simulator computes extras itself).
@override@JsonKey(name: 'extra_payment_cents') final  int? extraPaymentCents;

/// Create a copy of DebtPayoffTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebtPayoffTargetCopyWith<_DebtPayoffTarget> get copyWith => __$DebtPayoffTargetCopyWithImpl<_DebtPayoffTarget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtPayoffTargetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DebtPayoffTarget&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.minPaymentCents, minPaymentCents) || other.minPaymentCents == minPaymentCents)&&(identical(other.aprBps, aprBps) || other.aprBps == aprBps)&&(identical(other.extraPaymentCents, extraPaymentCents) || other.extraPaymentCents == extraPaymentCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accountId,minPaymentCents,aprBps,extraPaymentCents);

@override
String toString() {
  return 'DebtPayoffTarget(accountId: $accountId, minPaymentCents: $minPaymentCents, aprBps: $aprBps, extraPaymentCents: $extraPaymentCents)';
}


}

/// @nodoc
abstract mixin class _$DebtPayoffTargetCopyWith<$Res> implements $DebtPayoffTargetCopyWith<$Res> {
  factory _$DebtPayoffTargetCopyWith(_DebtPayoffTarget value, $Res Function(_DebtPayoffTarget) _then) = __$DebtPayoffTargetCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'account_id') String accountId,@JsonKey(name: 'min_payment_cents') int minPaymentCents,@JsonKey(name: 'apr_bps') int aprBps,@JsonKey(name: 'extra_payment_cents') int? extraPaymentCents
});




}
/// @nodoc
class __$DebtPayoffTargetCopyWithImpl<$Res>
    implements _$DebtPayoffTargetCopyWith<$Res> {
  __$DebtPayoffTargetCopyWithImpl(this._self, this._then);

  final _DebtPayoffTarget _self;
  final $Res Function(_DebtPayoffTarget) _then;

/// Create a copy of DebtPayoffTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? minPaymentCents = null,Object? aprBps = null,Object? extraPaymentCents = freezed,}) {
  return _then(_DebtPayoffTarget(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String,minPaymentCents: null == minPaymentCents ? _self.minPaymentCents : minPaymentCents // ignore: cast_nullable_to_non_nullable
as int,aprBps: null == aprBps ? _self.aprBps : aprBps // ignore: cast_nullable_to_non_nullable
as int,extraPaymentCents: freezed == extraPaymentCents ? _self.extraPaymentCents : extraPaymentCents // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Scenario {

 String get id; String get householdId; String get createdBy;/// Optional parent scenario this was branched from.
 String? get parentId; String get name; String? get description;/// The date from which projection starts (usually today or a future date).
 DateTime get baseDate;/// True when this scenario represents the unmodified baseline (no events).
 bool get isBaseline;/// Hex color for the chart line and card accent (e.g. "#6366F1").
 String? get color;/// When true this scenario is tracked as a financial goal.
 bool get isGoal;/// Target net-worth in cents the user wants to reach (goals only).
 int? get targetAmount;/// Deadline for hitting [targetAmount] (goals only).
 DateTime? get targetDate; DateTime get createdAt; DateTime get updatedAt;/// Which kind of scenario this is. Defaults to general so
/// existing rows (where the column has the SQL default) decode
/// cleanly. See [ScenarioKind] for the semantics.
 ScenarioKind get kind;/// Debt-payoff target list. Null for kind=general. The freezed
/// JSON converter handles the JSONB column directly.
@JsonKey(name: 'debt_payoff_targets') List<DebtPayoffTarget>? get debtPayoffTargets;/// Strategy for allocating extra-over-minimum payment across
/// the targets. Null for kind=general.
@JsonKey(name: 'debt_payoff_strategy') DebtPayoffStrategy? get debtPayoffStrategy;/// Total monthly $ the user is committing across all debts in
/// the plan (cents). Null for kind=general.
@JsonKey(name: 'debt_payoff_monthly_budget_cents') int? get debtPayoffMonthlyBudgetCents;/// Optional list of one-off lump-sum extra payments (tax
/// refunds, bonuses). Null for kind=general or until the user
/// adds one to a debt-payoff plan. See [OneOffPayment].
@JsonKey(name: 'debt_payoff_one_off_payments') List<OneOffPayment>? get debtPayoffOneOffPayments;
/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioCopyWith<Scenario> get copyWith => _$ScenarioCopyWithImpl<Scenario>(this as Scenario, _$identity);

  /// Serializes this Scenario to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Scenario&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.baseDate, baseDate) || other.baseDate == baseDate)&&(identical(other.isBaseline, isBaseline) || other.isBaseline == isBaseline)&&(identical(other.color, color) || other.color == color)&&(identical(other.isGoal, isGoal) || other.isGoal == isGoal)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.debtPayoffTargets, debtPayoffTargets)&&(identical(other.debtPayoffStrategy, debtPayoffStrategy) || other.debtPayoffStrategy == debtPayoffStrategy)&&(identical(other.debtPayoffMonthlyBudgetCents, debtPayoffMonthlyBudgetCents) || other.debtPayoffMonthlyBudgetCents == debtPayoffMonthlyBudgetCents)&&const DeepCollectionEquality().equals(other.debtPayoffOneOffPayments, debtPayoffOneOffPayments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,householdId,createdBy,parentId,name,description,baseDate,isBaseline,color,isGoal,targetAmount,targetDate,createdAt,updatedAt,kind,const DeepCollectionEquality().hash(debtPayoffTargets),debtPayoffStrategy,debtPayoffMonthlyBudgetCents,const DeepCollectionEquality().hash(debtPayoffOneOffPayments)]);

@override
String toString() {
  return 'Scenario(id: $id, householdId: $householdId, createdBy: $createdBy, parentId: $parentId, name: $name, description: $description, baseDate: $baseDate, isBaseline: $isBaseline, color: $color, isGoal: $isGoal, targetAmount: $targetAmount, targetDate: $targetDate, createdAt: $createdAt, updatedAt: $updatedAt, kind: $kind, debtPayoffTargets: $debtPayoffTargets, debtPayoffStrategy: $debtPayoffStrategy, debtPayoffMonthlyBudgetCents: $debtPayoffMonthlyBudgetCents, debtPayoffOneOffPayments: $debtPayoffOneOffPayments)';
}


}

/// @nodoc
abstract mixin class $ScenarioCopyWith<$Res>  {
  factory $ScenarioCopyWith(Scenario value, $Res Function(Scenario) _then) = _$ScenarioCopyWithImpl;
@useResult
$Res call({
 String id, String householdId, String createdBy, String? parentId, String name, String? description, DateTime baseDate, bool isBaseline, String? color, bool isGoal, int? targetAmount, DateTime? targetDate, DateTime createdAt, DateTime updatedAt, ScenarioKind kind,@JsonKey(name: 'debt_payoff_targets') List<DebtPayoffTarget>? debtPayoffTargets,@JsonKey(name: 'debt_payoff_strategy') DebtPayoffStrategy? debtPayoffStrategy,@JsonKey(name: 'debt_payoff_monthly_budget_cents') int? debtPayoffMonthlyBudgetCents,@JsonKey(name: 'debt_payoff_one_off_payments') List<OneOffPayment>? debtPayoffOneOffPayments
});




}
/// @nodoc
class _$ScenarioCopyWithImpl<$Res>
    implements $ScenarioCopyWith<$Res> {
  _$ScenarioCopyWithImpl(this._self, this._then);

  final Scenario _self;
  final $Res Function(Scenario) _then;

/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? householdId = null,Object? createdBy = null,Object? parentId = freezed,Object? name = null,Object? description = freezed,Object? baseDate = null,Object? isBaseline = null,Object? color = freezed,Object? isGoal = null,Object? targetAmount = freezed,Object? targetDate = freezed,Object? createdAt = null,Object? updatedAt = null,Object? kind = null,Object? debtPayoffTargets = freezed,Object? debtPayoffStrategy = freezed,Object? debtPayoffMonthlyBudgetCents = freezed,Object? debtPayoffOneOffPayments = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,baseDate: null == baseDate ? _self.baseDate : baseDate // ignore: cast_nullable_to_non_nullable
as DateTime,isBaseline: null == isBaseline ? _self.isBaseline : isBaseline // ignore: cast_nullable_to_non_nullable
as bool,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isGoal: null == isGoal ? _self.isGoal : isGoal // ignore: cast_nullable_to_non_nullable
as bool,targetAmount: freezed == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as int?,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ScenarioKind,debtPayoffTargets: freezed == debtPayoffTargets ? _self.debtPayoffTargets : debtPayoffTargets // ignore: cast_nullable_to_non_nullable
as List<DebtPayoffTarget>?,debtPayoffStrategy: freezed == debtPayoffStrategy ? _self.debtPayoffStrategy : debtPayoffStrategy // ignore: cast_nullable_to_non_nullable
as DebtPayoffStrategy?,debtPayoffMonthlyBudgetCents: freezed == debtPayoffMonthlyBudgetCents ? _self.debtPayoffMonthlyBudgetCents : debtPayoffMonthlyBudgetCents // ignore: cast_nullable_to_non_nullable
as int?,debtPayoffOneOffPayments: freezed == debtPayoffOneOffPayments ? _self.debtPayoffOneOffPayments : debtPayoffOneOffPayments // ignore: cast_nullable_to_non_nullable
as List<OneOffPayment>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Scenario].
extension ScenarioPatterns on Scenario {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Scenario value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Scenario() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Scenario value)  $default,){
final _that = this;
switch (_that) {
case _Scenario():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Scenario value)?  $default,){
final _that = this;
switch (_that) {
case _Scenario() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String householdId,  String createdBy,  String? parentId,  String name,  String? description,  DateTime baseDate,  bool isBaseline,  String? color,  bool isGoal,  int? targetAmount,  DateTime? targetDate,  DateTime createdAt,  DateTime updatedAt,  ScenarioKind kind, @JsonKey(name: 'debt_payoff_targets')  List<DebtPayoffTarget>? debtPayoffTargets, @JsonKey(name: 'debt_payoff_strategy')  DebtPayoffStrategy? debtPayoffStrategy, @JsonKey(name: 'debt_payoff_monthly_budget_cents')  int? debtPayoffMonthlyBudgetCents, @JsonKey(name: 'debt_payoff_one_off_payments')  List<OneOffPayment>? debtPayoffOneOffPayments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Scenario() when $default != null:
return $default(_that.id,_that.householdId,_that.createdBy,_that.parentId,_that.name,_that.description,_that.baseDate,_that.isBaseline,_that.color,_that.isGoal,_that.targetAmount,_that.targetDate,_that.createdAt,_that.updatedAt,_that.kind,_that.debtPayoffTargets,_that.debtPayoffStrategy,_that.debtPayoffMonthlyBudgetCents,_that.debtPayoffOneOffPayments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String householdId,  String createdBy,  String? parentId,  String name,  String? description,  DateTime baseDate,  bool isBaseline,  String? color,  bool isGoal,  int? targetAmount,  DateTime? targetDate,  DateTime createdAt,  DateTime updatedAt,  ScenarioKind kind, @JsonKey(name: 'debt_payoff_targets')  List<DebtPayoffTarget>? debtPayoffTargets, @JsonKey(name: 'debt_payoff_strategy')  DebtPayoffStrategy? debtPayoffStrategy, @JsonKey(name: 'debt_payoff_monthly_budget_cents')  int? debtPayoffMonthlyBudgetCents, @JsonKey(name: 'debt_payoff_one_off_payments')  List<OneOffPayment>? debtPayoffOneOffPayments)  $default,) {final _that = this;
switch (_that) {
case _Scenario():
return $default(_that.id,_that.householdId,_that.createdBy,_that.parentId,_that.name,_that.description,_that.baseDate,_that.isBaseline,_that.color,_that.isGoal,_that.targetAmount,_that.targetDate,_that.createdAt,_that.updatedAt,_that.kind,_that.debtPayoffTargets,_that.debtPayoffStrategy,_that.debtPayoffMonthlyBudgetCents,_that.debtPayoffOneOffPayments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String householdId,  String createdBy,  String? parentId,  String name,  String? description,  DateTime baseDate,  bool isBaseline,  String? color,  bool isGoal,  int? targetAmount,  DateTime? targetDate,  DateTime createdAt,  DateTime updatedAt,  ScenarioKind kind, @JsonKey(name: 'debt_payoff_targets')  List<DebtPayoffTarget>? debtPayoffTargets, @JsonKey(name: 'debt_payoff_strategy')  DebtPayoffStrategy? debtPayoffStrategy, @JsonKey(name: 'debt_payoff_monthly_budget_cents')  int? debtPayoffMonthlyBudgetCents, @JsonKey(name: 'debt_payoff_one_off_payments')  List<OneOffPayment>? debtPayoffOneOffPayments)?  $default,) {final _that = this;
switch (_that) {
case _Scenario() when $default != null:
return $default(_that.id,_that.householdId,_that.createdBy,_that.parentId,_that.name,_that.description,_that.baseDate,_that.isBaseline,_that.color,_that.isGoal,_that.targetAmount,_that.targetDate,_that.createdAt,_that.updatedAt,_that.kind,_that.debtPayoffTargets,_that.debtPayoffStrategy,_that.debtPayoffMonthlyBudgetCents,_that.debtPayoffOneOffPayments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Scenario implements Scenario {
  const _Scenario({required this.id, required this.householdId, required this.createdBy, this.parentId, required this.name, this.description, required this.baseDate, required this.isBaseline, this.color, required this.isGoal, this.targetAmount, this.targetDate, required this.createdAt, required this.updatedAt, this.kind = ScenarioKind.general, @JsonKey(name: 'debt_payoff_targets') final  List<DebtPayoffTarget>? debtPayoffTargets, @JsonKey(name: 'debt_payoff_strategy') this.debtPayoffStrategy, @JsonKey(name: 'debt_payoff_monthly_budget_cents') this.debtPayoffMonthlyBudgetCents, @JsonKey(name: 'debt_payoff_one_off_payments') final  List<OneOffPayment>? debtPayoffOneOffPayments}): _debtPayoffTargets = debtPayoffTargets,_debtPayoffOneOffPayments = debtPayoffOneOffPayments;
  factory _Scenario.fromJson(Map<String, dynamic> json) => _$ScenarioFromJson(json);

@override final  String id;
@override final  String householdId;
@override final  String createdBy;
/// Optional parent scenario this was branched from.
@override final  String? parentId;
@override final  String name;
@override final  String? description;
/// The date from which projection starts (usually today or a future date).
@override final  DateTime baseDate;
/// True when this scenario represents the unmodified baseline (no events).
@override final  bool isBaseline;
/// Hex color for the chart line and card accent (e.g. "#6366F1").
@override final  String? color;
/// When true this scenario is tracked as a financial goal.
@override final  bool isGoal;
/// Target net-worth in cents the user wants to reach (goals only).
@override final  int? targetAmount;
/// Deadline for hitting [targetAmount] (goals only).
@override final  DateTime? targetDate;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Which kind of scenario this is. Defaults to general so
/// existing rows (where the column has the SQL default) decode
/// cleanly. See [ScenarioKind] for the semantics.
@override@JsonKey() final  ScenarioKind kind;
/// Debt-payoff target list. Null for kind=general. The freezed
/// JSON converter handles the JSONB column directly.
 final  List<DebtPayoffTarget>? _debtPayoffTargets;
/// Debt-payoff target list. Null for kind=general. The freezed
/// JSON converter handles the JSONB column directly.
@override@JsonKey(name: 'debt_payoff_targets') List<DebtPayoffTarget>? get debtPayoffTargets {
  final value = _debtPayoffTargets;
  if (value == null) return null;
  if (_debtPayoffTargets is EqualUnmodifiableListView) return _debtPayoffTargets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Strategy for allocating extra-over-minimum payment across
/// the targets. Null for kind=general.
@override@JsonKey(name: 'debt_payoff_strategy') final  DebtPayoffStrategy? debtPayoffStrategy;
/// Total monthly $ the user is committing across all debts in
/// the plan (cents). Null for kind=general.
@override@JsonKey(name: 'debt_payoff_monthly_budget_cents') final  int? debtPayoffMonthlyBudgetCents;
/// Optional list of one-off lump-sum extra payments (tax
/// refunds, bonuses). Null for kind=general or until the user
/// adds one to a debt-payoff plan. See [OneOffPayment].
 final  List<OneOffPayment>? _debtPayoffOneOffPayments;
/// Optional list of one-off lump-sum extra payments (tax
/// refunds, bonuses). Null for kind=general or until the user
/// adds one to a debt-payoff plan. See [OneOffPayment].
@override@JsonKey(name: 'debt_payoff_one_off_payments') List<OneOffPayment>? get debtPayoffOneOffPayments {
  final value = _debtPayoffOneOffPayments;
  if (value == null) return null;
  if (_debtPayoffOneOffPayments is EqualUnmodifiableListView) return _debtPayoffOneOffPayments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioCopyWith<_Scenario> get copyWith => __$ScenarioCopyWithImpl<_Scenario>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Scenario&&(identical(other.id, id) || other.id == id)&&(identical(other.householdId, householdId) || other.householdId == householdId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.baseDate, baseDate) || other.baseDate == baseDate)&&(identical(other.isBaseline, isBaseline) || other.isBaseline == isBaseline)&&(identical(other.color, color) || other.color == color)&&(identical(other.isGoal, isGoal) || other.isGoal == isGoal)&&(identical(other.targetAmount, targetAmount) || other.targetAmount == targetAmount)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._debtPayoffTargets, _debtPayoffTargets)&&(identical(other.debtPayoffStrategy, debtPayoffStrategy) || other.debtPayoffStrategy == debtPayoffStrategy)&&(identical(other.debtPayoffMonthlyBudgetCents, debtPayoffMonthlyBudgetCents) || other.debtPayoffMonthlyBudgetCents == debtPayoffMonthlyBudgetCents)&&const DeepCollectionEquality().equals(other._debtPayoffOneOffPayments, _debtPayoffOneOffPayments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,householdId,createdBy,parentId,name,description,baseDate,isBaseline,color,isGoal,targetAmount,targetDate,createdAt,updatedAt,kind,const DeepCollectionEquality().hash(_debtPayoffTargets),debtPayoffStrategy,debtPayoffMonthlyBudgetCents,const DeepCollectionEquality().hash(_debtPayoffOneOffPayments)]);

@override
String toString() {
  return 'Scenario(id: $id, householdId: $householdId, createdBy: $createdBy, parentId: $parentId, name: $name, description: $description, baseDate: $baseDate, isBaseline: $isBaseline, color: $color, isGoal: $isGoal, targetAmount: $targetAmount, targetDate: $targetDate, createdAt: $createdAt, updatedAt: $updatedAt, kind: $kind, debtPayoffTargets: $debtPayoffTargets, debtPayoffStrategy: $debtPayoffStrategy, debtPayoffMonthlyBudgetCents: $debtPayoffMonthlyBudgetCents, debtPayoffOneOffPayments: $debtPayoffOneOffPayments)';
}


}

/// @nodoc
abstract mixin class _$ScenarioCopyWith<$Res> implements $ScenarioCopyWith<$Res> {
  factory _$ScenarioCopyWith(_Scenario value, $Res Function(_Scenario) _then) = __$ScenarioCopyWithImpl;
@override @useResult
$Res call({
 String id, String householdId, String createdBy, String? parentId, String name, String? description, DateTime baseDate, bool isBaseline, String? color, bool isGoal, int? targetAmount, DateTime? targetDate, DateTime createdAt, DateTime updatedAt, ScenarioKind kind,@JsonKey(name: 'debt_payoff_targets') List<DebtPayoffTarget>? debtPayoffTargets,@JsonKey(name: 'debt_payoff_strategy') DebtPayoffStrategy? debtPayoffStrategy,@JsonKey(name: 'debt_payoff_monthly_budget_cents') int? debtPayoffMonthlyBudgetCents,@JsonKey(name: 'debt_payoff_one_off_payments') List<OneOffPayment>? debtPayoffOneOffPayments
});




}
/// @nodoc
class __$ScenarioCopyWithImpl<$Res>
    implements _$ScenarioCopyWith<$Res> {
  __$ScenarioCopyWithImpl(this._self, this._then);

  final _Scenario _self;
  final $Res Function(_Scenario) _then;

/// Create a copy of Scenario
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? householdId = null,Object? createdBy = null,Object? parentId = freezed,Object? name = null,Object? description = freezed,Object? baseDate = null,Object? isBaseline = null,Object? color = freezed,Object? isGoal = null,Object? targetAmount = freezed,Object? targetDate = freezed,Object? createdAt = null,Object? updatedAt = null,Object? kind = null,Object? debtPayoffTargets = freezed,Object? debtPayoffStrategy = freezed,Object? debtPayoffMonthlyBudgetCents = freezed,Object? debtPayoffOneOffPayments = freezed,}) {
  return _then(_Scenario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,householdId: null == householdId ? _self.householdId : householdId // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,baseDate: null == baseDate ? _self.baseDate : baseDate // ignore: cast_nullable_to_non_nullable
as DateTime,isBaseline: null == isBaseline ? _self.isBaseline : isBaseline // ignore: cast_nullable_to_non_nullable
as bool,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,isGoal: null == isGoal ? _self.isGoal : isGoal // ignore: cast_nullable_to_non_nullable
as bool,targetAmount: freezed == targetAmount ? _self.targetAmount : targetAmount // ignore: cast_nullable_to_non_nullable
as int?,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ScenarioKind,debtPayoffTargets: freezed == debtPayoffTargets ? _self._debtPayoffTargets : debtPayoffTargets // ignore: cast_nullable_to_non_nullable
as List<DebtPayoffTarget>?,debtPayoffStrategy: freezed == debtPayoffStrategy ? _self.debtPayoffStrategy : debtPayoffStrategy // ignore: cast_nullable_to_non_nullable
as DebtPayoffStrategy?,debtPayoffMonthlyBudgetCents: freezed == debtPayoffMonthlyBudgetCents ? _self.debtPayoffMonthlyBudgetCents : debtPayoffMonthlyBudgetCents // ignore: cast_nullable_to_non_nullable
as int?,debtPayoffOneOffPayments: freezed == debtPayoffOneOffPayments ? _self._debtPayoffOneOffPayments : debtPayoffOneOffPayments // ignore: cast_nullable_to_non_nullable
as List<OneOffPayment>?,
  ));
}


}

// dart format on
