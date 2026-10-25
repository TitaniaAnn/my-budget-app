// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorizer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for the singleton [Categorizer].
///
/// The ML classifier loads asynchronously the first time the provider
/// is read; until then `mlAvailable` is false and the façade is a pure
/// keyword matcher. The first read must therefore be `await` (the
/// provider returns a Future). All call sites already do this.

@ProviderFor(categorizer)
final categorizerProvider = CategorizerProvider._();

/// Riverpod provider for the singleton [Categorizer].
///
/// The ML classifier loads asynchronously the first time the provider
/// is read; until then `mlAvailable` is false and the façade is a pure
/// keyword matcher. The first read must therefore be `await` (the
/// provider returns a Future). All call sites already do this.

final class CategorizerProvider
    extends
        $FunctionalProvider<
          AsyncValue<Categorizer>,
          Categorizer,
          FutureOr<Categorizer>
        >
    with $FutureModifier<Categorizer>, $FutureProvider<Categorizer> {
  /// Riverpod provider for the singleton [Categorizer].
  ///
  /// The ML classifier loads asynchronously the first time the provider
  /// is read; until then `mlAvailable` is false and the façade is a pure
  /// keyword matcher. The first read must therefore be `await` (the
  /// provider returns a Future). All call sites already do this.
  CategorizerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categorizerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categorizerHash();

  @$internal
  @override
  $FutureProviderElement<Categorizer> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Categorizer> create(Ref ref) {
    return categorizer(ref);
  }
}

String _$categorizerHash() => r'b2b2800cdb49aa46a72d3e593bdbb263c351a962';
