// Data access layer for recurring transaction rules.
//
// This is the proactive-side companion to TransactionsRepository:
// rules live here, the actual ledger entries the scheduler emits
// land in the `transactions` table. The scheduler itself is a
// follow-up — for now the repository is the vocabulary the rest
// of the app uses to CRUD the rules.
//
// All writes go through PostgREST; RLS in migration 031 enforces
// household scoping. No RPC is needed here yet — every operation
// is a single-row CRUD.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../models/recurring_transaction.dart';

part 'recurring_transactions_repository.g.dart';

@riverpod
RecurringTransactionsRepository recurringTransactionsRepository(
  RecurringTransactionsRepositoryRef ref,
) {
  return RecurringTransactionsRepository();
}

class RecurringTransactionsRepository {
  /// All recurring rules for a household, ordered by next occurrence
  /// ascending — what's due soonest comes first. Includes inactive
  /// rules; callers that want only active ones filter in Dart so
  /// the "show inactive" toggle in a future UI doesn't need a
  /// separate fetch.
  Future<List<RecurringTransaction>> fetchAll(String householdId) async {
    final data = await supabase
        .from('recurring_transactions')
        .select()
        .eq('household_id', householdId)
        .order('next_occurrence_date', ascending: true);
    return data.map<RecurringTransaction>(RecurringTransaction.fromJson)
        .toList();
  }

  /// Inserts a new rule and returns the persisted row (so the
  /// caller has the generated id + created_at / updated_at).
  Future<RecurringTransaction> create({
    required String householdId,
    required String accountId,
    required int amountCents,
    required String description,
    required RecurrenceCadence cadence,
    required DateTime nextOccurrenceDate,
    required String createdBy,
    String? merchant,
    String? categoryId,
  }) async {
    final data = await supabase
        .from('recurring_transactions')
        .insert({
          'household_id': householdId,
          'account_id': accountId,
          'amount_cents': amountCents,
          'currency': 'USD',
          'description': description,
          'merchant': merchant,
          'category_id': categoryId,
          'cadence': cadence.dbValue,
          'next_occurrence_date': nextOccurrenceDate
              .toIso8601String()
              .substring(0, 10),
          'created_by': createdBy,
        })
        .select()
        .single();
    return RecurringTransaction.fromJson(data);
  }

  /// Updates whichever fields the caller passed. Skipped-until-date
  /// has a special semantic: passing it as null does NOT clear an
  /// existing value (that would be a footgun where "I didn't touch
  /// this field" looks identical to "I want to clear it"). Use
  /// [clearSkippedUntil] for the explicit clear.
  Future<RecurringTransaction> update({
    required String id,
    int? amountCents,
    String? description,
    String? merchant,
    String? categoryId,
    RecurrenceCadence? cadence,
    DateTime? nextOccurrenceDate,
    DateTime? skippedUntilDate,
    bool? isActive,
  }) async {
    final data = await supabase
        .from('recurring_transactions')
        .update({
          'amount_cents': ?amountCents,
          'description': ?description,
          'merchant': ?merchant,
          'category_id': ?categoryId,
          'cadence': ?cadence?.dbValue,
          'next_occurrence_date': ?nextOccurrenceDate
              ?.toIso8601String()
              .substring(0, 10),
          'skipped_until_date': ?skippedUntilDate
              ?.toIso8601String()
              .substring(0, 10),
          'is_active': ?isActive,
        })
        .eq('id', id)
        .select()
        .single();
    return RecurringTransaction.fromJson(data);
  }

  /// Explicit clear for [skippedUntilDate] — see [update] for why
  /// passing null in the general update path doesn't do this.
  Future<void> clearSkippedUntil(String id) async {
    await supabase
        .from('recurring_transactions')
        .update({'skipped_until_date': null})
        .eq('id', id);
  }

  Future<void> delete(String id) async {
    await supabase.from('recurring_transactions').delete().eq('id', id);
  }
}
