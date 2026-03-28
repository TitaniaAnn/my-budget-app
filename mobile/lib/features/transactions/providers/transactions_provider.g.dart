// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionsHash() => r'd32fc498b4c0b39d588252c92a86a04e3dc586b5';

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

/// Fetches transactions for the current household, optionally filtered by
/// [accountId] (null = all accounts).
///
/// The [accountId] parameter makes this a "family" provider — each unique
/// accountId value gets its own cached AsyncValue, so switching between
/// the All / per-account filter views doesn't trigger a full rebuild.
///
/// Copied from [transactions].
@ProviderFor(transactions)
const transactionsProvider = TransactionsFamily();

/// Fetches transactions for the current household, optionally filtered by
/// [accountId] (null = all accounts).
///
/// The [accountId] parameter makes this a "family" provider — each unique
/// accountId value gets its own cached AsyncValue, so switching between
/// the All / per-account filter views doesn't trigger a full rebuild.
///
/// Copied from [transactions].
class TransactionsFamily extends Family<AsyncValue<List<Transaction>>> {
  /// Fetches transactions for the current household, optionally filtered by
  /// [accountId] (null = all accounts).
  ///
  /// The [accountId] parameter makes this a "family" provider — each unique
  /// accountId value gets its own cached AsyncValue, so switching between
  /// the All / per-account filter views doesn't trigger a full rebuild.
  ///
  /// Copied from [transactions].
  const TransactionsFamily();

  /// Fetches transactions for the current household, optionally filtered by
  /// [accountId] (null = all accounts).
  ///
  /// The [accountId] parameter makes this a "family" provider — each unique
  /// accountId value gets its own cached AsyncValue, so switching between
  /// the All / per-account filter views doesn't trigger a full rebuild.
  ///
  /// Copied from [transactions].
  TransactionsProvider call({String? accountId}) {
    return TransactionsProvider(accountId: accountId);
  }

  @override
  TransactionsProvider getProviderOverride(
    covariant TransactionsProvider provider,
  ) {
    return call(accountId: provider.accountId);
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

/// Fetches transactions for the current household, optionally filtered by
/// [accountId] (null = all accounts).
///
/// The [accountId] parameter makes this a "family" provider — each unique
/// accountId value gets its own cached AsyncValue, so switching between
/// the All / per-account filter views doesn't trigger a full rebuild.
///
/// Copied from [transactions].
class TransactionsProvider
    extends AutoDisposeFutureProvider<List<Transaction>> {
  /// Fetches transactions for the current household, optionally filtered by
  /// [accountId] (null = all accounts).
  ///
  /// The [accountId] parameter makes this a "family" provider — each unique
  /// accountId value gets its own cached AsyncValue, so switching between
  /// the All / per-account filter views doesn't trigger a full rebuild.
  ///
  /// Copied from [transactions].
  TransactionsProvider({String? accountId})
    : this._internal(
        (ref) => transactions(ref as TransactionsRef, accountId: accountId),
        from: transactionsProvider,
        name: r'transactionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$transactionsHash,
        dependencies: TransactionsFamily._dependencies,
        allTransitiveDependencies:
            TransactionsFamily._allTransitiveDependencies,
        accountId: accountId,
      );

  TransactionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.accountId,
  }) : super.internal();

  final String? accountId;

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
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Transaction>> createElement() {
    return _TransactionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionsProvider && other.accountId == accountId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, accountId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TransactionsRef on AutoDisposeFutureProviderRef<List<Transaction>> {
  /// The parameter `accountId` of this provider.
  String? get accountId;
}

class _TransactionsProviderElement
    extends AutoDisposeFutureProviderElement<List<Transaction>>
    with TransactionsRef {
  _TransactionsProviderElement(super.provider);

  @override
  String? get accountId => (origin as TransactionsProvider).accountId;
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
