// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenarios_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// All scenarios for the current household.

@ProviderFor(scenarios)
final scenariosProvider = ScenariosProvider._();

/// All scenarios for the current household.

final class ScenariosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Scenario>>,
          List<Scenario>,
          FutureOr<List<Scenario>>
        >
    with $FutureModifier<List<Scenario>>, $FutureProvider<List<Scenario>> {
  /// All scenarios for the current household.
  ScenariosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scenariosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scenariosHash();

  @$internal
  @override
  $FutureProviderElement<List<Scenario>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Scenario>> create(Ref ref) {
    return scenarios(ref);
  }
}

String _$scenariosHash() => r'a01c8b684a1b05af3f78f605124a886ef897ba74';

/// Cheap card-view companion to [scenarioDetailProvider].
///
/// Each list card needs only the projected end balance + net
/// change. The full detail provider, by contrast, also fetches a
/// 365-day historical walkback (one transactions round-trip per
/// scenario) which the card never displays.
///
/// This provider:
///   * watches the cached [scenariosProvider] + [householdInfoProvider]
///     so N cards share one fetch of each;
///   * still fetches accounts + FX + this-scenario events itself
///     (the scenarios list view is the only consumer right now —
///     extracting more shared providers can come if a third call
///     site appears);
///   * skips the historical walkback entirely.
///
/// Net effect for a household with 10 plans: 5x fewer round-trips
/// to Supabase on the scenarios screen.

@ProviderFor(scenarioCardSummary)
final scenarioCardSummaryProvider = ScenarioCardSummaryFamily._();

/// Cheap card-view companion to [scenarioDetailProvider].
///
/// Each list card needs only the projected end balance + net
/// change. The full detail provider, by contrast, also fetches a
/// 365-day historical walkback (one transactions round-trip per
/// scenario) which the card never displays.
///
/// This provider:
///   * watches the cached [scenariosProvider] + [householdInfoProvider]
///     so N cards share one fetch of each;
///   * still fetches accounts + FX + this-scenario events itself
///     (the scenarios list view is the only consumer right now —
///     extracting more shared providers can come if a third call
///     site appears);
///   * skips the historical walkback entirely.
///
/// Net effect for a household with 10 plans: 5x fewer round-trips
/// to Supabase on the scenarios screen.

final class ScenarioCardSummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<ScenarioCardSummary>,
          ScenarioCardSummary,
          FutureOr<ScenarioCardSummary>
        >
    with
        $FutureModifier<ScenarioCardSummary>,
        $FutureProvider<ScenarioCardSummary> {
  /// Cheap card-view companion to [scenarioDetailProvider].
  ///
  /// Each list card needs only the projected end balance + net
  /// change. The full detail provider, by contrast, also fetches a
  /// 365-day historical walkback (one transactions round-trip per
  /// scenario) which the card never displays.
  ///
  /// This provider:
  ///   * watches the cached [scenariosProvider] + [householdInfoProvider]
  ///     so N cards share one fetch of each;
  ///   * still fetches accounts + FX + this-scenario events itself
  ///     (the scenarios list view is the only consumer right now —
  ///     extracting more shared providers can come if a third call
  ///     site appears);
  ///   * skips the historical walkback entirely.
  ///
  /// Net effect for a household with 10 plans: 5x fewer round-trips
  /// to Supabase on the scenarios screen.
  ScenarioCardSummaryProvider._({
    required ScenarioCardSummaryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'scenarioCardSummaryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scenarioCardSummaryHash();

  @override
  String toString() {
    return r'scenarioCardSummaryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ScenarioCardSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ScenarioCardSummary> create(Ref ref) {
    final argument = this.argument as String;
    return scenarioCardSummary(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ScenarioCardSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scenarioCardSummaryHash() =>
    r'dd05f92eb996bc7eb4b8924edad89e7215e25f46';

/// Cheap card-view companion to [scenarioDetailProvider].
///
/// Each list card needs only the projected end balance + net
/// change. The full detail provider, by contrast, also fetches a
/// 365-day historical walkback (one transactions round-trip per
/// scenario) which the card never displays.
///
/// This provider:
///   * watches the cached [scenariosProvider] + [householdInfoProvider]
///     so N cards share one fetch of each;
///   * still fetches accounts + FX + this-scenario events itself
///     (the scenarios list view is the only consumer right now —
///     extracting more shared providers can come if a third call
///     site appears);
///   * skips the historical walkback entirely.
///
/// Net effect for a household with 10 plans: 5x fewer round-trips
/// to Supabase on the scenarios screen.

final class ScenarioCardSummaryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ScenarioCardSummary>, String> {
  ScenarioCardSummaryFamily._()
    : super(
        retry: null,
        name: r'scenarioCardSummaryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cheap card-view companion to [scenarioDetailProvider].
  ///
  /// Each list card needs only the projected end balance + net
  /// change. The full detail provider, by contrast, also fetches a
  /// 365-day historical walkback (one transactions round-trip per
  /// scenario) which the card never displays.
  ///
  /// This provider:
  ///   * watches the cached [scenariosProvider] + [householdInfoProvider]
  ///     so N cards share one fetch of each;
  ///   * still fetches accounts + FX + this-scenario events itself
  ///     (the scenarios list view is the only consumer right now —
  ///     extracting more shared providers can come if a third call
  ///     site appears);
  ///   * skips the historical walkback entirely.
  ///
  /// Net effect for a household with 10 plans: 5x fewer round-trips
  /// to Supabase on the scenarios screen.

  ScenarioCardSummaryProvider call(String scenarioId) =>
      ScenarioCardSummaryProvider._(argument: scenarioId, from: this);

  @override
  String toString() => r'scenarioCardSummaryProvider';
}

/// Full detail for a single scenario: events + projection.
///
/// The projection starts from the household's current net worth (sum of
/// account balances) and applies each event forward in time.

@ProviderFor(scenarioDetail)
final scenarioDetailProvider = ScenarioDetailFamily._();

/// Full detail for a single scenario: events + projection.
///
/// The projection starts from the household's current net worth (sum of
/// account balances) and applies each event forward in time.

final class ScenarioDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<ScenarioDetail>,
          ScenarioDetail,
          FutureOr<ScenarioDetail>
        >
    with $FutureModifier<ScenarioDetail>, $FutureProvider<ScenarioDetail> {
  /// Full detail for a single scenario: events + projection.
  ///
  /// The projection starts from the household's current net worth (sum of
  /// account balances) and applies each event forward in time.
  ScenarioDetailProvider._({
    required ScenarioDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'scenarioDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scenarioDetailHash();

  @override
  String toString() {
    return r'scenarioDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ScenarioDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ScenarioDetail> create(Ref ref) {
    final argument = this.argument as String;
    return scenarioDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ScenarioDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scenarioDetailHash() => r'14a8bdc96889cac3e461b77dd90b8e4c7138bfe7';

/// Full detail for a single scenario: events + projection.
///
/// The projection starts from the household's current net worth (sum of
/// account balances) and applies each event forward in time.

final class ScenarioDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ScenarioDetail>, String> {
  ScenarioDetailFamily._()
    : super(
        retry: null,
        name: r'scenarioDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Full detail for a single scenario: events + projection.
  ///
  /// The projection starts from the household's current net worth (sum of
  /// account balances) and applies each event forward in time.

  ScenarioDetailProvider call(String scenarioId) =>
      ScenarioDetailProvider._(argument: scenarioId, from: this);

  @override
  String toString() => r'scenarioDetailProvider';
}
