// Transaction model.
// Mirrors the `transactions` table. Amounts are stored as INTEGER CENTS;
// negative = debit (money out), positive = credit (money in).
import 'package:freezed_annotation/freezed_annotation.dart';
import 'category.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// Immutable representation of a row in the `transactions` table.
///
/// [amount] is in cents. Negative means money left the account (purchase,
/// fee, payment). Positive means money entered (deposit, refund).
///
/// [category] is an optional joined [Category] row, populated when the
/// repository selects with `*, category:categories(*)`.
@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String householdId,
    required String accountId,
    /// Amount in cents. Negative = debit/expense, positive = credit/income.
    required int amount,
    required String currency,
    /// Raw description from the bank statement or user entry.
    required String description,
    /// Cleaned merchant name (may differ from description).
    String? merchant,
    String? categoryId,
    /// The date the transaction occurred (not the processing date).
    required DateTime transactionDate,
    /// The date the transaction cleared the account (may lag transactionDate).
    DateTime? postedDate,
    required bool pending,
    /// How the transaction was created: 'manual', 'import', or 'plaid'.
    required String source,
    String? enteredBy,
    String? receiptId,
    String? notes,
    /// Bank-assigned dedup key. Prevents re-importing the same statement twice.
    String? externalId,
    required DateTime createdAt,
    required DateTime updatedAt,
    /// Eagerly-loaded category row (null if uncategorized or not joined).
    Category? category,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
