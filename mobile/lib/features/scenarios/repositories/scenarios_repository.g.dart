// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenarios_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(scenariosRepository)
final scenariosRepositoryProvider = ScenariosRepositoryProvider._();

final class ScenariosRepositoryProvider
    extends
        $FunctionalProvider<
          ScenariosRepository,
          ScenariosRepository,
          ScenariosRepository
        >
    with $Provider<ScenariosRepository> {
  ScenariosRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scenariosRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scenariosRepositoryHash();

  @$internal
  @override
  $ProviderElement<ScenariosRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ScenariosRepository create(Ref ref) {
    return scenariosRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScenariosRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScenariosRepository>(value),
    );
  }
}

String _$scenariosRepositoryHash() =>
    r'9d9ad1c4fb914164be91045807ed56aa58ad8249';
