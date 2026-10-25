// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sign_out_cache_clear.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SignOutCacheClear)
final signOutCacheClearProvider = SignOutCacheClearProvider._();

final class SignOutCacheClearProvider
    extends $NotifierProvider<SignOutCacheClear, void> {
  SignOutCacheClearProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signOutCacheClearProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signOutCacheClearHash();

  @$internal
  @override
  SignOutCacheClear create() => SignOutCacheClear();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$signOutCacheClearHash() => r'6652b3c2ed0086a451b215763ddcfdc210d8dd2d';

abstract class _$SignOutCacheClear extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
