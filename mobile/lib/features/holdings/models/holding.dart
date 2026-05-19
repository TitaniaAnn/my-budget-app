// Holding model — mirrors the `holdings` table (migration 027).
//
// A single security/position inside an investment account. Coexists
// with the account's `current_balance` rather than replacing it
// (audit's "approach 2" — holdings are a detail view, balance stays
// the authoritative number for net worth).
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'holding.freezed.dart';
part 'holding.g.dart';

/// Maps to the `asset_class` Postgres enum. The set is deliberately
/// short — the dashboard's allocation donut renders one slice per
/// class, so a long-tail of free-text classes would just produce a
/// pie chart no human can read.
enum AssetClass {
  @JsonValue('us_equity')
  usEquity,
  @JsonValue('intl_equity')
  intlEquity,
  @JsonValue('bond')
  bond,
  @JsonValue('real_estate')
  realEstate,
  @JsonValue('cash')
  cash,
  @JsonValue('crypto')
  crypto,
  @JsonValue('other')
  other;

  /// User-facing label.
  String get displayName => switch (this) {
    AssetClass.usEquity => 'US Equity',
    AssetClass.intlEquity => 'International Equity',
    AssetClass.bond => 'Bonds',
    AssetClass.realEstate => 'Real Estate',
    AssetClass.cash => 'Cash',
    AssetClass.crypto => 'Crypto',
    AssetClass.other => 'Other',
  };

  /// Exact string stored in the Postgres enum. Used when building
  /// INSERT payloads manually — @JsonValue handles the read path but
  /// not the write path.
  String get dbValue => switch (this) {
    AssetClass.usEquity => 'us_equity',
    AssetClass.intlEquity => 'intl_equity',
    AssetClass.bond => 'bond',
    AssetClass.realEstate => 'real_estate',
    AssetClass.cash => 'cash',
    AssetClass.crypto => 'crypto',
    AssetClass.other => 'other',
  };

  /// Stable donut-slice color per class. Hand-picked rather than
  /// derived from the [BrandColors] palette so the same slice keeps
  /// its color even if the theme rotates accents.
  Color get sliceColor => switch (this) {
    AssetClass.usEquity => const Color(0xFF3B82F6), // blue
    AssetClass.intlEquity => const Color(0xFF22C55E), // green
    AssetClass.bond => const Color(0xFFA855F7), // purple
    AssetClass.realEstate => const Color(0xFFF59E0B), // amber
    AssetClass.cash => const Color(0xFF14B8A6), // teal
    AssetClass.crypto => const Color(0xFFF97316), // orange
    AssetClass.other => const Color(0xFF6B7280), // gray
  };
}

/// Immutable representation of a row in the `holdings` table.
///
/// [currentValue] and [costBasis] are integer cents. [quantity] is a
/// double; the SQL column is NUMERIC(20,8) so the model accepts the
/// usual double precision loss past ~15 sig figs (see migration 027).
@freezed
class Holding with _$Holding {
  const factory Holding({
    required String id,
    required String householdId,
    required String accountId,

    /// Ticker / fund symbol / short crypto code.
    required String symbol,

    /// Optional human-readable name; the symbol is the source of
    /// truth for "which security."
    String? description,
    required double quantity,

    /// Total cost basis in cents. Null = unknown (e.g. backfilled
    /// position without a purchase history).
    int? costBasis,

    /// Current value in cents. User-entered — no price feed in v1.
    required int currentValue,
    AssetClass? assetClass,

    /// Wall-clock of the last user-entered [currentValue]. Powers a
    /// future "stale" indicator; null when never priced.
    DateTime? lastPricedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Holding;

  factory Holding.fromJson(Map<String, dynamic> json) =>
      _$HoldingFromJson(json);
}
