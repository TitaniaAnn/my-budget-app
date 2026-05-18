// Riverpod providers for the tag dictionary and per-transaction
// assignments. Kept separate from [transactions_provider] so the
// tag-picker UI can invalidate just the assignments for one
// transaction without rebuilding the full transactions list.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/household_provider.dart';
import '../models/transaction_tag.dart';
import '../repositories/transaction_tags_repository.dart';

part 'transaction_tags_provider.g.dart';

/// Every tag in the current household, alphabetical. Powers the
/// chip-picker on the transaction edit sheet — and later, the tag
/// filter on the transactions list.
@riverpod
Future<List<TransactionTag>> transactionTags(TransactionTagsRef ref) async {
  final householdId = await ref.watch(householdIdProvider.future);
  if (householdId == null) return [];
  final repo = ref.watch(transactionTagsRepositoryProvider);
  return repo.fetchTags(householdId);
}

/// Ids of the tags currently assigned to [transactionId]. Family-
/// keyed so invalidating one transaction's assignments doesn't
/// disturb the picker state for any other open editor.
@riverpod
Future<List<String>> tagIdsForTransaction(
  TagIdsForTransactionRef ref,
  String transactionId,
) async {
  final repo = ref.watch(transactionTagsRepositoryProvider);
  return repo.fetchAssignedTagIds(transactionId);
}

/// Every visible tag assignment, indexed by transaction id. The
/// transactions list watches this once and looks up tags per card
/// in O(1) — alternative would be a per-row provider that fires
/// hundreds of requests on a long list.
///
/// RLS scopes the underlying fetch to the caller's household via
/// the assignment table's "transaction_id IN (SELECT id FROM
/// transactions)" policy (migration 020).
@riverpod
Future<Map<String, Set<String>>> transactionTagAssignments(
  TransactionTagAssignmentsRef ref,
) async {
  final repo = ref.watch(transactionTagsRepositoryProvider);
  return repo.fetchAllAssignments();
}
