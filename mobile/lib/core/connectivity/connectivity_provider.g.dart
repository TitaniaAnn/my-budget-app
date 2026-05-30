// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isOnlineHash() => r'b12122e7668a5a7a98dd15ae1e540bb39749f315';

/// Wraps connectivity_plus in a Riverpod state. keepAlive so the
/// subscription survives provider scope changes — connectivity
/// state is app-global, not per-screen.
///
/// Copied from [IsOnline].
@ProviderFor(IsOnline)
final isOnlineProvider = NotifierProvider<IsOnline, bool>.internal(
  IsOnline.new,
  name: r'isOnlineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isOnlineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$IsOnline = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
