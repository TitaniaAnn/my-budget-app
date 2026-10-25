// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserLocale)
final userLocaleProvider = UserLocaleProvider._();

final class UserLocaleProvider extends $NotifierProvider<UserLocale, String> {
  UserLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userLocaleHash();

  @$internal
  @override
  UserLocale create() => UserLocale();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$userLocaleHash() => r'f6867ec6a9e0d9395d9585e3d16b68dc24b577b9';

abstract class _$UserLocale extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
