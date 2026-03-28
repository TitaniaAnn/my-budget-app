// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dashboardDataHash() => r'e8476de36440f4c3992bcde85d51f9dbcfdc4d9f';

/// Fetches all dashboard data in parallel. Watches [householdIdProvider] so
/// it refreshes automatically when the household changes.
///
/// Copied from [dashboardData].
@ProviderFor(dashboardData)
final dashboardDataProvider = AutoDisposeFutureProvider<DashboardData>.internal(
  dashboardData,
  name: r'dashboardDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DashboardDataRef = AutoDisposeFutureProviderRef<DashboardData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
