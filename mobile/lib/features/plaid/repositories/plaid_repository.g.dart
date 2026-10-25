// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plaid_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(plaidRepository)
final plaidRepositoryProvider = PlaidRepositoryProvider._();

final class PlaidRepositoryProvider
    extends
        $FunctionalProvider<PlaidRepository, PlaidRepository, PlaidRepository>
    with $Provider<PlaidRepository> {
  PlaidRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'plaidRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$plaidRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlaidRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaidRepository create(Ref ref) {
    return plaidRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaidRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaidRepository>(value),
    );
  }
}

String _$plaidRepositoryHash() => r'52422d08046009f3545017683130655c2837434b';
