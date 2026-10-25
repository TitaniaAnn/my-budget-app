// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'converted_net_worth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(convertedNetWorth)
final convertedNetWorthProvider = ConvertedNetWorthProvider._();

final class ConvertedNetWorthProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConvertedNetWorth>,
          ConvertedNetWorth,
          FutureOr<ConvertedNetWorth>
        >
    with
        $FutureModifier<ConvertedNetWorth>,
        $FutureProvider<ConvertedNetWorth> {
  ConvertedNetWorthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'convertedNetWorthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$convertedNetWorthHash();

  @$internal
  @override
  $FutureProviderElement<ConvertedNetWorth> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ConvertedNetWorth> create(Ref ref) {
    return convertedNetWorth(ref);
  }
}

String _$convertedNetWorthHash() => r'd7bbca5281a093f463d2ee489b0d612d423d7333';
