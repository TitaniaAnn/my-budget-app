// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_writes_queue.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton-ish (per ProviderScope) queue exposed via Riverpod.

@ProviderFor(pendingWritesQueue)
final pendingWritesQueueProvider = PendingWritesQueueProvider._();

/// Singleton-ish (per ProviderScope) queue exposed via Riverpod.

final class PendingWritesQueueProvider
    extends
        $FunctionalProvider<
          PendingWritesQueue,
          PendingWritesQueue,
          PendingWritesQueue
        >
    with $Provider<PendingWritesQueue> {
  /// Singleton-ish (per ProviderScope) queue exposed via Riverpod.
  PendingWritesQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingWritesQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingWritesQueueHash();

  @$internal
  @override
  $ProviderElement<PendingWritesQueue> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PendingWritesQueue create(Ref ref) {
    return pendingWritesQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingWritesQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingWritesQueue>(value),
    );
  }
}

String _$pendingWritesQueueHash() =>
    r'7fac98eb349b797331ed92a4fb4a17b326046b90';

/// Side-effect provider: drains the queue whenever connectivity
/// flips false→true. keepAlive because the listener subscription
/// is process-lifetime.
///
/// Wiring lives here rather than in main.dart so the listener
/// and the queue stay co-located — future maintainers see the
/// trigger and the action together.

@ProviderFor(PendingWritesAutoDrain)
final pendingWritesAutoDrainProvider = PendingWritesAutoDrainProvider._();

/// Side-effect provider: drains the queue whenever connectivity
/// flips false→true. keepAlive because the listener subscription
/// is process-lifetime.
///
/// Wiring lives here rather than in main.dart so the listener
/// and the queue stay co-located — future maintainers see the
/// trigger and the action together.
final class PendingWritesAutoDrainProvider
    extends $NotifierProvider<PendingWritesAutoDrain, void> {
  /// Side-effect provider: drains the queue whenever connectivity
  /// flips false→true. keepAlive because the listener subscription
  /// is process-lifetime.
  ///
  /// Wiring lives here rather than in main.dart so the listener
  /// and the queue stay co-located — future maintainers see the
  /// trigger and the action together.
  PendingWritesAutoDrainProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingWritesAutoDrainProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingWritesAutoDrainHash();

  @$internal
  @override
  PendingWritesAutoDrain create() => PendingWritesAutoDrain();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$pendingWritesAutoDrainHash() =>
    r'1f6ba777a443eda89cae77271aa4538f90a51218';

/// Side-effect provider: drains the queue whenever connectivity
/// flips false→true. keepAlive because the listener subscription
/// is process-lifetime.
///
/// Wiring lives here rather than in main.dart so the listener
/// and the queue stay co-located — future maintainers see the
/// trigger and the action together.

abstract class _$PendingWritesAutoDrain extends $Notifier<void> {
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
