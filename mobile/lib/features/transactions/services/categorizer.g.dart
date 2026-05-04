// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorizer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categorizerHash() => r'7d07e5159b7b6d72babba016ba712f51908a351a';

/// Riverpod provider for the singleton [Categorizer].
///
/// The ML classifier loads asynchronously the first time the provider
/// is read; until then `mlAvailable` is false and the façade is a pure
/// keyword matcher. The first read must therefore be `await` (the
/// provider returns a Future). All call sites already do this.
///
/// Copied from [categorizer].
@ProviderFor(categorizer)
final categorizerProvider = FutureProvider<Categorizer>.internal(
  categorizer,
  name: r'categorizerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categorizerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CategorizerRef = FutureProviderRef<Categorizer>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
