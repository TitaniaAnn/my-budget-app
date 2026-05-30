// Smoke tests for the shared factories. Audit 2026-05-26 T1.
//
// One assertion per factory: defaults produce a valid instance.
// If a new required field is added to a freezed model, the
// factory's constructor call will fail to compile and this
// file is the first one CI surfaces — a fast, single-spot
// signal for what would otherwise be a model-drift bug.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/accounts/models/account.dart';
import 'package:mybudget/features/budget/models/budget.dart';

import 'factories.dart';

void main() {
  test('anAccount() builds a valid Account', () {
    final a = anAccount();
    expect(a.id, 'a-1');
    expect(a.accountType, AccountType.checking);
    expect(a.currentBalance, 100000);
  });

  test('aTransaction() builds a valid Transaction', () {
    final t = aTransaction();
    expect(t.amount, -2500);
    expect(t.description, 'Coffee');
    expect(t.source, 'manual');
  });

  test('aCategory() builds a valid Category', () {
    final c = aCategory();
    expect(c.id, 'cat-1');
    expect(c.isIncome, isFalse);
    expect(c.householdId, isNull, reason: 'default = system category');
  });

  test('aBudget() builds a valid Budget', () {
    final b = aBudget();
    expect(b.amount, 50000);
    expect(b.period, BudgetPeriod.monthly);
  });

  test('aReceipt() builds a valid Receipt', () {
    final r = aReceipt();
    expect(r.merchantName, 'Whole Foods');
    expect(r.totalAmount, 12500);
  });

  test('aLineItem() builds a valid ReceiptLineItem', () {
    final li = aLineItem();
    expect(li.amount, 199);
    expect(li.isTax, isFalse);
  });

  test('aHolding() builds a valid Holding', () {
    final h = aHolding();
    expect(h.symbol, 'VOO');
    expect(h.currentValue, 450000);
  });

  test('anFxRate() builds a valid FxRate', () {
    final fx = anFxRate();
    expect(fx.fromCurrency, 'EUR');
    expect(fx.toCurrency, 'USD');
    expect(fx.rate, 1.08);
  });

  test('aRecurring() builds a valid RecurringTransaction', () {
    final r = aRecurring();
    expect(r.amountCents, -999);
    expect(r.isActive, isTrue);
  });

  test('aTag() builds a valid TransactionTag', () {
    final t = aTag();
    expect(t.name, 'contractor');
  });

  test('overrides win over defaults', () {
    // Sanity-pin the named-param override pattern so a future
    // refactor of the factory signature doesn't silently break
    // every caller that relies on it.
    final a = anAccount(name: 'Custom', currentBalance: 999);
    expect(a.name, 'Custom');
    expect(a.currentBalance, 999);
    // Untouched fields still default.
    expect(a.accountType, AccountType.checking);
  });
}
