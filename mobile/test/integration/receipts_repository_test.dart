// Integration tests for ReceiptsRepository methods. Currently focuses
// on `findMatchCandidates`, which is the riskiest of the receipt
// methods — it goes through a SQL function with non-trivial scoring
// logic and exact filter semantics that mocks can't verify.
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY env
// vars aren't set. See _supabase_harness.dart for the setup.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/receipts/repositories/receipts_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('ReceiptsRepository (integration)', () {
    late Harness harness;
    late ReceiptsRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'receipts-repo');
      repo = ReceiptsRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    // ── findMatchCandidates ──────────────────────────────────────────────
    //
    // The RPC returns transactions in the same household, within
    // ±p_date_window_days of the receipt's date, whose |amount| is
    // within p_amount_tolerance_pct of the receipt's total (with a
    // $1 floor on tolerance). Already-paired transactions are excluded.
    // Score is the sum of two halves: date proximity + amount proximity.

    group('findMatchCandidates', () {
      // Inserts a receipt directly into the table (no storage upload)
      // because the RPC only reads receipt_date / total_amount /
      // household_id — the file bytes are irrelevant.
      Future<String> insertReceipt({
        DateTime? receiptDate,
        int? totalAmountCents,
      }) async {
        final row = await harness.client
            .from('receipts')
            .insert({
              'household_id': harness.householdId,
              'uploaded_by': harness.userId,
              // Path is NOT NULL but no file is uploaded — the RPC
              // never dereferences this string.
              'storage_path':
                  '${harness.householdId}/test-${DateTime.now().microsecondsSinceEpoch}.jpg',
              'receipt_date': receiptDate?.toIso8601String().substring(0, 10),
              'total_amount': totalAmountCents,
              'ocr_status': 'pending',
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      test('exact-date-and-amount transaction scores at the top, '
          'date-shifted scores lower, out-of-window is excluded', () async {
        final anchor = DateTime.utc(2026, 5, 10);
        final receiptId = await insertReceipt(
          receiptDate: anchor,
          totalAmountCents: 1234,
        );

        final exactId = await harness.insertTransaction(
          description: 'EXACT',
          amountCents: -1234,
          transactionDate: anchor,
        );
        final oneDayOffId = await harness.insertTransaction(
          description: 'ONE DAY OFF',
          amountCents: -1234,
          transactionDate: anchor.add(const Duration(days: 1)),
        );
        // Outside the default ±3-day window — should be excluded.
        final farId = await harness.insertTransaction(
          description: 'FAR',
          amountCents: -1234,
          transactionDate: anchor.add(const Duration(days: 10)),
        );

        final candidates = await repo.findMatchCandidates(receiptId);
        final ids = candidates.map((c) => c.transactionId).toList();
        expect(ids.contains(exactId), isTrue);
        expect(ids.contains(oneDayOffId), isTrue);
        expect(
          ids.contains(farId),
          isFalse,
          reason:
              'transaction outside ±3-day window must NOT appear in '
              'candidates.',
        );
        // Exact match should rank ahead of one-day-off.
        final exactScore = candidates
            .firstWhere((c) => c.transactionId == exactId)
            .score;
        final shiftedScore = candidates
            .firstWhere((c) => c.transactionId == oneDayOffId)
            .score;
        expect(exactScore, greaterThan(shiftedScore));
        // Exact date + exact amount = 1.0 (0.5 + 0.5 halves).
        expect(exactScore, closeTo(1.0, 1e-9));
      }, skip: reason);

      test('amount outside tolerance is excluded', () async {
        final anchor = DateTime.utc(2026, 5, 10);
        // $50 receipt — 5% tolerance ⇒ ±$2.50 (250 cents). With the $1
        // floor that effectively gives a $2.50 window. A $60 charge
        // ($10 off) is well outside.
        final receiptId = await insertReceipt(
          receiptDate: anchor,
          totalAmountCents: 5000,
        );

        final inToleranceId = await harness.insertTransaction(
          description: 'IN TOLERANCE',
          amountCents: -5050, // $50.50, within 5% + $1 floor
          transactionDate: anchor,
        );
        final outOfToleranceId = await harness.insertTransaction(
          description: 'OUT OF TOLERANCE',
          amountCents: -6000, // $60, way out
          transactionDate: anchor,
        );

        final candidates = await repo.findMatchCandidates(receiptId);
        final ids = candidates.map((c) => c.transactionId).toSet();
        expect(ids.contains(inToleranceId), isTrue);
        expect(
          ids.contains(outOfToleranceId),
          isFalse,
          reason:
              'transaction outside the 5% (or \$1 floor) amount '
              'tolerance must be excluded.',
        );
      }, skip: reason);

      test('already-paired transactions are excluded', () async {
        final anchor = DateTime.utc(2026, 5, 10);
        final receiptId = await insertReceipt(
          receiptDate: anchor,
          totalAmountCents: 1234,
        );
        final otherReceiptId = await insertReceipt(
          receiptDate: anchor,
          totalAmountCents: 1234,
        );

        // Pre-pair this transaction to a DIFFERENT receipt.
        final pairedId = await harness.insertTransaction(
          description: 'ALREADY PAIRED',
          amountCents: -1234,
          transactionDate: anchor,
        );
        await harness.client
            .from('transactions')
            .update({'receipt_id': otherReceiptId})
            .eq('id', pairedId);

        final candidates = await repo.findMatchCandidates(receiptId);
        expect(
          candidates.any((c) => c.transactionId == pairedId),
          isFalse,
          reason:
              'transactions already paired to another receipt must NOT '
              'appear as candidates — pairing should never silently '
              'break an existing link.',
        );
      }, skip: reason);

      test('receipt with no total still matches by date', () async {
        // Pre-OCR: receipt has no total_amount yet. RPC should fall
        // back to date-only ranking and still return candidates.
        final anchor = DateTime.utc(2026, 5, 10);
        final receiptId = await insertReceipt(
          receiptDate: anchor,
          // total_amount intentionally omitted (null).
        );
        final txId = await harness.insertTransaction(
          description: 'PRE-OCR CANDIDATE',
          amountCents: -9999,
          transactionDate: anchor,
        );
        final candidates = await repo.findMatchCandidates(receiptId);
        expect(
          candidates.any((c) => c.transactionId == txId),
          isTrue,
          reason:
              'pre-OCR receipts (no total_amount) should still surface '
              'date-aligned candidates so the user can pair early.',
        );
      }, skip: reason);
    });
  });
}
