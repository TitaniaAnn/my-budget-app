// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_writes_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingWritesQueueHash() =>
    r'd3fed8fda5563dc8b6e324bc0a625a7872390791';

/// Singleton-ish (per ProviderScope) queue exposed via Riverpod.
///
/// Copied from [pendingWritesQueue].
@ProviderFor(pendingWritesQueue)
final pendingWritesQueueProvider = Provider<PendingWritesQueue>.internal(
  pendingWritesQueue,
  name: r'pendingWritesQueueProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingWritesQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingWritesQueueRef = ProviderRef<PendingWritesQueue>;
String _$pendingWritesAutoDrainHash() =>
    r'1f6ba777a443eda89cae77271aa4538f90a51218';

/// Side-effect provider: drains the queue whenever connectivity
/// flips false→true. keepAlive because the listener subscription
/// is process-lifetime.
///
/// Wiring lives here rather than in main.dart so the listener
/// and the queue stay co-located — future maintainers see the
/// trigger and the action together.
///
/// Copied from [PendingWritesAutoDrain].
@ProviderFor(PendingWritesAutoDrain)
final pendingWritesAutoDrainProvider =
    NotifierProvider<PendingWritesAutoDrain, void>.internal(
      PendingWritesAutoDrain.new,
      name: r'pendingWritesAutoDrainProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingWritesAutoDrainHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PendingWritesAutoDrain = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
