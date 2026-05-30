// Shared test data factories. Audit 2026-05-26 T1.
//
// Every existing test file inlines its own sample rows — the
// audit counted ~59 test files doing some flavour of "make me
// an Account". The result is hundreds of lines of "what does a
// valid X look like" boilerplate that drifts every time a
// model gains a field. Build the factories once, use forward:
// new tests should reach for `aTransaction(...)` instead of
// hand-rolling a Transaction constructor call. Existing tests
// can migrate opportunistically; nothing here breaks the old
// pattern.
//
// Conventions:
//   * Functions named `aX(...)` where X is the model — reads
//     "a Transaction with this id" out loud.
//   * Every required field has a sensible default. Names follow
//     the schema's snake_case → camelCase mapping.
//   * Override what you care about by passing named args.
//   * Deterministic defaults (no DateTime.now(), no Random) so
//     factory-built rows compare equal across runs.

import 'package:mybudget/features/accounts/models/account.dart';
import 'package:mybudget/features/budget/models/budget.dart';
import 'package:mybudget/features/currency/models/fx_rate.dart';
import 'package:mybudget/features/holdings/models/holding.dart';
import 'package:mybudget/features/receipts/models/receipt.dart';
import 'package:mybudget/features/receipts/models/receipt_line_item.dart';
import 'package:mybudget/features/recurring/models/recurring_transaction.dart';
import 'package:mybudget/features/transactions/models/category.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';
import 'package:mybudget/features/transactions/models/transaction_tag.dart';

/// Anchor timestamp the factories default to. Pinning a
/// concrete instant keeps assertions like `expect(x.createdAt,
/// kFactoryDate)` stable; tests that care about ranges can
/// `.add(...)` from this.
final DateTime kFactoryDate = DateTime.utc(2026, 5, 28, 12);

Account anAccount({
  String id = 'a-1',
  String householdId = 'hh-1',
  String ownerUserId = 'user-1',
  String name = 'Checking',
  AccountType accountType = AccountType.checking,
  String? institution = 'Chase',
  String? lastFour = '1234',
  String currency = 'USD',
  int startingBalance = 0,
  int currentBalance = 100000,
  int? creditLimit,
  bool isActive = true,
  String? color,
  double? interestRate,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Account(
    id: id,
    householdId: householdId,
    ownerUserId: ownerUserId,
    name: name,
    accountType: accountType,
    institution: institution,
    lastFour: lastFour,
    currency: currency,
    startingBalance: startingBalance,
    currentBalance: currentBalance,
    creditLimit: creditLimit,
    isActive: isActive,
    color: color,
    interestRate: interestRate,
    createdAt: createdAt ?? kFactoryDate,
    updatedAt: updatedAt ?? kFactoryDate,
  );
}

Transaction aTransaction({
  String id = 't-1',
  String householdId = 'hh-1',
  String accountId = 'a-1',
  int amount = -2500,
  String currency = 'USD',
  String description = 'Coffee',
  String? merchant,
  String? categoryId = 'cat-food',
  DateTime? transactionDate,
  DateTime? postedDate,
  bool pending = false,
  String source = 'manual',
  String? enteredBy = 'user-1',
  String? receiptId,
  String? rateId,
  String? notes,
  String? externalId,
  String? transferId,
  int? mlModelConfidence,
  Category? category,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Transaction(
    id: id,
    householdId: householdId,
    accountId: accountId,
    amount: amount,
    currency: currency,
    description: description,
    merchant: merchant,
    categoryId: categoryId,
    transactionDate: transactionDate ?? kFactoryDate,
    postedDate: postedDate,
    pending: pending,
    source: source,
    enteredBy: enteredBy,
    receiptId: receiptId,
    rateId: rateId,
    notes: notes,
    externalId: externalId,
    transferId: transferId,
    mlModelConfidence: mlModelConfidence,
    category: category,
    createdAt: createdAt ?? kFactoryDate,
    updatedAt: updatedAt ?? kFactoryDate,
  );
}

Category aCategory({
  String id = 'cat-1',
  String? householdId,
  String name = 'Groceries',
  String? parentId,
  String? icon = 'shopping_cart',
  String? color = '#22C55E',
  bool isIncome = false,
  int sortOrder = 100,
}) {
  return Category(
    id: id,
    householdId: householdId,
    name: name,
    parentId: parentId,
    icon: icon,
    color: color,
    isIncome: isIncome,
    sortOrder: sortOrder,
  );
}

Budget aBudget({
  String id = 'b-1',
  String householdId = 'hh-1',
  String categoryId = 'cat-1',
  int amount = 50000,
  String currency = 'USD',
  BudgetPeriod period = BudgetPeriod.monthly,
  DateTime? startDate,
  DateTime? endDate,
  String createdBy = 'user-1',
}) {
  return Budget(
    id: id,
    householdId: householdId,
    categoryId: categoryId,
    amount: amount,
    currency: currency,
    period: period,
    startDate: startDate ?? kFactoryDate,
    endDate: endDate,
    createdBy: createdBy,
  );
}

Receipt aReceipt({
  String id = 'r-1',
  String householdId = 'hh-1',
  String uploadedBy = 'user-1',
  String? storagePath = 'hh-1/r-1.jpg',
  String? thumbnailPath,
  String? merchantName = 'Whole Foods',
  DateTime? receiptDate,
  int? totalAmount = 12500,
  OcrStatus ocrStatus = OcrStatus.complete,
  Map<String, dynamic>? ocrRaw,
  DateTime? uploadedAt,
}) {
  return Receipt(
    id: id,
    householdId: householdId,
    uploadedBy: uploadedBy,
    storagePath: storagePath ?? 'hh-1/r-1.jpg',
    thumbnailPath: thumbnailPath,
    merchantName: merchantName,
    receiptDate: receiptDate ?? kFactoryDate,
    totalAmount: totalAmount,
    ocrStatus: ocrStatus,
    ocrRaw: ocrRaw,
    uploadedAt: uploadedAt ?? kFactoryDate,
  );
}

ReceiptLineItem aLineItem({
  String id = 'li-1',
  String receiptId = 'r-1',
  String description = 'Bananas',
  int amount = 199,
  double? quantity,
  int? unitPrice,
  String? categoryId,
  bool isTax = false,
  bool isTip = false,
  bool isDiscount = false,
  int sortOrder = 0,
  int? ocrConfidenceBp,
}) {
  return ReceiptLineItem(
    id: id,
    receiptId: receiptId,
    description: description,
    amount: amount,
    quantity: quantity,
    unitPrice: unitPrice,
    categoryId: categoryId,
    isTax: isTax,
    isTip: isTip,
    isDiscount: isDiscount,
    sortOrder: sortOrder,
    ocrConfidenceBp: ocrConfidenceBp,
  );
}

Holding aHolding({
  String id = 'h-1',
  String householdId = 'hh-1',
  String accountId = 'a-1',
  String symbol = 'VOO',
  String? description = 'Vanguard S&P 500',
  double quantity = 10.5,
  int? costBasis = 380000,
  int currentValue = 450000,
  AssetClass? assetClass = AssetClass.usEquity,
  DateTime? lastPricedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Holding(
    id: id,
    householdId: householdId,
    accountId: accountId,
    symbol: symbol,
    description: description,
    quantity: quantity,
    costBasis: costBasis,
    currentValue: currentValue,
    assetClass: assetClass,
    lastPricedAt: lastPricedAt ?? kFactoryDate,
    createdAt: createdAt ?? kFactoryDate,
    updatedAt: updatedAt ?? kFactoryDate,
  );
}

FxRate anFxRate({
  String householdId = 'hh-1',
  String fromCurrency = 'EUR',
  String toCurrency = 'USD',
  DateTime? asOfDate,
  double rate = 1.08,
  String? createdBy = 'user-1',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return FxRate(
    householdId: householdId,
    fromCurrency: fromCurrency,
    toCurrency: toCurrency,
    asOfDate: asOfDate ?? kFactoryDate,
    rate: rate,
    createdBy: createdBy,
    createdAt: createdAt ?? kFactoryDate,
    updatedAt: updatedAt ?? kFactoryDate,
  );
}

RecurringTransaction aRecurring({
  String id = 'rec-1',
  String householdId = 'hh-1',
  String accountId = 'a-1',
  int amountCents = -999,
  String currency = 'USD',
  String description = 'Spotify',
  String? merchant,
  String? categoryId,
  RecurrenceCadence cadence = RecurrenceCadence.monthly,
  DateTime? nextOccurrenceDate,
  DateTime? lastEmittedAt,
  DateTime? skippedUntilDate,
  bool isActive = true,
  String? createdBy = 'user-1',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return RecurringTransaction(
    id: id,
    householdId: householdId,
    accountId: accountId,
    amountCents: amountCents,
    currency: currency,
    description: description,
    merchant: merchant,
    categoryId: categoryId,
    cadence: cadence,
    nextOccurrenceDate: nextOccurrenceDate ?? kFactoryDate,
    lastEmittedAt: lastEmittedAt,
    skippedUntilDate: skippedUntilDate,
    isActive: isActive,
    createdBy: createdBy,
    createdAt: createdAt ?? kFactoryDate,
    updatedAt: updatedAt ?? kFactoryDate,
  );
}

TransactionTag aTag({
  String id = 'tag-1',
  String householdId = 'hh-1',
  String name = 'contractor',
  String? color = '#22C55E',
  DateTime? createdAt,
}) {
  return TransactionTag(
    id: id,
    householdId: householdId,
    name: name,
    color: color,
    createdAt: createdAt ?? kFactoryDate,
  );
}
