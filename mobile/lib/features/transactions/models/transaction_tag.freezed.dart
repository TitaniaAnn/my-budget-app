// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TransactionTag _$TransactionTagFromJson(Map<String, dynamic> json) {
  return _TransactionTag.fromJson(json);
}

/// @nodoc
mixin _$TransactionTag {
  String get id => throw _privateConstructorUsedError;
  String get householdId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Optional hex color (e.g. "#22C55E") for the chip background.
  /// CHAR(7) in SQL so a 6-digit hex + leading '#' fits exactly.
  String? get color => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this TransactionTag to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TransactionTag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionTagCopyWith<TransactionTag> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionTagCopyWith<$Res> {
  factory $TransactionTagCopyWith(
    TransactionTag value,
    $Res Function(TransactionTag) then,
  ) = _$TransactionTagCopyWithImpl<$Res, TransactionTag>;
  @useResult
  $Res call({
    String id,
    String householdId,
    String name,
    String? color,
    DateTime createdAt,
  });
}

/// @nodoc
class _$TransactionTagCopyWithImpl<$Res, $Val extends TransactionTag>
    implements $TransactionTagCopyWith<$Res> {
  _$TransactionTagCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TransactionTag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? name = null,
    Object? color = freezed,
    Object? createdAt = null,
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
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            color: freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TransactionTagImplCopyWith<$Res>
    implements $TransactionTagCopyWith<$Res> {
  factory _$$TransactionTagImplCopyWith(
    _$TransactionTagImpl value,
    $Res Function(_$TransactionTagImpl) then,
  ) = __$$TransactionTagImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String householdId,
    String name,
    String? color,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$TransactionTagImplCopyWithImpl<$Res>
    extends _$TransactionTagCopyWithImpl<$Res, _$TransactionTagImpl>
    implements _$$TransactionTagImplCopyWith<$Res> {
  __$$TransactionTagImplCopyWithImpl(
    _$TransactionTagImpl _value,
    $Res Function(_$TransactionTagImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TransactionTag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? householdId = null,
    Object? name = null,
    Object? color = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$TransactionTagImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        householdId: null == householdId
            ? _value.householdId
            : householdId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        color: freezed == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionTagImpl implements _TransactionTag {
  const _$TransactionTagImpl({
    required this.id,
    required this.householdId,
    required this.name,
    this.color,
    required this.createdAt,
  });

  factory _$TransactionTagImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionTagImplFromJson(json);

  @override
  final String id;
  @override
  final String householdId;
  @override
  final String name;

  /// Optional hex color (e.g. "#22C55E") for the chip background.
  /// CHAR(7) in SQL so a 6-digit hex + leading '#' fits exactly.
  @override
  final String? color;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'TransactionTag(id: $id, householdId: $householdId, name: $name, color: $color, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionTagImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.householdId, householdId) ||
                other.householdId == householdId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, householdId, name, color, createdAt);

  /// Create a copy of TransactionTag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionTagImplCopyWith<_$TransactionTagImpl> get copyWith =>
      __$$TransactionTagImplCopyWithImpl<_$TransactionTagImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionTagImplToJson(this);
  }
}

abstract class _TransactionTag implements TransactionTag {
  const factory _TransactionTag({
    required final String id,
    required final String householdId,
    required final String name,
    final String? color,
    required final DateTime createdAt,
  }) = _$TransactionTagImpl;

  factory _TransactionTag.fromJson(Map<String, dynamic> json) =
      _$TransactionTagImpl.fromJson;

  @override
  String get id;
  @override
  String get householdId;
  @override
  String get name;

  /// Optional hex color (e.g. "#22C55E") for the chip background.
  /// CHAR(7) in SQL so a 6-digit hex + leading '#' fits exactly.
  @override
  String? get color;
  @override
  DateTime get createdAt;

  /// Create a copy of TransactionTag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionTagImplCopyWith<_$TransactionTagImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
