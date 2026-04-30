import 'package:freezed_annotation/freezed_annotation.dart';

part 'credit_card_rate.freezed.dart';
part 'credit_card_rate.g.dart';

enum CreditRateType {
  @JsonValue('purchase') purchase,
  @JsonValue('cash_advance') cashAdvance,
  @JsonValue('balance_transfer') balanceTransfer,
  @JsonValue('penalty') penalty;

  String get displayName => switch (this) {
        CreditRateType.purchase => 'Purchase APR',
        CreditRateType.cashAdvance => 'Cash Advance APR',
        CreditRateType.balanceTransfer => 'Balance Transfer APR',
        CreditRateType.penalty => 'Penalty APR',
      };

  /// Exact string stored in the Postgres `credit_rate_type` enum.
  /// `.name` returns the Dart camelCase identifier (e.g. `cashAdvance`),
  /// which doesn't match the snake_case enum values — so manual INSERTs
  /// must use this getter instead.
  String get dbValue => switch (this) {
        CreditRateType.purchase => 'purchase',
        CreditRateType.cashAdvance => 'cash_advance',
        CreditRateType.balanceTransfer => 'balance_transfer',
        CreditRateType.penalty => 'penalty',
      };
}

@freezed
class CreditCardRate with _$CreditCardRate {
  const factory CreditCardRate({
    required String id,
    required String accountId,
    required CreditRateType rateType,
    /// Annual rate as a decimal (e.g. 0.2499 = 24.99%).
    required double rate,
    required bool isIntro,
    DateTime? introEndsOn,
    required bool isActive,
    String? label,
    required DateTime createdAt,
  }) = _CreditCardRate;

  factory CreditCardRate.fromJson(Map<String, dynamic> json) =>
      _$CreditCardRateFromJson(json);
}
