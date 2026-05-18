// Data access layer for the tag dictionary and tag assignments.
//
// Two row shapes the repo cares about:
//   * the dictionary (transaction_tags): one row per (household, name)
//   * the join table (transaction_tag_assignments): one row per
//     (transaction, tag)
//
// Line-item tag assignments share the dictionary but live in a
// different join table (receipt_line_item_tag_assignments). They're
// not exposed in this repo yet — the v1 picker is on transaction
// rows only.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/transaction_tag.dart';

part 'transaction_tags_repository.g.dart';

@riverpod
TransactionTagsRepository transactionTagsRepository(
  TransactionTagsRepositoryRef ref,
) {
  return TransactionTagsRepository();
}

class TransactionTagsRepository {
  /// Returns every tag in [householdId], alphabetically by name. The
  /// dictionary is small (dozens of rows at most) so we don't bother
  /// paginating.
  ///
  /// RLS scopes to the caller's household; passing the explicit
  /// householdId is belt-and-braces.
  Future<List<TransactionTag>> fetchTags(String householdId) async {
    final data = await supabase
        .from('transaction_tags')
        .select()
        .eq('household_id', householdId)
        // postgrest's .order() defaults to DESCENDING — alphabetical
        // ASC only happens when we say so explicitly. Without this the
        // picker would render Z…A which is jarring on a long tag list.
        .order('name', ascending: true);
    return data.map<TransactionTag>(TransactionTag.fromJson).toList();
  }

  /// Creates a new tag and returns it. Trimmed [name] so a stray
  /// trailing space can't slip past the `UNIQUE (household_id, name)`
  /// guard and create a "phantom dup" the user can't see.
  Future<TransactionTag> createTag({
    required String householdId,
    required String name,
    String? color,
  }) async {
    final data = await supabase
        .from('transaction_tags')
        .insert({
          'household_id': householdId,
          'name': name.trim(),
          'color': color,
        })
        .select()
        .single();
    return TransactionTag.fromJson(data);
  }

  /// Deletes a tag. The schema's `ON DELETE CASCADE` on both
  /// assignment tables means we don't have to clean up assignments
  /// manually — they vanish with the tag row.
  Future<void> deleteTag(String tagId) async {
    await supabase.from('transaction_tags').delete().eq('id', tagId);
  }

  /// Returns the ids of tags currently assigned to [transactionId].
  /// Just ids — callers that need the full row look them up in the
  /// dictionary fetch which is cached separately, so we don't pay
  /// for the join every time.
  Future<List<String>> fetchAssignedTagIds(String transactionId) async {
    final data = await supabase
        .from('transaction_tag_assignments')
        .select('tag_id')
        .eq('transaction_id', transactionId);
    return data.map<String>((row) => row['tag_id'] as String).toList();
  }

  /// Replaces the set of tags assigned to [transactionId] with
  /// exactly [tagIds]. Implemented as a delete-then-insert pair
  /// because the v1 surface is "pick any subset" rather than
  /// "toggle one tag," so a single round-trip per change would mean
  /// per-tap chatter that's both slower and harder to reason about.
  ///
  /// Not atomic across the two writes — if the insert fails after
  /// the delete commits, the transaction is left with no tags. We
  /// accept this for the v1 picker; the next iteration should push
  /// it into a SQL function the same way [save_receipt_line_items]
  /// does (migration 018).
  Future<void> replaceAssignments({
    required String transactionId,
    required List<String> tagIds,
  }) async {
    await supabase
        .from('transaction_tag_assignments')
        .delete()
        .eq('transaction_id', transactionId);

    if (tagIds.isEmpty) return;

    await supabase
        .from('transaction_tag_assignments')
        .insert(
          tagIds
              .map((id) => {'transaction_id': transactionId, 'tag_id': id})
              .toList(),
        );
  }
}
