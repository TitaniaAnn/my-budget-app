// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All receipts for the current household, newest first.

@ProviderFor(receipts)
final receiptsProvider = ReceiptsProvider._();

/// All receipts for the current household, newest first.

final class ReceiptsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Receipt>>,
          List<Receipt>,
          FutureOr<List<Receipt>>
        >
    with $FutureModifier<List<Receipt>>, $FutureProvider<List<Receipt>> {
  /// All receipts for the current household, newest first.
  ReceiptsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptsHash();

  @$internal
  @override
  $FutureProviderElement<List<Receipt>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Receipt>> create(Ref ref) {
    return receipts(ref);
  }
}

String _$receiptsHash() => r'dd5460db069d6e7598a9fed8eb9fdd15fd69f54e';

/// Single receipt by [receiptId]. Used by the detail screen.

@ProviderFor(receipt)
final receiptProvider = ReceiptFamily._();

/// Single receipt by [receiptId]. Used by the detail screen.

final class ReceiptProvider
    extends $FunctionalProvider<AsyncValue<Receipt>, Receipt, FutureOr<Receipt>>
    with $FutureModifier<Receipt>, $FutureProvider<Receipt> {
  /// Single receipt by [receiptId]. Used by the detail screen.
  ReceiptProvider._({
    required ReceiptFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'receiptProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$receiptHash();

  @override
  String toString() {
    return r'receiptProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Receipt> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Receipt> create(Ref ref) {
    final argument = this.argument as String;
    return receipt(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$receiptHash() => r'32dade9d85376a3c10cf381514d7b698cb5109b1';

/// Single receipt by [receiptId]. Used by the detail screen.

final class ReceiptFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Receipt>, String> {
  ReceiptFamily._()
    : super(
        retry: null,
        name: r'receiptProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Single receipt by [receiptId]. Used by the detail screen.

  ReceiptProvider call(String receiptId) =>
      ReceiptProvider._(argument: receiptId, from: this);

  @override
  String toString() => r'receiptProvider';
}

/// Line items for a receipt. Separate provider so the grid list doesn't
/// need to load line items for every thumbnail.

@ProviderFor(receiptLineItems)
final receiptLineItemsProvider = ReceiptLineItemsFamily._();

/// Line items for a receipt. Separate provider so the grid list doesn't
/// need to load line items for every thumbnail.

final class ReceiptLineItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReceiptLineItem>>,
          List<ReceiptLineItem>,
          FutureOr<List<ReceiptLineItem>>
        >
    with
        $FutureModifier<List<ReceiptLineItem>>,
        $FutureProvider<List<ReceiptLineItem>> {
  /// Line items for a receipt. Separate provider so the grid list doesn't
  /// need to load line items for every thumbnail.
  ReceiptLineItemsProvider._({
    required ReceiptLineItemsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'receiptLineItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$receiptLineItemsHash();

  @override
  String toString() {
    return r'receiptLineItemsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ReceiptLineItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ReceiptLineItem>> create(Ref ref) {
    final argument = this.argument as String;
    return receiptLineItems(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptLineItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$receiptLineItemsHash() => r'c3a1ee49c065c3214cd4477a2dcb7460d3595696';

/// Line items for a receipt. Separate provider so the grid list doesn't
/// need to load line items for every thumbnail.

final class ReceiptLineItemsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ReceiptLineItem>>, String> {
  ReceiptLineItemsFamily._()
    : super(
        retry: null,
        name: r'receiptLineItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Line items for a receipt. Separate provider so the grid list doesn't
  /// need to load line items for every thumbnail.

  ReceiptLineItemsProvider call(String receiptId) =>
      ReceiptLineItemsProvider._(argument: receiptId, from: this);

  @override
  String toString() => r'receiptLineItemsProvider';
}

/// Receipts in the current household with no transaction pointing at
/// them. Powers the transaction edit sheet's "Attach Receipt" picker —
/// the inverse direction of the existing pair-from-receipt flow.

@ProviderFor(unpairedReceipts)
final unpairedReceiptsProvider = UnpairedReceiptsProvider._();

/// Receipts in the current household with no transaction pointing at
/// them. Powers the transaction edit sheet's "Attach Receipt" picker —
/// the inverse direction of the existing pair-from-receipt flow.

final class UnpairedReceiptsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Receipt>>,
          List<Receipt>,
          FutureOr<List<Receipt>>
        >
    with $FutureModifier<List<Receipt>>, $FutureProvider<List<Receipt>> {
  /// Receipts in the current household with no transaction pointing at
  /// them. Powers the transaction edit sheet's "Attach Receipt" picker —
  /// the inverse direction of the existing pair-from-receipt flow.
  UnpairedReceiptsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unpairedReceiptsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unpairedReceiptsHash();

  @$internal
  @override
  $FutureProviderElement<List<Receipt>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Receipt>> create(Ref ref) {
    return unpairedReceipts(ref);
  }
}

String _$unpairedReceiptsHash() => r'00b8e978a01f522faf9ac037f96da28923cd4cd0';

/// Signed URLs for EVERY receipt in the current household, keyed by
/// `storagePath`. Audit P4: pre-fix each `_ReceiptCard` watched its
/// own per-path provider so a 50-receipt grid fired 50 sign-url
/// HTTP round-trips on first paint. This pulls them in one
/// `createSignedUrls` POST that covers both full-resolution paths
/// AND thumbnail paths — the grid uses thumbnails when present,
/// the detail screen uses full images, but one wire fetch covers
/// both. Cards resolve from the map.

@ProviderFor(signedReceiptUrls)
final signedReceiptUrlsProvider = SignedReceiptUrlsProvider._();

/// Signed URLs for EVERY receipt in the current household, keyed by
/// `storagePath`. Audit P4: pre-fix each `_ReceiptCard` watched its
/// own per-path provider so a 50-receipt grid fired 50 sign-url
/// HTTP round-trips on first paint. This pulls them in one
/// `createSignedUrls` POST that covers both full-resolution paths
/// AND thumbnail paths — the grid uses thumbnails when present,
/// the detail screen uses full images, but one wire fetch covers
/// both. Cards resolve from the map.

final class SignedReceiptUrlsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  /// Signed URLs for EVERY receipt in the current household, keyed by
  /// `storagePath`. Audit P4: pre-fix each `_ReceiptCard` watched its
  /// own per-path provider so a 50-receipt grid fired 50 sign-url
  /// HTTP round-trips on first paint. This pulls them in one
  /// `createSignedUrls` POST that covers both full-resolution paths
  /// AND thumbnail paths — the grid uses thumbnails when present,
  /// the detail screen uses full images, but one wire fetch covers
  /// both. Cards resolve from the map.
  SignedReceiptUrlsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signedReceiptUrlsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signedReceiptUrlsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    return signedReceiptUrls(ref);
  }
}

String _$signedReceiptUrlsHash() => r'4fa35d92b1237e5d1aca7459292e5ec41f7dd262';

/// Signed URL for one receipt image, by [storagePath]. Resolves
/// from the batched [signedReceiptUrlsProvider] when the path is
/// part of the current household receipts list (the common case);
/// falls back to a one-off sign for paths outside that list
/// (e.g. detail screen opened via deep link before the list has
/// been fetched, or for a brand-new receipt that hasn't propagated
/// into the cached `receiptsProvider` value yet).

@ProviderFor(receiptImageUrl)
final receiptImageUrlProvider = ReceiptImageUrlFamily._();

/// Signed URL for one receipt image, by [storagePath]. Resolves
/// from the batched [signedReceiptUrlsProvider] when the path is
/// part of the current household receipts list (the common case);
/// falls back to a one-off sign for paths outside that list
/// (e.g. detail screen opened via deep link before the list has
/// been fetched, or for a brand-new receipt that hasn't propagated
/// into the cached `receiptsProvider` value yet).

final class ReceiptImageUrlProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Signed URL for one receipt image, by [storagePath]. Resolves
  /// from the batched [signedReceiptUrlsProvider] when the path is
  /// part of the current household receipts list (the common case);
  /// falls back to a one-off sign for paths outside that list
  /// (e.g. detail screen opened via deep link before the list has
  /// been fetched, or for a brand-new receipt that hasn't propagated
  /// into the cached `receiptsProvider` value yet).
  ReceiptImageUrlProvider._({
    required ReceiptImageUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'receiptImageUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$receiptImageUrlHash();

  @override
  String toString() {
    return r'receiptImageUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return receiptImageUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptImageUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$receiptImageUrlHash() => r'b52a3d6b8bc501be713836290e5e143504c6af8c';

/// Signed URL for one receipt image, by [storagePath]. Resolves
/// from the batched [signedReceiptUrlsProvider] when the path is
/// part of the current household receipts list (the common case);
/// falls back to a one-off sign for paths outside that list
/// (e.g. detail screen opened via deep link before the list has
/// been fetched, or for a brand-new receipt that hasn't propagated
/// into the cached `receiptsProvider` value yet).

final class ReceiptImageUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  ReceiptImageUrlFamily._()
    : super(
        retry: null,
        name: r'receiptImageUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Signed URL for one receipt image, by [storagePath]. Resolves
  /// from the batched [signedReceiptUrlsProvider] when the path is
  /// part of the current household receipts list (the common case);
  /// falls back to a one-off sign for paths outside that list
  /// (e.g. detail screen opened via deep link before the list has
  /// been fetched, or for a brand-new receipt that hasn't propagated
  /// into the cached `receiptsProvider` value yet).

  ReceiptImageUrlProvider call(String storagePath) =>
      ReceiptImageUrlProvider._(argument: storagePath, from: this);

  @override
  String toString() => r'receiptImageUrlProvider';
}
