// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All budgets for the current household, each paired with correct-period
/// spending and an end-of-period projection.
///
/// Spending is fetched per-budget using its own [BudgetPeriod.currentRange]
/// so weekly budgets aren't inflated with a full year of transactions.

@ProviderFor(budgetData)
final budgetDataProvider = BudgetDataProvider._();

/// All budgets for the current household, each paired with correct-period
/// spending and an end-of-period projection.
///
/// Spending is fetched per-budget using its own [BudgetPeriod.currentRange]
/// so weekly budgets aren't inflated with a full year of transactions.

final class BudgetDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BudgetWithSpending>>,
          List<BudgetWithSpending>,
          FutureOr<List<BudgetWithSpending>>
        >
    with
        $FutureModifier<List<BudgetWithSpending>>,
        $FutureProvider<List<BudgetWithSpending>> {
  /// All budgets for the current household, each paired with correct-period
  /// spending and an end-of-period projection.
  ///
  /// Spending is fetched per-budget using its own [BudgetPeriod.currentRange]
  /// so weekly budgets aren't inflated with a full year of transactions.
  BudgetDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetDataHash();

  @$internal
  @override
  $FutureProviderElement<List<BudgetWithSpending>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BudgetWithSpending>> create(Ref ref) {
    return budgetData(ref);
  }
}

String _$budgetDataHash() => r'cb1536ed519bbf017c6a9f2caca6cb21add2a27a';
