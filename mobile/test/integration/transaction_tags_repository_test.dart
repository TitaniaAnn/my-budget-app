// Integration tests for TransactionTagsRepository.
//
// Pins the contract the picker UI relies on:
//   * a household's tag dictionary is alphabetically sorted
//   * UNIQUE (household_id, name) is enforced
//   * deleting a tag cascades through assignments without leaving
//     dangling join rows that would crash a later fetch
//   * replaceAssignments is "set equality" — not append
//
// Skipped when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY env
// vars aren't set.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/repositories/transaction_tags_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('TransactionTagsRepository (integration)', () {
    late Harness harness;
    late TransactionTagsRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'tag-repo');
      repo = TransactionTagsRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    // Stamp per test so tag names don't collide across the suite —
    // UNIQUE (household_id, name) would otherwise reject reruns.
    String stamped(String base) =>
        '$base-${DateTime.now().microsecondsSinceEpoch}';

    // ─── fetchTags / createTag ─────────────────────────────────────────

    test('createTag inserts and fetchTags returns alphabetically', () async {
      // Insert deliberately out of order.
      await repo.createTag(
        householdId: harness.householdId,
        name: stamped('z'),
      );
      await repo.createTag(
        householdId: harness.householdId,
        name: stamped('a'),
      );
      await repo.createTag(
        householdId: harness.householdId,
        name: stamped('m'),
      );

      final result = await repo.fetchTags(harness.householdId);
      // Other tests in this group may add their own; assert relative
      // order among the rows we just inserted.
      final names = result.map((t) => t.name).toList();
      final aIdx = names.indexWhere((n) => n.startsWith('a-'));
      final mIdx = names.indexWhere((n) => n.startsWith('m-'));
      final zIdx = names.indexWhere((n) => n.startsWith('z-'));
      expect(
        aIdx < mIdx && mIdx < zIdx,
        isTrue,
        reason:
            'fetchTags must order by name ASC. '
            'Found order: a=$aIdx m=$mIdx z=$zIdx in $names.',
      );
    }, skip: reason);

    test('createTag trims whitespace before insert', () async {
      // Sanity-check the "phantom dup" guard from the repo: the
      // trimmed name is what hits UNIQUE (household_id, name).
      final tag = await repo.createTag(
        householdId: harness.householdId,
        name: '  ${stamped('trim')}  ',
      );
      expect(
        tag.name.startsWith(' '),
        isFalse,
        reason:
            'createTag must trim — otherwise UNIQUE would let two '
            'visibly-identical names coexist.',
      );
      expect(tag.name.endsWith(' '), isFalse);
    }, skip: reason);

    // ─── replaceAssignments ────────────────────────────────────────────

    test('replaceAssignments is set semantics, not append', () async {
      final tagA = await repo.createTag(
        householdId: harness.householdId,
        name: stamped('set-a'),
      );
      final tagB = await repo.createTag(
        householdId: harness.householdId,
        name: stamped('set-b'),
      );
      final tagC = await repo.createTag(
        householdId: harness.householdId,
        name: stamped('set-c'),
      );

      final txId = await harness.insertTransaction(description: 'WITH TAGS');

      // First assign A + B.
      await repo.replaceAssignments(
        transactionId: txId,
        tagIds: [tagA.id, tagB.id],
      );
      expect((await repo.fetchAssignedTagIds(txId)).toSet(), {
        tagA.id,
        tagB.id,
      });

      // Now replace with C only — A and B must drop, not stack.
      await repo.replaceAssignments(transactionId: txId, tagIds: [tagC.id]);
      expect(
        (await repo.fetchAssignedTagIds(txId)).toSet(),
        {tagC.id},
        reason:
            'replaceAssignments must replace, not append — the picker '
            'relies on this to remove tags the user de-selected.',
      );

      // Empty list clears.
      await repo.replaceAssignments(transactionId: txId, tagIds: []);
      expect(await repo.fetchAssignedTagIds(txId), isEmpty);
    }, skip: reason);

    // ─── updateTag ────────────────────────────────────────────────────

    test('updateTag renames in place', () async {
      final original = await repo.createTag(
        householdId: harness.householdId,
        name: stamped('original'),
      );
      final newName = stamped('renamed');
      final updated = await repo.updateTag(tagId: original.id, name: newName);
      expect(updated.id, original.id, reason: 'id must not change on rename.');
      expect(updated.name, newName);
    }, skip: reason);

    test('updateTag trims whitespace from name', () async {
      // Same "phantom dup" guard as createTag — trailing whitespace
      // would let two tags coexist that look identical to the user.
      final tag = await repo.createTag(
        householdId: harness.householdId,
        name: stamped('untrimmed'),
      );
      final newName = stamped('trim-target');
      final updated = await repo.updateTag(tagId: tag.id, name: '  $newName  ');
      expect(updated.name.startsWith(' '), isFalse);
      expect(updated.name.endsWith(' '), isFalse);
      expect(updated.name, newName);
    }, skip: reason);

    test('updateTag with name-only patch leaves color alone', () async {
      // Null fields in the patch mean "leave alone" — verifies the
      // method doesn't accidentally clear unspecified columns.
      final tag = await repo.createTag(
        householdId: harness.householdId,
        name: stamped('keep-color'),
        color: '#3B82F6',
      );
      final updated = await repo.updateTag(
        tagId: tag.id,
        name: stamped('keep-color-renamed'),
      );
      expect(updated.color, '#3B82F6');
    }, skip: reason);

    // ─── tagUsageCounts ───────────────────────────────────────────────

    test('tagUsageCounts returns both tx and line-item counts per tag, '
        'omits tags with no assignments', () async {
      // Fresh tag with no usage → must NOT appear in the map.
      final unused = await repo.createTag(
        householdId: harness.householdId,
        name: stamped('unused'),
      );

      // Tagged transactions: assign tagA to two transactions.
      final tagA = await repo.createTag(
        householdId: harness.householdId,
        name: stamped('usage-a'),
      );
      final tx1 = await harness.insertTransaction(description: 'USAGE 1');
      final tx2 = await harness.insertTransaction(description: 'USAGE 2');
      await repo.replaceAssignments(transactionId: tx1, tagIds: [tagA.id]);
      await repo.replaceAssignments(transactionId: tx2, tagIds: [tagA.id]);

      // Tagged line item: tagA on one line item.
      final receiptRow = await harness.client
          .from('receipts')
          .insert({
            'household_id': harness.householdId,
            'uploaded_by': harness.userId,
            'storage_path':
                '${harness.householdId}/usage-${DateTime.now().microsecondsSinceEpoch}.jpg',
            'ocr_status': 'pending',
          })
          .select('id')
          .single();
      final receiptId = receiptRow['id'] as String;
      final liRow = await harness.client
          .from('receipt_line_items')
          .insert({
            'receipt_id': receiptId,
            'description': 'usage-li',
            'amount': 100,
            'is_tax': false,
            'is_tip': false,
            'is_discount': false,
            'sort_order': 0,
          })
          .select('id')
          .single();
      await repo.replaceLineItemAssignments(
        lineItemId: liRow['id'] as String,
        tagIds: [tagA.id],
      );

      final counts = await repo.tagUsageCounts();
      expect(
        counts.containsKey(unused.id),
        isFalse,
        reason:
            'tags with zero assignments must NOT appear in the map — '
            'callers treat absent keys as (0, 0), and surfacing them '
            'would clutter the "currently unused" view.',
      );
      expect(counts[tagA.id]?.txCount, 2);
      expect(counts[tagA.id]?.lineItemCount, 1);
    }, skip: reason);

    // ─── deleteTag cascade ────────────────────────────────────────────

    test('deleteTag cascades to assignments', () async {
      // Verifies migration 020's ON DELETE CASCADE: deleting a tag
      // must remove its join rows, otherwise fetchAssignedTagIds for
      // an old transaction would return ids that don't resolve
      // against the dictionary and the chip row would render blanks.
      final tag = await repo.createTag(
        householdId: harness.householdId,
        name: stamped('to-delete'),
      );
      final txId = await harness.insertTransaction(description: 'TAGGED');
      await repo.replaceAssignments(transactionId: txId, tagIds: [tag.id]);
      expect(await repo.fetchAssignedTagIds(txId), contains(tag.id));

      await repo.deleteTag(tag.id);
      expect(
        await repo.fetchAssignedTagIds(txId),
        isNot(contains(tag.id)),
        reason:
            'ON DELETE CASCADE from migration 020 must propagate — '
            'a deleted tag must not survive as a dangling assignment.',
      );
    }, skip: reason);

    // ── line-item tag assignments ───────────────────────────────────────
    //
    // Mirrors the transaction-side picker contract for line items.
    // The bulk fetch is what the line-items editor uses to seed
    // each row's chips on load, so it gets its own test.

    group('line-item tag assignments', () {
      // Helper: insert a receipt directly, then a line item under it.
      // Tag assignments need a real line_item_id to reference.
      Future<String> insertReceipt() async {
        final row = await harness.client
            .from('receipts')
            .insert({
              'household_id': harness.householdId,
              'uploaded_by': harness.userId,
              'storage_path':
                  '${harness.householdId}/li-${DateTime.now().microsecondsSinceEpoch}.jpg',
              'ocr_status': 'pending',
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      Future<String> insertLineItem(
        String receiptId, {
        int sortOrder = 0,
      }) async {
        final row = await harness.client
            .from('receipt_line_items')
            .insert({
              'receipt_id': receiptId,
              'description': 'test item',
              'amount': 100,
              'is_tax': false,
              'is_tip': false,
              'is_discount': false,
              'sort_order': sortOrder,
            })
            .select('id')
            .single();
        return row['id'] as String;
      }

      test(
        'replaceLineItemAssignments is set semantics, same as the tx side',
        () async {
          final tagA = await repo.createTag(
            householdId: harness.householdId,
            name: 'li-a-${DateTime.now().microsecondsSinceEpoch}',
          );
          final tagB = await repo.createTag(
            householdId: harness.householdId,
            name: 'li-b-${DateTime.now().microsecondsSinceEpoch}',
          );
          final receiptId = await insertReceipt();
          final liId = await insertLineItem(receiptId);

          // Assign both, then replace with one, then empty.
          await repo.replaceLineItemAssignments(
            lineItemId: liId,
            tagIds: [tagA.id, tagB.id],
          );
          expect((await repo.fetchAssignedTagIdsForLineItem(liId)).toSet(), {
            tagA.id,
            tagB.id,
          });

          await repo.replaceLineItemAssignments(
            lineItemId: liId,
            tagIds: [tagA.id],
          );
          expect(
            (await repo.fetchAssignedTagIdsForLineItem(liId)).toSet(),
            {tagA.id},
            reason:
                'replaceLineItemAssignments must replace, not append — '
                'the editor relies on this to drop tags the user de-'
                'selected.',
          );

          await repo.replaceLineItemAssignments(
            lineItemId: liId,
            tagIds: const [],
          );
          expect(await repo.fetchAssignedTagIdsForLineItem(liId), isEmpty);
        },
        skip: reason,
      );

      test(
        'fetchAllLineItemAssignmentsForReceipt indexes by line_item_id',
        () async {
          final tag = await repo.createTag(
            householdId: harness.householdId,
            name: 'li-bulk-${DateTime.now().microsecondsSinceEpoch}',
          );
          final receiptId = await insertReceipt();
          final liA = await insertLineItem(receiptId, sortOrder: 0);
          final liB = await insertLineItem(receiptId, sortOrder: 1);
          // Tag only liA; liB has no assignments and must NOT appear
          // in the map.
          await repo.replaceLineItemAssignments(
            lineItemId: liA,
            tagIds: [tag.id],
          );

          final result = await repo.fetchAllLineItemAssignmentsForReceipt(
            receiptId,
          );
          expect(result.keys, contains(liA));
          expect(result[liA], contains(tag.id));
          expect(
            result.containsKey(liB),
            isFalse,
            reason:
                'line items with no assignments must not appear as empty '
                'keys — the editor treats absence as empty.',
          );
        },
        skip: reason,
      );

      test('fetchAllLineItemAssignmentsForReceipt is empty for an '
          'untagged receipt', () async {
        final receiptId = await insertReceipt();
        await insertLineItem(receiptId);
        final result = await repo.fetchAllLineItemAssignmentsForReceipt(
          receiptId,
        );
        expect(result, isEmpty);
      }, skip: reason);

      test('assignments survive a save_receipt_line_items UPDATE — '
          'migration 028 contract', () async {
        // Verifies the full flow the line-items editor depends on:
        // saving a line item via the upsert RPC (migration 028)
        // preserves its id, so tag assignments pointing at it stay
        // valid. If the RPC ever reverts to delete-and-reinsert
        // this test fails immediately.
        final tag = await repo.createTag(
          householdId: harness.householdId,
          name: 'survive-${DateTime.now().microsecondsSinceEpoch}',
        );
        final receiptId = await insertReceipt();
        final liId = await insertLineItem(receiptId);
        await repo.replaceLineItemAssignments(
          lineItemId: liId,
          tagIds: [tag.id],
        );

        // Re-save the same line item via the RPC, passing its id.
        // Tag assignments must still be there afterward.
        await harness.client.rpc(
          'save_receipt_line_items',
          params: {
            'p_receipt_id': receiptId,
            'p_items': [
              {
                'id': liId,
                'description': 'edited',
                'amount': 200,
                'is_tax': false,
                'is_tip': false,
                'is_discount': false,
              },
            ],
          },
        );

        expect(
          (await repo.fetchAssignedTagIdsForLineItem(liId)).toSet(),
          {tag.id},
          reason:
              'a re-save via save_receipt_line_items (migration 028) '
              'must preserve the line item id, so tag assignments '
              'with that FK survive. Reverting to migration 018\'s '
              'delete-and-reinsert behaviour fails this test.',
        );
      }, skip: reason);
    });
  });
}
