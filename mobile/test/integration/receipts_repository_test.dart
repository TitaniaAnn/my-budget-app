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

    // ── fetchUnpaired ────────────────────────────────────────────────────
    //
    // Powers the "Attach Receipt" picker on the transaction edit sheet.
    // The SQL function (migration 025) excludes any receipt that at
    // least one transaction is pointing at, then orders by uploaded_at
    // DESC under RLS so the result is scoped to the caller's household.

    group('fetchUnpaired', () {
      Future<String> insertReceipt() async {
        final row = await harness.client
            .from('receipts')
            .insert({
              'household_id': harness.householdId,
              'uploaded_by': harness.userId,
              'storage_path':
                  '${harness.householdId}/test-${DateTime.now().microsecondsSinceEpoch}.jpg',
              'ocr_status': 'pending',
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      test('returns only receipts no transaction points at, '
          'newest upload first', () async {
        final unpairedA = await insertReceipt();
        // Force a small upload-time gap so ordering is deterministic.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final unpairedB = await insertReceipt();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final pairedReceiptId = await insertReceipt();

        // Pair a transaction to pairedReceiptId — that receipt must
        // drop out of the unpaired set.
        final txId = await harness.insertTransaction(description: 'PAIRED TX');
        await harness.client
            .from('transactions')
            .update({'receipt_id': pairedReceiptId})
            .eq('id', txId);

        final result = await repo.fetchUnpaired();
        final ids = result.map((r) => r.id).toList();

        expect(
          ids.contains(pairedReceiptId),
          isFalse,
          reason:
              'a receipt that any transaction is pointing at must NOT '
              'surface as unpaired.',
        );
        expect(ids.contains(unpairedA), isTrue);
        expect(ids.contains(unpairedB), isTrue);

        // Newest-first ordering. Compare via indexOf so unrelated rows
        // from earlier tests in this group don't false-fail.
        final idxA = ids.indexOf(unpairedA);
        final idxB = ids.indexOf(unpairedB);
        expect(
          idxB,
          lessThan(idxA),
          reason:
              'fetchUnpaired must order by uploaded_at DESC — the '
              'later-uploaded receipt should come first.',
        );
      }, skip: reason);

      test('respects the limit parameter', () async {
        await insertReceipt();
        await insertReceipt();
        final result = await repo.fetchUnpaired(limit: 1);
        expect(result.length, lessThanOrEqualTo(1));
      }, skip: reason);

      test(
        'receipt re-enters the pool after its transaction unpairs',
        () async {
          final receiptId = await insertReceipt();
          final txId = await harness.insertTransaction(
            description: 'TEMPORARILY PAIRED',
          );

          // Pair, then verify it's gone from the unpaired set.
          await harness.client
              .from('transactions')
              .update({'receipt_id': receiptId})
              .eq('id', txId);
          var ids = (await repo.fetchUnpaired()).map((r) => r.id).toSet();
          expect(ids.contains(receiptId), isFalse);

          // Unpair, then verify it's back. The NOT EXISTS subquery in
          // migration 025 has no caching — flipping receipt_id back to
          // NULL must be observable immediately.
          await harness.client
              .from('transactions')
              .update({'receipt_id': null})
              .eq('id', txId);
          ids = (await repo.fetchUnpaired()).map((r) => r.id).toSet();
          expect(
            ids.contains(receiptId),
            isTrue,
            reason:
                'unpairing a transaction must return its receipt to the '
                'unpaired pool — the picker would otherwise hide a now-'
                'available receipt.',
          );
        },
        skip: reason,
      );
    });

    // ── fetchLineItems ordering ──────────────────────────────────────────
    //
    // Pins the postgrest `.order()` gotcha: the default is DESC, so
    // an implicit `.order('sort_order')` rendered line items
    // bottom-up. The repo now asks for ASC explicitly; this test
    // catches any regression if someone strips the keyword arg.

    group('fetchLineItems', () {
      test('returns items in sort_order ASC', () async {
        // Insert a receipt, then three line items with explicit
        // sort_order values, in non-monotonic insertion order. The
        // repo's ASC ordering must surface them in 0, 1, 2 sequence
        // regardless of which row went into the table first.
        final receiptRow = await harness.client
            .from('receipts')
            .insert({
              'household_id': harness.householdId,
              'uploaded_by': harness.userId,
              'storage_path':
                  '${harness.householdId}/order-${DateTime.now().microsecondsSinceEpoch}.jpg',
              'ocr_status': 'pending',
            })
            .select('id')
            .single();
        final receiptId = receiptRow['id'] as String;

        Future<void> insertItem(int sortOrder, String desc) async {
          await harness.client.from('receipt_line_items').insert({
            'receipt_id': receiptId,
            'description': desc,
            'amount': 100,
            'is_tax': false,
            'is_tip': false,
            'is_discount': false,
            'sort_order': sortOrder,
          });
        }

        await insertItem(2, 'third');
        await insertItem(0, 'first');
        await insertItem(1, 'second');

        final items = await repo.fetchLineItems(receiptId);
        expect(
          items.map((i) => i.description).toList(),
          ['first', 'second', 'third'],
          reason:
              'fetchLineItems must order by sort_order ASC — postgrest '
              'defaults to DESC, so the `ascending: true` in the repo '
              'is load-bearing.',
        );
      }, skip: reason);
    });

    // ── saveLineItems ID preservation (migration 028) ────────────────────
    //
    // Original save_receipt_line_items (migration 018) did a full
    // DELETE + INSERT, regenerating IDs on every edit. That cascade-
    // deleted any FK pointing at the rows — e.g. the
    // receipt_line_item_tag_assignments table from migration 020.
    // Migration 028 made the RPC upsert-by-id with delete-orphans.
    // These tests pin that behaviour so a future refactor can't
    // silently revert to the destructive shape.

    group('saveLineItems ID preservation', () {
      Future<String> insertReceipt() async {
        final row = await harness.client
            .from('receipts')
            .insert({
              'household_id': harness.householdId,
              'uploaded_by': harness.userId,
              'storage_path':
                  '${harness.householdId}/id-${DateTime.now().microsecondsSinceEpoch}.jpg',
              'ocr_status': 'pending',
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      test(
        'passing an existing id UPDATEs in place — id and FKs survive',
        () async {
          final receiptId = await insertReceipt();
          // Initial save: no ids supplied → fresh UUIDs.
          final first = await repo.saveLineItems(
            receiptId: receiptId,
            items: const [
              {
                'description': 'coffee',
                'amount': 500,
                'is_tax': false,
                'is_tip': false,
                'is_discount': false,
              },
              {
                'description': 'pastry',
                'amount': 350,
                'is_tax': false,
                'is_tip': false,
                'is_discount': false,
              },
            ],
          );
          expect(first, hasLength(2));
          final coffeeId = first
              .firstWhere((i) => i.description == 'coffee')
              .id;
          final pastryId = first
              .firstWhere((i) => i.description == 'pastry')
              .id;

          // Re-save with the same ids but a tweaked amount on coffee.
          // The returned rows should keep their ids — UPDATEd in place.
          final second = await repo.saveLineItems(
            receiptId: receiptId,
            items: [
              {
                'id': coffeeId,
                'description': 'coffee',
                'amount': 600,
                'is_tax': false,
                'is_tip': false,
                'is_discount': false,
              },
              {
                'id': pastryId,
                'description': 'pastry',
                'amount': 350,
                'is_tax': false,
                'is_tip': false,
                'is_discount': false,
              },
            ],
          );
          expect(
            second.firstWhere((i) => i.description == 'coffee').id,
            coffeeId,
            reason:
                'coffee row id must survive the re-save — the upsert is '
                'load-bearing for the line-item tag picker (migration 020 '
                'FKs cascade-delete otherwise).',
          );
          expect(
            second.firstWhere((i) => i.description == 'coffee').amount,
            600,
            reason: 'the UPDATE branch must apply the new amount.',
          );
          expect(
            second.firstWhere((i) => i.description == 'pastry').id,
            pastryId,
            reason: 'untouched row id must also survive.',
          );
        },
        skip: reason,
      );

      test('rows not in the input set are deleted', () async {
        final receiptId = await insertReceipt();
        final initial = await repo.saveLineItems(
          receiptId: receiptId,
          items: const [
            {
              'description': 'keep me',
              'amount': 100,
              'is_tax': false,
              'is_tip': false,
              'is_discount': false,
            },
            {
              'description': 'delete me',
              'amount': 200,
              'is_tax': false,
              'is_tip': false,
              'is_discount': false,
            },
          ],
        );
        final keepId = initial.firstWhere((i) => i.description == 'keep me').id;

        // Save again with only the "keep me" row.
        final after = await repo.saveLineItems(
          receiptId: receiptId,
          items: [
            {
              'id': keepId,
              'description': 'keep me',
              'amount': 100,
              'is_tax': false,
              'is_tip': false,
              'is_discount': false,
            },
          ],
        );
        expect(after, hasLength(1));
        expect(after.single.description, 'keep me');
        expect(after.single.id, keepId);
      }, skip: reason);

      test('empty items input deletes everything for the receipt', () async {
        // Matches the original migration 018 short-circuit. The
        // editor should never pass an empty list when the user
        // wants to keep items, but the RPC supports it for
        // completeness.
        final receiptId = await insertReceipt();
        await repo.saveLineItems(
          receiptId: receiptId,
          items: const [
            {
              'description': 'doomed',
              'amount': 100,
              'is_tax': false,
              'is_tip': false,
              'is_discount': false,
            },
          ],
        );
        await repo.saveLineItems(receiptId: receiptId, items: const []);
        final items = await repo.fetchLineItems(receiptId);
        expect(items, isEmpty);
      }, skip: reason);
    });

    // ── fetchUncertainLineItems + confirmLineItem (migration 034) ──────
    //
    // The OCR review surface filters on ocr_confidence_bp <= threshold.
    // Pinned:
    //   * fetch returns only rows below the threshold, ordered by
    //     confidence ascending (most uncertain first);
    //   * rows with null confidence (manual entries) are excluded;
    //   * confirmLineItem clears the confidence so the same row
    //     doesn't keep resurfacing — and field overrides apply when
    //     provided.

    group('OCR uncertain review (migration 034)', () {
      Future<String> insertReceipt({DateTime? receiptDate}) async {
        final row = await harness.client
            .from('receipts')
            .insert({
              'household_id': harness.householdId,
              'uploaded_by': harness.userId,
              'storage_path':
                  '${harness.householdId}/uncertain-${DateTime.now().microsecondsSinceEpoch}.jpg',
              'ocr_status': 'complete',
              'receipt_date': receiptDate
                  ?.toIso8601String()
                  .substring(0, 10),
              'merchant_name': 'CONFIDENCE TEST CO',
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      Future<String> insertLineItem({
        required String receiptId,
        required String description,
        required int amount,
        int? confidenceBp,
      }) async {
        final row = await harness.client
            .from('receipt_line_items')
            .insert({
              'receipt_id': receiptId,
              'description': description,
              'amount': amount,
              'is_tax': false,
              'is_tip': false,
              'is_discount': false,
              'sort_order': 0,
              'ocr_confidence_bp': confidenceBp,
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      test(
        'fetchUncertainLineItems returns only rows below threshold, '
        'most-uncertain first; null-confidence rows are excluded',
        () async {
          final receiptId = await insertReceipt(
            receiptDate: DateTime.utc(2026, 5, 14),
          );
          // 25% — well below the 55% default threshold.
          final lowId = await insertLineItem(
            receiptId: receiptId,
            description: 'fetch-low',
            amount: 100,
            confidenceBp: 2500,
          );
          // 50% — also below.
          final midId = await insertLineItem(
            receiptId: receiptId,
            description: 'fetch-mid',
            amount: 200,
            confidenceBp: 5000,
          );
          // 75% — above. Must NOT surface.
          await insertLineItem(
            receiptId: receiptId,
            description: 'fetch-high',
            amount: 300,
            confidenceBp: 7500,
          );
          // No confidence — user typed it manually. Must NOT surface.
          await insertLineItem(
            receiptId: receiptId,
            description: 'fetch-manual',
            amount: 400,
            confidenceBp: null,
          );

          final result = await repo.fetchUncertainLineItems(
            householdId: harness.householdId,
          );
          // Filter to the ids we created so sibling tests can't
          // pollute the assertion.
          final ours = result
              .where((u) => [lowId, midId].contains(u.lineItem.id))
              .toList();
          expect(
            ours.map((u) => u.lineItem.id),
            [lowId, midId],
            reason: 'ordered ascending by confidence — the lowest '
                'confidence (most uncertain) row surfaces first.',
          );
          // Receipt context joined in.
          expect(ours.first.merchant, 'CONFIDENCE TEST CO');
          expect(
            ours.first.receiptDate?.toIso8601String().substring(0, 10),
            '2026-05-14',
          );
        },
        skip: reason,
      );

      test(
        'confirmLineItem clears confidence so the row stops surfacing',
        () async {
          final receiptId = await insertReceipt();
          final lineId = await insertLineItem(
            receiptId: receiptId,
            description: 'confirm-clear',
            amount: 999,
            confidenceBp: 3000,
          );

          await repo.confirmLineItem(lineItemId: lineId);

          final all = await repo.fetchUncertainLineItems(
            householdId: harness.householdId,
          );
          expect(
            all.any((u) => u.lineItem.id == lineId),
            isFalse,
            reason: 'the confirm action is the review — once cleared, '
                'the row must not resurface on the next fetch.',
          );
          // Verify the underlying column is actually NULL (and the
          // description / amount survived unchanged because we didn't
          // pass overrides).
          final row = await harness.client
              .from('receipt_line_items')
              .select('description, amount, ocr_confidence_bp')
              .eq('id', lineId)
              .single();
          expect(row['ocr_confidence_bp'], isNull);
          expect(row['description'], 'confirm-clear');
          expect(row['amount'], 999);
        },
        skip: reason,
      );

      test(
        'confirmLineItem applies field overrides when provided',
        () async {
          final groceriesId = await harness.systemCategoryIdByName('Groceries');
          final receiptId = await insertReceipt();
          final lineId = await insertLineItem(
            receiptId: receiptId,
            description: 'misspeled',
            amount: 100,
            confidenceBp: 3000,
          );

          await repo.confirmLineItem(
            lineItemId: lineId,
            description: 'corrected',
            amountCents: 555,
            categoryId: groceriesId,
          );

          final row = await harness.client
              .from('receipt_line_items')
              .select('description, amount, category_id, ocr_confidence_bp')
              .eq('id', lineId)
              .single();
          expect(row['description'], 'corrected');
          expect(row['amount'], 555);
          expect(row['category_id'], groceriesId);
          expect(
            row['ocr_confidence_bp'],
            isNull,
            reason: 'a correction-with-overrides path must STILL clear '
                'confidence — otherwise the row resurfaces and the '
                'user re-corrects forever.',
          );
        },
        skip: reason,
      );
    });

    // ── H5 (migration 047): storage_path household prefix ──────────────
    //
    // The receipts INSERT policy gates only on household_id. The
    // storage DELETE policy authorises by looking up
    // receipts.storage_path = storage.objects.name. Pre-fix this
    // let a member craft a receipts row in THEIR household with
    // another household's storage_path, then delete the victim's
    // image. Migration 047 added a row-level CHECK requiring
    // storage_path (and thumbnail_path when set) to live under the
    // row's own household_id prefix.

    group('storage_path household-prefix constraint', () {
      test(
        'rejects INSERT with storage_path under another household_id',
        () async {
          // Use a UUID that doesn't match the harness household so
          // the prefix check fails. The other-household value
          // doesn't have to exist — the CHECK doesn't look up the
          // referenced storage object; it just validates the path
          // string starts with this row's own household_id.
          const otherHousehold = '00000000-0000-0000-0000-000000000999';

          await expectLater(
            harness.client.from('receipts').insert({
              'household_id': harness.householdId,
              'uploaded_by': harness.userId,
              'storage_path': '$otherHousehold/some-receipt.jpg',
              'ocr_status': 'pending',
            }),
            throwsA(anything),
            reason:
                'CHECK constraint must reject a storage_path whose '
                'prefix is not the row\'s own household_id.',
          );
        },
        skip: reason,
      );

      test(
        'rejects UPDATE that rewrites storage_path to another household',
        () async {
          // The constraint also has to hold for UPDATEs — otherwise
          // a row could be inserted with a valid path, then the
          // attacker UPDATEs it to a foreign one and runs the
          // delete. Pin the same shape via UPDATE.
          final inserted = await harness.client
              .from('receipts')
              .insert({
                'household_id': harness.householdId,
                'uploaded_by': harness.userId,
                'storage_path':
                    '${harness.householdId}/legit-${DateTime.now().microsecondsSinceEpoch}.jpg',
                'ocr_status': 'pending',
              })
              .select('id')
              .single();

          await expectLater(
            harness.client
                .from('receipts')
                .update({
                  'storage_path':
                      '00000000-0000-0000-0000-000000000999/attack.jpg',
                })
                .eq('id', inserted['id']),
            throwsA(anything),
            reason:
                'CHECK fires on UPDATE too; otherwise the attack is '
                'just two steps (insert valid → rewrite to victim).',
          );
        },
        skip: reason,
      );

      test(
        'accepts a storage_path correctly prefixed with the row\'s household',
        () async {
          // Negative-of-the-negative — sanity check the constraint
          // isn't over-broad and reject legitimate inserts. The
          // production upload code builds paths this way; the
          // happy path must keep working.
          final inserted = await harness.client
              .from('receipts')
              .insert({
                'household_id': harness.householdId,
                'uploaded_by': harness.userId,
                'storage_path':
                    '${harness.householdId}/ok-${DateTime.now().microsecondsSinceEpoch}.jpg',
                'ocr_status': 'pending',
              })
              .select('id')
              .single();
          expect(inserted['id'], isNotNull);
        },
        skip: reason,
      );
    });
  });
}
