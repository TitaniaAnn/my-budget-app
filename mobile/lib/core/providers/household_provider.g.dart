// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the household_id for the currently authenticated user.
///
/// Returns null if the user is not logged in or has no membership row yet
/// (the [handle_new_user] DB trigger normally creates one on signup, but we
/// don't crash if a race or invite-cleanup edge case briefly leaves the user
/// without one). If the user belongs to multiple households (e.g. after a
/// future household-switching feature), the most recently joined wins.

@ProviderFor(householdId)
final householdIdProvider = HouseholdIdProvider._();

/// Fetches the household_id for the currently authenticated user.
///
/// Returns null if the user is not logged in or has no membership row yet
/// (the [handle_new_user] DB trigger normally creates one on signup, but we
/// don't crash if a race or invite-cleanup edge case briefly leaves the user
/// without one). If the user belongs to multiple households (e.g. after a
/// future household-switching feature), the most recently joined wins.

final class HouseholdIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Fetches the household_id for the currently authenticated user.
  ///
  /// Returns null if the user is not logged in or has no membership row yet
  /// (the [handle_new_user] DB trigger normally creates one on signup, but we
  /// don't crash if a race or invite-cleanup edge case briefly leaves the user
  /// without one). If the user belongs to multiple households (e.g. after a
  /// future household-switching feature), the most recently joined wins.
  HouseholdIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'householdIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$householdIdHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return householdId(ref);
  }
}

String _$householdIdHash() => r'd5aabf9bfec7da5f004b11acfccf27f0e163fc8e';
