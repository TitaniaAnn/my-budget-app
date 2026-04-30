// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$budgetDataHash() => r'095a3c1cfc58b43a859b2ef011690a98a58172e5';

/// All budgets for the current household, each paired with correct-period
/// spending and an end-of-period projection.
///
/// Spending is fetched per-budget using its own [BudgetPeriod.currentRange]
/// so weekly budgets aren't inflated with a full year of transactions.
///
/// Copied from [budgetData].
@ProviderFor(budgetData)
final budgetDataProvider =
    AutoDisposeFutureProvider<List<BudgetWithSpending>>.internal(
      budgetData,
      name: r'budgetDataProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$budgetDataHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BudgetDataRef = AutoDisposeFutureProviderRef<List<BudgetWithSpending>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
