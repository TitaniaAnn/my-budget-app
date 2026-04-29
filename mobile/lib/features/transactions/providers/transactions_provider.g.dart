// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionsHash() => r'a05e212324bbec5abc674627eb9d31841ae27a44';

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

/// Fetches transactions for the current household with optional filters.
///
/// All params form the family key — each unique combination gets its own
/// cached AsyncValue so filter changes don't clear unrelated caches.
///
/// Copied from [transactions].
@ProviderFor(transactions)
const transactionsProvider = TransactionsFamily();

/// Fetches transactions for the current household with optional filters.
///
/// All params form the family key — each unique combination gets its own
/// cached AsyncValue so filter changes don't clear unrelated caches.
///
/// Copied from [transactions].
class TransactionsFamily extends Family<AsyncValue<List<Transaction>>> {
  /// Fetches transactions for the current household with optional filters.
  ///
  /// All params form the family key — each unique combination gets its own
  /// cached AsyncValue so filter changes don't clear unrelated caches.
  ///
  /// Copied from [transactions].
  const TransactionsFamily();

  /// Fetches transactions for the current household with optional filters.
  ///
  /// All params form the family key — each unique combination gets its own
  /// cached AsyncValue so filter changes don't clear unrelated caches.
  ///
  /// Copied from [transactions].
  TransactionsProvider call({
    String? accountId,
    String? categoryId,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    return TransactionsProvider(
      accountId: accountId,
      categoryId: categoryId,
      search: search,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  @override
  TransactionsProvider getProviderOverride(
    covariant TransactionsProvider provider,
  ) {
    return call(
      accountId: provider.accountId,
      categoryId: provider.categoryId,
      search: provider.search,
      dateFrom: provider.dateFrom,
      dateTo: provider.dateTo,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'transactionsProvider';
}

/// Fetches transactions for the current household with optional filters.
///
/// All params form the family key — each unique combination gets its own
/// cached AsyncValue so filter changes don't clear unrelated caches.
///
/// Copied from [transactions].
class TransactionsProvider
    extends AutoDisposeFutureProvider<List<Transaction>> {
  /// Fetches transactions for the current household with optional filters.
  ///
  /// All params form the family key — each unique combination gets its own
  /// cached AsyncValue so filter changes don't clear unrelated caches.
  ///
  /// Copied from [transactions].
  TransactionsProvider({
    String? accountId,
    String? categoryId,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) : this._internal(
         (ref) => transactions(
           ref as TransactionsRef,
           accountId: accountId,
           categoryId: categoryId,
           search: search,
           dateFrom: dateFrom,
           dateTo: dateTo,
         ),
         from: transactionsProvider,
         name: r'transactionsProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$transactionsHash,
         dependencies: TransactionsFamily._dependencies,
         allTransitiveDependencies:
             TransactionsFamily._allTransitiveDependencies,
         accountId: accountId,
         categoryId: categoryId,
         search: search,
         dateFrom: dateFrom,
         dateTo: dateTo,
       );

  TransactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.accountId,
    required this.categoryId,
    required this.search,
    required this.dateFrom,
    required this.dateTo,
  }) : super.internal();

  final String? accountId;
  final String? categoryId;
  final String? search;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  @override
  Override overrideWith(
    FutureOr<List<Transaction>> Function(TransactionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TransactionsProvider._internal(
        (ref) => create(ref as TransactionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        accountId: accountId,
        categoryId: categoryId,
        search: search,
        dateFrom: dateFrom,
        dateTo: dateTo,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Transaction>> createElement() {
    return _TransactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionsProvider &&
        other.accountId == accountId &&
        other.categoryId == categoryId &&
        other.search == search &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, accountId.hashCode);
    hash = _SystemHash.combine(hash, categoryId.hashCode);
    hash = _SystemHash.combine(hash, search.hashCode);
    hash = _SystemHash.combine(hash, dateFrom.hashCode);
    hash = _SystemHash.combine(hash, dateTo.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TransactionsRef on AutoDisposeFutureProviderRef<List<Transaction>> {
  /// The parameter `accountId` of this provider.
  String? get accountId;

  /// The parameter `categoryId` of this provider.
  String? get categoryId;

  /// The parameter `search` of this provider.
  String? get search;

  /// The parameter `dateFrom` of this provider.
  DateTime? get dateFrom;

  /// The parameter `dateTo` of this provider.
  DateTime? get dateTo;
}

class _TransactionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Transaction>>
    with TransactionsRef {
  _TransactionsProviderElement(super.provider);

  @override
  String? get accountId => (origin as TransactionsProvider).accountId;
  @override
  String? get categoryId => (origin as TransactionsProvider).categoryId;
  @override
  String? get search => (origin as TransactionsProvider).search;
  @override
  DateTime? get dateFrom => (origin as TransactionsProvider).dateFrom;
  @override
  DateTime? get dateTo => (origin as TransactionsProvider).dateTo;
}

String _$categoriesHash() => r'495a36b56b3907af2518121c5ae4d7d87f29c30f';

/// Fetches all categories (system + household).
/// Cached independently so it doesn't re-fetch every time transactions refresh.
///
/// Copied from [categories].
@ProviderFor(categories)
final categoriesProvider = AutoDisposeFutureProvider<List<Category>>.internal(
  categories,
  name: r'categoriesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categoriesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategoriesRef = AutoDisposeFutureProviderRef<List<Category>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
