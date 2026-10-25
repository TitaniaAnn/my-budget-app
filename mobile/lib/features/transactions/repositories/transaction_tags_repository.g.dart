// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_tags_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionTagsRepository)
final transactionTagsRepositoryProvider = TransactionTagsRepositoryProvider._();

final class TransactionTagsRepositoryProvider
    extends
        $FunctionalProvider<
          TransactionTagsRepository,
          TransactionTagsRepository,
          TransactionTagsRepository
        >
    with $Provider<TransactionTagsRepository> {
  TransactionTagsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionTagsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionTagsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransactionTagsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionTagsRepository create(Ref ref) {
    return transactionTagsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionTagsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionTagsRepository>(value),
    );
  }
}

String _$transactionTagsRepositoryHash() =>
    r'400e694852f0e38a0e86d81651c121c38e9f1d86';
