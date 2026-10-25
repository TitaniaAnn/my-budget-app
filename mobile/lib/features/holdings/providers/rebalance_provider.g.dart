// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rebalance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rebalanceReport)
final rebalanceReportProvider = RebalanceReportProvider._();

final class RebalanceReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<RebalanceReport>,
          RebalanceReport,
          FutureOr<RebalanceReport>
        >
    with $FutureModifier<RebalanceReport>, $FutureProvider<RebalanceReport> {
  RebalanceReportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rebalanceReportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rebalanceReportHash();

  @$internal
  @override
  $FutureProviderElement<RebalanceReport> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RebalanceReport> create(Ref ref) {
    return rebalanceReport(ref);
  }
}

String _$rebalanceReportHash() => r'785bf43a2d23bb75d2208df428807e2d60d7fb1c';
