// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$householdIdHash() => r'840cffeb850558e1ceb3337f78dcba174de90c7a';

/// Fetches the household_id for the currently authenticated user.
///
/// Returns null if the user is not logged in. The household is created
/// automatically by the [handle_new_user] DB trigger on signup, so every
/// user is guaranteed to have exactly one household.
///
/// Copied from [householdId].
@ProviderFor(householdId)
final householdIdProvider = AutoDisposeFutureProvider<String?>.internal(
  householdId,
  name: r'householdIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$householdIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HouseholdIdRef = AutoDisposeFutureProviderRef<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
