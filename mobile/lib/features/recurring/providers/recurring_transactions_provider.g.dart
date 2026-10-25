// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transactions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recurringTransactions)
final recurringTransactionsProvider = RecurringTransactionsProvider._();

final class RecurringTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RecurringTransaction>>,
          List<RecurringTransaction>,
          FutureOr<List<RecurringTransaction>>
        >
    with
        $FutureModifier<List<RecurringTransaction>>,
        $FutureProvider<List<RecurringTransaction>> {
  RecurringTransactionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurringTransactionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurringTransactionsHash();

  @$internal
  @override
  $FutureProviderElement<List<RecurringTransaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RecurringTransaction>> create(Ref ref) {
    return recurringTransactions(ref);
  }
}

String _$recurringTransactionsHash() =>
    r'f12d985050ce6a46846acb945a17176b42bc71ed';
