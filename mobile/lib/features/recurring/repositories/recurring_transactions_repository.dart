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
//
// Audit L1 Phase 2d: cache-through on fetchAll. Writes update the
// cache after the server returns the row. runScheduler is an RPC
// that materialises transactions server-side; the offline behavior
// is "schedule is deferred until online" — Phase 4 hard case.

import 'package:drift/drift.dart' show Value;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/app_database_provider.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/recurring_transaction.dart';

part 'recurring_transactions_repository.g.dart';

@riverpod
RecurringTransactionsRepository recurringTransactionsRepository(
  RecurringTransactionsRepositoryRef ref,
) {
  return RecurringTransactionsRepository(db: ref.watch(appDatabaseProvider));
}

class RecurringTransactionsRepository {
  RecurringTransactionsRepository({AppDatabase? db}) : _db = db;
  final AppDatabase? _db;

  /// All recurring rules for a household, ordered by next occurrence
  /// ascending — what's due soonest comes first. Includes inactive
  /// rules; callers that want only active ones filter in Dart so
  /// the "show inactive" toggle in a future UI doesn't need a
  /// separate fetch.
  Future<List<RecurringTransaction>> fetchAll(String householdId) async {
    try {
      final data = await supabase
          .from('recurring_transactions')
          .select()
          .eq('household_id', householdId)
          .order('next_occurrence_date', ascending: true);
      final rules = data
          .map<RecurringTransaction>(RecurringTransaction.fromJson)
          .toList();
      await _refreshRecurringCacheForHousehold(householdId, rules);
      return rules;
    } catch (_) {
      final cached = await _loadFromCache(householdId);
      if (cached != null) return cached;
      rethrow;
    }
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
    final rule = RecurringTransaction.fromJson(data);
    await _writeRecurringCacheRow(rule);
    return rule;
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
    final rule = RecurringTransaction.fromJson(data);
    await _writeRecurringCacheRow(rule);
    return rule;
  }

  /// Explicit clear for [skippedUntilDate] — see [update] for why
  /// passing null in the general update path doesn't do this.
  Future<void> clearSkippedUntil(String id) async {
    await supabase
        .from('recurring_transactions')
        .update({'skipped_until_date': null})
        .eq('id', id);
    // The .update doesn't return the row; invalidate the cache
    // row so the next fetchAll reads the cleared state.
    final db = _db;
    if (db != null) {
      try {
        await db.deleteRecurring(id);
      } catch (_) {/**/}
    }
  }

  Future<void> delete(String id) async {
    await supabase.from('recurring_transactions').delete().eq('id', id);
    final db = _db;
    if (db != null) {
      try {
        await db.deleteRecurring(id);
      } catch (_) {/**/}
    }
  }

  /// Runs the scheduler against every active rule in [householdId]
  /// whose `next_occurrence_date` is on or before [today]. Each due
  /// rule emits one transaction per missed cycle and its
  /// `next_occurrence_date` advances accordingly; pause windows
  /// (`skipped_until_date`) are honored. Returns the count of
  /// transactions actually inserted.
  ///
  /// The whole pass runs inside one SQL function (migration 032)
  /// so a mid-call failure rolls everything back rather than
  /// leaving the household with half-emitted state. Idempotent on
  /// subsequent calls — once a rule's next_occurrence_date is in
  /// the future it's skipped.
  ///
  /// [today] defaults to the current UTC date so the call site
  /// doesn't have to think about local-time formatting; tests
  /// inject a fixed date.
  ///
  /// Network-only — the scheduler materialises rows server-side
  /// and advances rule state; replicating that logic offline is a
  /// Phase 4 hard case. When offline this throws as usual; the
  /// dashboard's existing try/catch around its scheduler trigger
  /// already handles that path.
  Future<int> runScheduler({
    required String householdId,
    DateTime? today,
  }) async {
    final t = today ?? DateTime.now().toUtc();
    final result = await supabase.rpc(
      'run_recurring_scheduler',
      params: {
        'p_household_id': householdId,
        'p_today': t.toIso8601String().substring(0, 10),
      },
    );
    return result as int;
  }

  // ── Cache helpers ──────────────────────────────────────────

  Future<void> _refreshRecurringCacheForHousehold(
    String householdId,
    List<RecurringTransaction> rules,
  ) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.replaceRecurringForHousehold(
        householdId,
        rules.map(_toCompanion).toList(),
      );
    } catch (_) {/**/}
  }

  Future<void> _writeRecurringCacheRow(RecurringTransaction r) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.upsertRecurring(_toCompanion(r));
    } catch (_) {/**/}
  }

  Future<List<RecurringTransaction>?> _loadFromCache(String householdId) async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.loadRecurringForHousehold(householdId);
      if (rows.isEmpty) return null;
      return rows.map(_fromCacheRow).toList();
    } catch (_) {
      return null;
    }
  }
}

RecurringTransactionsCacheCompanion _toCompanion(RecurringTransaction r) {
  return RecurringTransactionsCacheCompanion(
    id: Value(r.id),
    householdId: Value(r.householdId),
    accountId: Value(r.accountId),
    amountCents: Value(r.amountCents),
    currency: Value(r.currency),
    description: Value(r.description),
    merchant: Value(r.merchant),
    categoryId: Value(r.categoryId),
    cadence: Value(r.cadence.dbValue),
    // M10: DATE columns stored without toUtc; lastEmittedAt is
    // TIMESTAMPTZ so it keeps the .toUtc().
    nextOccurrenceDate: Value(r.nextOccurrenceDate),
    lastEmittedAt: Value(r.lastEmittedAt?.toUtc()),
    skippedUntilDate: Value(r.skippedUntilDate),
    isActive: Value(r.isActive),
    createdBy: Value(r.createdBy),
    createdAt: Value(r.createdAt.toUtc()),
    updatedAt: Value(r.updatedAt.toUtc()),
    cachedAt: Value(DateTime.now().toUtc()),
  );
}

RecurringTransaction _fromCacheRow(RecurringTransactionsCacheRow r) {
  return RecurringTransaction(
    id: r.id,
    householdId: r.householdId,
    accountId: r.accountId,
    amountCents: r.amountCents,
    currency: r.currency,
    description: r.description,
    merchant: r.merchant,
    categoryId: r.categoryId,
    cadence: RecurrenceCadence.values.firstWhere(
      (c) => c.dbValue == r.cadence,
      orElse: () => RecurrenceCadence.monthly,
    ),
    nextOccurrenceDate: r.nextOccurrenceDate,
    lastEmittedAt: r.lastEmittedAt,
    skippedUntilDate: r.skippedUntilDate,
    isActive: r.isActive,
    createdBy: r.createdBy,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}
