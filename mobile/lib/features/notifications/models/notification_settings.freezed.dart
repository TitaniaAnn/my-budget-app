// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NotificationSettings {
  /// Master switch. When false, the engine returns no notifications
  /// regardless of the per-trigger toggles. Lets the user silence
  /// everything in one tap without losing their other preferences.
  bool get enabled => throw _privateConstructorUsedError;

  /// Fire when a category budget's actual spend exceeds the cap.
  bool get budgetOverEnabled => throw _privateConstructorUsedError;

  /// Fire when a transaction's |amount| crosses [largeTxThresholdCents].
  bool get largeTxEnabled => throw _privateConstructorUsedError;

  /// Magnitude in cents at or above which a transaction triggers a
  /// large-transaction notification. Default $200; the settings
  /// screen lets the user adjust.
  int get largeTxThresholdCents => throw _privateConstructorUsedError;

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationSettingsCopyWith<NotificationSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationSettingsCopyWith<$Res> {
  factory $NotificationSettingsCopyWith(
    NotificationSettings value,
    $Res Function(NotificationSettings) then,
  ) = _$NotificationSettingsCopyWithImpl<$Res, NotificationSettings>;
  @useResult
  $Res call({
    bool enabled,
    bool budgetOverEnabled,
    bool largeTxEnabled,
    int largeTxThresholdCents,
  });
}

/// @nodoc
class _$NotificationSettingsCopyWithImpl<
  $Res,
  $Val extends NotificationSettings
>
    implements $NotificationSettingsCopyWith<$Res> {
  _$NotificationSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? budgetOverEnabled = null,
    Object? largeTxEnabled = null,
    Object? largeTxThresholdCents = null,
  }) {
    return _then(
      _value.copyWith(
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            budgetOverEnabled: null == budgetOverEnabled
                ? _value.budgetOverEnabled
                : budgetOverEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            largeTxEnabled: null == largeTxEnabled
                ? _value.largeTxEnabled
                : largeTxEnabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            largeTxThresholdCents: null == largeTxThresholdCents
                ? _value.largeTxThresholdCents
                : largeTxThresholdCents // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NotificationSettingsImplCopyWith<$Res>
    implements $NotificationSettingsCopyWith<$Res> {
  factory _$$NotificationSettingsImplCopyWith(
    _$NotificationSettingsImpl value,
    $Res Function(_$NotificationSettingsImpl) then,
  ) = __$$NotificationSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool enabled,
    bool budgetOverEnabled,
    bool largeTxEnabled,
    int largeTxThresholdCents,
  });
}

/// @nodoc
class __$$NotificationSettingsImplCopyWithImpl<$Res>
    extends _$NotificationSettingsCopyWithImpl<$Res, _$NotificationSettingsImpl>
    implements _$$NotificationSettingsImplCopyWith<$Res> {
  __$$NotificationSettingsImplCopyWithImpl(
    _$NotificationSettingsImpl _value,
    $Res Function(_$NotificationSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? budgetOverEnabled = null,
    Object? largeTxEnabled = null,
    Object? largeTxThresholdCents = null,
  }) {
    return _then(
      _$NotificationSettingsImpl(
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        budgetOverEnabled: null == budgetOverEnabled
            ? _value.budgetOverEnabled
            : budgetOverEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        largeTxEnabled: null == largeTxEnabled
            ? _value.largeTxEnabled
            : largeTxEnabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        largeTxThresholdCents: null == largeTxThresholdCents
            ? _value.largeTxThresholdCents
            : largeTxThresholdCents // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$NotificationSettingsImpl implements _NotificationSettings {
  const _$NotificationSettingsImpl({
    this.enabled = false,
    this.budgetOverEnabled = true,
    this.largeTxEnabled = true,
    this.largeTxThresholdCents = 20000,
  });

  /// Master switch. When false, the engine returns no notifications
  /// regardless of the per-trigger toggles. Lets the user silence
  /// everything in one tap without losing their other preferences.
  @override
  @JsonKey()
  final bool enabled;

  /// Fire when a category budget's actual spend exceeds the cap.
  @override
  @JsonKey()
  final bool budgetOverEnabled;

  /// Fire when a transaction's |amount| crosses [largeTxThresholdCents].
  @override
  @JsonKey()
  final bool largeTxEnabled;

  /// Magnitude in cents at or above which a transaction triggers a
  /// large-transaction notification. Default $200; the settings
  /// screen lets the user adjust.
  @override
  @JsonKey()
  final int largeTxThresholdCents;

  @override
  String toString() {
    return 'NotificationSettings(enabled: $enabled, budgetOverEnabled: $budgetOverEnabled, largeTxEnabled: $largeTxEnabled, largeTxThresholdCents: $largeTxThresholdCents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationSettingsImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.budgetOverEnabled, budgetOverEnabled) ||
                other.budgetOverEnabled == budgetOverEnabled) &&
            (identical(other.largeTxEnabled, largeTxEnabled) ||
                other.largeTxEnabled == largeTxEnabled) &&
            (identical(other.largeTxThresholdCents, largeTxThresholdCents) ||
                other.largeTxThresholdCents == largeTxThresholdCents));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    enabled,
    budgetOverEnabled,
    largeTxEnabled,
    largeTxThresholdCents,
  );

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationSettingsImplCopyWith<_$NotificationSettingsImpl>
  get copyWith =>
      __$$NotificationSettingsImplCopyWithImpl<_$NotificationSettingsImpl>(
        this,
        _$identity,
      );
}

abstract class _NotificationSettings implements NotificationSettings {
  const factory _NotificationSettings({
    final bool enabled,
    final bool budgetOverEnabled,
    final bool largeTxEnabled,
    final int largeTxThresholdCents,
  }) = _$NotificationSettingsImpl;

  /// Master switch. When false, the engine returns no notifications
  /// regardless of the per-trigger toggles. Lets the user silence
  /// everything in one tap without losing their other preferences.
  @override
  bool get enabled;

  /// Fire when a category budget's actual spend exceeds the cap.
  @override
  bool get budgetOverEnabled;

  /// Fire when a transaction's |amount| crosses [largeTxThresholdCents].
  @override
  bool get largeTxEnabled;

  /// Magnitude in cents at or above which a transaction triggers a
  /// large-transaction notification. Default $200; the settings
  /// screen lets the user adjust.
  @override
  int get largeTxThresholdCents;

  /// Create a copy of NotificationSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationSettingsImplCopyWith<_$NotificationSettingsImpl>
  get copyWith => throw _privateConstructorUsedError;
}
