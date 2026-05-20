// FxRate — mirrors the `fx_rates` table (migration 036).
//
// One row per (household, from_currency, to_currency, as_of_date).
// The lookup pattern is "give me the most recent rate from X to Y
// at or before date Z" — handled by the repository, this is just
// the persisted shape.

// Freezed × json_serializable: @JsonKey on a constructor param
// triggers an analyzer warning even though codegen consumes it
// correctly. File-level ignore so we don't sprinkle inline
// suppressions.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'fx_rate.freezed.dart';
part 'fx_rate.g.dart';

@freezed
class FxRate with _$FxRate {
  const factory FxRate({
    required String householdId,
    required String fromCurrency,
    required String toCurrency,
    required DateTime asOfDate,

    /// Multiplier. amountInTo = amountInFrom × rate. Stored as
    /// NUMERIC(18,8) in the DB; Postgres returns NUMERIC as a
    /// string on the JSON wire to avoid float loss in transit, so
    /// [_rateFromJson] coerces it to a double here. The math
    /// downstream uses plain `num` multipliers.
    @JsonKey(fromJson: _rateFromJson) required double rate,
    String? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FxRate;

  factory FxRate.fromJson(Map<String, dynamic> json) =>
      _$FxRateFromJson(json);
}

double _rateFromJson(Object? raw) {
  if (raw is num) return raw.toDouble();
  return double.parse(raw.toString());
}
