// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches transactions for the current household with optional filters.
///
/// All params form the family key — each unique combination gets its own
/// cached AsyncValue so filter changes don't clear unrelated caches.
///
/// Audit L6: [limit] is part of the family key so the
/// transactions screen's "Load more" affordance can bump it
/// without colliding with the dashboard / scenarios callers that
/// always want the default. Underlying [fetchTransactions]
/// defaults to 1000; pre-fix a year-3 power user silently lost
/// transactions off the end of that page. Now the UI can grow the
/// page by re-keying the family.

@ProviderFor(transactions)
final transactionsProvider = TransactionsFamily._();

/// Fetches transactions for the current household with optional filters.
///
/// All params form the family key — each unique combination gets its own
/// cached AsyncValue so filter changes don't clear unrelated caches.
///
/// Audit L6: [limit] is part of the family key so the
/// transactions screen's "Load more" affordance can bump it
/// without colliding with the dashboard / scenarios callers that
/// always want the default. Underlying [fetchTransactions]
/// defaults to 1000; pre-fix a year-3 power user silently lost
/// transactions off the end of that page. Now the UI can grow the
/// page by re-keying the family.

final class TransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          FutureOr<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $FutureProvider<List<Transaction>> {
  /// Fetches transactions for the current household with optional filters.
  ///
  /// All params form the family key — each unique combination gets its own
  /// cached AsyncValue so filter changes don't clear unrelated caches.
  ///
  /// Audit L6: [limit] is part of the family key so the
  /// transactions screen's "Load more" affordance can bump it
  /// without colliding with the dashboard / scenarios callers that
  /// always want the default. Underlying [fetchTransactions]
  /// defaults to 1000; pre-fix a year-3 power user silently lost
  /// transactions off the end of that page. Now the UI can grow the
  /// page by re-keying the family.
  TransactionsProvider._({
    required TransactionsFamily super.from,
    required ({
      String? accountId,
      String? categoryId,
      String? tagId,
      String? search,
      DateTime? dateFrom,
      DateTime? dateTo,
      int limit,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'transactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionsHash();

  @override
  String toString() {
    return r'transactionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String? accountId,
              String? categoryId,
              String? tagId,
              String? search,
              DateTime? dateFrom,
              DateTime? dateTo,
              int limit,
            });
    return transactions(
      ref,
      accountId: argument.accountId,
      categoryId: argument.categoryId,
      tagId: argument.tagId,
      search: argument.search,
      dateFrom: argument.dateFrom,
      dateTo: argument.dateTo,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionsHash() => r'172ba378b5e26e6d12c43de73152962a28b11d3a';

/// Fetches transactions for the current household with optional filters.
///
/// All params form the family key — each unique combination gets its own
/// cached AsyncValue so filter changes don't clear unrelated caches.
///
/// Audit L6: [limit] is part of the family key so the
/// transactions screen's "Load more" affordance can bump it
/// without colliding with the dashboard / scenarios callers that
/// always want the default. Underlying [fetchTransactions]
/// defaults to 1000; pre-fix a year-3 power user silently lost
/// transactions off the end of that page. Now the UI can grow the
/// page by re-keying the family.

final class TransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Transaction>>,
          ({
            String? accountId,
            String? categoryId,
            String? tagId,
            String? search,
            DateTime? dateFrom,
            DateTime? dateTo,
            int limit,
          })
        > {
  TransactionsFamily._()
    : super(
        retry: null,
        name: r'transactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches transactions for the current household with optional filters.
  ///
  /// All params form the family key — each unique combination gets its own
  /// cached AsyncValue so filter changes don't clear unrelated caches.
  ///
  /// Audit L6: [limit] is part of the family key so the
  /// transactions screen's "Load more" affordance can bump it
  /// without colliding with the dashboard / scenarios callers that
  /// always want the default. Underlying [fetchTransactions]
  /// defaults to 1000; pre-fix a year-3 power user silently lost
  /// transactions off the end of that page. Now the UI can grow the
  /// page by re-keying the family.

  TransactionsProvider call({
    String? accountId,
    String? categoryId,
    String? tagId,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 1000,
  }) => TransactionsProvider._(
    argument: (
      accountId: accountId,
      categoryId: categoryId,
      tagId: tagId,
      search: search,
      dateFrom: dateFrom,
      dateTo: dateTo,
      limit: limit,
    ),
    from: this,
  );

  @override
  String toString() => r'transactionsProvider';
}

/// Fetches all categories (system + household).
/// Cached independently so it doesn't re-fetch every time transactions refresh.

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

/// Fetches all categories (system + household).
/// Cached independently so it doesn't re-fetch every time transactions refresh.

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          FutureOr<List<Category>>
        >
    with $FutureModifier<List<Category>>, $FutureProvider<List<Category>> {
  /// Fetches all categories (system + household).
  /// Cached independently so it doesn't re-fetch every time transactions refresh.
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Category>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'12b34e3b4663652b0544ee5960c51df92d7b9da5';

/// Transactions currently paired to a specific receipt. Powers the
/// receipt detail screen's "Paired Transactions" section so the user
/// can see and unpair existing links without re-querying the global
/// transactions list.

@ProviderFor(transactionsForReceipt)
final transactionsForReceiptProvider = TransactionsForReceiptFamily._();

/// Transactions currently paired to a specific receipt. Powers the
/// receipt detail screen's "Paired Transactions" section so the user
/// can see and unpair existing links without re-querying the global
/// transactions list.

final class TransactionsForReceiptProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          FutureOr<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $FutureProvider<List<Transaction>> {
  /// Transactions currently paired to a specific receipt. Powers the
  /// receipt detail screen's "Paired Transactions" section so the user
  /// can see and unpair existing links without re-querying the global
  /// transactions list.
  TransactionsForReceiptProvider._({
    required TransactionsForReceiptFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'transactionsForReceiptProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$transactionsForReceiptHash();

  @override
  String toString() {
    return r'transactionsForReceiptProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    final argument = this.argument as String;
    return transactionsForReceipt(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionsForReceiptProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transactionsForReceiptHash() =>
    r'ab48fa47dad32ec63429238604fb99e17ded2024';

/// Transactions currently paired to a specific receipt. Powers the
/// receipt detail screen's "Paired Transactions" section so the user
/// can see and unpair existing links without re-querying the global
/// transactions list.

final class TransactionsForReceiptFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Transaction>>, String> {
  TransactionsForReceiptFamily._()
    : super(
        retry: null,
        name: r'transactionsForReceiptProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Transactions currently paired to a specific receipt. Powers the
  /// receipt detail screen's "Paired Transactions" section so the user
  /// can see and unpair existing links without re-querying the global
  /// transactions list.

  TransactionsForReceiptProvider call(String receiptId) =>
      TransactionsForReceiptProvider._(argument: receiptId, from: this);

  @override
  String toString() => r'transactionsForReceiptProvider';
}

/// Fetches ML-categorised transactions whose confidence fell in the
/// uncertain band. Backs the "Review categorisations" surface — the user
/// confirms or corrects each row, which flips `category_assigned_by` to
/// 'user' and feeds the next retrain.

@ProviderFor(uncertainTransactions)
final uncertainTransactionsProvider = UncertainTransactionsProvider._();

/// Fetches ML-categorised transactions whose confidence fell in the
/// uncertain band. Backs the "Review categorisations" surface — the user
/// confirms or corrects each row, which flips `category_assigned_by` to
/// 'user' and feeds the next retrain.

final class UncertainTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          FutureOr<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $FutureProvider<List<Transaction>> {
  /// Fetches ML-categorised transactions whose confidence fell in the
  /// uncertain band. Backs the "Review categorisations" surface — the user
  /// confirms or corrects each row, which flips `category_assigned_by` to
  /// 'user' and feeds the next retrain.
  UncertainTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'uncertainTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$uncertainTransactionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    return uncertainTransactions(ref);
  }
}

String _$uncertainTransactionsHash() =>
    r'dee3bffe3584d161138f984867dff6f5a488968a';
