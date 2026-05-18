// Widget tests for [TransactionCard].
//
// Pins the receipt-attached paperclip behaviour: the indicator must
// appear iff `transaction.receiptId` is set. A pure-logic test can't
// cover this — the conditional lives inside the build tree.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/theme/app_theme.dart';
import 'package:mybudget/features/transactions/models/transaction.dart';
import 'package:mybudget/features/transactions/widgets/transaction_card.dart';

Transaction _tx({String? receiptId}) {
  final now = DateTime.utc(2026, 5, 18);
  return Transaction(
    id: 'tx-1',
    householdId: 'hh-1',
    accountId: 'acc-1',
    amount: -1234,
    currency: 'USD',
    description: 'TEST MERCHANT',
    transactionDate: now,
    pending: false,
    source: 'manual',
    receiptId: receiptId,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _harness(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('TransactionCard receipt indicator', () {
    testWidgets('shows paperclip when receiptId is set', (tester) async {
      await tester.pumpWidget(
        _harness(TransactionCard(transaction: _tx(receiptId: 'r-1'))),
      );

      expect(
        find.byIcon(Icons.attach_file_outlined),
        findsOneWidget,
        reason:
            'A transaction with receipt_id should surface the paperclip '
            'so users can tell at a glance that the row has proof attached.',
      );
    });

    testWidgets('hides paperclip when receiptId is null', (tester) async {
      await tester.pumpWidget(_harness(TransactionCard(transaction: _tx())));

      expect(
        find.byIcon(Icons.attach_file_outlined),
        findsNothing,
        reason:
            'An unpaired transaction must not render the paperclip — '
            'otherwise every row in a list would look "receipted".',
      );
    });
  });
}
