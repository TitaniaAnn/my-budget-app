// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Account _$AccountFromJson(Map<String, dynamic> json) {
  return _Account.fromJson(json);
}

/// @nodoc
mixin _$Account {
  String get id => throw _privateConstructorUsedError;
  String get householdId => throw _privateConstructorUsedError;

  /// The family member who owns this account (may differ from the logged-in user).
  String get ownerUserId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  AccountType get accountType => throw _privateConstructorUsedError;
  String? get institution => throw _privateConstructorUsedError;

  /// Last 4 digits of the account/card number for display purposes.
  String? get lastFour => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;

  /// Current balance in cents. Negative values indicate debt (credit cards).
  int get currentBalance => throw _privateConstructorUsedError;

  /// Credit limit in cents. Only set for [AccountType.creditCard].
  int? get creditLimit => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Optional hex color for the account card (e.g. "#3B82F6").
  String? get color => throw _privateConstructorUsedError;

  /// Annual interest rate as a decimal (e.g. 0.2499 = 24.99% APR).
  /// Null means not applicable (e.g. checking, cash).
  double? get interestRate => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Account to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountCopyWith<Account> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountCopyWith<$Res> {
  factory $AccountCopyWith(Account value, $Res Function(Account) then) =
      _$AccountCopyWithImpl<$Res, Account>;
  @useResult
  $Res call({
    String id,
    String householdId,
    String ownerUserId,
    String name,
    AccountType accountType,
    String? institution,
    String? lastFour,
    String currency,
    int currentBalance,
    int? creditLimit,
    bool isActive,
    String? color,
    double? interestRate,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$AccountCopyWithImpl<$Res, $Val extends Account>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? ownerUserId = null,
    Object? name = null,
    Object? accountType = null,
    Object? institution = freezed,
    Object? lastFour = freezed,
    Object? currency = null,
    Object? currentBalance = null,
    Object? creditLimit = freezed,
    Object? isActive = null,
    Object? color = freezed,
    Object? interestRate = freezed,
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
            ownerUserId: null == ownerUserId
                ? _value.ownerUserId
                : ownerUserId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            accountType: null == accountType
                ? _value.accountType
                : accountType // ignore: cast_nullable_to_non_nullable
                      as AccountType,
            institution: freezed == institution
                ? _value.institution
                : institution // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastFour: freezed == lastFour
                ? _value.lastFour
                : lastFour // ignore: cast_nullable_to_non_nullable
                      as String?,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            currentBalance: null == currentBalance
                ? _value.currentBalance
                : currentBalance // ignore: cast_nullable_to_non_nullable
                      as int,
            creditLimit: freezed == creditLimit
                ? _value.creditLimit
                : creditLimit // ignore: cast_nullable_to_non_nullable
                      as int?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            interestRate: freezed == interestRate
                ? _value.interestRate
                : interestRate // ignore: cast_nullable_to_non_nullable
                      as double?,
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
abstract class _$$AccountImplCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$$AccountImplCopyWith(
    _$AccountImpl value,
    $Res Function(_$AccountImpl) then,
  ) = __$$AccountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String householdId,
    String ownerUserId,
    String name,
    AccountType accountType,
    String? institution,
    String? lastFour,
    String currency,
    int currentBalance,
    int? creditLimit,
    bool isActive,
    String? color,
    double? interestRate,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$AccountImplCopyWithImpl<$Res>
    extends _$AccountCopyWithImpl<$Res, _$AccountImpl>
    implements _$$AccountImplCopyWith<$Res> {
  __$$AccountImplCopyWithImpl(
    _$AccountImpl _value,
    $Res Function(_$AccountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? ownerUserId = null,
    Object? name = null,
    Object? accountType = null,
    Object? institution = freezed,
    Object? lastFour = freezed,
    Object? currency = null,
    Object? currentBalance = null,
    Object? creditLimit = freezed,
    Object? isActive = null,
    Object? color = freezed,
    Object? interestRate = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$AccountImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        householdId: null == householdId
            ? _value.householdId
            : householdId // ignore: cast_nullable_to_non_nullable
                  as String,
        ownerUserId: null == ownerUserId
            ? _value.ownerUserId
            : ownerUserId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        accountType: null == accountType
            ? _value.accountType
            : accountType // ignore: cast_nullable_to_non_nullable
                  as AccountType,
        institution: freezed == institution
            ? _value.institution
            : institution // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastFour: freezed == lastFour
            ? _value.lastFour
            : lastFour // ignore: cast_nullable_to_non_nullable
                  as String?,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        currentBalance: null == currentBalance
            ? _value.currentBalance
            : currentBalance // ignore: cast_nullable_to_non_nullable
                  as int,
        creditLimit: freezed == creditLimit
            ? _value.creditLimit
            : creditLimit // ignore: cast_nullable_to_non_nullable
                  as int?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        interestRate: freezed == interestRate
            ? _value.interestRate
            : interestRate // ignore: cast_nullable_to_non_nullable
                  as double?,
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
class _$AccountImpl implements _Account {
  const _$AccountImpl({
    required this.id,
    required this.householdId,
    required this.ownerUserId,
    required this.name,
    required this.accountType,
    this.institution,
    this.lastFour,
    required this.currency,
    required this.currentBalance,
    this.creditLimit,
    required this.isActive,
    this.color,
    this.interestRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$AccountImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccountImplFromJson(json);

  @override
  final String id;
  @override
  final String householdId;

  /// The family member who owns this account (may differ from the logged-in user).
  @override
  final String ownerUserId;
  @override
  final String name;
  @override
  final AccountType accountType;
  @override
  final String? institution;

  /// Last 4 digits of the account/card number for display purposes.
  @override
  final String? lastFour;
  @override
  final String currency;

  /// Current balance in cents. Negative values indicate debt (credit cards).
  @override
  final int currentBalance;

  /// Credit limit in cents. Only set for [AccountType.creditCard].
  @override
  final int? creditLimit;
  @override
  final bool isActive;

  /// Optional hex color for the account card (e.g. "#3B82F6").
  @override
  final String? color;

  /// Annual interest rate as a decimal (e.g. 0.2499 = 24.99% APR).
  /// Null means not applicable (e.g. checking, cash).
  @override
  final double? interestRate;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'Account(id: $id, householdId: $householdId, ownerUserId: $ownerUserId, name: $name, accountType: $accountType, institution: $institution, lastFour: $lastFour, currency: $currency, currentBalance: $currentBalance, creditLimit: $creditLimit, isActive: $isActive, color: $color, interestRate: $interestRate, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.ownerUserId, ownerUserId) ||
                other.ownerUserId == ownerUserId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.accountType, accountType) ||
                other.accountType == accountType) &&
            (identical(other.institution, institution) ||
                other.institution == institution) &&
            (identical(other.lastFour, lastFour) ||
                other.lastFour == lastFour) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.currentBalance, currentBalance) ||
                other.currentBalance == currentBalance) &&
            (identical(other.creditLimit, creditLimit) ||
                other.creditLimit == creditLimit) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.interestRate, interestRate) ||
                other.interestRate == interestRate) &&
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
    ownerUserId,
    name,
    accountType,
    institution,
    lastFour,
    currency,
    currentBalance,
    creditLimit,
    isActive,
    color,
    interestRate,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      __$$AccountImplCopyWithImpl<_$AccountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccountImplToJson(this);
  }
}

abstract class _Account implements Account {
  const factory _Account({
    required final String id,
    required final String householdId,
    required final String ownerUserId,
    required final String name,
    required final AccountType accountType,
    final String? institution,
    final String? lastFour,
    required final String currency,
    required final int currentBalance,
    final int? creditLimit,
    required final bool isActive,
    final String? color,
    final double? interestRate,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$AccountImpl;

  factory _Account.fromJson(Map<String, dynamic> json) = _$AccountImpl.fromJson;

  @override
  String get id;
  @override
  String get householdId;

  /// The family member who owns this account (may differ from the logged-in user).
  @override
  String get ownerUserId;
  @override
  String get name;
  @override
  AccountType get accountType;
  @override
  String? get institution;

  /// Last 4 digits of the account/card number for display purposes.
  @override
  String? get lastFour;
  @override
  String get currency;

  /// Current balance in cents. Negative values indicate debt (credit cards).
  @override
  int get currentBalance;

  /// Credit limit in cents. Only set for [AccountType.creditCard].
  @override
  int? get creditLimit;
  @override
  bool get isActive;

  /// Optional hex color for the account card (e.g. "#3B82F6").
  @override
  String? get color;

  /// Annual interest rate as a decimal (e.g. 0.2499 = 24.99% APR).
  /// Null means not applicable (e.g. checking, cash).
  @override
  double? get interestRate;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
