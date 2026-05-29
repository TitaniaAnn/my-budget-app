// Drift round-trip tests for the receipts + receipt_line_items
// caches added in L1 Phase 2c. Same in-memory pattern as the
// prior cache tests.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ReceiptsCacheCompanion sampleReceipt({
    required String id,
    String householdId = 'hh-1',
    String? merchantName = 'Whole Foods',
    DateTime? uploadedAt,
    String ocrStatus = 'complete',
    String? ocrRawJson,
  }) {
    final ts = uploadedAt ?? DateTime.utc(2026, 5, 1);
    return ReceiptsCacheCompanion(
      id: Value(id),
      householdId: Value(householdId),
      uploadedBy: const Value('user-1'),
      storagePath: Value('$householdId/$id.jpg'),
      thumbnailPath: Value('$householdId/${id}_thumb.jpg'),
      merchantName: Value(merchantName),
      receiptDate: Value(ts),
      totalAmount: const Value(12500),
      ocrStatus: Value(ocrStatus),
      ocrRawJson: Value(ocrRawJson),
      uploadedAt: Value(ts),
      cachedAt: Value(DateTime.utc(2026, 5, 28, 12)),
    );
  }

  ReceiptLineItemsCacheCompanion sampleLineItem({
    required String id,
    required String receiptId,
    String description = 'Bananas',
    int amount = 199,
    int sortOrder = 0,
    bool isTax = false,
    bool isTip = false,
    bool isDiscount = false,
    int? ocrConfidenceBp,
  }) {
    return ReceiptLineItemsCacheCompanion(
      id: Value(id),
      receiptId: Value(receiptId),
      description: Value(description),
      amount: Value(amount),
      quantity: const Value(null),
      unitPrice: const Value(null),
      categoryId: const Value(null),
      isTax: Value(isTax),
      isTip: Value(isTip),
      isDiscount: Value(isDiscount),
      sortOrder: Value(sortOrder),
      ocrConfidenceBp: Value(ocrConfidenceBp),
      cachedAt: Value(DateTime.utc(2026, 5, 28, 12)),
    );
  }

  group('AppDatabase.replaceReceiptsForHousehold', () {
    test('purges prior receipts for the household before inserting', () async {
      await db.upsertReceipt(sampleReceipt(id: 'r-old-1'));
      await db.upsertReceipt(sampleReceipt(id: 'r-old-2'));
      await db.replaceReceiptsForHousehold('hh-1', [
        sampleReceipt(id: 'r-new'),
      ]);
      final rows = await db.loadReceiptsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['r-new']);
    });

    test('leaves other households untouched', () async {
      await db.upsertReceipt(sampleReceipt(id: 'r-hh1', householdId: 'hh-1'));
      await db.upsertReceipt(sampleReceipt(id: 'r-hh2', householdId: 'hh-2'));
      await db.replaceReceiptsForHousehold('hh-1', [
        sampleReceipt(id: 'r-fresh-hh1', householdId: 'hh-1'),
      ]);
      final hh2 = await db.loadReceiptsForHousehold('hh-2');
      expect(hh2.map((r) => r.id), ['r-hh2']);
    });
  });

  group('AppDatabase receipts surface', () {
    test('upsertReceipt round-trips a single row', () async {
      await db.upsertReceipt(sampleReceipt(
        id: 'r-1',
        ocrRawJson: '{"raw":"text"}',
      ));
      final row = await db.loadReceiptById('r-1');
      expect(row, isNotNull);
      expect(row!.id, 'r-1');
      expect(row.merchantName, 'Whole Foods');
      expect(row.ocrRawJson, '{"raw":"text"}');
    });

    test('upsertReceipt replaces on id conflict', () async {
      await db.upsertReceipt(
        sampleReceipt(id: 'r-1', merchantName: 'Original'),
      );
      await db.upsertReceipt(
        sampleReceipt(id: 'r-1', merchantName: 'Renamed'),
      );
      final row = await db.loadReceiptById('r-1');
      expect(row?.merchantName, 'Renamed');
    });

    test('loadReceiptById returns null for an unknown id', () async {
      final row = await db.loadReceiptById('does-not-exist');
      expect(row, isNull);
    });

    test('deleteReceipt removes the row', () async {
      await db.upsertReceipt(sampleReceipt(id: 'r-1'));
      await db.upsertReceipt(sampleReceipt(id: 'r-2'));
      await db.deleteReceipt('r-1');
      final rows = await db.loadReceiptsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['r-2']);
    });

    test('loadReceiptsForHousehold sorts uploaded_at DESC', () async {
      await db.upsertReceipt(
        sampleReceipt(id: 'r-early', uploadedAt: DateTime.utc(2026, 1, 1)),
      );
      await db.upsertReceipt(
        sampleReceipt(id: 'r-late', uploadedAt: DateTime.utc(2026, 5, 1)),
      );
      await db.upsertReceipt(
        sampleReceipt(id: 'r-mid', uploadedAt: DateTime.utc(2026, 3, 1)),
      );
      final rows = await db.loadReceiptsForHousehold('hh-1');
      expect(rows.map((r) => r.id), ['r-late', 'r-mid', 'r-early']);
    });
  });

  group('AppDatabase.replaceLineItemsForReceipt', () {
    test('purges prior line items for the receipt before inserting', () async {
      await db.upsertLineItem(
        sampleLineItem(id: 'li-old-1', receiptId: 'r-1'),
      );
      await db.upsertLineItem(
        sampleLineItem(id: 'li-old-2', receiptId: 'r-1'),
      );
      await db.replaceLineItemsForReceipt('r-1', [
        sampleLineItem(id: 'li-new', receiptId: 'r-1'),
      ]);
      final rows = await db.loadLineItemsForReceipt('r-1');
      expect(rows.map((r) => r.id), ['li-new']);
    });

    test('leaves line items for other receipts untouched', () async {
      await db.upsertLineItem(
        sampleLineItem(id: 'li-r1', receiptId: 'r-1'),
      );
      await db.upsertLineItem(
        sampleLineItem(id: 'li-r2', receiptId: 'r-2'),
      );
      await db.replaceLineItemsForReceipt('r-1', [
        sampleLineItem(id: 'li-fresh', receiptId: 'r-1'),
      ]);
      final r2 = await db.loadLineItemsForReceipt('r-2');
      expect(r2.map((r) => r.id), ['li-r2']);
    });

    test('empty replacement leaves the receipt with no line items', () async {
      await db.upsertLineItem(
        sampleLineItem(id: 'li-1', receiptId: 'r-1'),
      );
      await db.replaceLineItemsForReceipt('r-1', const []);
      final rows = await db.loadLineItemsForReceipt('r-1');
      expect(rows, isEmpty);
    });
  });

  group('AppDatabase.loadLineItemsForReceipt', () {
    test('sorts by sort_order ASC (matches server contract)', () async {
      await db.upsertLineItem(
        sampleLineItem(id: 'li-c', receiptId: 'r-1', sortOrder: 2),
      );
      await db.upsertLineItem(
        sampleLineItem(id: 'li-a', receiptId: 'r-1', sortOrder: 0),
      );
      await db.upsertLineItem(
        sampleLineItem(id: 'li-b', receiptId: 'r-1', sortOrder: 1),
      );
      final rows = await db.loadLineItemsForReceipt('r-1');
      expect(rows.map((r) => r.id), ['li-a', 'li-b', 'li-c']);
    });

    test('returns empty list for a receipt with no items', () async {
      final rows = await db.loadLineItemsForReceipt('r-empty');
      expect(rows, isEmpty);
    });

    test('preserves the special-line flags (tax/tip/discount)', () async {
      await db.upsertLineItem(
        sampleLineItem(id: 'li-tax', receiptId: 'r-1', isTax: true),
      );
      await db.upsertLineItem(
        sampleLineItem(id: 'li-tip', receiptId: 'r-1', isTip: true),
      );
      await db.upsertLineItem(
        sampleLineItem(id: 'li-disc', receiptId: 'r-1', isDiscount: true),
      );
      final rows = await db.loadLineItemsForReceipt('r-1');
      final byId = {for (final r in rows) r.id: r};
      expect(byId['li-tax']!.isTax, true);
      expect(byId['li-tip']!.isTip, true);
      expect(byId['li-disc']!.isDiscount, true);
    });

    test('preserves ocrConfidenceBp when present, null otherwise', () async {
      await db.upsertLineItem(
        sampleLineItem(
          id: 'li-ocr',
          receiptId: 'r-1',
          ocrConfidenceBp: 4200,
        ),
      );
      await db.upsertLineItem(
        sampleLineItem(id: 'li-manual', receiptId: 'r-1'),
      );
      final rows = await db.loadLineItemsForReceipt('r-1');
      final byId = {for (final r in rows) r.id: r};
      expect(byId['li-ocr']!.ocrConfidenceBp, 4200);
      expect(byId['li-manual']!.ocrConfidenceBp, isNull);
    });
  });
}
