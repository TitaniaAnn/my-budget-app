// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$receiptsHash() => r'ddb81cbbeb9a3fb56e8916d3a2db9d265f05c6a7';

/// All receipts for the current household, newest first.
///
/// Copied from [receipts].
@ProviderFor(receipts)
final receiptsProvider = AutoDisposeFutureProvider<List<Receipt>>.internal(
  receipts,
  name: r'receiptsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$receiptsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReceiptsRef = AutoDisposeFutureProviderRef<List<Receipt>>;
String _$receiptHash() => r'540a48ee86b43a70497e31ce34fbb9cf18f3a9ab';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Single receipt by [receiptId]. Used by the detail screen.
///
/// Copied from [receipt].
@ProviderFor(receipt)
const receiptProvider = ReceiptFamily();

/// Single receipt by [receiptId]. Used by the detail screen.
///
/// Copied from [receipt].
class ReceiptFamily extends Family<AsyncValue<Receipt>> {
  /// Single receipt by [receiptId]. Used by the detail screen.
  ///
  /// Copied from [receipt].
  const ReceiptFamily();

  /// Single receipt by [receiptId]. Used by the detail screen.
  ///
  /// Copied from [receipt].
  ReceiptProvider call(String receiptId) {
    return ReceiptProvider(receiptId);
  }

  @override
  ReceiptProvider getProviderOverride(covariant ReceiptProvider provider) {
    return call(provider.receiptId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'receiptProvider';
}

/// Single receipt by [receiptId]. Used by the detail screen.
///
/// Copied from [receipt].
class ReceiptProvider extends AutoDisposeFutureProvider<Receipt> {
  /// Single receipt by [receiptId]. Used by the detail screen.
  ///
  /// Copied from [receipt].
  ReceiptProvider(String receiptId)
    : this._internal(
        (ref) => receipt(ref as ReceiptRef, receiptId),
        from: receiptProvider,
        name: r'receiptProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$receiptHash,
        dependencies: ReceiptFamily._dependencies,
        allTransitiveDependencies: ReceiptFamily._allTransitiveDependencies,
        receiptId: receiptId,
      );

  ReceiptProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.receiptId,
  }) : super.internal();

  final String receiptId;

  @override
  Override overrideWith(
    FutureOr<Receipt> Function(ReceiptRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReceiptProvider._internal(
        (ref) => create(ref as ReceiptRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        receiptId: receiptId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Receipt> createElement() {
    return _ReceiptProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptProvider && other.receiptId == receiptId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, receiptId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReceiptRef on AutoDisposeFutureProviderRef<Receipt> {
  /// The parameter `receiptId` of this provider.
  String get receiptId;
}

class _ReceiptProviderElement extends AutoDisposeFutureProviderElement<Receipt>
    with ReceiptRef {
  _ReceiptProviderElement(super.provider);

  @override
  String get receiptId => (origin as ReceiptProvider).receiptId;
}

String _$receiptLineItemsHash() => r'e8fa749755f0485d81e604973db3f687975dede9';

/// Line items for a receipt. Separate provider so the grid list doesn't
/// need to load line items for every thumbnail.
///
/// Copied from [receiptLineItems].
@ProviderFor(receiptLineItems)
const receiptLineItemsProvider = ReceiptLineItemsFamily();

/// Line items for a receipt. Separate provider so the grid list doesn't
/// need to load line items for every thumbnail.
///
/// Copied from [receiptLineItems].
class ReceiptLineItemsFamily extends Family<AsyncValue<List<ReceiptLineItem>>> {
  /// Line items for a receipt. Separate provider so the grid list doesn't
  /// need to load line items for every thumbnail.
  ///
  /// Copied from [receiptLineItems].
  const ReceiptLineItemsFamily();

  /// Line items for a receipt. Separate provider so the grid list doesn't
  /// need to load line items for every thumbnail.
  ///
  /// Copied from [receiptLineItems].
  ReceiptLineItemsProvider call(String receiptId) {
    return ReceiptLineItemsProvider(receiptId);
  }

  @override
  ReceiptLineItemsProvider getProviderOverride(
    covariant ReceiptLineItemsProvider provider,
  ) {
    return call(provider.receiptId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'receiptLineItemsProvider';
}

/// Line items for a receipt. Separate provider so the grid list doesn't
/// need to load line items for every thumbnail.
///
/// Copied from [receiptLineItems].
class ReceiptLineItemsProvider
    extends AutoDisposeFutureProvider<List<ReceiptLineItem>> {
  /// Line items for a receipt. Separate provider so the grid list doesn't
  /// need to load line items for every thumbnail.
  ///
  /// Copied from [receiptLineItems].
  ReceiptLineItemsProvider(String receiptId)
    : this._internal(
        (ref) => receiptLineItems(ref as ReceiptLineItemsRef, receiptId),
        from: receiptLineItemsProvider,
        name: r'receiptLineItemsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$receiptLineItemsHash,
        dependencies: ReceiptLineItemsFamily._dependencies,
        allTransitiveDependencies:
            ReceiptLineItemsFamily._allTransitiveDependencies,
        receiptId: receiptId,
      );

  ReceiptLineItemsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.receiptId,
  }) : super.internal();

  final String receiptId;

  @override
  Override overrideWith(
    FutureOr<List<ReceiptLineItem>> Function(ReceiptLineItemsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReceiptLineItemsProvider._internal(
        (ref) => create(ref as ReceiptLineItemsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        receiptId: receiptId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ReceiptLineItem>> createElement() {
    return _ReceiptLineItemsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptLineItemsProvider && other.receiptId == receiptId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, receiptId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReceiptLineItemsRef
    on AutoDisposeFutureProviderRef<List<ReceiptLineItem>> {
  /// The parameter `receiptId` of this provider.
  String get receiptId;
}

class _ReceiptLineItemsProviderElement
    extends AutoDisposeFutureProviderElement<List<ReceiptLineItem>>
    with ReceiptLineItemsRef {
  _ReceiptLineItemsProviderElement(super.provider);

  @override
  String get receiptId => (origin as ReceiptLineItemsProvider).receiptId;
}

String _$receiptImageUrlHash() => r'5e0fadcdbd66da7241ab9b87b078a10c028b3341';

/// Signed URL for displaying a private receipt image.
/// Cached by [storagePath]; expires in 1 hour (Supabase re-signs on cache miss).
///
/// Copied from [receiptImageUrl].
@ProviderFor(receiptImageUrl)
const receiptImageUrlProvider = ReceiptImageUrlFamily();

/// Signed URL for displaying a private receipt image.
/// Cached by [storagePath]; expires in 1 hour (Supabase re-signs on cache miss).
///
/// Copied from [receiptImageUrl].
class ReceiptImageUrlFamily extends Family<AsyncValue<String>> {
  /// Signed URL for displaying a private receipt image.
  /// Cached by [storagePath]; expires in 1 hour (Supabase re-signs on cache miss).
  ///
  /// Copied from [receiptImageUrl].
  const ReceiptImageUrlFamily();

  /// Signed URL for displaying a private receipt image.
  /// Cached by [storagePath]; expires in 1 hour (Supabase re-signs on cache miss).
  ///
  /// Copied from [receiptImageUrl].
  ReceiptImageUrlProvider call(String storagePath) {
    return ReceiptImageUrlProvider(storagePath);
  }

  @override
  ReceiptImageUrlProvider getProviderOverride(
    covariant ReceiptImageUrlProvider provider,
  ) {
    return call(provider.storagePath);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'receiptImageUrlProvider';
}

/// Signed URL for displaying a private receipt image.
/// Cached by [storagePath]; expires in 1 hour (Supabase re-signs on cache miss).
///
/// Copied from [receiptImageUrl].
class ReceiptImageUrlProvider extends AutoDisposeFutureProvider<String> {
  /// Signed URL for displaying a private receipt image.
  /// Cached by [storagePath]; expires in 1 hour (Supabase re-signs on cache miss).
  ///
  /// Copied from [receiptImageUrl].
  ReceiptImageUrlProvider(String storagePath)
    : this._internal(
        (ref) => receiptImageUrl(ref as ReceiptImageUrlRef, storagePath),
        from: receiptImageUrlProvider,
        name: r'receiptImageUrlProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$receiptImageUrlHash,
        dependencies: ReceiptImageUrlFamily._dependencies,
        allTransitiveDependencies:
            ReceiptImageUrlFamily._allTransitiveDependencies,
        storagePath: storagePath,
      );

  ReceiptImageUrlProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.storagePath,
  }) : super.internal();

  final String storagePath;

  @override
  Override overrideWith(
    FutureOr<String> Function(ReceiptImageUrlRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReceiptImageUrlProvider._internal(
        (ref) => create(ref as ReceiptImageUrlRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        storagePath: storagePath,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _ReceiptImageUrlProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptImageUrlProvider && other.storagePath == storagePath;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, storagePath.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReceiptImageUrlRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `storagePath` of this provider.
  String get storagePath;
}

class _ReceiptImageUrlProviderElement
    extends AutoDisposeFutureProviderElement<String>
    with ReceiptImageUrlRef {
  _ReceiptImageUrlProviderElement(super.provider);

  @override
  String get storagePath => (origin as ReceiptImageUrlProvider).storagePath;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
