// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  return _Transaction.fromJson(json);
}

/// @nodoc
mixin _$Transaction {
  String get id => throw _privateConstructorUsedError;
  String get householdId => throw _privateConstructorUsedError;
  String get accountId => throw _privateConstructorUsedError;

  /// Amount in cents. Negative = debit/expense, positive = credit/income.
  int get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;

  /// Raw description from the bank statement or user entry.
  String get description => throw _privateConstructorUsedError;

  /// Cleaned merchant name (may differ from description).
  String? get merchant => throw _privateConstructorUsedError;
  String? get categoryId => throw _privateConstructorUsedError;

  /// The date the transaction occurred (not the processing date).
  DateTime get transactionDate => throw _privateConstructorUsedError;

  /// The date the transaction cleared the account (may lag transactionDate).
  DateTime? get postedDate => throw _privateConstructorUsedError;
  bool get pending => throw _privateConstructorUsedError;

  /// How the transaction was created: 'manual', 'import', or 'plaid'.
  String get source => throw _privateConstructorUsedError;
  String? get enteredBy => throw _privateConstructorUsedError;
  String? get receiptId => throw _privateConstructorUsedError;
  String? get rateId => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  /// Bank-assigned dedup key. Prevents re-importing the same statement twice.
  String? get externalId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Eagerly-loaded category row (null if uncategorized or not joined).
  Category? get category => throw _privateConstructorUsedError;

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionCopyWith<Transaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionCopyWith<$Res> {
  factory $TransactionCopyWith(
    Transaction value,
    $Res Function(Transaction) then,
  ) = _$TransactionCopyWithImpl<$Res, Transaction>;
  @useResult
  $Res call({
    String id,
    String householdId,
    String accountId,
    int amount,
    String currency,
    String description,
    String? merchant,
    String? categoryId,
    DateTime transactionDate,
    DateTime? postedDate,
    bool pending,
    String source,
    String? enteredBy,
    String? receiptId,
    String? rateId,
    String? notes,
    String? externalId,
    DateTime createdAt,
    DateTime updatedAt,
    Category? category,
  });

  $CategoryCopyWith<$Res>? get category;
}

/// @nodoc
class _$TransactionCopyWithImpl<$Res, $Val extends Transaction>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? accountId = null,
    Object? amount = null,
    Object? currency = null,
    Object? description = null,
    Object? merchant = freezed,
    Object? categoryId = freezed,
    Object? transactionDate = null,
    Object? postedDate = freezed,
    Object? pending = null,
    Object? source = null,
    Object? enteredBy = freezed,
    Object? receiptId = freezed,
    Object? rateId = freezed,
    Object? notes = freezed,
    Object? externalId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? category = freezed,
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
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
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
            transactionDate: null == transactionDate
                ? _value.transactionDate
                : transactionDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            postedDate: freezed == postedDate
                ? _value.postedDate
                : postedDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            pending: null == pending
                ? _value.pending
                : pending // ignore: cast_nullable_to_non_nullable
                      as bool,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            enteredBy: freezed == enteredBy
                ? _value.enteredBy
                : enteredBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            receiptId: freezed == receiptId
                ? _value.receiptId
                : receiptId // ignore: cast_nullable_to_non_nullable
                      as String?,
            rateId: freezed == rateId
                ? _value.rateId
                : rateId // ignore: cast_nullable_to_non_nullable
                      as String?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            externalId: freezed == externalId
                ? _value.externalId
                : externalId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as Category?,
          )
          as $Val,
    );
  }

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryCopyWith<$Res>? get category {
    if (_value.category == null) {
      return null;
    }

    return $CategoryCopyWith<$Res>(_value.category!, (value) {
      return _then(_value.copyWith(category: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TransactionImplCopyWith<$Res>
    implements $TransactionCopyWith<$Res> {
  factory _$$TransactionImplCopyWith(
    _$TransactionImpl value,
    $Res Function(_$TransactionImpl) then,
  ) = __$$TransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String householdId,
    String accountId,
    int amount,
    String currency,
    String description,
    String? merchant,
    String? categoryId,
    DateTime transactionDate,
    DateTime? postedDate,
    bool pending,
    String source,
    String? enteredBy,
    String? receiptId,
    String? rateId,
    String? notes,
    String? externalId,
    DateTime createdAt,
    DateTime updatedAt,
    Category? category,
  });

  @override
  $CategoryCopyWith<$Res>? get category;
}

/// @nodoc
class __$$TransactionImplCopyWithImpl<$Res>
    extends _$TransactionCopyWithImpl<$Res, _$TransactionImpl>
    implements _$$TransactionImplCopyWith<$Res> {
  __$$TransactionImplCopyWithImpl(
    _$TransactionImpl _value,
    $Res Function(_$TransactionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? accountId = null,
    Object? amount = null,
    Object? currency = null,
    Object? description = null,
    Object? merchant = freezed,
    Object? categoryId = freezed,
    Object? transactionDate = null,
    Object? postedDate = freezed,
    Object? pending = null,
    Object? source = null,
    Object? enteredBy = freezed,
    Object? receiptId = freezed,
    Object? rateId = freezed,
    Object? notes = freezed,
    Object? externalId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? category = freezed,
  }) {
    return _then(
      _$TransactionImpl(
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
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
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
        transactionDate: null == transactionDate
            ? _value.transactionDate
            : transactionDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        postedDate: freezed == postedDate
            ? _value.postedDate
            : postedDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        pending: null == pending
            ? _value.pending
            : pending // ignore: cast_nullable_to_non_nullable
                  as bool,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        enteredBy: freezed == enteredBy
            ? _value.enteredBy
            : enteredBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        receiptId: freezed == receiptId
            ? _value.receiptId
            : receiptId // ignore: cast_nullable_to_non_nullable
                  as String?,
        rateId: freezed == rateId
            ? _value.rateId
            : rateId // ignore: cast_nullable_to_non_nullable
                  as String?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        externalId: freezed == externalId
            ? _value.externalId
            : externalId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as Category?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionImpl implements _Transaction {
  const _$TransactionImpl({
    required this.id,
    required this.householdId,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.description,
    this.merchant,
    this.categoryId,
    required this.transactionDate,
    this.postedDate,
    required this.pending,
    required this.source,
    this.enteredBy,
    this.receiptId,
    this.rateId,
    this.notes,
    this.externalId,
    required this.createdAt,
    required this.updatedAt,
    this.category,
  });

  factory _$TransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionImplFromJson(json);

  @override
  final String id;
  @override
  final String householdId;
  @override
  final String accountId;

  /// Amount in cents. Negative = debit/expense, positive = credit/income.
  @override
  final int amount;
  @override
  final String currency;

  /// Raw description from the bank statement or user entry.
  @override
  final String description;

  /// Cleaned merchant name (may differ from description).
  @override
  final String? merchant;
  @override
  final String? categoryId;

  /// The date the transaction occurred (not the processing date).
  @override
  final DateTime transactionDate;

  /// The date the transaction cleared the account (may lag transactionDate).
  @override
  final DateTime? postedDate;
  @override
  final bool pending;

  /// How the transaction was created: 'manual', 'import', or 'plaid'.
  @override
  final String source;
  @override
  final String? enteredBy;
  @override
  final String? receiptId;
  @override
  final String? rateId;
  @override
  final String? notes;

  /// Bank-assigned dedup key. Prevents re-importing the same statement twice.
  @override
  final String? externalId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  /// Eagerly-loaded category row (null if uncategorized or not joined).
  @override
  final Category? category;

  @override
  String toString() {
    return 'Transaction(id: $id, householdId: $householdId, accountId: $accountId, amount: $amount, currency: $currency, description: $description, merchant: $merchant, categoryId: $categoryId, transactionDate: $transactionDate, postedDate: $postedDate, pending: $pending, source: $source, enteredBy: $enteredBy, receiptId: $receiptId, rateId: $rateId, notes: $notes, externalId: $externalId, createdAt: $createdAt, updatedAt: $updatedAt, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.transactionDate, transactionDate) ||
                other.transactionDate == transactionDate) &&
            (identical(other.postedDate, postedDate) ||
                other.postedDate == postedDate) &&
            (identical(other.pending, pending) || other.pending == pending) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.enteredBy, enteredBy) ||
                other.enteredBy == enteredBy) &&
            (identical(other.receiptId, receiptId) ||
                other.receiptId == receiptId) &&
            (identical(other.rateId, rateId) || other.rateId == rateId) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.category, category) ||
                other.category == category));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    householdId,
    accountId,
    amount,
    currency,
    description,
    merchant,
    categoryId,
    transactionDate,
    postedDate,
    pending,
    source,
    enteredBy,
    receiptId,
    rateId,
    notes,
    externalId,
    createdAt,
    updatedAt,
    category,
  ]);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      __$$TransactionImplCopyWithImpl<_$TransactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionImplToJson(this);
  }
}

abstract class _Transaction implements Transaction {
  const factory _Transaction({
    required final String id,
    required final String householdId,
    required final String accountId,
    required final int amount,
    required final String currency,
    required final String description,
    final String? merchant,
    final String? categoryId,
    required final DateTime transactionDate,
    final DateTime? postedDate,
    required final bool pending,
    required final String source,
    final String? enteredBy,
    final String? receiptId,
    final String? rateId,
    final String? notes,
    final String? externalId,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final Category? category,
  }) = _$TransactionImpl;

  factory _Transaction.fromJson(Map<String, dynamic> json) =
      _$TransactionImpl.fromJson;

  @override
  String get id;
  @override
  String get householdId;
  @override
  String get accountId;

  /// Amount in cents. Negative = debit/expense, positive = credit/income.
  @override
  int get amount;
  @override
  String get currency;

  /// Raw description from the bank statement or user entry.
  @override
  String get description;

  /// Cleaned merchant name (may differ from description).
  @override
  String? get merchant;
  @override
  String? get categoryId;

  /// The date the transaction occurred (not the processing date).
  @override
  DateTime get transactionDate;

  /// The date the transaction cleared the account (may lag transactionDate).
  @override
  DateTime? get postedDate;
  @override
  bool get pending;

  /// How the transaction was created: 'manual', 'import', or 'plaid'.
  @override
  String get source;
  @override
  String? get enteredBy;
  @override
  String? get receiptId;
  @override
  String? get rateId;
  @override
  String? get notes;

  /// Bank-assigned dedup key. Prevents re-importing the same statement twice.
  @override
  String? get externalId;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Eagerly-loaded category row (null if uncategorized or not joined).
  @override
  Category? get category;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
