// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scenario_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScenarioEvent {

 String get id; String get scenarioId; EventType get eventType; String get label; DateTime get eventDate;/// Amount in cents (always positive; direction set by [eventType]).
 int get amount; String? get accountId; bool get isRecurring;/// iCal RRULE string when [isRecurring] is true (e.g. "FREQ=MONTHLY").
 String? get recurrenceRule;/// Free-form JSON for extra parameters (unused for now, future-proofing).
 Map<String, dynamic>? get parameters; int get sortOrder;/// APR in basis points (10000 = 100%) for payoff-plan events.
/// Null for all other event types. Set at create time from the
/// debt account's `interestRate` — capturing it on the event
/// keeps the plan stable if the user updates the account's APR
/// later. Migration 041.
@JsonKey(name: 'payoff_apr_bps') int? get paymentAprBps;
/// Create a copy of ScenarioEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioEventCopyWith<ScenarioEvent> get copyWith => _$ScenarioEventCopyWithImpl<ScenarioEvent>(this as ScenarioEvent, _$identity);

  /// Serializes this ScenarioEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.scenarioId, scenarioId) || other.scenarioId == scenarioId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.label, label) || other.label == label)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&const DeepCollectionEquality().equals(other.parameters, parameters)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.paymentAprBps, paymentAprBps) || other.paymentAprBps == paymentAprBps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,scenarioId,eventType,label,eventDate,amount,accountId,isRecurring,recurrenceRule,const DeepCollectionEquality().hash(parameters),sortOrder,paymentAprBps);

@override
String toString() {
  return 'ScenarioEvent(id: $id, scenarioId: $scenarioId, eventType: $eventType, label: $label, eventDate: $eventDate, amount: $amount, accountId: $accountId, isRecurring: $isRecurring, recurrenceRule: $recurrenceRule, parameters: $parameters, sortOrder: $sortOrder, paymentAprBps: $paymentAprBps)';
}


}

/// @nodoc
abstract mixin class $ScenarioEventCopyWith<$Res>  {
  factory $ScenarioEventCopyWith(ScenarioEvent value, $Res Function(ScenarioEvent) _then) = _$ScenarioEventCopyWithImpl;
@useResult
$Res call({
 String id, String scenarioId, EventType eventType, String label, DateTime eventDate, int amount, String? accountId, bool isRecurring, String? recurrenceRule, Map<String, dynamic>? parameters, int sortOrder,@JsonKey(name: 'payoff_apr_bps') int? paymentAprBps
});




}
/// @nodoc
class _$ScenarioEventCopyWithImpl<$Res>
    implements $ScenarioEventCopyWith<$Res> {
  _$ScenarioEventCopyWithImpl(this._self, this._then);

  final ScenarioEvent _self;
  final $Res Function(ScenarioEvent) _then;

/// Create a copy of ScenarioEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? scenarioId = null,Object? eventType = null,Object? label = null,Object? eventDate = null,Object? amount = null,Object? accountId = freezed,Object? isRecurring = null,Object? recurrenceRule = freezed,Object? parameters = freezed,Object? sortOrder = null,Object? paymentAprBps = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scenarioId: null == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,isRecurring: null == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool,recurrenceRule: freezed == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as String?,parameters: freezed == parameters ? _self.parameters : parameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,paymentAprBps: freezed == paymentAprBps ? _self.paymentAprBps : paymentAprBps // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScenarioEvent].
extension ScenarioEventPatterns on ScenarioEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioEvent value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String scenarioId,  EventType eventType,  String label,  DateTime eventDate,  int amount,  String? accountId,  bool isRecurring,  String? recurrenceRule,  Map<String, dynamic>? parameters,  int sortOrder, @JsonKey(name: 'payoff_apr_bps')  int? paymentAprBps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioEvent() when $default != null:
return $default(_that.id,_that.scenarioId,_that.eventType,_that.label,_that.eventDate,_that.amount,_that.accountId,_that.isRecurring,_that.recurrenceRule,_that.parameters,_that.sortOrder,_that.paymentAprBps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String scenarioId,  EventType eventType,  String label,  DateTime eventDate,  int amount,  String? accountId,  bool isRecurring,  String? recurrenceRule,  Map<String, dynamic>? parameters,  int sortOrder, @JsonKey(name: 'payoff_apr_bps')  int? paymentAprBps)  $default,) {final _that = this;
switch (_that) {
case _ScenarioEvent():
return $default(_that.id,_that.scenarioId,_that.eventType,_that.label,_that.eventDate,_that.amount,_that.accountId,_that.isRecurring,_that.recurrenceRule,_that.parameters,_that.sortOrder,_that.paymentAprBps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String scenarioId,  EventType eventType,  String label,  DateTime eventDate,  int amount,  String? accountId,  bool isRecurring,  String? recurrenceRule,  Map<String, dynamic>? parameters,  int sortOrder, @JsonKey(name: 'payoff_apr_bps')  int? paymentAprBps)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioEvent() when $default != null:
return $default(_that.id,_that.scenarioId,_that.eventType,_that.label,_that.eventDate,_that.amount,_that.accountId,_that.isRecurring,_that.recurrenceRule,_that.parameters,_that.sortOrder,_that.paymentAprBps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScenarioEvent implements ScenarioEvent {
  const _ScenarioEvent({required this.id, required this.scenarioId, required this.eventType, required this.label, required this.eventDate, required this.amount, this.accountId, required this.isRecurring, this.recurrenceRule, final  Map<String, dynamic>? parameters, required this.sortOrder, @JsonKey(name: 'payoff_apr_bps') this.paymentAprBps}): _parameters = parameters;
  factory _ScenarioEvent.fromJson(Map<String, dynamic> json) => _$ScenarioEventFromJson(json);

@override final  String id;
@override final  String scenarioId;
@override final  EventType eventType;
@override final  String label;
@override final  DateTime eventDate;
/// Amount in cents (always positive; direction set by [eventType]).
@override final  int amount;
@override final  String? accountId;
@override final  bool isRecurring;
/// iCal RRULE string when [isRecurring] is true (e.g. "FREQ=MONTHLY").
@override final  String? recurrenceRule;
/// Free-form JSON for extra parameters (unused for now, future-proofing).
 final  Map<String, dynamic>? _parameters;
/// Free-form JSON for extra parameters (unused for now, future-proofing).
@override Map<String, dynamic>? get parameters {
  final value = _parameters;
  if (value == null) return null;
  if (_parameters is EqualUnmodifiableMapView) return _parameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  int sortOrder;
/// APR in basis points (10000 = 100%) for payoff-plan events.
/// Null for all other event types. Set at create time from the
/// debt account's `interestRate` — capturing it on the event
/// keeps the plan stable if the user updates the account's APR
/// later. Migration 041.
@override@JsonKey(name: 'payoff_apr_bps') final  int? paymentAprBps;

/// Create a copy of ScenarioEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioEventCopyWith<_ScenarioEvent> get copyWith => __$ScenarioEventCopyWithImpl<_ScenarioEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.scenarioId, scenarioId) || other.scenarioId == scenarioId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.label, label) || other.label == label)&&(identical(other.eventDate, eventDate) || other.eventDate == eventDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.isRecurring, isRecurring) || other.isRecurring == isRecurring)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&const DeepCollectionEquality().equals(other._parameters, _parameters)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.paymentAprBps, paymentAprBps) || other.paymentAprBps == paymentAprBps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,scenarioId,eventType,label,eventDate,amount,accountId,isRecurring,recurrenceRule,const DeepCollectionEquality().hash(_parameters),sortOrder,paymentAprBps);

@override
String toString() {
  return 'ScenarioEvent(id: $id, scenarioId: $scenarioId, eventType: $eventType, label: $label, eventDate: $eventDate, amount: $amount, accountId: $accountId, isRecurring: $isRecurring, recurrenceRule: $recurrenceRule, parameters: $parameters, sortOrder: $sortOrder, paymentAprBps: $paymentAprBps)';
}


}

/// @nodoc
abstract mixin class _$ScenarioEventCopyWith<$Res> implements $ScenarioEventCopyWith<$Res> {
  factory _$ScenarioEventCopyWith(_ScenarioEvent value, $Res Function(_ScenarioEvent) _then) = __$ScenarioEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String scenarioId, EventType eventType, String label, DateTime eventDate, int amount, String? accountId, bool isRecurring, String? recurrenceRule, Map<String, dynamic>? parameters, int sortOrder,@JsonKey(name: 'payoff_apr_bps') int? paymentAprBps
});




}
/// @nodoc
class __$ScenarioEventCopyWithImpl<$Res>
    implements _$ScenarioEventCopyWith<$Res> {
  __$ScenarioEventCopyWithImpl(this._self, this._then);

  final _ScenarioEvent _self;
  final $Res Function(_ScenarioEvent) _then;

/// Create a copy of ScenarioEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? scenarioId = null,Object? eventType = null,Object? label = null,Object? eventDate = null,Object? amount = null,Object? accountId = freezed,Object? isRecurring = null,Object? recurrenceRule = freezed,Object? parameters = freezed,Object? sortOrder = null,Object? paymentAprBps = freezed,}) {
  return _then(_ScenarioEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,scenarioId: null == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as EventType,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,eventDate: null == eventDate ? _self.eventDate : eventDate // ignore: cast_nullable_to_non_nullable
as DateTime,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as String?,isRecurring: null == isRecurring ? _self.isRecurring : isRecurring // ignore: cast_nullable_to_non_nullable
as bool,recurrenceRule: freezed == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as String?,parameters: freezed == parameters ? _self._parameters : parameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,paymentAprBps: freezed == paymentAprBps ? _self.paymentAprBps : paymentAprBps // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
