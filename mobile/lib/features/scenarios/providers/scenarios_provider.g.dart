// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenarios_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scenariosHash() => r'9d84f39490ba5fb4fee8ce61dd6902f424a3aac1';

/// All scenarios for the current household.
///
/// Copied from [scenarios].
@ProviderFor(scenarios)
final scenariosProvider = AutoDisposeFutureProvider<List<Scenario>>.internal(
  scenarios,
  name: r'scenariosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scenariosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScenariosRef = AutoDisposeFutureProviderRef<List<Scenario>>;
String _$scenarioDetailHash() => r'0ded30aab9af40ad1180249cf0601d9ad7a07b93';

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

/// Full detail for a single scenario: events + projection.
///
/// The projection starts from the household's current net worth (sum of
/// account balances) and applies each event forward in time.
///
/// Copied from [scenarioDetail].
@ProviderFor(scenarioDetail)
const scenarioDetailProvider = ScenarioDetailFamily();

/// Full detail for a single scenario: events + projection.
///
/// The projection starts from the household's current net worth (sum of
/// account balances) and applies each event forward in time.
///
/// Copied from [scenarioDetail].
class ScenarioDetailFamily extends Family<AsyncValue<ScenarioDetail>> {
  /// Full detail for a single scenario: events + projection.
  ///
  /// The projection starts from the household's current net worth (sum of
  /// account balances) and applies each event forward in time.
  ///
  /// Copied from [scenarioDetail].
  const ScenarioDetailFamily();

  /// Full detail for a single scenario: events + projection.
  ///
  /// The projection starts from the household's current net worth (sum of
  /// account balances) and applies each event forward in time.
  ///
  /// Copied from [scenarioDetail].
  ScenarioDetailProvider call(String scenarioId) {
    return ScenarioDetailProvider(scenarioId);
  }

  @override
  ScenarioDetailProvider getProviderOverride(
    covariant ScenarioDetailProvider provider,
  ) {
    return call(provider.scenarioId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'scenarioDetailProvider';
}

/// Full detail for a single scenario: events + projection.
///
/// The projection starts from the household's current net worth (sum of
/// account balances) and applies each event forward in time.
///
/// Copied from [scenarioDetail].
class ScenarioDetailProvider extends AutoDisposeFutureProvider<ScenarioDetail> {
  /// Full detail for a single scenario: events + projection.
  ///
  /// The projection starts from the household's current net worth (sum of
  /// account balances) and applies each event forward in time.
  ///
  /// Copied from [scenarioDetail].
  ScenarioDetailProvider(String scenarioId)
    : this._internal(
        (ref) => scenarioDetail(ref as ScenarioDetailRef, scenarioId),
        from: scenarioDetailProvider,
        name: r'scenarioDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$scenarioDetailHash,
        dependencies: ScenarioDetailFamily._dependencies,
        allTransitiveDependencies:
            ScenarioDetailFamily._allTransitiveDependencies,
        scenarioId: scenarioId,
      );

  ScenarioDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scenarioId,
  }) : super.internal();

  final String scenarioId;

  @override
  Override overrideWith(
    FutureOr<ScenarioDetail> Function(ScenarioDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScenarioDetailProvider._internal(
        (ref) => create(ref as ScenarioDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scenarioId: scenarioId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ScenarioDetail> createElement() {
    return _ScenarioDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScenarioDetailProvider && other.scenarioId == scenarioId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scenarioId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScenarioDetailRef on AutoDisposeFutureProviderRef<ScenarioDetail> {
  /// The parameter `scenarioId` of this provider.
  String get scenarioId;
}

class _ScenarioDetailProviderElement
    extends AutoDisposeFutureProviderElement<ScenarioDetail>
    with ScenarioDetailRef {
  _ScenarioDetailProviderElement(super.provider);

  @override
  String get scenarioId => (origin as ScenarioDetailProvider).scenarioId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
