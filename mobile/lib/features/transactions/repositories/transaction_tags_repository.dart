// Data access layer for the tag dictionary and tag assignments.
//
// Three row shapes the repo cares about:
//   * the dictionary (transaction_tags): one row per (household, name)
//   * transaction_tag_assignments: one row per (transaction, tag)
//   * receipt_line_item_tag_assignments: one row per (line_item, tag)
//
// The two assignment tables share the same dictionary — a tag named
// "contractor" applies to both surfaces. The line-item assignments
// rely on migration 028's id-preserving save_receipt_line_items;
// the original migration 018 would cascade-delete them on every
// receipt edit, making line-item tags useless.
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

  /// Returns assignment counts per tag, keyed by tag_id. Each value
  /// is `(txCount, lineItemCount)` — how many transactions carry
  /// the tag and how many receipt line items, respectively. Used by
  /// the manage-tags screen to surface usage and warn before
  /// destructive actions.
  ///
  /// Implemented as two flat fetches (no GROUP BY in PostgREST's
  /// select grammar) with aggregation in Dart. Cheap at household
  /// scale — the assignment tables typically hold low hundreds of
  /// rows even for active households. If usage grows past that
  /// threshold this should move into an RPC.
  ///
  /// RLS on both join tables scopes the visible rows to the
  /// caller's household, so no household_id parameter is needed.
  Future<Map<String, ({int txCount, int lineItemCount})>>
  tagUsageCounts() async {
    final txRows = await supabase
        .from('transaction_tag_assignments')
        .select('tag_id');
    final liRows = await supabase
        .from('receipt_line_item_tag_assignments')
        .select('tag_id');

    final tx = <String, int>{};
    for (final row in txRows) {
      final tagId = row['tag_id'] as String;
      tx[tagId] = (tx[tagId] ?? 0) + 1;
    }
    final li = <String, int>{};
    for (final row in liRows) {
      final tagId = row['tag_id'] as String;
      li[tagId] = (li[tagId] ?? 0) + 1;
    }

    final keys = {...tx.keys, ...li.keys};
    return {
      for (final id in keys)
        id: (txCount: tx[id] ?? 0, lineItemCount: li[id] ?? 0),
    };
  }

  /// Renames a tag and/or recolors it. Either field is optional —
  /// null means "leave alone." Name is trimmed for the same
  /// "phantom dup" reason [createTag] is.
  ///
  /// Returns the updated row. The unique constraint on
  /// `(household_id, name)` lives at the schema level; a rename
  /// collision surfaces as a Postgres error the caller catches.
  Future<TransactionTag> updateTag({
    required String tagId,
    String? name,
    String? color,
  }) async {
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name.trim();
    if (color != null) patch['color'] = color;

    final data = await supabase
        .from('transaction_tags')
        .update(patch)
        .eq('id', tagId)
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

  /// Returns every (transaction_id, tag_id) pair the caller can see,
  /// indexed by transaction_id. Used by the transactions list to
  /// render tag chips inline without N+1 fetches per row.
  ///
  /// Returns a map (not a list) because the call site needs O(1)
  /// lookup per transaction row. Empty inner sets are omitted: the
  /// caller treats an absent key the same as "no tags".
  ///
  /// RLS scopes through the assignment table's "transaction_id IN
  /// (SELECT id FROM transactions)" policy from migration 020, so
  /// only assignments for transactions in the caller's household
  /// come back. No householdId parameter — the policy is the
  /// authority.
  Future<Map<String, Set<String>>> fetchAllAssignments() async {
    final data = await supabase
        .from('transaction_tag_assignments')
        .select('transaction_id, tag_id');
    final result = <String, Set<String>>{};
    for (final row in data) {
      final txId = row['transaction_id'] as String;
      final tagId = row['tag_id'] as String;
      (result[txId] ??= <String>{}).add(tagId);
    }
    return result;
  }

  /// Returns the ids of every transaction in the household that
  /// carries the given [tagId]. Used to filter the transactions list
  /// by tag — the caller follows up with an `inFilter('id', …)`
  /// on the transactions query. Done in two trips rather than a SQL
  /// join because the assignment table is tiny and PostgREST's
  /// embed-with-filter ergonomics aren't worth the complexity here.
  Future<List<String>> fetchTransactionIdsForTag(String tagId) async {
    final data = await supabase
        .from('transaction_tag_assignments')
        .select('transaction_id')
        .eq('tag_id', tagId);
    return data.map<String>((row) => row['transaction_id'] as String).toList();
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

  /// Returns the ids of tags assigned to [lineItemId]. Mirrors
  /// [fetchAssignedTagIds] for the line-item side; the picker on
  /// the line-items editor uses the bulk method below in practice,
  /// but this exists for completeness and for any future
  /// per-row consumer.
  Future<List<String>> fetchAssignedTagIdsForLineItem(String lineItemId) async {
    final data = await supabase
        .from('receipt_line_item_tag_assignments')
        .select('tag_id')
        .eq('line_item_id', lineItemId);
    return data.map<String>((row) => row['tag_id'] as String).toList();
  }

  /// Bulk-fetches every tag assignment for line items belonging to
  /// [receiptId], indexed by line_item_id. Used by the line-items
  /// editor to render existing tags on every row without N+1
  /// fetches.
  ///
  /// Two-step under the hood: first fetch the receipt's line item
  /// ids, then their tag assignments via inFilter. Postgrest doesn't
  /// support the "join through" filter that would let this be a
  /// single trip without an RPC, and the cost of the extra hop is
  /// trivial — line items per receipt is in the single digits.
  Future<Map<String, Set<String>>> fetchAllLineItemAssignmentsForReceipt(
    String receiptId,
  ) async {
    final lineItemRows = await supabase
        .from('receipt_line_items')
        .select('id')
        .eq('receipt_id', receiptId);
    final ids = lineItemRows.map<String>((r) => r['id'] as String).toList();
    if (ids.isEmpty) return const {};

    final assignments = await supabase
        .from('receipt_line_item_tag_assignments')
        .select('line_item_id, tag_id')
        .inFilter('line_item_id', ids);
    final result = <String, Set<String>>{};
    for (final row in assignments) {
      final liId = row['line_item_id'] as String;
      final tagId = row['tag_id'] as String;
      (result[liId] ??= <String>{}).add(tagId);
    }
    return result;
  }

  /// Replaces the tag assignments on [lineItemId] with exactly
  /// [tagIds]. Same delete-then-insert shape as the transaction-side
  /// method, with the same caveat: not atomic across the two
  /// writes. Acceptable trade-off for v1 — the line items editor
  /// already batches one assignment-write per row, so an N-line
  /// receipt does at most N such operations on save.
  Future<void> replaceLineItemAssignments({
    required String lineItemId,
    required List<String> tagIds,
  }) async {
    await supabase
        .from('receipt_line_item_tag_assignments')
        .delete()
        .eq('line_item_id', lineItemId);

    if (tagIds.isEmpty) return;

    await supabase
        .from('receipt_line_item_tag_assignments')
        .insert(
          tagIds
              .map((id) => {'line_item_id': lineItemId, 'tag_id': id})
              .toList(),
        );
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

  /// Adds [tagId] to every transaction in [transactionIds] in a
  /// single round-trip. Existing assignments are preserved — already-
  /// tagged rows are no-ops via ON CONFLICT DO NOTHING on the
  /// composite primary key (transaction_id, tag_id).
  ///
  /// Distinct from [replaceAssignments], which is for the
  /// per-transaction picker where the user authoritatively picks the
  /// full set. Bulk-tag is purely additive.
  Future<void> addTagToMany({
    required String tagId,
    required List<String> transactionIds,
  }) async {
    if (transactionIds.isEmpty) return;
    await supabase
        .from('transaction_tag_assignments')
        .upsert(
          [
            for (final txId in transactionIds)
              {'transaction_id': txId, 'tag_id': tagId},
          ],
          onConflict: 'transaction_id,tag_id',
          ignoreDuplicates: true,
        );
  }

  /// Removes [tagId] from every transaction in [transactionIds] in a
  /// single round-trip. Rows that weren't tagged with [tagId] are
  /// no-ops; other tags on the same transaction are left alone.
  ///
  /// The inverse of [addTagToMany] — kept narrowly scoped to one
  /// tag at a time so the bulk-edit UX matches the bulk-add path
  /// (one selection action targets one tag).
  Future<void> removeTagFromMany({
    required String tagId,
    required List<String> transactionIds,
  }) async {
    if (transactionIds.isEmpty) return;
    await supabase
        .from('transaction_tag_assignments')
        .delete()
        .eq('tag_id', tagId)
        .inFilter('transaction_id', transactionIds);
  }
}
