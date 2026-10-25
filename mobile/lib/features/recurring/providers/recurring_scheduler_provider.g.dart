// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_scheduler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Runs [RecurringTransactionsRepository.runScheduler] once per
/// app process. Returns the count of transactions emitted.
///
/// Resolves to 0 immediately when the user has no household
/// (pre-auth, etc.) — the scheduler has nothing to act on then,
/// and we don't want the dashboard provider to be blocked by an
/// auth-state race.

@ProviderFor(runRecurringScheduler)
final runRecurringSchedulerProvider = RunRecurringSchedulerProvider._();

/// Runs [RecurringTransactionsRepository.runScheduler] once per
/// app process. Returns the count of transactions emitted.
///
/// Resolves to 0 immediately when the user has no household
/// (pre-auth, etc.) — the scheduler has nothing to act on then,
/// and we don't want the dashboard provider to be blocked by an
/// auth-state race.

final class RunRecurringSchedulerProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Runs [RecurringTransactionsRepository.runScheduler] once per
  /// app process. Returns the count of transactions emitted.
  ///
  /// Resolves to 0 immediately when the user has no household
  /// (pre-auth, etc.) — the scheduler has nothing to act on then,
  /// and we don't want the dashboard provider to be blocked by an
  /// auth-state race.
  RunRecurringSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runRecurringSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runRecurringSchedulerHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return runRecurringScheduler(ref);
  }
}

String _$runRecurringSchedulerHash() =>
    r'559f461f3f97d6054048229c6cdce93a8c2d03d1';
