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
//
// Audit L1 Phase 2d: cache-through on fetchTags, fetchAllAssignments,
// fetchTransactionIdsForTag, fetchAssignedTagIds, and
// fetchAssignedTagIdsForLineItem. Replace-assignment paths mirror to
// the cache; bulk addTagToMany / removeTagFromMany invalidate the
// touched transaction-side assignments (next fetchAllAssignments
// reconciles). tagUsageCounts and the receipt-line-item bulk fetch
// stay network-only — neither is on the hot offline path.
//
// Audit L1 Phase 3c: createTag / updateTag / deleteTag flow through
// the pending_writes queue on transient failure. The two
// replace-assignments paths and the addTagToMany / removeTagFromMany
// bulk paths stay direct-network: their "replace set" semantics
// don't map cleanly onto QueuedInsert/Update/Delete's per-row shape,
// and the assignment tables have no `updated_at` column for H5
// optimistic-lock anyway. Documented gap.
import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/sync/atomic_write.dart';
import '../../../core/sync/pending_writes_queue.dart';
import '../../../core/sync/transient_error.dart';
import '../models/transaction_tag.dart';

part 'transaction_tags_repository.g.dart';

@riverpod
TransactionTagsRepository transactionTagsRepository(
  TransactionTagsRepositoryRef ref,
) {
  return TransactionTagsRepository(
    db: ref.watch(appDatabaseProvider),
    queue: ref.watch(pendingWritesQueueProvider),
  );
}

class TransactionTagsRepository {
  TransactionTagsRepository({AppDatabase? db, PendingWritesQueue? queue})
    : _db = db,
      _queue = queue;
  final AppDatabase? _db;
  final PendingWritesQueue? _queue;
  final _uuid = const Uuid();
  /// Returns every tag in [householdId], alphabetically by name. The
  /// dictionary is small (dozens of rows at most) so we don't bother
  /// paginating.
  ///
  /// RLS scopes to the caller's household; passing the explicit
  /// householdId is belt-and-braces.
  Future<List<TransactionTag>> fetchTags(String householdId) async {
    try {
      final data = await supabase
          .from('transaction_tags')
          .select()
          .eq('household_id', householdId)
          // postgrest's .order() defaults to DESCENDING — alphabetical
          // ASC only happens when we say so explicitly. Without this the
          // picker would render Z…A which is jarring on a long tag list.
          .order('name', ascending: true);
      final tags = data.map<TransactionTag>(TransactionTag.fromJson).toList();
      await _refreshTagsCache(householdId, tags);
      return tags;
    } catch (_) {
      final cached = await _loadTagsFromCache(householdId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Creates a new tag and returns it. Trimmed [name] so a stray
  /// trailing space can't slip past the `UNIQUE (household_id, name)`
  /// guard and create a "phantom dup" the user can't see.
  Future<TransactionTag> createTag({
    required String householdId,
    required String name,
    String? color,
  }) async {
    final clientId = _uuid.v4();
    final trimmedName = name.trim();
    final payload = <String, dynamic>{
      'id': clientId,
      'household_id': householdId,
      'name': trimmedName,
      'color': color,
    };
    try {
      final data = await supabase
          .from('transaction_tags')
          .insert(payload)
          .select()
          .single();
      final tag = TransactionTag.fromJson(data);
      await _writeTagCacheRow(tag);
      return tag;
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      final optimistic = TransactionTag(
        id: clientId,
        householdId: householdId,
        name: trimmedName,
        color: color,
        createdAt: DateTime.now().toUtc(),
      );
      await atomicCacheAndEnqueue(
        db: _db,
        queue: _queue,
        write: () => _writeTagCacheRow(optimistic),
        queueOp: QueuedInsert(
          table: 'transaction_tags',
          payload: payload,
          rowId: clientId,
        ),
      );
      return optimistic;
    }
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

    try {
      final data = await supabase
          .from('transaction_tags')
          .update(patch)
          .eq('id', tagId)
          .select()
          .single();
      final tag = TransactionTag.fromJson(data);
      await _writeTagCacheRow(tag);
      return tag;
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      final existing = await _loadTagCacheRowById(tagId);
      if (existing == null) rethrow;
      final patched = existing.copyWith(
        name: name?.trim() ?? existing.name,
        color: color ?? existing.color,
      );
      await atomicCacheAndEnqueue(
        db: _db,
        queue: _queue,
        write: () => _writeTagCacheRow(patched),
        queueOp: QueuedUpdate(
          table: 'transaction_tags',
          rowId: tagId,
          payload: patch,
        ),
      );
      return patched;
    }
  }

  /// Deletes a tag. The schema's `ON DELETE CASCADE` on both
  /// assignment tables means we don't have to clean up assignments
  /// manually — they vanish with the tag row.
  Future<void> deleteTag(String tagId) async {
    try {
      await supabase.from('transaction_tags').delete().eq('id', tagId);
      await _deleteTagCacheRow(tagId);
      // Server's ON DELETE CASCADE removes assignments too; mirror
      // by clearing every cached assignment for this tag. Done as a
      // separate cache write because the cache has no FK cascade.
      await _deleteAssignmentsForTag(tagId);
    } catch (e) {
      if (!isTransientWriteError(e)) rethrow;
      await atomicCacheAndEnqueue(
        db: _db,
        queue: _queue,
        write: () async {
          await _deleteTagCacheRow(tagId);
          await _deleteAssignmentsForTag(tagId);
        },
        queueOp: QueuedDelete(table: 'transaction_tags', rowId: tagId),
      );
    }
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
    try {
      final data = await supabase
          .from('transaction_tag_assignments')
          .select('transaction_id, tag_id');
      final result = <String, Set<String>>{};
      for (final row in data) {
        final txId = row['transaction_id'] as String;
        final tagId = row['tag_id'] as String;
        (result[txId] ??= <String>{}).add(tagId);
      }
      await _refreshAllTransactionAssignmentsCache(result);
      return result;
    } catch (_) {
      final cached = await _loadAllAssignmentsFromCache();
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Returns the ids of every transaction in the household that
  /// carries the given [tagId]. Used to filter the transactions list
  /// by tag — the caller follows up with an `inFilter('id', …)`
  /// on the transactions query. Done in two trips rather than a SQL
  /// join because the assignment table is tiny and PostgREST's
  /// embed-with-filter ergonomics aren't worth the complexity here.
  Future<List<String>> fetchTransactionIdsForTag(String tagId) async {
    try {
      final data = await supabase
          .from('transaction_tag_assignments')
          .select('transaction_id')
          .eq('tag_id', tagId);
      return data
          .map<String>((row) => row['transaction_id'] as String)
          .toList();
    } catch (_) {
      final cached = await _loadTransactionIdsForTagFromCache(tagId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Returns the ids of tags currently assigned to [transactionId].
  /// Just ids — callers that need the full row look them up in the
  /// dictionary fetch which is cached separately, so we don't pay
  /// for the join every time.
  Future<List<String>> fetchAssignedTagIds(String transactionId) async {
    try {
      final data = await supabase
          .from('transaction_tag_assignments')
          .select('tag_id')
          .eq('transaction_id', transactionId);
      return data.map<String>((row) => row['tag_id'] as String).toList();
    } catch (_) {
      final cached = await _loadAssignedTagIdsFromCache(transactionId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Returns the ids of tags assigned to [lineItemId]. Mirrors
  /// [fetchAssignedTagIds] for the line-item side; the picker on
  /// the line-items editor uses the bulk method below in practice,
  /// but this exists for completeness and for any future
  /// per-row consumer.
  Future<List<String>> fetchAssignedTagIdsForLineItem(String lineItemId) async {
    try {
      final data = await supabase
          .from('receipt_line_item_tag_assignments')
          .select('tag_id')
          .eq('line_item_id', lineItemId);
      return data.map<String>((row) => row['tag_id'] as String).toList();
    } catch (_) {
      final cached = await _loadAssignedTagIdsForLineItemFromCache(lineItemId);
      if (cached != null) return cached;
      rethrow;
    }
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

    if (tagIds.isNotEmpty) {
      await supabase
          .from('receipt_line_item_tag_assignments')
          .insert(
            tagIds
                .map((id) => {'line_item_id': lineItemId, 'tag_id': id})
                .toList(),
          );
    }

    // Mirror the server-side replace into the cache. Drift wraps
    // both legs in a transaction so a mid-write crash doesn't
    // leave the cache half-updated. NB: the server-side two-leg
    // shape is still non-atomic by design (documented in
    // [replaceAssignments]).
    final db = _db;
    if (db != null) {
      try {
        await db.replaceReceiptLineItemTagAssignments(
          lineItemId: lineItemId,
          tagIds: tagIds,
        );
      } catch (_) {/**/}
    }
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

    if (tagIds.isNotEmpty) {
      await supabase
          .from('transaction_tag_assignments')
          .insert(
            tagIds
                .map((id) => {'transaction_id': transactionId, 'tag_id': id})
                .toList(),
          );
    }

    final db = _db;
    if (db != null) {
      try {
        await db.replaceTransactionTagAssignments(
          transactionId: transactionId,
          tagIds: tagIds,
        );
      } catch (_) {/**/}
    }
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
    // Invalidate the touched transaction-side assignments. The
    // next fetchAllAssignments reconciles fully; we don't try to
    // patch the cache in place because a row's other-tag set
    // might have changed too.
    final db = _db;
    if (db != null) {
      try {
        await db.deleteTransactionTagAssignmentsByTransactionIds(transactionIds);
      } catch (_) {/**/}
    }
  }

  // ── Cache helpers ──────────────────────────────────────────

  Future<void> _refreshTagsCache(
    String householdId,
    List<TransactionTag> tags,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.replaceTagsForHousehold(
        householdId,
        tags.map(_tagToCompanion).toList(),
      );
    } catch (_) {/**/}
  }

  Future<void> _writeTagCacheRow(TransactionTag t) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.upsertTag(_tagToCompanion(t));
    } catch (_) {/**/}
  }

  Future<void> _deleteTagCacheRow(String id) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.deleteTag(id);
    } catch (_) {/**/}
  }

  Future<void> _deleteAssignmentsForTag(String tagId) async {
    final db = _db;
    if (db == null) return;
    try {
      // Find every transaction that carried this tag, then drop
      // those transactions' cached rows entirely. Mirrors the
      // server-side ON DELETE CASCADE effect.
      final txIds = await db.loadTransactionIdsForTag(tagId);
      if (txIds.isNotEmpty) {
        await db.deleteTransactionTagAssignmentsByTransactionIds(txIds);
      }
    } catch (_) {/**/}
  }

  /// Phase 3c: read-by-id for the optimistic-update path. Scans
  /// the per-install cache (small — tag dictionaries are dozens of
  /// rows at most).
  Future<TransactionTag?> _loadTagCacheRowById(String id) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.select(db.transactionTagsCache).get();
      for (final r in rows) {
        if (r.id == id) return _tagFromCacheRow(r);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<TransactionTag>?> _loadTagsFromCache(String householdId) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.loadTagsForHousehold(householdId);
      if (rows.isEmpty) return null;
      return rows.map(_tagFromCacheRow).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshAllTransactionAssignmentsCache(
    Map<String, Set<String>> assignments,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      final now = DateTime.now().toUtc();
      final rows = <TransactionTagAssignmentsCacheCompanion>[
        for (final entry in assignments.entries)
          for (final tagId in entry.value)
            TransactionTagAssignmentsCacheCompanion(
              transactionId: Value(entry.key),
              tagId: Value(tagId),
              cachedAt: Value(now),
            ),
      ];
      await db.replaceAllTransactionTagAssignments(rows);
    } catch (_) {/**/}
  }

  Future<Map<String, Set<String>>?> _loadAllAssignmentsFromCache() async {
    final db = _db;
    if (db == null) return null;
    try {
      final result = await db.loadAllTransactionTagAssignments();
      if (result.isEmpty) return null;
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> _loadTransactionIdsForTagFromCache(
    String tagId,
  ) async {
    final db = _db;
    if (db == null) return null;
    try {
      final ids = await db.loadTransactionIdsForTag(tagId);
      if (ids.isEmpty) return null;
      return ids;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> _loadAssignedTagIdsFromCache(
    String transactionId,
  ) async {
    final db = _db;
    if (db == null) return null;
    try {
      final ids = await db.loadAssignedTagIds(transactionId);
      if (ids.isEmpty) return null;
      return ids;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> _loadAssignedTagIdsForLineItemFromCache(
    String lineItemId,
  ) async {
    final db = _db;
    if (db == null) return null;
    try {
      final ids = await db.loadAssignedTagIdsForLineItem(lineItemId);
      if (ids.isEmpty) return null;
      return ids;
    } catch (_) {
      return null;
    }
  }
}

TransactionTagsCacheCompanion _tagToCompanion(TransactionTag t) {
  return TransactionTagsCacheCompanion(
    id: Value(t.id),
    householdId: Value(t.householdId),
    name: Value(t.name),
    color: Value(t.color),
    createdAt: Value(t.createdAt.toUtc()),
    cachedAt: Value(DateTime.now().toUtc()),
  );
}

TransactionTag _tagFromCacheRow(TransactionTagsCacheRow r) {
  return TransactionTag(
    id: r.id,
    householdId: r.householdId,
    name: r.name,
    color: r.color,
    createdAt: r.createdAt,
  );
}
