// Account model and related enums.
//
// [Account] mirrors the `accounts` table in Supabase. All monetary values
// (current_balance, credit_limit) are stored as INTEGER CENTS.
// Freezed generates immutable value semantics and copyWith; json_serializable
// handles snake_case ↔ camelCase conversion via build.yaml field_rename config.
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/theme/app_theme.dart';

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
  @JsonValue('cash') cash,
  @JsonValue('mortgage') mortgage;

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
        AccountType.mortgage => 'Mortgage',
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
        AccountType.mortgage => 'mortgage',
      };

  /// Groups this account type into one of three UI sections.
  AccountGroup get group => switch (this) {
        AccountType.checking ||
        AccountType.savings ||
        AccountType.cash =>
          AccountGroup.banking,
        AccountType.creditCard => AccountGroup.creditCards,
        AccountType.mortgage => AccountGroup.loans,
        _ => AccountGroup.investments,
      };

  /// Material icon shown in account cards / detail headers.
  IconData get icon => switch (this) {
        AccountType.checking => Icons.account_balance_outlined,
        AccountType.savings => Icons.savings_outlined,
        AccountType.creditCard => Icons.credit_card_outlined,
        AccountType.brokerage => Icons.trending_up_outlined,
        AccountType.iraTraditional ||
        AccountType.iraRoth =>
          Icons.account_balance_wallet_outlined,
        AccountType.retirement401k ||
        AccountType.retirement403b =>
          Icons.work_outline,
        AccountType.hsa => Icons.health_and_safety_outlined,
        AccountType.college529 => Icons.school_outlined,
        AccountType.cash => Icons.payments_outlined,
        AccountType.mortgage => Icons.home_outlined,
      };

  /// True when this account represents money owed (debt) rather than an asset.
  /// Liability balances are stored as negative cents and rendered as the
  /// magnitude owed in the UI.
  bool get isLiability =>
      group == AccountGroup.creditCards || group == AccountGroup.loans;
}

/// Used to group accounts into sections on the Accounts screen.
enum AccountGroup {
  banking,
  creditCards,
  loans,
  investments;

  String get displayName => switch (this) {
        AccountGroup.banking => 'Banking',
        AccountGroup.creditCards => 'Credit Cards',
        AccountGroup.loans => 'Loans',
        AccountGroup.investments => 'Investments & Retirement',
      };

  /// Default accent color used when an account doesn't set its own [Account.color].
  Color get defaultColor => switch (this) {
        AccountGroup.banking => BrandColors.primary,
        AccountGroup.creditCards => BrandColors.expense,
        AccountGroup.loans => BrandColors.warning,
        AccountGroup.investments => BrandColors.income,
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
    /// Balance in cents before any tracked transactions.
    /// current_balance = starting_balance + sum(transactions).
    @Default(0) int startingBalance,
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
