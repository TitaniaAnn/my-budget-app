// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UserProfile {
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
    UserProfile value,
    $Res Function(UserProfile) then,
  ) = _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call({String userId, String displayName});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? displayName = null}) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
    _$UserProfileImpl value,
    $Res Function(_$UserProfileImpl) then,
  ) = __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, String displayName});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
    _$UserProfileImpl _value,
    $Res Function(_$UserProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? userId = null, Object? displayName = null}) {
    return _then(
      _$UserProfileImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl({required this.userId, required this.displayName});

  @override
  final String userId;
  @override
  final String displayName;

  @override
  String toString() {
    return 'UserProfile(userId: $userId, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, userId, displayName);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile({
    required final String userId,
    required final String displayName,
  }) = _$UserProfileImpl;

  @override
  String get userId;
  @override
  String get displayName;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$HouseholdMember {
  String get userId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  bool get isCurrentUser => throw _privateConstructorUsedError;

  /// Create a copy of HouseholdMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HouseholdMemberCopyWith<HouseholdMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HouseholdMemberCopyWith<$Res> {
  factory $HouseholdMemberCopyWith(
    HouseholdMember value,
    $Res Function(HouseholdMember) then,
  ) = _$HouseholdMemberCopyWithImpl<$Res, HouseholdMember>;
  @useResult
  $Res call({
    String userId,
    String displayName,
    String role,
    bool isCurrentUser,
  });
}

/// @nodoc
class _$HouseholdMemberCopyWithImpl<$Res, $Val extends HouseholdMember>
    implements $HouseholdMemberCopyWith<$Res> {
  _$HouseholdMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HouseholdMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? role = null,
    Object? isCurrentUser = null,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            isCurrentUser: null == isCurrentUser
                ? _value.isCurrentUser
                : isCurrentUser // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HouseholdMemberImplCopyWith<$Res>
    implements $HouseholdMemberCopyWith<$Res> {
  factory _$$HouseholdMemberImplCopyWith(
    _$HouseholdMemberImpl value,
    $Res Function(_$HouseholdMemberImpl) then,
  ) = __$$HouseholdMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String displayName,
    String role,
    bool isCurrentUser,
  });
}

/// @nodoc
class __$$HouseholdMemberImplCopyWithImpl<$Res>
    extends _$HouseholdMemberCopyWithImpl<$Res, _$HouseholdMemberImpl>
    implements _$$HouseholdMemberImplCopyWith<$Res> {
  __$$HouseholdMemberImplCopyWithImpl(
    _$HouseholdMemberImpl _value,
    $Res Function(_$HouseholdMemberImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HouseholdMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? displayName = null,
    Object? role = null,
    Object? isCurrentUser = null,
  }) {
    return _then(
      _$HouseholdMemberImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        isCurrentUser: null == isCurrentUser
            ? _value.isCurrentUser
            : isCurrentUser // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$HouseholdMemberImpl implements _HouseholdMember {
  const _$HouseholdMemberImpl({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.isCurrentUser,
  });

  @override
  final String userId;
  @override
  final String displayName;
  @override
  final String role;
  @override
  final bool isCurrentUser;

  @override
  String toString() {
    return 'HouseholdMember(userId: $userId, displayName: $displayName, role: $role, isCurrentUser: $isCurrentUser)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HouseholdMemberImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isCurrentUser, isCurrentUser) ||
                other.isCurrentUser == isCurrentUser));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, displayName, role, isCurrentUser);

  /// Create a copy of HouseholdMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HouseholdMemberImplCopyWith<_$HouseholdMemberImpl> get copyWith =>
      __$$HouseholdMemberImplCopyWithImpl<_$HouseholdMemberImpl>(
        this,
        _$identity,
      );
}

abstract class _HouseholdMember implements HouseholdMember {
  const factory _HouseholdMember({
    required final String userId,
    required final String displayName,
    required final String role,
    required final bool isCurrentUser,
  }) = _$HouseholdMemberImpl;

  @override
  String get userId;
  @override
  String get displayName;
  @override
  String get role;
  @override
  bool get isCurrentUser;

  /// Create a copy of HouseholdMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HouseholdMemberImplCopyWith<_$HouseholdMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$HouseholdInfo {
  String get householdId => throw _privateConstructorUsedError;
  String get householdName => throw _privateConstructorUsedError;
  bool get isOwner => throw _privateConstructorUsedError;
  List<HouseholdMember> get members => throw _privateConstructorUsedError;

  /// Create a copy of HouseholdInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HouseholdInfoCopyWith<HouseholdInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HouseholdInfoCopyWith<$Res> {
  factory $HouseholdInfoCopyWith(
    HouseholdInfo value,
    $Res Function(HouseholdInfo) then,
  ) = _$HouseholdInfoCopyWithImpl<$Res, HouseholdInfo>;
  @useResult
  $Res call({
    String householdId,
    String householdName,
    bool isOwner,
    List<HouseholdMember> members,
  });
}

/// @nodoc
class _$HouseholdInfoCopyWithImpl<$Res, $Val extends HouseholdInfo>
    implements $HouseholdInfoCopyWith<$Res> {
  _$HouseholdInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HouseholdInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? householdId = null,
    Object? householdName = null,
    Object? isOwner = null,
    Object? members = null,
  }) {
    return _then(
      _value.copyWith(
            householdId: null == householdId
                ? _value.householdId
                : householdId // ignore: cast_nullable_to_non_nullable
                      as String,
            householdName: null == householdName
                ? _value.householdName
                : householdName // ignore: cast_nullable_to_non_nullable
                      as String,
            isOwner: null == isOwner
                ? _value.isOwner
                : isOwner // ignore: cast_nullable_to_non_nullable
                      as bool,
            members: null == members
                ? _value.members
                : members // ignore: cast_nullable_to_non_nullable
                      as List<HouseholdMember>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HouseholdInfoImplCopyWith<$Res>
    implements $HouseholdInfoCopyWith<$Res> {
  factory _$$HouseholdInfoImplCopyWith(
    _$HouseholdInfoImpl value,
    $Res Function(_$HouseholdInfoImpl) then,
  ) = __$$HouseholdInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String householdId,
    String householdName,
    bool isOwner,
    List<HouseholdMember> members,
  });
}

/// @nodoc
class __$$HouseholdInfoImplCopyWithImpl<$Res>
    extends _$HouseholdInfoCopyWithImpl<$Res, _$HouseholdInfoImpl>
    implements _$$HouseholdInfoImplCopyWith<$Res> {
  __$$HouseholdInfoImplCopyWithImpl(
    _$HouseholdInfoImpl _value,
    $Res Function(_$HouseholdInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HouseholdInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? householdId = null,
    Object? householdName = null,
    Object? isOwner = null,
    Object? members = null,
  }) {
    return _then(
      _$HouseholdInfoImpl(
        householdId: null == householdId
            ? _value.householdId
            : householdId // ignore: cast_nullable_to_non_nullable
                  as String,
        householdName: null == householdName
            ? _value.householdName
            : householdName // ignore: cast_nullable_to_non_nullable
                  as String,
        isOwner: null == isOwner
            ? _value.isOwner
            : isOwner // ignore: cast_nullable_to_non_nullable
                  as bool,
        members: null == members
            ? _value._members
            : members // ignore: cast_nullable_to_non_nullable
                  as List<HouseholdMember>,
      ),
    );
  }
}

/// @nodoc

class _$HouseholdInfoImpl implements _HouseholdInfo {
  const _$HouseholdInfoImpl({
    required this.householdId,
    required this.householdName,
    required this.isOwner,
    required final List<HouseholdMember> members,
  }) : _members = members;

  @override
  final String householdId;
  @override
  final String householdName;
  @override
  final bool isOwner;
  final List<HouseholdMember> _members;
  @override
  List<HouseholdMember> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  String toString() {
    return 'HouseholdInfo(householdId: $householdId, householdName: $householdName, isOwner: $isOwner, members: $members)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HouseholdInfoImpl &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.householdName, householdName) ||
                other.householdName == householdName) &&
            (identical(other.isOwner, isOwner) || other.isOwner == isOwner) &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    householdId,
    householdName,
    isOwner,
    const DeepCollectionEquality().hash(_members),
  );

  /// Create a copy of HouseholdInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HouseholdInfoImplCopyWith<_$HouseholdInfoImpl> get copyWith =>
      __$$HouseholdInfoImplCopyWithImpl<_$HouseholdInfoImpl>(this, _$identity);
}

abstract class _HouseholdInfo implements HouseholdInfo {
  const factory _HouseholdInfo({
    required final String householdId,
    required final String householdName,
    required final bool isOwner,
    required final List<HouseholdMember> members,
  }) = _$HouseholdInfoImpl;

  @override
  String get householdId;
  @override
  String get householdName;
  @override
  bool get isOwner;
  @override
  List<HouseholdMember> get members;

  /// Create a copy of HouseholdInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HouseholdInfoImplCopyWith<_$HouseholdInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
