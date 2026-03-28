// Account model and related enums.
//
// [Account] mirrors the `accounts` table in Supabase. All monetary values
// (current_balance, credit_limit) are stored as INTEGER CENTS.
// Freezed generates immutable value semantics and copyWith; json_serializable
// handles snake_case ↔ camelCase conversion via build.yaml field_rename config.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// Maps to the `account_type` Postgres enum.
/// [dbValue] returns the exact string stored in the DB.
enum AccountType {
  @JsonValue('checking') checking,
  @JsonValue('savings') savings,
  @JsonValue('credit_card') creditCard,
  @JsonValue('brokerage') brokerage,
  @JsonValue('ira_traditional') iraTraditional,
  @JsonValue('ira_roth') iraRoth,
  @JsonValue('retirement_401k') retirement401k,
  @JsonValue('retirement_403b') retirement403b,
  @JsonValue('hsa') hsa,
  @JsonValue('college_529') college529,
  @JsonValue('cash') cash;

  /// Human-readable label shown in the UI.
  String get displayName => switch (this) {
        AccountType.checking => 'Checking',
        AccountType.savings => 'Savings',
        AccountType.creditCard => 'Credit Card',
        AccountType.brokerage => 'Brokerage',
        AccountType.iraTraditional => 'Traditional IRA',
        AccountType.iraRoth => 'Roth IRA',
        AccountType.retirement401k => '401(k)',
        AccountType.retirement403b => '403(b)',
        AccountType.hsa => 'HSA',
        AccountType.college529 => '529 Plan',
        AccountType.cash => 'Cash',
      };

  /// The exact string value stored in the Postgres `account_type` enum column.
  /// Used when building INSERT payloads manually (the @JsonValue annotation
  /// handles deserialization but not manual map construction).
  String get dbValue => switch (this) {
        AccountType.checking => 'checking',
        AccountType.savings => 'savings',
        AccountType.creditCard => 'credit_card',
        AccountType.brokerage => 'brokerage',
        AccountType.iraTraditional => 'ira_traditional',
        AccountType.iraRoth => 'ira_roth',
        AccountType.retirement401k => 'retirement_401k',
        AccountType.retirement403b => 'retirement_403b',
        AccountType.hsa => 'hsa',
        AccountType.college529 => 'college_529',
        AccountType.cash => 'cash',
      };

  /// Groups this account type into one of three UI sections.
  AccountGroup get group => switch (this) {
        AccountType.checking ||
        AccountType.savings ||
        AccountType.cash =>
          AccountGroup.banking,
        AccountType.creditCard => AccountGroup.creditCards,
        _ => AccountGroup.investments,
      };
}

/// Used to group accounts into sections on the Accounts screen.
enum AccountGroup {
  banking,
  creditCards,
  investments;

  String get displayName => switch (this) {
        AccountGroup.banking => 'Banking',
        AccountGroup.creditCards => 'Credit Cards',
        AccountGroup.investments => 'Investments & Retirement',
      };
}

/// Immutable representation of a row in the `accounts` table.
///
/// [currentBalance] and [creditLimit] are in cents (integer).
/// [color] is an optional hex string (e.g. "#3B82F6") for custom account colors.
@freezed
class Account with _$Account {
  const factory Account({
    required String id,
    required String householdId,
    /// The family member who owns this account (may differ from the logged-in user).
    required String ownerUserId,
    required String name,
    required AccountType accountType,
    String? institution,
    /// Last 4 digits of the account/card number for display purposes.
    String? lastFour,
    required String currency,
    /// Current balance in cents. Negative values indicate debt (credit cards).
    required int currentBalance,
    /// Credit limit in cents. Only set for [AccountType.creditCard].
    int? creditLimit,
    required bool isActive,
    /// Optional hex color for the account card (e.g. "#3B82F6").
    String? color,
    /// Annual interest rate as a decimal (e.g. 0.2499 = 24.99% APR).
    /// Null means not applicable (e.g. checking, cash).
    double? interestRate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
