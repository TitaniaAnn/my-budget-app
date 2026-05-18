// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_tags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$transactionTagsHash() => r'ca3aa37d4efa80e5837316f7be775b1f6ad29696';

/// Every tag in the current household, alphabetical. Powers the
/// chip-picker on the transaction edit sheet — and later, the tag
/// filter on the transactions list.
///
/// Copied from [transactionTags].
@ProviderFor(transactionTags)
final transactionTagsProvider =
    AutoDisposeFutureProvider<List<TransactionTag>>.internal(
      transactionTags,
      name: r'transactionTagsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transactionTagsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionTagsRef = AutoDisposeFutureProviderRef<List<TransactionTag>>;
String _$tagIdsForTransactionHash() =>
    r'a7fcc25ba5d168876998a5975c6c4f371b6cf456';

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

/// Ids of the tags currently assigned to [transactionId]. Family-
/// keyed so invalidating one transaction's assignments doesn't
/// disturb the picker state for any other open editor.
///
/// Copied from [tagIdsForTransaction].
@ProviderFor(tagIdsForTransaction)
const tagIdsForTransactionProvider = TagIdsForTransactionFamily();

/// Ids of the tags currently assigned to [transactionId]. Family-
/// keyed so invalidating one transaction's assignments doesn't
/// disturb the picker state for any other open editor.
///
/// Copied from [tagIdsForTransaction].
class TagIdsForTransactionFamily extends Family<AsyncValue<List<String>>> {
  /// Ids of the tags currently assigned to [transactionId]. Family-
  /// keyed so invalidating one transaction's assignments doesn't
  /// disturb the picker state for any other open editor.
  ///
  /// Copied from [tagIdsForTransaction].
  const TagIdsForTransactionFamily();

  /// Ids of the tags currently assigned to [transactionId]. Family-
  /// keyed so invalidating one transaction's assignments doesn't
  /// disturb the picker state for any other open editor.
  ///
  /// Copied from [tagIdsForTransaction].
  TagIdsForTransactionProvider call(String transactionId) {
    return TagIdsForTransactionProvider(transactionId);
  }

  @override
  TagIdsForTransactionProvider getProviderOverride(
    covariant TagIdsForTransactionProvider provider,
  ) {
    return call(provider.transactionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'tagIdsForTransactionProvider';
}

/// Ids of the tags currently assigned to [transactionId]. Family-
/// keyed so invalidating one transaction's assignments doesn't
/// disturb the picker state for any other open editor.
///
/// Copied from [tagIdsForTransaction].
class TagIdsForTransactionProvider
    extends AutoDisposeFutureProvider<List<String>> {
  /// Ids of the tags currently assigned to [transactionId]. Family-
  /// keyed so invalidating one transaction's assignments doesn't
  /// disturb the picker state for any other open editor.
  ///
  /// Copied from [tagIdsForTransaction].
  TagIdsForTransactionProvider(String transactionId)
    : this._internal(
        (ref) =>
            tagIdsForTransaction(ref as TagIdsForTransactionRef, transactionId),
        from: tagIdsForTransactionProvider,
        name: r'tagIdsForTransactionProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$tagIdsForTransactionHash,
        dependencies: TagIdsForTransactionFamily._dependencies,
        allTransitiveDependencies:
            TagIdsForTransactionFamily._allTransitiveDependencies,
        transactionId: transactionId,
      );

  TagIdsForTransactionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.transactionId,
  }) : super.internal();

  final String transactionId;

  @override
  Override overrideWith(
    FutureOr<List<String>> Function(TagIdsForTransactionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TagIdsForTransactionProvider._internal(
        (ref) => create(ref as TagIdsForTransactionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        transactionId: transactionId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<String>> createElement() {
    return _TagIdsForTransactionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TagIdsForTransactionProvider &&
        other.transactionId == transactionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, transactionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TagIdsForTransactionRef on AutoDisposeFutureProviderRef<List<String>> {
  /// The parameter `transactionId` of this provider.
  String get transactionId;
}

class _TagIdsForTransactionProviderElement
    extends AutoDisposeFutureProviderElement<List<String>>
    with TagIdsForTransactionRef {
  _TagIdsForTransactionProviderElement(super.provider);

  @override
  String get transactionId =>
      (origin as TagIdsForTransactionProvider).transactionId;
}

String _$transactionTagAssignmentsHash() =>
    r'b1c31894f76d09f20c62cb2c6b16a7762a5f19cf';

/// Every visible tag assignment, indexed by transaction id. The
/// transactions list watches this once and looks up tags per card
/// in O(1) — alternative would be a per-row provider that fires
/// hundreds of requests on a long list.
///
/// RLS scopes the underlying fetch to the caller's household via
/// the assignment table's "transaction_id IN (SELECT id FROM
/// transactions)" policy (migration 020).
///
/// Copied from [transactionTagAssignments].
@ProviderFor(transactionTagAssignments)
final transactionTagAssignmentsProvider =
    AutoDisposeFutureProvider<Map<String, Set<String>>>.internal(
      transactionTagAssignments,
      name: r'transactionTagAssignmentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transactionTagAssignmentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TransactionTagAssignmentsRef =
    AutoDisposeFutureProviderRef<Map<String, Set<String>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
