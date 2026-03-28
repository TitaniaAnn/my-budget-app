// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scenario_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ScenarioEvent _$ScenarioEventFromJson(Map<String, dynamic> json) {
  return _ScenarioEvent.fromJson(json);
}

/// @nodoc
mixin _$ScenarioEvent {
  String get id => throw _privateConstructorUsedError;
  String get scenarioId => throw _privateConstructorUsedError;
  EventType get eventType => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  DateTime get eventDate => throw _privateConstructorUsedError;

  /// Amount in cents (always positive; direction set by [eventType]).
  int get amount => throw _privateConstructorUsedError;
  String? get accountId => throw _privateConstructorUsedError;
  bool get isRecurring => throw _privateConstructorUsedError;

  /// iCal RRULE string when [isRecurring] is true (e.g. "FREQ=MONTHLY").
  String? get recurrenceRule => throw _privateConstructorUsedError;

  /// Free-form JSON for extra parameters (unused for now, future-proofing).
  Map<String, dynamic>? get parameters => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;

  /// Serializes this ScenarioEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScenarioEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScenarioEventCopyWith<ScenarioEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScenarioEventCopyWith<$Res> {
  factory $ScenarioEventCopyWith(
    ScenarioEvent value,
    $Res Function(ScenarioEvent) then,
  ) = _$ScenarioEventCopyWithImpl<$Res, ScenarioEvent>;
  @useResult
  $Res call({
    String id,
    String scenarioId,
    EventType eventType,
    String label,
    DateTime eventDate,
    int amount,
    String? accountId,
    bool isRecurring,
    String? recurrenceRule,
    Map<String, dynamic>? parameters,
    int sortOrder,
  });
}

/// @nodoc
class _$ScenarioEventCopyWithImpl<$Res, $Val extends ScenarioEvent>
    implements $ScenarioEventCopyWith<$Res> {
  _$ScenarioEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScenarioEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scenarioId = null,
    Object? eventType = null,
    Object? label = null,
    Object? eventDate = null,
    Object? amount = null,
    Object? accountId = freezed,
    Object? isRecurring = null,
    Object? recurrenceRule = freezed,
    Object? parameters = freezed,
    Object? sortOrder = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            scenarioId: null == scenarioId
                ? _value.scenarioId
                : scenarioId // ignore: cast_nullable_to_non_nullable
                      as String,
            eventType: null == eventType
                ? _value.eventType
                : eventType // ignore: cast_nullable_to_non_nullable
                      as EventType,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            eventDate: null == eventDate
                ? _value.eventDate
                : eventDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as int,
            accountId: freezed == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String?,
            isRecurring: null == isRecurring
                ? _value.isRecurring
                : isRecurring // ignore: cast_nullable_to_non_nullable
                      as bool,
            recurrenceRule: freezed == recurrenceRule
                ? _value.recurrenceRule
                : recurrenceRule // ignore: cast_nullable_to_non_nullable
                      as String?,
            parameters: freezed == parameters
                ? _value.parameters
                : parameters // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
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
abstract class _$$ScenarioEventImplCopyWith<$Res>
    implements $ScenarioEventCopyWith<$Res> {
  factory _$$ScenarioEventImplCopyWith(
    _$ScenarioEventImpl value,
    $Res Function(_$ScenarioEventImpl) then,
  ) = __$$ScenarioEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String scenarioId,
    EventType eventType,
    String label,
    DateTime eventDate,
    int amount,
    String? accountId,
    bool isRecurring,
    String? recurrenceRule,
    Map<String, dynamic>? parameters,
    int sortOrder,
  });
}

/// @nodoc
class __$$ScenarioEventImplCopyWithImpl<$Res>
    extends _$ScenarioEventCopyWithImpl<$Res, _$ScenarioEventImpl>
    implements _$$ScenarioEventImplCopyWith<$Res> {
  __$$ScenarioEventImplCopyWithImpl(
    _$ScenarioEventImpl _value,
    $Res Function(_$ScenarioEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ScenarioEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scenarioId = null,
    Object? eventType = null,
    Object? label = null,
    Object? eventDate = null,
    Object? amount = null,
    Object? accountId = freezed,
    Object? isRecurring = null,
    Object? recurrenceRule = freezed,
    Object? parameters = freezed,
    Object? sortOrder = null,
  }) {
    return _then(
      _$ScenarioEventImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        scenarioId: null == scenarioId
            ? _value.scenarioId
            : scenarioId // ignore: cast_nullable_to_non_nullable
                  as String,
        eventType: null == eventType
            ? _value.eventType
            : eventType // ignore: cast_nullable_to_non_nullable
                  as EventType,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        eventDate: null == eventDate
            ? _value.eventDate
            : eventDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        accountId: freezed == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String?,
        isRecurring: null == isRecurring
            ? _value.isRecurring
            : isRecurring // ignore: cast_nullable_to_non_nullable
                  as bool,
        recurrenceRule: freezed == recurrenceRule
            ? _value.recurrenceRule
            : recurrenceRule // ignore: cast_nullable_to_non_nullable
                  as String?,
        parameters: freezed == parameters
            ? _value._parameters
            : parameters // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
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
class _$ScenarioEventImpl implements _ScenarioEvent {
  const _$ScenarioEventImpl({
    required this.id,
    required this.scenarioId,
    required this.eventType,
    required this.label,
    required this.eventDate,
    required this.amount,
    this.accountId,
    required this.isRecurring,
    this.recurrenceRule,
    final Map<String, dynamic>? parameters,
    required this.sortOrder,
  }) : _parameters = parameters;

  factory _$ScenarioEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScenarioEventImplFromJson(json);

  @override
  final String id;
  @override
  final String scenarioId;
  @override
  final EventType eventType;
  @override
  final String label;
  @override
  final DateTime eventDate;

  /// Amount in cents (always positive; direction set by [eventType]).
  @override
  final int amount;
  @override
  final String? accountId;
  @override
  final bool isRecurring;

  /// iCal RRULE string when [isRecurring] is true (e.g. "FREQ=MONTHLY").
  @override
  final String? recurrenceRule;

  /// Free-form JSON for extra parameters (unused for now, future-proofing).
  final Map<String, dynamic>? _parameters;

  /// Free-form JSON for extra parameters (unused for now, future-proofing).
  @override
  Map<String, dynamic>? get parameters {
    final value = _parameters;
    if (value == null) return null;
    if (_parameters is EqualUnmodifiableMapView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final int sortOrder;

  @override
  String toString() {
    return 'ScenarioEvent(id: $id, scenarioId: $scenarioId, eventType: $eventType, label: $label, eventDate: $eventDate, amount: $amount, accountId: $accountId, isRecurring: $isRecurring, recurrenceRule: $recurrenceRule, parameters: $parameters, sortOrder: $sortOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScenarioEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.scenarioId, scenarioId) ||
                other.scenarioId == scenarioId) &&
            (identical(other.eventType, eventType) ||
                other.eventType == eventType) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.eventDate, eventDate) ||
                other.eventDate == eventDate) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring) &&
            (identical(other.recurrenceRule, recurrenceRule) ||
                other.recurrenceRule == recurrenceRule) &&
            const DeepCollectionEquality().equals(
              other._parameters,
              _parameters,
            ) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    scenarioId,
    eventType,
    label,
    eventDate,
    amount,
    accountId,
    isRecurring,
    recurrenceRule,
    const DeepCollectionEquality().hash(_parameters),
    sortOrder,
  );

  /// Create a copy of ScenarioEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScenarioEventImplCopyWith<_$ScenarioEventImpl> get copyWith =>
      __$$ScenarioEventImplCopyWithImpl<_$ScenarioEventImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScenarioEventImplToJson(this);
  }
}

abstract class _ScenarioEvent implements ScenarioEvent {
  const factory _ScenarioEvent({
    required final String id,
    required final String scenarioId,
    required final EventType eventType,
    required final String label,
    required final DateTime eventDate,
    required final int amount,
    final String? accountId,
    required final bool isRecurring,
    final String? recurrenceRule,
    final Map<String, dynamic>? parameters,
    required final int sortOrder,
  }) = _$ScenarioEventImpl;

  factory _ScenarioEvent.fromJson(Map<String, dynamic> json) =
      _$ScenarioEventImpl.fromJson;

  @override
  String get id;
  @override
  String get scenarioId;
  @override
  EventType get eventType;
  @override
  String get label;
  @override
  DateTime get eventDate;

  /// Amount in cents (always positive; direction set by [eventType]).
  @override
  int get amount;
  @override
  String? get accountId;
  @override
  bool get isRecurring;

  /// iCal RRULE string when [isRecurring] is true (e.g. "FREQ=MONTHLY").
  @override
  String? get recurrenceRule;

  /// Free-form JSON for extra parameters (unused for now, future-proofing).
  @override
  Map<String, dynamic>? get parameters;
  @override
  int get sortOrder;

  /// Create a copy of ScenarioEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScenarioEventImplCopyWith<_$ScenarioEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
