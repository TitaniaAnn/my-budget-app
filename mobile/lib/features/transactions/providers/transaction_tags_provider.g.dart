// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_tags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every tag in the current household, alphabetical. Powers the
/// chip-picker on the transaction edit sheet — and later, the tag
/// filter on the transactions list.

@ProviderFor(transactionTags)
final transactionTagsProvider = TransactionTagsProvider._();

/// Every tag in the current household, alphabetical. Powers the
/// chip-picker on the transaction edit sheet — and later, the tag
/// filter on the transactions list.

final class TransactionTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TransactionTag>>,
          List<TransactionTag>,
          FutureOr<List<TransactionTag>>
        >
    with
        $FutureModifier<List<TransactionTag>>,
        $FutureProvider<List<TransactionTag>> {
  /// Every tag in the current household, alphabetical. Powers the
  /// chip-picker on the transaction edit sheet — and later, the tag
  /// filter on the transactions list.
  TransactionTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<TransactionTag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TransactionTag>> create(Ref ref) {
    return transactionTags(ref);
  }
}

String _$transactionTagsHash() => r'4233f0485546fd72d4e7ffdd35546286efa36852';

/// Ids of the tags currently assigned to [transactionId]. Family-
/// keyed so invalidating one transaction's assignments doesn't
/// disturb the picker state for any other open editor.

@ProviderFor(tagIdsForTransaction)
final tagIdsForTransactionProvider = TagIdsForTransactionFamily._();

/// Ids of the tags currently assigned to [transactionId]. Family-
/// keyed so invalidating one transaction's assignments doesn't
/// disturb the picker state for any other open editor.

final class TagIdsForTransactionProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Ids of the tags currently assigned to [transactionId]. Family-
  /// keyed so invalidating one transaction's assignments doesn't
  /// disturb the picker state for any other open editor.
  TagIdsForTransactionProvider._({
    required TagIdsForTransactionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tagIdsForTransactionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tagIdsForTransactionHash();

  @override
  String toString() {
    return r'tagIdsForTransactionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return tagIdsForTransaction(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TagIdsForTransactionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tagIdsForTransactionHash() =>
    r'5092cf29ff25649dc889ed065f97cf28ecaba99d';

/// Ids of the tags currently assigned to [transactionId]. Family-
/// keyed so invalidating one transaction's assignments doesn't
/// disturb the picker state for any other open editor.

final class TagIdsForTransactionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, String> {
  TagIdsForTransactionFamily._()
    : super(
        retry: null,
        name: r'tagIdsForTransactionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ids of the tags currently assigned to [transactionId]. Family-
  /// keyed so invalidating one transaction's assignments doesn't
  /// disturb the picker state for any other open editor.

  TagIdsForTransactionProvider call(String transactionId) =>
      TagIdsForTransactionProvider._(argument: transactionId, from: this);

  @override
  String toString() => r'tagIdsForTransactionProvider';
}

/// Every visible tag assignment, indexed by transaction id. The
/// transactions list watches this once and looks up tags per card
/// in O(1) — alternative would be a per-row provider that fires
/// hundreds of requests on a long list.
///
/// RLS scopes the underlying fetch to the caller's household via
/// the assignment table's "transaction_id IN (SELECT id FROM
/// transactions)" policy (migration 020).

@ProviderFor(transactionTagAssignments)
final transactionTagAssignmentsProvider = TransactionTagAssignmentsProvider._();

/// Every visible tag assignment, indexed by transaction id. The
/// transactions list watches this once and looks up tags per card
/// in O(1) — alternative would be a per-row provider that fires
/// hundreds of requests on a long list.
///
/// RLS scopes the underlying fetch to the caller's household via
/// the assignment table's "transaction_id IN (SELECT id FROM
/// transactions)" policy (migration 020).

final class TransactionTagAssignmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Set<String>>>,
          Map<String, Set<String>>,
          FutureOr<Map<String, Set<String>>>
        >
    with
        $FutureModifier<Map<String, Set<String>>>,
        $FutureProvider<Map<String, Set<String>>> {
  /// Every visible tag assignment, indexed by transaction id. The
  /// transactions list watches this once and looks up tags per card
  /// in O(1) — alternative would be a per-row provider that fires
  /// hundreds of requests on a long list.
  ///
  /// RLS scopes the underlying fetch to the caller's household via
  /// the assignment table's "transaction_id IN (SELECT id FROM
  /// transactions)" policy (migration 020).
  TransactionTagAssignmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionTagAssignmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionTagAssignmentsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, Set<String>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, Set<String>>> create(Ref ref) {
    return transactionTagAssignments(ref);
  }
}

String _$transactionTagAssignmentsHash() =>
    r'1a7f91d53f3645893e4162b2de7fff3fec57260d';

/// Assignment counts per tag, used by the manage-tags screen for
/// the "X transactions, Y line items" subtitle and to inform the
/// delete-confirmation message. Empty inner counts are omitted —
/// callers treat an absent key the same as "(0, 0)".

@ProviderFor(tagUsageCounts)
final tagUsageCountsProvider = TagUsageCountsProvider._();

/// Assignment counts per tag, used by the manage-tags screen for
/// the "X transactions, Y line items" subtitle and to inform the
/// delete-confirmation message. Empty inner counts are omitted —
/// callers treat an absent key the same as "(0, 0)".

final class TagUsageCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, ({int lineItemCount, int txCount})>>,
          Map<String, ({int lineItemCount, int txCount})>,
          FutureOr<Map<String, ({int lineItemCount, int txCount})>>
        >
    with
        $FutureModifier<Map<String, ({int lineItemCount, int txCount})>>,
        $FutureProvider<Map<String, ({int lineItemCount, int txCount})>> {
  /// Assignment counts per tag, used by the manage-tags screen for
  /// the "X transactions, Y line items" subtitle and to inform the
  /// delete-confirmation message. Empty inner counts are omitted —
  /// callers treat an absent key the same as "(0, 0)".
  TagUsageCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagUsageCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagUsageCountsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, ({int lineItemCount, int txCount})>>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, ({int lineItemCount, int txCount})>> create(Ref ref) {
    return tagUsageCounts(ref);
  }
}

String _$tagUsageCountsHash() => r'd82d504634b80a8dab56f3c837fe30768754c479';
