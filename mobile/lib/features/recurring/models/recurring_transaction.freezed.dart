// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RecurringTransaction _$RecurringTransactionFromJson(Map<String, dynamic> json) {
  return _RecurringTransaction.fromJson(json);
}

/// @nodoc
mixin _$RecurringTransaction {
  String get id => throw _privateConstructorUsedError;
  String get householdId => throw _privateConstructorUsedError;
  String get accountId => throw _privateConstructorUsedError;

  /// Signed cents. Negative = outflow, positive = inflow.
  /// Zero is rejected by the DB CHECK constraint.
  int get amountCents => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get merchant => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;
  RecurrenceCadence get cadence => throw _privateConstructorUsedError;

  /// Next date the scheduler should emit a transaction. Updated
  /// by the (future) scheduler after each emission.
  DateTime get nextOccurrenceDate => throw _privateConstructorUsedError;

  /// Wall-clock of the last scheduler emission. Null until the
  /// first emission — distinct from [nextOccurrenceDate] because
  /// the scheduler may sit dormant for days and the audit trail
  /// remains useful even then.
  DateTime? get lastEmittedAt => throw _privateConstructorUsedError;

  /// When set, the scheduler skips any occurrence whose date is
  /// on or before this. Pauses a subscription without deleting
  /// the rule. Null = no skip in effect.
  DateTime? get skippedUntilDate => throw _privateConstructorUsedError;

  /// Whether the scheduler should consider this row at all.
  /// Easier than deleting when the user wants to keep history
  /// of "we used to have this subscription."
  bool get isActive => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this RecurringTransaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecurringTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecurringTransactionCopyWith<RecurringTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecurringTransactionCopyWith<$Res> {
  factory $RecurringTransactionCopyWith(
    RecurringTransaction value,
    $Res Function(RecurringTransaction) then,
  ) = _$RecurringTransactionCopyWithImpl<$Res, RecurringTransaction>;
  @useResult
  $Res call({
    String id,
    String householdId,
    String accountId,
    int amountCents,
    String currency,
    String description,
    String? merchant,
    String? categoryId,
    RecurrenceCadence cadence,
    DateTime nextOccurrenceDate,
    DateTime? lastEmittedAt,
    DateTime? skippedUntilDate,
    bool isActive,
    String? createdBy,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$RecurringTransactionCopyWithImpl<
  $Res,
  $Val extends RecurringTransaction
>
    implements $RecurringTransactionCopyWith<$Res> {
  _$RecurringTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecurringTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? accountId = null,
    Object? amountCents = null,
    Object? currency = null,
    Object? description = null,
    Object? merchant = freezed,
    Object? categoryId = freezed,
    Object? cadence = null,
    Object? nextOccurrenceDate = null,
    Object? lastEmittedAt = freezed,
    Object? skippedUntilDate = freezed,
    Object? isActive = null,
    Object? createdBy = freezed,
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
            amountCents: null == amountCents
                ? _value.amountCents
                : amountCents // ignore: cast_nullable_to_non_nullable
                      as int,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            merchant: freezed == merchant
                ? _value.merchant
                : merchant // ignore: cast_nullable_to_non_nullable
                      as String?,
            categoryId: freezed == categoryId
                ? _value.categoryId
                : categoryId // ignore: cast_nullable_to_non_nullable
                      as String?,
            cadence: null == cadence
                ? _value.cadence
                : cadence // ignore: cast_nullable_to_non_nullable
                      as RecurrenceCadence,
            nextOccurrenceDate: null == nextOccurrenceDate
                ? _value.nextOccurrenceDate
                : nextOccurrenceDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            lastEmittedAt: freezed == lastEmittedAt
                ? _value.lastEmittedAt
                : lastEmittedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            skippedUntilDate: freezed == skippedUntilDate
                ? _value.skippedUntilDate
                : skippedUntilDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$RecurringTransactionImplCopyWith<$Res>
    implements $RecurringTransactionCopyWith<$Res> {
  factory _$$RecurringTransactionImplCopyWith(
    _$RecurringTransactionImpl value,
    $Res Function(_$RecurringTransactionImpl) then,
  ) = __$$RecurringTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String householdId,
    String accountId,
    int amountCents,
    String currency,
    String description,
    String? merchant,
    String? categoryId,
    RecurrenceCadence cadence,
    DateTime nextOccurrenceDate,
    DateTime? lastEmittedAt,
    DateTime? skippedUntilDate,
    bool isActive,
    String? createdBy,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$RecurringTransactionImplCopyWithImpl<$Res>
    extends _$RecurringTransactionCopyWithImpl<$Res, _$RecurringTransactionImpl>
    implements _$$RecurringTransactionImplCopyWith<$Res> {
  __$$RecurringTransactionImplCopyWithImpl(
    _$RecurringTransactionImpl _value,
    $Res Function(_$RecurringTransactionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecurringTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? accountId = null,
    Object? amountCents = null,
    Object? currency = null,
    Object? description = null,
    Object? merchant = freezed,
    Object? categoryId = freezed,
    Object? cadence = null,
    Object? nextOccurrenceDate = null,
    Object? lastEmittedAt = freezed,
    Object? skippedUntilDate = freezed,
    Object? isActive = null,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$RecurringTransactionImpl(
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
        amountCents: null == amountCents
            ? _value.amountCents
            : amountCents // ignore: cast_nullable_to_non_nullable
                  as int,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        merchant: freezed == merchant
            ? _value.merchant
            : merchant // ignore: cast_nullable_to_non_nullable
                  as String?,
        categoryId: freezed == categoryId
            ? _value.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        cadence: null == cadence
            ? _value.cadence
            : cadence // ignore: cast_nullable_to_non_nullable
                  as RecurrenceCadence,
        nextOccurrenceDate: null == nextOccurrenceDate
            ? _value.nextOccurrenceDate
            : nextOccurrenceDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        lastEmittedAt: freezed == lastEmittedAt
            ? _value.lastEmittedAt
            : lastEmittedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        skippedUntilDate: freezed == skippedUntilDate
            ? _value.skippedUntilDate
            : skippedUntilDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$RecurringTransactionImpl implements _RecurringTransaction {
  const _$RecurringTransactionImpl({
    required this.id,
    required this.householdId,
    required this.accountId,
    required this.amountCents,
    required this.currency,
    required this.description,
    this.merchant,
    this.categoryId,
    required this.cadence,
    required this.nextOccurrenceDate,
    this.lastEmittedAt,
    this.skippedUntilDate,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$RecurringTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecurringTransactionImplFromJson(json);

  @override
  final String id;
  @override
  final String householdId;
  @override
  final String accountId;

  /// Signed cents. Negative = outflow, positive = inflow.
  /// Zero is rejected by the DB CHECK constraint.
  @override
  final int amountCents;
  @override
  final String currency;
  @override
  final String description;
  @override
  final String? merchant;
  @override
  final String? categoryId;
  @override
  final RecurrenceCadence cadence;

  /// Next date the scheduler should emit a transaction. Updated
  /// by the (future) scheduler after each emission.
  @override
  final DateTime nextOccurrenceDate;

  /// Wall-clock of the last scheduler emission. Null until the
  /// first emission — distinct from [nextOccurrenceDate] because
  /// the scheduler may sit dormant for days and the audit trail
  /// remains useful even then.
  @override
  final DateTime? lastEmittedAt;

  /// When set, the scheduler skips any occurrence whose date is
  /// on or before this. Pauses a subscription without deleting
  /// the rule. Null = no skip in effect.
  @override
  final DateTime? skippedUntilDate;

  /// Whether the scheduler should consider this row at all.
  /// Easier than deleting when the user wants to keep history
  /// of "we used to have this subscription."
  @override
  final bool isActive;
  @override
  final String? createdBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, householdId: $householdId, accountId: $accountId, amountCents: $amountCents, currency: $currency, description: $description, merchant: $merchant, categoryId: $categoryId, cadence: $cadence, nextOccurrenceDate: $nextOccurrenceDate, lastEmittedAt: $lastEmittedAt, skippedUntilDate: $skippedUntilDate, isActive: $isActive, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecurringTransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.amountCents, amountCents) ||
                other.amountCents == amountCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.cadence, cadence) || other.cadence == cadence) &&
            (identical(other.nextOccurrenceDate, nextOccurrenceDate) ||
                other.nextOccurrenceDate == nextOccurrenceDate) &&
            (identical(other.lastEmittedAt, lastEmittedAt) ||
                other.lastEmittedAt == lastEmittedAt) &&
            (identical(other.skippedUntilDate, skippedUntilDate) ||
                other.skippedUntilDate == skippedUntilDate) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
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
    id,
    householdId,
    accountId,
    amountCents,
    currency,
    description,
    merchant,
    categoryId,
    cadence,
    nextOccurrenceDate,
    lastEmittedAt,
    skippedUntilDate,
    isActive,
    createdBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of RecurringTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecurringTransactionImplCopyWith<_$RecurringTransactionImpl>
  get copyWith =>
      __$$RecurringTransactionImplCopyWithImpl<_$RecurringTransactionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecurringTransactionImplToJson(this);
  }
}

abstract class _RecurringTransaction implements RecurringTransaction {
  const factory _RecurringTransaction({
    required final String id,
    required final String householdId,
    required final String accountId,
    required final int amountCents,
    required final String currency,
    required final String description,
    final String? merchant,
    final String? categoryId,
    required final RecurrenceCadence cadence,
    required final DateTime nextOccurrenceDate,
    final DateTime? lastEmittedAt,
    final DateTime? skippedUntilDate,
    required final bool isActive,
    final String? createdBy,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$RecurringTransactionImpl;

  factory _RecurringTransaction.fromJson(Map<String, dynamic> json) =
      _$RecurringTransactionImpl.fromJson;

  @override
  String get id;
  @override
  String get householdId;
  @override
  String get accountId;

  /// Signed cents. Negative = outflow, positive = inflow.
  /// Zero is rejected by the DB CHECK constraint.
  @override
  int get amountCents;
  @override
  String get currency;
  @override
  String get description;
  @override
  String? get merchant;
  @override
  String? get categoryId;
  @override
  RecurrenceCadence get cadence;

  /// Next date the scheduler should emit a transaction. Updated
  /// by the (future) scheduler after each emission.
  @override
  DateTime get nextOccurrenceDate;

  /// Wall-clock of the last scheduler emission. Null until the
  /// first emission — distinct from [nextOccurrenceDate] because
  /// the scheduler may sit dormant for days and the audit trail
  /// remains useful even then.
  @override
  DateTime? get lastEmittedAt;

  /// When set, the scheduler skips any occurrence whose date is
  /// on or before this. Pauses a subscription without deleting
  /// the rule. Null = no skip in effect.
  @override
  DateTime? get skippedUntilDate;

  /// Whether the scheduler should consider this row at all.
  /// Easier than deleting when the user wants to keep history
  /// of "we used to have this subscription."
  @override
  bool get isActive;
  @override
  String? get createdBy;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of RecurringTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecurringTransactionImplCopyWith<_$RecurringTransactionImpl>
  get copyWith => throw _privateConstructorUsedError;
}
