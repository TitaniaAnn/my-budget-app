// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_scheduler_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$runRecurringSchedulerHash() =>
    r'74309c3536b5044e805c4f82499295a7902339a8';

/// Runs [RecurringTransactionsRepository.runScheduler] once per
/// app process. Returns the count of transactions emitted.
///
/// Resolves to 0 immediately when the user has no household
/// (pre-auth, etc.) — the scheduler has nothing to act on then,
/// and we don't want the dashboard provider to be blocked by an
/// auth-state race.
///
/// Copied from [runRecurringScheduler].
@ProviderFor(runRecurringScheduler)
final runRecurringSchedulerProvider = FutureProvider<int>.internal(
  runRecurringScheduler,
  name: r'runRecurringSchedulerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$runRecurringSchedulerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RunRecurringSchedulerRef = FutureProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
