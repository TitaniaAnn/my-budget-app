// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$householdIdHash() => r'7dcdb8735f9752b4769f280dfacfc7015a77849f';

/// Fetches the household_id for the currently authenticated user.
///
/// Returns null if the user is not logged in or has no membership row yet
/// (the [handle_new_user] DB trigger normally creates one on signup, but we
/// don't crash if a race or invite-cleanup edge case briefly leaves the user
/// without one). If the user belongs to multiple households (e.g. after a
/// future household-switching feature), the most recently joined wins.
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
