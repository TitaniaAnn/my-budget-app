// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Wraps connectivity_plus in a Riverpod state. keepAlive so the
/// subscription survives provider scope changes — connectivity
/// state is app-global, not per-screen.

@ProviderFor(IsOnline)
final isOnlineProvider = IsOnlineProvider._();

/// Wraps connectivity_plus in a Riverpod state. keepAlive so the
/// subscription survives provider scope changes — connectivity
/// state is app-global, not per-screen.
final class IsOnlineProvider extends $NotifierProvider<IsOnline, bool> {
  /// Wraps connectivity_plus in a Riverpod state. keepAlive so the
  /// subscription survives provider scope changes — connectivity
  /// state is app-global, not per-screen.
  IsOnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isOnlineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isOnlineHash();

  @$internal
  @override
  IsOnline create() => IsOnline();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isOnlineHash() => r'b12122e7668a5a7a98dd15ae1e540bb39749f315';

/// Wraps connectivity_plus in a Riverpod state. keepAlive so the
/// subscription survives provider scope changes — connectivity
/// state is app-global, not per-screen.

abstract class _$IsOnline extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
