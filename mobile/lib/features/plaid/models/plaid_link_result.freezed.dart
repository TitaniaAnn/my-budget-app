// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plaid_link_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlaidExchangeResult _$PlaidExchangeResultFromJson(Map<String, dynamic> json) {
  return _PlaidExchangeResult.fromJson(json);
}

/// @nodoc
mixin _$PlaidExchangeResult {
  String get plaidItemId => throw _privateConstructorUsedError;
  PlaidInstitutionRef get institution => throw _privateConstructorUsedError;
  List<PlaidInsertedAccount> get insertedAccounts =>
      throw _privateConstructorUsedError;
  List<PlaidSkippedAccount> get skippedAccounts =>
      throw _privateConstructorUsedError;

  /// Serializes this PlaidExchangeResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaidExchangeResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaidExchangeResultCopyWith<PlaidExchangeResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaidExchangeResultCopyWith<$Res> {
  factory $PlaidExchangeResultCopyWith(
    PlaidExchangeResult value,
    $Res Function(PlaidExchangeResult) then,
  ) = _$PlaidExchangeResultCopyWithImpl<$Res, PlaidExchangeResult>;
  @useResult
  $Res call({
    String plaidItemId,
    PlaidInstitutionRef institution,
    List<PlaidInsertedAccount> insertedAccounts,
    List<PlaidSkippedAccount> skippedAccounts,
  });

  $PlaidInstitutionRefCopyWith<$Res> get institution;
}

/// @nodoc
class _$PlaidExchangeResultCopyWithImpl<$Res, $Val extends PlaidExchangeResult>
    implements $PlaidExchangeResultCopyWith<$Res> {
  _$PlaidExchangeResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaidExchangeResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plaidItemId = null,
    Object? institution = null,
    Object? insertedAccounts = null,
    Object? skippedAccounts = null,
  }) {
    return _then(
      _value.copyWith(
            plaidItemId: null == plaidItemId
                ? _value.plaidItemId
                : plaidItemId // ignore: cast_nullable_to_non_nullable
                      as String,
            institution: null == institution
                ? _value.institution
                : institution // ignore: cast_nullable_to_non_nullable
                      as PlaidInstitutionRef,
            insertedAccounts: null == insertedAccounts
                ? _value.insertedAccounts
                : insertedAccounts // ignore: cast_nullable_to_non_nullable
                      as List<PlaidInsertedAccount>,
            skippedAccounts: null == skippedAccounts
                ? _value.skippedAccounts
                : skippedAccounts // ignore: cast_nullable_to_non_nullable
                      as List<PlaidSkippedAccount>,
          )
          as $Val,
    );
  }

  /// Create a copy of PlaidExchangeResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaidInstitutionRefCopyWith<$Res> get institution {
    return $PlaidInstitutionRefCopyWith<$Res>(_value.institution, (value) {
      return _then(_value.copyWith(institution: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PlaidExchangeResultImplCopyWith<$Res>
    implements $PlaidExchangeResultCopyWith<$Res> {
  factory _$$PlaidExchangeResultImplCopyWith(
    _$PlaidExchangeResultImpl value,
    $Res Function(_$PlaidExchangeResultImpl) then,
  ) = __$$PlaidExchangeResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String plaidItemId,
    PlaidInstitutionRef institution,
    List<PlaidInsertedAccount> insertedAccounts,
    List<PlaidSkippedAccount> skippedAccounts,
  });

  @override
  $PlaidInstitutionRefCopyWith<$Res> get institution;
}

/// @nodoc
class __$$PlaidExchangeResultImplCopyWithImpl<$Res>
    extends _$PlaidExchangeResultCopyWithImpl<$Res, _$PlaidExchangeResultImpl>
    implements _$$PlaidExchangeResultImplCopyWith<$Res> {
  __$$PlaidExchangeResultImplCopyWithImpl(
    _$PlaidExchangeResultImpl _value,
    $Res Function(_$PlaidExchangeResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaidExchangeResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plaidItemId = null,
    Object? institution = null,
    Object? insertedAccounts = null,
    Object? skippedAccounts = null,
  }) {
    return _then(
      _$PlaidExchangeResultImpl(
        plaidItemId: null == plaidItemId
            ? _value.plaidItemId
            : plaidItemId // ignore: cast_nullable_to_non_nullable
                  as String,
        institution: null == institution
            ? _value.institution
            : institution // ignore: cast_nullable_to_non_nullable
                  as PlaidInstitutionRef,
        insertedAccounts: null == insertedAccounts
            ? _value._insertedAccounts
            : insertedAccounts // ignore: cast_nullable_to_non_nullable
                  as List<PlaidInsertedAccount>,
        skippedAccounts: null == skippedAccounts
            ? _value._skippedAccounts
            : skippedAccounts // ignore: cast_nullable_to_non_nullable
                  as List<PlaidSkippedAccount>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaidExchangeResultImpl implements _PlaidExchangeResult {
  const _$PlaidExchangeResultImpl({
    required this.plaidItemId,
    required this.institution,
    final List<PlaidInsertedAccount> insertedAccounts = const [],
    final List<PlaidSkippedAccount> skippedAccounts = const [],
  }) : _insertedAccounts = insertedAccounts,
       _skippedAccounts = skippedAccounts;

  factory _$PlaidExchangeResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaidExchangeResultImplFromJson(json);

  @override
  final String plaidItemId;
  @override
  final PlaidInstitutionRef institution;
  final List<PlaidInsertedAccount> _insertedAccounts;
  @override
  @JsonKey()
  List<PlaidInsertedAccount> get insertedAccounts {
    if (_insertedAccounts is EqualUnmodifiableListView)
      return _insertedAccounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_insertedAccounts);
  }

  final List<PlaidSkippedAccount> _skippedAccounts;
  @override
  @JsonKey()
  List<PlaidSkippedAccount> get skippedAccounts {
    if (_skippedAccounts is EqualUnmodifiableListView) return _skippedAccounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_skippedAccounts);
  }

  @override
  String toString() {
    return 'PlaidExchangeResult(plaidItemId: $plaidItemId, institution: $institution, insertedAccounts: $insertedAccounts, skippedAccounts: $skippedAccounts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaidExchangeResultImpl &&
            (identical(other.plaidItemId, plaidItemId) ||
                other.plaidItemId == plaidItemId) &&
            (identical(other.institution, institution) ||
                other.institution == institution) &&
            const DeepCollectionEquality().equals(
              other._insertedAccounts,
              _insertedAccounts,
            ) &&
            const DeepCollectionEquality().equals(
              other._skippedAccounts,
              _skippedAccounts,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    plaidItemId,
    institution,
    const DeepCollectionEquality().hash(_insertedAccounts),
    const DeepCollectionEquality().hash(_skippedAccounts),
  );

  /// Create a copy of PlaidExchangeResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaidExchangeResultImplCopyWith<_$PlaidExchangeResultImpl> get copyWith =>
      __$$PlaidExchangeResultImplCopyWithImpl<_$PlaidExchangeResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaidExchangeResultImplToJson(this);
  }
}

abstract class _PlaidExchangeResult implements PlaidExchangeResult {
  const factory _PlaidExchangeResult({
    required final String plaidItemId,
    required final PlaidInstitutionRef institution,
    final List<PlaidInsertedAccount> insertedAccounts,
    final List<PlaidSkippedAccount> skippedAccounts,
  }) = _$PlaidExchangeResultImpl;

  factory _PlaidExchangeResult.fromJson(Map<String, dynamic> json) =
      _$PlaidExchangeResultImpl.fromJson;

  @override
  String get plaidItemId;
  @override
  PlaidInstitutionRef get institution;
  @override
  List<PlaidInsertedAccount> get insertedAccounts;
  @override
  List<PlaidSkippedAccount> get skippedAccounts;

  /// Create a copy of PlaidExchangeResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaidExchangeResultImplCopyWith<_$PlaidExchangeResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaidInstitutionRef _$PlaidInstitutionRefFromJson(Map<String, dynamic> json) {
  return _PlaidInstitutionRef.fromJson(json);
}

/// @nodoc
mixin _$PlaidInstitutionRef {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this PlaidInstitutionRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaidInstitutionRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaidInstitutionRefCopyWith<PlaidInstitutionRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaidInstitutionRefCopyWith<$Res> {
  factory $PlaidInstitutionRefCopyWith(
    PlaidInstitutionRef value,
    $Res Function(PlaidInstitutionRef) then,
  ) = _$PlaidInstitutionRefCopyWithImpl<$Res, PlaidInstitutionRef>;
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class _$PlaidInstitutionRefCopyWithImpl<$Res, $Val extends PlaidInstitutionRef>
    implements $PlaidInstitutionRefCopyWith<$Res> {
  _$PlaidInstitutionRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaidInstitutionRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaidInstitutionRefImplCopyWith<$Res>
    implements $PlaidInstitutionRefCopyWith<$Res> {
  factory _$$PlaidInstitutionRefImplCopyWith(
    _$PlaidInstitutionRefImpl value,
    $Res Function(_$PlaidInstitutionRefImpl) then,
  ) = __$$PlaidInstitutionRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name});
}

/// @nodoc
class __$$PlaidInstitutionRefImplCopyWithImpl<$Res>
    extends _$PlaidInstitutionRefCopyWithImpl<$Res, _$PlaidInstitutionRefImpl>
    implements _$$PlaidInstitutionRefImplCopyWith<$Res> {
  __$$PlaidInstitutionRefImplCopyWithImpl(
    _$PlaidInstitutionRefImpl _value,
    $Res Function(_$PlaidInstitutionRefImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaidInstitutionRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null}) {
    return _then(
      _$PlaidInstitutionRefImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaidInstitutionRefImpl implements _PlaidInstitutionRef {
  const _$PlaidInstitutionRefImpl({required this.id, required this.name});

  factory _$PlaidInstitutionRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaidInstitutionRefImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  @override
  String toString() {
    return 'PlaidInstitutionRef(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaidInstitutionRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name);

  /// Create a copy of PlaidInstitutionRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaidInstitutionRefImplCopyWith<_$PlaidInstitutionRefImpl> get copyWith =>
      __$$PlaidInstitutionRefImplCopyWithImpl<_$PlaidInstitutionRefImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaidInstitutionRefImplToJson(this);
  }
}

abstract class _PlaidInstitutionRef implements PlaidInstitutionRef {
  const factory _PlaidInstitutionRef({
    required final String id,
    required final String name,
  }) = _$PlaidInstitutionRefImpl;

  factory _PlaidInstitutionRef.fromJson(Map<String, dynamic> json) =
      _$PlaidInstitutionRefImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Create a copy of PlaidInstitutionRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaidInstitutionRefImplCopyWith<_$PlaidInstitutionRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaidInsertedAccount _$PlaidInsertedAccountFromJson(Map<String, dynamic> json) {
  return _PlaidInsertedAccount.fromJson(json);
}

/// @nodoc
mixin _$PlaidInsertedAccount {
  String get accountId => throw _privateConstructorUsedError;
  String get plaidAccountId => throw _privateConstructorUsedError;
  String get accountType => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Serializes this PlaidInsertedAccount to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaidInsertedAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaidInsertedAccountCopyWith<PlaidInsertedAccount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaidInsertedAccountCopyWith<$Res> {
  factory $PlaidInsertedAccountCopyWith(
    PlaidInsertedAccount value,
    $Res Function(PlaidInsertedAccount) then,
  ) = _$PlaidInsertedAccountCopyWithImpl<$Res, PlaidInsertedAccount>;
  @useResult
  $Res call({
    String accountId,
    String plaidAccountId,
    String accountType,
    String name,
  });
}

/// @nodoc
class _$PlaidInsertedAccountCopyWithImpl<
  $Res,
  $Val extends PlaidInsertedAccount
>
    implements $PlaidInsertedAccountCopyWith<$Res> {
  _$PlaidInsertedAccountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaidInsertedAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? plaidAccountId = null,
    Object? accountType = null,
    Object? name = null,
  }) {
    return _then(
      _value.copyWith(
            accountId: null == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String,
            plaidAccountId: null == plaidAccountId
                ? _value.plaidAccountId
                : plaidAccountId // ignore: cast_nullable_to_non_nullable
                      as String,
            accountType: null == accountType
                ? _value.accountType
                : accountType // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaidInsertedAccountImplCopyWith<$Res>
    implements $PlaidInsertedAccountCopyWith<$Res> {
  factory _$$PlaidInsertedAccountImplCopyWith(
    _$PlaidInsertedAccountImpl value,
    $Res Function(_$PlaidInsertedAccountImpl) then,
  ) = __$$PlaidInsertedAccountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accountId,
    String plaidAccountId,
    String accountType,
    String name,
  });
}

/// @nodoc
class __$$PlaidInsertedAccountImplCopyWithImpl<$Res>
    extends _$PlaidInsertedAccountCopyWithImpl<$Res, _$PlaidInsertedAccountImpl>
    implements _$$PlaidInsertedAccountImplCopyWith<$Res> {
  __$$PlaidInsertedAccountImplCopyWithImpl(
    _$PlaidInsertedAccountImpl _value,
    $Res Function(_$PlaidInsertedAccountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaidInsertedAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? plaidAccountId = null,
    Object? accountType = null,
    Object? name = null,
  }) {
    return _then(
      _$PlaidInsertedAccountImpl(
        accountId: null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
        plaidAccountId: null == plaidAccountId
            ? _value.plaidAccountId
            : plaidAccountId // ignore: cast_nullable_to_non_nullable
                  as String,
        accountType: null == accountType
            ? _value.accountType
            : accountType // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaidInsertedAccountImpl implements _PlaidInsertedAccount {
  const _$PlaidInsertedAccountImpl({
    required this.accountId,
    required this.plaidAccountId,
    required this.accountType,
    required this.name,
  });

  factory _$PlaidInsertedAccountImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaidInsertedAccountImplFromJson(json);

  @override
  final String accountId;
  @override
  final String plaidAccountId;
  @override
  final String accountType;
  @override
  final String name;

  @override
  String toString() {
    return 'PlaidInsertedAccount(accountId: $accountId, plaidAccountId: $plaidAccountId, accountType: $accountType, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaidInsertedAccountImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.plaidAccountId, plaidAccountId) ||
                other.plaidAccountId == plaidAccountId) &&
            (identical(other.accountType, accountType) ||
                other.accountType == accountType) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, accountId, plaidAccountId, accountType, name);

  /// Create a copy of PlaidInsertedAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaidInsertedAccountImplCopyWith<_$PlaidInsertedAccountImpl>
  get copyWith =>
      __$$PlaidInsertedAccountImplCopyWithImpl<_$PlaidInsertedAccountImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaidInsertedAccountImplToJson(this);
  }
}

abstract class _PlaidInsertedAccount implements PlaidInsertedAccount {
  const factory _PlaidInsertedAccount({
    required final String accountId,
    required final String plaidAccountId,
    required final String accountType,
    required final String name,
  }) = _$PlaidInsertedAccountImpl;

  factory _PlaidInsertedAccount.fromJson(Map<String, dynamic> json) =
      _$PlaidInsertedAccountImpl.fromJson;

  @override
  String get accountId;
  @override
  String get plaidAccountId;
  @override
  String get accountType;
  @override
  String get name;

  /// Create a copy of PlaidInsertedAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaidInsertedAccountImplCopyWith<_$PlaidInsertedAccountImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PlaidSkippedAccount _$PlaidSkippedAccountFromJson(Map<String, dynamic> json) {
  return _PlaidSkippedAccount.fromJson(json);
}

/// @nodoc
mixin _$PlaidSkippedAccount {
  String get plaidAccountId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get plaidType => throw _privateConstructorUsedError;
  String get plaidSubtype => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;

  /// Serializes this PlaidSkippedAccount to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaidSkippedAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaidSkippedAccountCopyWith<PlaidSkippedAccount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaidSkippedAccountCopyWith<$Res> {
  factory $PlaidSkippedAccountCopyWith(
    PlaidSkippedAccount value,
    $Res Function(PlaidSkippedAccount) then,
  ) = _$PlaidSkippedAccountCopyWithImpl<$Res, PlaidSkippedAccount>;
  @useResult
  $Res call({
    String plaidAccountId,
    String name,
    String plaidType,
    String plaidSubtype,
    String reason,
  });
}

/// @nodoc
class _$PlaidSkippedAccountCopyWithImpl<$Res, $Val extends PlaidSkippedAccount>
    implements $PlaidSkippedAccountCopyWith<$Res> {
  _$PlaidSkippedAccountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaidSkippedAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plaidAccountId = null,
    Object? name = null,
    Object? plaidType = null,
    Object? plaidSubtype = null,
    Object? reason = null,
  }) {
    return _then(
      _value.copyWith(
            plaidAccountId: null == plaidAccountId
                ? _value.plaidAccountId
                : plaidAccountId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            plaidType: null == plaidType
                ? _value.plaidType
                : plaidType // ignore: cast_nullable_to_non_nullable
                      as String,
            plaidSubtype: null == plaidSubtype
                ? _value.plaidSubtype
                : plaidSubtype // ignore: cast_nullable_to_non_nullable
                      as String,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaidSkippedAccountImplCopyWith<$Res>
    implements $PlaidSkippedAccountCopyWith<$Res> {
  factory _$$PlaidSkippedAccountImplCopyWith(
    _$PlaidSkippedAccountImpl value,
    $Res Function(_$PlaidSkippedAccountImpl) then,
  ) = __$$PlaidSkippedAccountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String plaidAccountId,
    String name,
    String plaidType,
    String plaidSubtype,
    String reason,
  });
}

/// @nodoc
class __$$PlaidSkippedAccountImplCopyWithImpl<$Res>
    extends _$PlaidSkippedAccountCopyWithImpl<$Res, _$PlaidSkippedAccountImpl>
    implements _$$PlaidSkippedAccountImplCopyWith<$Res> {
  __$$PlaidSkippedAccountImplCopyWithImpl(
    _$PlaidSkippedAccountImpl _value,
    $Res Function(_$PlaidSkippedAccountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaidSkippedAccount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plaidAccountId = null,
    Object? name = null,
    Object? plaidType = null,
    Object? plaidSubtype = null,
    Object? reason = null,
  }) {
    return _then(
      _$PlaidSkippedAccountImpl(
        plaidAccountId: null == plaidAccountId
            ? _value.plaidAccountId
            : plaidAccountId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        plaidType: null == plaidType
            ? _value.plaidType
            : plaidType // ignore: cast_nullable_to_non_nullable
                  as String,
        plaidSubtype: null == plaidSubtype
            ? _value.plaidSubtype
            : plaidSubtype // ignore: cast_nullable_to_non_nullable
                  as String,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaidSkippedAccountImpl implements _PlaidSkippedAccount {
  const _$PlaidSkippedAccountImpl({
    required this.plaidAccountId,
    required this.name,
    required this.plaidType,
    required this.plaidSubtype,
    required this.reason,
  });

  factory _$PlaidSkippedAccountImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaidSkippedAccountImplFromJson(json);

  @override
  final String plaidAccountId;
  @override
  final String name;
  @override
  final String plaidType;
  @override
  final String plaidSubtype;
  @override
  final String reason;

  @override
  String toString() {
    return 'PlaidSkippedAccount(plaidAccountId: $plaidAccountId, name: $name, plaidType: $plaidType, plaidSubtype: $plaidSubtype, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaidSkippedAccountImpl &&
            (identical(other.plaidAccountId, plaidAccountId) ||
                other.plaidAccountId == plaidAccountId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.plaidType, plaidType) ||
                other.plaidType == plaidType) &&
            (identical(other.plaidSubtype, plaidSubtype) ||
                other.plaidSubtype == plaidSubtype) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    plaidAccountId,
    name,
    plaidType,
    plaidSubtype,
    reason,
  );

  /// Create a copy of PlaidSkippedAccount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaidSkippedAccountImplCopyWith<_$PlaidSkippedAccountImpl> get copyWith =>
      __$$PlaidSkippedAccountImplCopyWithImpl<_$PlaidSkippedAccountImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaidSkippedAccountImplToJson(this);
  }
}

abstract class _PlaidSkippedAccount implements PlaidSkippedAccount {
  const factory _PlaidSkippedAccount({
    required final String plaidAccountId,
    required final String name,
    required final String plaidType,
    required final String plaidSubtype,
    required final String reason,
  }) = _$PlaidSkippedAccountImpl;

  factory _PlaidSkippedAccount.fromJson(Map<String, dynamic> json) =
      _$PlaidSkippedAccountImpl.fromJson;

  @override
  String get plaidAccountId;
  @override
  String get name;
  @override
  String get plaidType;
  @override
  String get plaidSubtype;
  @override
  String get reason;

  /// Create a copy of PlaidSkippedAccount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaidSkippedAccountImplCopyWith<_$PlaidSkippedAccountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlaidSyncResult _$PlaidSyncResultFromJson(Map<String, dynamic> json) {
  return _PlaidSyncResult.fromJson(json);
}

/// @nodoc
mixin _$PlaidSyncResult {
  int get added => throw _privateConstructorUsedError;
  int get modified => throw _privateConstructorUsedError;
  int get removed => throw _privateConstructorUsedError;
  int get merged => throw _privateConstructorUsedError;
  List<String> get accountsSynced => throw _privateConstructorUsedError;
  bool get requiresReauth => throw _privateConstructorUsedError;
  String? get errorCode => throw _privateConstructorUsedError;

  /// Serializes this PlaidSyncResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaidSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaidSyncResultCopyWith<PlaidSyncResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaidSyncResultCopyWith<$Res> {
  factory $PlaidSyncResultCopyWith(
    PlaidSyncResult value,
    $Res Function(PlaidSyncResult) then,
  ) = _$PlaidSyncResultCopyWithImpl<$Res, PlaidSyncResult>;
  @useResult
  $Res call({
    int added,
    int modified,
    int removed,
    int merged,
    List<String> accountsSynced,
    bool requiresReauth,
    String? errorCode,
  });
}

/// @nodoc
class _$PlaidSyncResultCopyWithImpl<$Res, $Val extends PlaidSyncResult>
    implements $PlaidSyncResultCopyWith<$Res> {
  _$PlaidSyncResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaidSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? added = null,
    Object? modified = null,
    Object? removed = null,
    Object? merged = null,
    Object? accountsSynced = null,
    Object? requiresReauth = null,
    Object? errorCode = freezed,
  }) {
    return _then(
      _value.copyWith(
            added: null == added
                ? _value.added
                : added // ignore: cast_nullable_to_non_nullable
                      as int,
            modified: null == modified
                ? _value.modified
                : modified // ignore: cast_nullable_to_non_nullable
                      as int,
            removed: null == removed
                ? _value.removed
                : removed // ignore: cast_nullable_to_non_nullable
                      as int,
            merged: null == merged
                ? _value.merged
                : merged // ignore: cast_nullable_to_non_nullable
                      as int,
            accountsSynced: null == accountsSynced
                ? _value.accountsSynced
                : accountsSynced // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            requiresReauth: null == requiresReauth
                ? _value.requiresReauth
                : requiresReauth // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorCode: freezed == errorCode
                ? _value.errorCode
                : errorCode // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaidSyncResultImplCopyWith<$Res>
    implements $PlaidSyncResultCopyWith<$Res> {
  factory _$$PlaidSyncResultImplCopyWith(
    _$PlaidSyncResultImpl value,
    $Res Function(_$PlaidSyncResultImpl) then,
  ) = __$$PlaidSyncResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int added,
    int modified,
    int removed,
    int merged,
    List<String> accountsSynced,
    bool requiresReauth,
    String? errorCode,
  });
}

/// @nodoc
class __$$PlaidSyncResultImplCopyWithImpl<$Res>
    extends _$PlaidSyncResultCopyWithImpl<$Res, _$PlaidSyncResultImpl>
    implements _$$PlaidSyncResultImplCopyWith<$Res> {
  __$$PlaidSyncResultImplCopyWithImpl(
    _$PlaidSyncResultImpl _value,
    $Res Function(_$PlaidSyncResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaidSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? added = null,
    Object? modified = null,
    Object? removed = null,
    Object? merged = null,
    Object? accountsSynced = null,
    Object? requiresReauth = null,
    Object? errorCode = freezed,
  }) {
    return _then(
      _$PlaidSyncResultImpl(
        added: null == added
            ? _value.added
            : added // ignore: cast_nullable_to_non_nullable
                  as int,
        modified: null == modified
            ? _value.modified
            : modified // ignore: cast_nullable_to_non_nullable
                  as int,
        removed: null == removed
            ? _value.removed
            : removed // ignore: cast_nullable_to_non_nullable
                  as int,
        merged: null == merged
            ? _value.merged
            : merged // ignore: cast_nullable_to_non_nullable
                  as int,
        accountsSynced: null == accountsSynced
            ? _value._accountsSynced
            : accountsSynced // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        requiresReauth: null == requiresReauth
            ? _value.requiresReauth
            : requiresReauth // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorCode: freezed == errorCode
            ? _value.errorCode
            : errorCode // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaidSyncResultImpl implements _PlaidSyncResult {
  const _$PlaidSyncResultImpl({
    this.added = 0,
    this.modified = 0,
    this.removed = 0,
    this.merged = 0,
    final List<String> accountsSynced = const [],
    this.requiresReauth = false,
    this.errorCode,
  }) : _accountsSynced = accountsSynced;

  factory _$PlaidSyncResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaidSyncResultImplFromJson(json);

  @override
  @JsonKey()
  final int added;
  @override
  @JsonKey()
  final int modified;
  @override
  @JsonKey()
  final int removed;
  @override
  @JsonKey()
  final int merged;
  final List<String> _accountsSynced;
  @override
  @JsonKey()
  List<String> get accountsSynced {
    if (_accountsSynced is EqualUnmodifiableListView) return _accountsSynced;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_accountsSynced);
  }

  @override
  @JsonKey()
  final bool requiresReauth;
  @override
  final String? errorCode;

  @override
  String toString() {
    return 'PlaidSyncResult(added: $added, modified: $modified, removed: $removed, merged: $merged, accountsSynced: $accountsSynced, requiresReauth: $requiresReauth, errorCode: $errorCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaidSyncResultImpl &&
            (identical(other.added, added) || other.added == added) &&
            (identical(other.modified, modified) ||
                other.modified == modified) &&
            (identical(other.removed, removed) || other.removed == removed) &&
            (identical(other.merged, merged) || other.merged == merged) &&
            const DeepCollectionEquality().equals(
              other._accountsSynced,
              _accountsSynced,
            ) &&
            (identical(other.requiresReauth, requiresReauth) ||
                other.requiresReauth == requiresReauth) &&
            (identical(other.errorCode, errorCode) ||
                other.errorCode == errorCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    added,
    modified,
    removed,
    merged,
    const DeepCollectionEquality().hash(_accountsSynced),
    requiresReauth,
    errorCode,
  );

  /// Create a copy of PlaidSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaidSyncResultImplCopyWith<_$PlaidSyncResultImpl> get copyWith =>
      __$$PlaidSyncResultImplCopyWithImpl<_$PlaidSyncResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaidSyncResultImplToJson(this);
  }
}

abstract class _PlaidSyncResult implements PlaidSyncResult {
  const factory _PlaidSyncResult({
    final int added,
    final int modified,
    final int removed,
    final int merged,
    final List<String> accountsSynced,
    final bool requiresReauth,
    final String? errorCode,
  }) = _$PlaidSyncResultImpl;

  factory _PlaidSyncResult.fromJson(Map<String, dynamic> json) =
      _$PlaidSyncResultImpl.fromJson;

  @override
  int get added;
  @override
  int get modified;
  @override
  int get removed;
  @override
  int get merged;
  @override
  List<String> get accountsSynced;
  @override
  bool get requiresReauth;
  @override
  String? get errorCode;

  /// Create a copy of PlaidSyncResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaidSyncResultImplCopyWith<_$PlaidSyncResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
