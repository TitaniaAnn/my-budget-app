// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plaid_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlaidItem _$PlaidItemFromJson(Map<String, dynamic> json) {
  return _PlaidItem.fromJson(json);
}

/// @nodoc
mixin _$PlaidItem {
  String get id => throw _privateConstructorUsedError;
  String get householdId => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  String get plaidItemId => throw _privateConstructorUsedError;
  String? get plaidInstitutionId => throw _privateConstructorUsedError;
  String? get institutionName => throw _privateConstructorUsedError;
  PlaidEnvironment get environment => throw _privateConstructorUsedError;
  String? get syncCursor => throw _privateConstructorUsedError;
  DateTime? get lastSyncAt => throw _privateConstructorUsedError;
  String? get lastSyncError => throw _privateConstructorUsedError;
  DateTime? get consentExpiresAt => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PlaidItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaidItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaidItemCopyWith<PlaidItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaidItemCopyWith<$Res> {
  factory $PlaidItemCopyWith(PlaidItem value, $Res Function(PlaidItem) then) =
      _$PlaidItemCopyWithImpl<$Res, PlaidItem>;
  @useResult
  $Res call({
    String id,
    String householdId,
    String createdBy,
    String plaidItemId,
    String? plaidInstitutionId,
    String? institutionName,
    PlaidEnvironment environment,
    String? syncCursor,
    DateTime? lastSyncAt,
    String? lastSyncError,
    DateTime? consentExpiresAt,
    bool isActive,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$PlaidItemCopyWithImpl<$Res, $Val extends PlaidItem>
    implements $PlaidItemCopyWith<$Res> {
  _$PlaidItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaidItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? createdBy = null,
    Object? plaidItemId = null,
    Object? plaidInstitutionId = freezed,
    Object? institutionName = freezed,
    Object? environment = null,
    Object? syncCursor = freezed,
    Object? lastSyncAt = freezed,
    Object? lastSyncError = freezed,
    Object? consentExpiresAt = freezed,
    Object? isActive = null,
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
            plaidItemId: null == plaidItemId
                ? _value.plaidItemId
                : plaidItemId // ignore: cast_nullable_to_non_nullable
                      as String,
            plaidInstitutionId: freezed == plaidInstitutionId
                ? _value.plaidInstitutionId
                : plaidInstitutionId // ignore: cast_nullable_to_non_nullable
                      as String?,
            institutionName: freezed == institutionName
                ? _value.institutionName
                : institutionName // ignore: cast_nullable_to_non_nullable
                      as String?,
            environment: null == environment
                ? _value.environment
                : environment // ignore: cast_nullable_to_non_nullable
                      as PlaidEnvironment,
            syncCursor: freezed == syncCursor
                ? _value.syncCursor
                : syncCursor // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastSyncAt: freezed == lastSyncAt
                ? _value.lastSyncAt
                : lastSyncAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastSyncError: freezed == lastSyncError
                ? _value.lastSyncError
                : lastSyncError // ignore: cast_nullable_to_non_nullable
                      as String?,
            consentExpiresAt: freezed == consentExpiresAt
                ? _value.consentExpiresAt
                : consentExpiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$PlaidItemImplCopyWith<$Res>
    implements $PlaidItemCopyWith<$Res> {
  factory _$$PlaidItemImplCopyWith(
    _$PlaidItemImpl value,
    $Res Function(_$PlaidItemImpl) then,
  ) = __$$PlaidItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String householdId,
    String createdBy,
    String plaidItemId,
    String? plaidInstitutionId,
    String? institutionName,
    PlaidEnvironment environment,
    String? syncCursor,
    DateTime? lastSyncAt,
    String? lastSyncError,
    DateTime? consentExpiresAt,
    bool isActive,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$PlaidItemImplCopyWithImpl<$Res>
    extends _$PlaidItemCopyWithImpl<$Res, _$PlaidItemImpl>
    implements _$$PlaidItemImplCopyWith<$Res> {
  __$$PlaidItemImplCopyWithImpl(
    _$PlaidItemImpl _value,
    $Res Function(_$PlaidItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaidItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? createdBy = null,
    Object? plaidItemId = null,
    Object? plaidInstitutionId = freezed,
    Object? institutionName = freezed,
    Object? environment = null,
    Object? syncCursor = freezed,
    Object? lastSyncAt = freezed,
    Object? lastSyncError = freezed,
    Object? consentExpiresAt = freezed,
    Object? isActive = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$PlaidItemImpl(
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
        plaidItemId: null == plaidItemId
            ? _value.plaidItemId
            : plaidItemId // ignore: cast_nullable_to_non_nullable
                  as String,
        plaidInstitutionId: freezed == plaidInstitutionId
            ? _value.plaidInstitutionId
            : plaidInstitutionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        institutionName: freezed == institutionName
            ? _value.institutionName
            : institutionName // ignore: cast_nullable_to_non_nullable
                  as String?,
        environment: null == environment
            ? _value.environment
            : environment // ignore: cast_nullable_to_non_nullable
                  as PlaidEnvironment,
        syncCursor: freezed == syncCursor
            ? _value.syncCursor
            : syncCursor // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastSyncAt: freezed == lastSyncAt
            ? _value.lastSyncAt
            : lastSyncAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSyncError: freezed == lastSyncError
            ? _value.lastSyncError
            : lastSyncError // ignore: cast_nullable_to_non_nullable
                  as String?,
        consentExpiresAt: freezed == consentExpiresAt
            ? _value.consentExpiresAt
            : consentExpiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$PlaidItemImpl implements _PlaidItem {
  const _$PlaidItemImpl({
    required this.id,
    required this.householdId,
    required this.createdBy,
    required this.plaidItemId,
    this.plaidInstitutionId,
    this.institutionName,
    required this.environment,
    this.syncCursor,
    this.lastSyncAt,
    this.lastSyncError,
    this.consentExpiresAt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _$PlaidItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaidItemImplFromJson(json);

  @override
  final String id;
  @override
  final String householdId;
  @override
  final String createdBy;
  @override
  final String plaidItemId;
  @override
  final String? plaidInstitutionId;
  @override
  final String? institutionName;
  @override
  final PlaidEnvironment environment;
  @override
  final String? syncCursor;
  @override
  final DateTime? lastSyncAt;
  @override
  final String? lastSyncError;
  @override
  final DateTime? consentExpiresAt;
  @override
  final bool isActive;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'PlaidItem(id: $id, householdId: $householdId, createdBy: $createdBy, plaidItemId: $plaidItemId, plaidInstitutionId: $plaidInstitutionId, institutionName: $institutionName, environment: $environment, syncCursor: $syncCursor, lastSyncAt: $lastSyncAt, lastSyncError: $lastSyncError, consentExpiresAt: $consentExpiresAt, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaidItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.plaidItemId, plaidItemId) ||
                other.plaidItemId == plaidItemId) &&
            (identical(other.plaidInstitutionId, plaidInstitutionId) ||
                other.plaidInstitutionId == plaidInstitutionId) &&
            (identical(other.institutionName, institutionName) ||
                other.institutionName == institutionName) &&
            (identical(other.environment, environment) ||
                other.environment == environment) &&
            (identical(other.syncCursor, syncCursor) ||
                other.syncCursor == syncCursor) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt) &&
            (identical(other.lastSyncError, lastSyncError) ||
                other.lastSyncError == lastSyncError) &&
            (identical(other.consentExpiresAt, consentExpiresAt) ||
                other.consentExpiresAt == consentExpiresAt) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
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
    plaidItemId,
    plaidInstitutionId,
    institutionName,
    environment,
    syncCursor,
    lastSyncAt,
    lastSyncError,
    consentExpiresAt,
    isActive,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PlaidItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaidItemImplCopyWith<_$PlaidItemImpl> get copyWith =>
      __$$PlaidItemImplCopyWithImpl<_$PlaidItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaidItemImplToJson(this);
  }
}

abstract class _PlaidItem implements PlaidItem {
  const factory _PlaidItem({
    required final String id,
    required final String householdId,
    required final String createdBy,
    required final String plaidItemId,
    final String? plaidInstitutionId,
    final String? institutionName,
    required final PlaidEnvironment environment,
    final String? syncCursor,
    final DateTime? lastSyncAt,
    final String? lastSyncError,
    final DateTime? consentExpiresAt,
    required final bool isActive,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$PlaidItemImpl;

  factory _PlaidItem.fromJson(Map<String, dynamic> json) =
      _$PlaidItemImpl.fromJson;

  @override
  String get id;
  @override
  String get householdId;
  @override
  String get createdBy;
  @override
  String get plaidItemId;
  @override
  String? get plaidInstitutionId;
  @override
  String? get institutionName;
  @override
  PlaidEnvironment get environment;
  @override
  String? get syncCursor;
  @override
  DateTime? get lastSyncAt;
  @override
  String? get lastSyncError;
  @override
  DateTime? get consentExpiresAt;
  @override
  bool get isActive;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of PlaidItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaidItemImplCopyWith<_$PlaidItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
