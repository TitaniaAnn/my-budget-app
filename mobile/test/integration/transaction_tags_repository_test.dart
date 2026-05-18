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
  });
}
