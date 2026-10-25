// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipts_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(receiptsRepository)
final receiptsRepositoryProvider = ReceiptsRepositoryProvider._();

final class ReceiptsRepositoryProvider
    extends
        $FunctionalProvider<
          ReceiptsRepository,
          ReceiptsRepository,
          ReceiptsRepository
        >
    with $Provider<ReceiptsRepository> {
  ReceiptsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReceiptsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptsRepository create(Ref ref) {
    return receiptsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptsRepository>(value),
    );
  }
}

String _$receiptsRepositoryHash() =>
    r'da8f52200277f1ee5be8ab6149895b6c028d6fd4';
