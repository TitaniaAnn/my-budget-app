// Data access layer for transactions and categories.
// Transactions are fetched with a join on categories so the UI gets
// category name/color/icon in a single round-trip.
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/categorizer.dart';
import 'transaction_tags_repository.dart';

part 'transactions_repository.g.dart';

/// Provides a singleton [TransactionsRepository] instance via Riverpod.
@riverpod
TransactionsRepository transactionsRepository(TransactionsRepositoryRef ref) {
  return TransactionsRepository();
}

class TransactionsRepository {
  /// Fetches transactions for a household, optionally filtered by [accountId].
  ///
  /// Joins the categories table so [Transaction.category] is populated.
  /// Results are paginated via [limit] and [offset]; ordered newest-first.
  ///
  /// When [tagId] is set, the result is narrowed to transactions
  /// carrying that tag. Done as a pre-fetch on the assignment table
  /// followed by `inFilter('id', …)` on the main query — two trips,
  /// but the assignment table is small and PostgREST's embed-with-
  /// filter ergonomics aren't worth the complexity for this v1
  /// surface. If a tag has no assignments, this short-circuits and
  /// returns an empty list without touching the main table.
  Future<List<Transaction>> fetchTransactions({
    required String householdId,
    String? accountId,
    String? categoryId,
    String? tagId,
    String? search,
    DateTime? from,
    DateTime? to,
    int limit = 1000,
    int offset = 0,
  }) async {
    List<String>? tagFilteredIds;
    if (tagId != null) {
      tagFilteredIds = await TransactionTagsRepository()
          .fetchTransactionIdsForTag(tagId);
      if (tagFilteredIds.isEmpty) return const [];
    }

    var query = supabase
        .from('transactions')
        .select('*, category:categories(*)')
        .eq('household_id', householdId);

    if (accountId != null) query = query.eq('account_id', accountId);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (tagFilteredIds != null) {
      query = query.inFilter('id', tagFilteredIds);
    }
    if (search != null && search.isNotEmpty) {
      // Match either the raw description or the cleaned merchant column.
      // The user's input goes into a SQL ILIKE pattern, so:
      //   1. escape the LIKE wildcards `%` and `_` (and the escape char `\`)
      //      so that "50%" matches the literal string, not "anything starting
      //      with 50";
      //   2. escape the PostgREST `or=` separator `,` so commas in the input
      //      don't split the filter into two branches.
      final term = search
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_')
          .replaceAll(',', r'\,');
      query = query.or('description.ilike.%$term%,merchant.ilike.%$term%');
    }
    if (from != null) {
      query = query.gte(
        'transaction_date',
        from.toIso8601String().substring(0, 10),
      );
    }
    if (to != null) {
      query = query.lte(
        'transaction_date',
        to.toIso8601String().substring(0, 10),
      );
    }

    final data = await query
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return data.map<Transaction>(Transaction.fromJson).toList();
  }

  /// Creates a household-specific category and returns it.
  Future<Category> createCategory({
    required String householdId,
    required String name,
    required bool isIncome,
    String? parentId,
    String? icon,
    String? color,
  }) async {
    final data = await supabase
        .from('categories')
        .insert({
          'household_id': householdId,
          'name': name,
          'is_income': isIncome,
          'parent_id': parentId,
          'icon': icon,
          'color': color,
          'sort_order': 500,
        })
        .select()
        .single();
    return Category.fromJson(data);
  }

  /// Deletes a household category. System categories (householdId=null) are
  /// protected by RLS and will reject this call server-side.
  Future<void> deleteCategory(String categoryId) async {
    await supabase.from('categories').delete().eq('id', categoryId);
  }

  /// Fetches all categories (system + household-specific).
  /// System categories have household_id IS NULL; RLS exposes them to everyone.
  ///
  /// Ordered by `sort_order` ASC, then `name` ASC as tiebreaker. The
  /// seed (migration 002) packs parents at 0/10/20… and children at
  /// 1/2/3…, so ASC reproduces the intended on-screen grouping
  /// (Income then Housing then Food…, with children in spec order).
  /// postgrest's .order() defaults to DESC, so the explicit
  /// `ascending: true` here is load-bearing.
  Future<List<Category>> fetchCategories() async {
    final data = await supabase
        .from('categories')
        .select()
        .order('sort_order', ascending: true)
        .order('name', ascending: true);
    return data.map<Category>(Category.fromJson).toList();
  }

  /// Inserts a single manually-entered transaction and returns it with
  /// the category row joined.
  ///
  /// When [categoryId] is non-null the row is recorded as user-assigned
  /// ground truth — the upcoming ML categorizer trains on these.
  Future<Transaction> createTransaction({
    required String householdId,
    required String accountId,
    required String enteredBy,
    required int amount,
    required String description,
    required DateTime transactionDate,
    String? merchant,
    String? categoryId,
    String? rateId,
    String? notes,
  }) async {
    final data = await supabase
        .from('transactions')
        .insert({
          'household_id': householdId,
          'account_id': accountId,
          'entered_by': enteredBy,
          'amount': amount,
          'currency': 'USD',
          'description': description,
          'merchant': merchant,
          'category_id': categoryId,
          'rate_id': rateId,
          'transaction_date': transactionDate.toIso8601String().substring(
            0,
            10,
          ),
          'source': 'manual',
          if (categoryId != null) 'category_assigned_by': 'user',
          if (categoryId != null)
            'category_assigned_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('*, category:categories(*)')
        .single();

    return Transaction.fromJson(data);
  }

  /// Atomically records a transfer between two accounts in the same
  /// household. Inserts two transaction rows sharing a fresh
  /// `transfer_id`: a negative leg on [fromAccountId] and a positive
  /// leg on [toAccountId], both for [amountCents] (which must be
  /// positive — the SQL function flips the sign per leg).
  ///
  /// Goes through the `create_transfer` RPC (migration 030) so the
  /// two inserts share one DB transaction. A mid-call failure rolls
  /// both legs back rather than leaving a half-recorded transfer that
  /// would skew account balances.
  ///
  /// Returns the shared `transfer_id` (UUID). The caller typically
  /// refetches the ledger afterwards rather than holding onto the id
  /// — it's returned mainly so integration tests can join back to
  /// both legs.
  Future<String> createTransfer({
    required String householdId,
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    required DateTime transactionDate,
    required String description,
    required String enteredBy,
  }) async {
    final result = await supabase.rpc(
      'create_transfer',
      params: {
        'p_household_id': householdId,
        'p_from_account_id': fromAccountId,
        'p_to_account_id': toAccountId,
        'p_amount_cents': amountCents,
        'p_transaction_date': transactionDate
            .toIso8601String()
            .substring(0, 10),
        'p_description': description,
        'p_entered_by': enteredBy,
      },
    );
    return result as String;
  }

  /// Fetches transactions whose ML-assigned category fell in the
  /// "uncertain" confidence band — predictions that auto-applied at or
  /// above [maxConfidenceBp] are excluded (those are the "we're sure"
  /// cases the active-learning UX shouldn't bother the user with).
  ///
  /// Confidence is stored in basis points (0–10000) so the comparison
  /// stays integer-only. The default upper bound mirrors the Categorizer's
  /// `minMlConfidence` of 0.55 (== 5500 bp).
  ///
  /// Ordered by confidence ascending so the most-uncertain rows surface
  /// first — that's where user feedback is most valuable for retraining.
  Future<List<Transaction>> fetchUncertain({
    required String householdId,
    int maxConfidenceBp = 5500,
    int limit = 100,
  }) async {
    final data = await supabase
        .from('transactions')
        .select('*, category:categories(*)')
        .eq('household_id', householdId)
        .eq('category_assigned_by', 'ml_model')
        .lt('ml_model_confidence', maxConfidenceBp)
        .order('ml_model_confidence', ascending: true)
        .limit(limit);
    return data.map<Transaction>(Transaction.fromJson).toList();
  }

  /// Sums positive-amount transactions on [accountIds] dated on or
  /// after [from]. Returns the total in cents, or 0 if [accountIds]
  /// is empty.
  ///
  /// Used by the Roth IRA Underused growth-advisor rule to compute
  /// year-to-date contributions. Positive amount = inflow = a
  /// contribution (the sign convention is the same as the rest of
  /// the app — debits negative, credits positive). PostgREST doesn't
  /// have a server-side SUM in its select grammar, so the sum
  /// happens in Dart over a focused result set: a typical year has
  /// 12-26 contribution rows per Roth account, which is well under
  /// the threshold where shipping a new RPC would be worth it.
  Future<int> sumPositiveAmountsForAccountsSince({
    required List<String> accountIds,
    required DateTime from,
    String displayCurrency = 'USD',
    Map<String, double>? ratesToDisplay,
  }) async {
    if (accountIds.isEmpty) return 0;
    final rows = await supabase
        .from('transactions')
        .select('amount, currency')
        .inFilter('account_id', accountIds)
        .gt('amount', 0)
        .gte('transaction_date', from.toIso8601String().substring(0, 10));

    // Multi-currency contract matches the rest of the FX-aware
    // surfaces: rows in `displayCurrency` count at face value;
    // foreign rows convert via `ratesToDisplay`; rows in a
    // currency missing from the map are EXCLUDED (rate=0). A
    // null `ratesToDisplay` preserves legacy single-currency
    // behaviour — sum raw amounts regardless of currency.
    var sum = 0;
    for (final row in rows) {
      final amount = row['amount'] as int;
      final currency = (row['currency'] as String?) ?? displayCurrency;
      if (ratesToDisplay == null) {
        sum += amount;
        continue;
      }
      if (currency == displayCurrency) {
        sum += amount;
        continue;
      }
      final rate = ratesToDisplay[currency];
      if (rate == null) continue;
      sum += (amount * rate).round();
    }
    return sum;
  }

  /// Fetches all transactions within a date range for dashboard summaries.
  /// Joins categories so spending-by-category can be computed in Dart.
  Future<List<Transaction>> fetchTransactionsForDashboard({
    required String householdId,
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await supabase
        .from('transactions')
        .select('*, category:categories(*)')
        .eq('household_id', householdId)
        .gte('transaction_date', from.toIso8601String().substring(0, 10))
        .lte('transaction_date', to.toIso8601String().substring(0, 10))
        .order('transaction_date', ascending: false);

    return data.map<Transaction>(Transaction.fromJson).toList();
  }

  /// Updates a manually-entered transaction.
  ///
  /// Any change here is treated as a user decision, including category
  /// changes — so [category_assigned_by] flips to 'user' and the timestamp
  /// is refreshed. Predictions made by the ML model that the user didn't
  /// override stay flagged as 'ml_model'.
  Future<void> updateTransaction({
    required String id,
    required int amount,
    required String description,
    String? merchant,
    String? categoryId,
    String? rateId,
    required DateTime transactionDate,
    String? notes,
  }) async {
    await supabase
        .from('transactions')
        .update({
          'amount': amount,
          'description': description,
          'merchant': merchant,
          'category_id': categoryId,
          'rate_id': rateId,
          'transaction_date': transactionDate.toIso8601String().substring(
            0,
            10,
          ),
          'notes': notes,
          if (categoryId != null) 'category_assigned_by': 'user',
          if (categoryId != null)
            'category_assigned_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  /// Hard-deletes a transaction row.
  Future<void> deleteTransaction(String id) async {
    await supabase.from('transactions').delete().eq('id', id);
  }

  /// Assigns [categoryId] to every transaction in [transactionIds] as
  /// a user-sourced choice — sets `category_assigned_by = 'user'`,
  /// stamps `category_assigned_at`, and clears `ml_model_confidence`
  /// (a stale ML value would confuse the active-learning review
  /// screen). One UPDATE…WHERE id IN (…) round-trip.
  ///
  /// Distinct from [bulkRecategorize], which runs the categorizer
  /// per row and groups by predicted class; this method takes an
  /// explicit user choice and applies it to a known set.
  Future<void> setUserCategoryForMany({
    required List<String> transactionIds,
    required String categoryId,
  }) async {
    if (transactionIds.isEmpty) return;
    await supabase
        .from('transactions')
        .update({
          'category_id': categoryId,
          'category_assigned_by': 'user',
          'category_assigned_at': DateTime.now().toUtc().toIso8601String(),
          'ml_model_confidence': null,
        })
        .inFilter('id', transactionIds);
  }

  /// Deletes every transaction in [transactionIds] in one round-trip.
  /// Returns the distinct account ids that were touched so the caller
  /// can recompute their balances (the trigger fires per-row, but the
  /// Dart-side `currentBalance` mirror needs an explicit refresh).
  ///
  /// Uses PostgREST's delete-returning form so we learn the affected
  /// account ids without a separate SELECT — same pattern as
  /// [deleteTransfer].
  Future<List<String>> deleteMany(List<String> transactionIds) async {
    if (transactionIds.isEmpty) return const [];
    final rows = await supabase
        .from('transactions')
        .delete()
        .inFilter('id', transactionIds)
        .select('account_id');
    return {
      for (final r in (rows as List).cast<Map<String, dynamic>>())
        r['account_id'] as String,
    }.toList();
  }

  /// Deletes both legs of a transfer (migration 030) in one round-trip.
  /// Returns the account ids that were affected so the caller can
  /// recompute balances. Deleting a single leg in isolation would
  /// orphan the other side and skew net worth — this is the only
  /// blessed way to remove a transfer.
  ///
  /// Uses PostgREST's "delete returning" form so we learn the affected
  /// account ids in the same trip; a follow-up SELECT would race
  /// against the cascade.
  Future<List<String>> deleteTransfer(String transferId) async {
    final rows = await supabase
        .from('transactions')
        .delete()
        .eq('transfer_id', transferId)
        .select('account_id');
    return [for (final r in rows as List) r['account_id'] as String];
  }

  /// Confirms or corrects an ML-assigned category, flipping provenance to
  /// 'user' so the row joins the next training dump. Clears the stored
  /// ML confidence — the value is only meaningful while the row is still
  /// "what the model guessed", not after the user accepts or overrides.
  ///
  /// Used by the active-learning Review surface; doesn't touch any other
  /// fields, so it's safe to call without re-supplying amount/date/etc.
  ///
  /// Timestamp uses `.toUtc().toIso8601String()` so the wire string ends
  /// in `Z`. A timezone-naive string would be interpreted as UTC by
  /// Postgres TIMESTAMPTZ, silently shifting the stored time by the
  /// host's UTC offset.
  Future<void> setUserCategory({
    required String transactionId,
    required String categoryId,
  }) async {
    await supabase
        .from('transactions')
        .update({
          'category_id': categoryId,
          'category_assigned_by': 'user',
          'category_assigned_at': DateTime.now().toUtc().toIso8601String(),
          'ml_model_confidence': null,
        })
        .eq('id', transactionId);
  }

  /// Fetches every transaction currently paired to [receiptId], ordered
  /// by date (newest first). Joins the category row so the receipt detail
  /// list can render the same chip styling as the main transactions list.
  ///
  /// The schema lets one receipt back multiple transactions (an
  /// installment plan, a bill split across two charges) — see the
  /// note on [setReceiptId] — so this returns a list, not a single row.
  Future<List<Transaction>> fetchByReceiptId(String receiptId) async {
    final data = await supabase
        .from('transactions')
        .select('*, category:categories(*)')
        .eq('receipt_id', receiptId)
        .order('transaction_date', ascending: false);
    return data.map<Transaction>(Transaction.fromJson).toList();
  }

  /// Pairs an existing transaction with a receipt by setting [receiptId],
  /// or unpairs when [receiptId] is null. The schema permits many
  /// transactions per receipt (an installment plan, a bill split across
  /// two charges) so this never inspects whether the receipt is already
  /// linked elsewhere — the caller decides what makes sense.
  Future<void> setReceiptId({
    required String transactionId,
    required String? receiptId,
  }) async {
    await supabase
        .from('transactions')
        .update({'receipt_id': receiptId})
        .eq('id', transactionId);
  }

  /// Re-runs the [categorizer] on all uncategorized transactions for
  /// [householdId] (optionally scoped to [accountId]) and bulk-updates
  /// their category_id, recording which engine produced each label.
  /// Returns the number of transactions updated.
  Future<int> bulkRecategorize({
    required String householdId,
    String? accountId,
    required Categorizer categorizer,
  }) async {
    // Join through `accounts` so the categorizer can use account_type as a
    // feature. Uses the `account:accounts(account_type)` PostgREST shape
    // that's already the convention here.
    var query = supabase
        .from('transactions')
        .select(
          'id, description, merchant, amount, account:accounts(account_type)',
        )
        .eq('household_id', householdId)
        .isFilter('category_id', null);

    if (accountId != null) query = query.eq('account_id', accountId);

    final rows = await query;
    if (rows.isEmpty) return 0;

    // Group transactions by (categoryId, source, confidenceBp) so we can
    // update each group with a single UPDATE…WHERE id IN (…) call rather
    // than one round-trip per row. The source is part of the key so an
    // ML hit and a keyword-matcher hit on the same category don't blur
    // their provenance for downstream training. Confidence is rounded
    // to the nearest percentage point (1 percent == 100 basis points)
    // so the grouping doesn't degenerate to one-bucket-per-row when
    // every prediction has a slightly different float — the precision
    // loss is invisible to the active-learning UX which thinks in
    // "high / mid / low" bands.
    final groups = <(String, CategorizerSource, int?), List<String>>{};
    for (final row in rows) {
      final acct = row['account'] as Map<String, dynamic>?;
      final r = categorizer.categorize(
        description: row['description'] as String,
        merchant: row['merchant'] as String?,
        amountCents: (row['amount'] as int),
        accountType: acct?['account_type'] as String?,
      );
      if (r == null) continue;
      final confidenceBp = confidenceToBasisPoints(r);
      groups
          .putIfAbsent((r.categoryId, r.source, confidenceBp), () => [])
          .add(row['id'] as String);
    }
    if (groups.isEmpty) return 0;

    final now = DateTime.now().toUtc().toIso8601String();
    var updated = 0;
    await Future.wait(
      groups.entries.map((entry) async {
        final (categoryId, source, confidenceBp) = entry.key;
        await supabase
            .from('transactions')
            .update({
              'category_id': categoryId,
              'category_assigned_by': source.dbValue,
              'category_assigned_at': now,
              // Always write the column — for keyword rows this clears
              // any stale value carried over from a prior ML run.
              'ml_model_confidence': confidenceBp,
            })
            .inFilter('id', entry.value);
        updated += entry.value.length;
      }),
    );

    return updated;
  }

  /// Bulk-inserts imported transactions.
  ///
  /// Uses upsert with conflict resolution on (account_id, external_id) so
  /// re-importing the same CSV is safe. Returns a [BulkImportResult] with
  /// the count actually inserted, skipped as duplicates of a prior import,
  /// and reconciled against scheduler-emitted recurring rows — the
  /// user-facing toast can surface all three.
  ///
  /// Caller is responsible for setting `category_assigned_by` /
  /// `category_assigned_at` on any row where they also set `category_id`
  /// (the import sheet routes through the Categorizer façade for this).
  ///
  /// Reconciliation against recurring rules: before the upsert, this
  /// method looks for `source='recurring'` rows in the last 14 days on
  /// the target account that align with import rows (same account, same
  /// signed amount, transaction date within ±1 day). Each match deletes
  /// the scheduler-emitted row before the upsert lands the bank's
  /// canonical row — otherwise a Spotify rule that materialised on the
  /// 1st would leave a duplicate next to the bank's actual Spotify
  /// charge.
  Future<BulkImportResult> bulkImport({
    required String householdId,
    required String accountId,
    required String enteredBy,
    required List<Map<String, dynamic>> rows,
  }) async {
    if (rows.isEmpty) {
      return const BulkImportResult(inserted: 0, skipped: 0);
    }

    // ── Reconcile against recurring emissions ────────────────────────
    // 14-day window: scheduler emissions older than this almost
    // certainly reflect different real-world charges than today's
    // import. Wider windows risk matching unrelated $9.99 events; this
    // matches the typical bank-posting lag tolerance.
    final fourteenDaysAgo = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 14));
    final recurringJson = await supabase
        .from('transactions')
        .select('id, transaction_date, amount')
        .eq('household_id', householdId)
        .eq('account_id', accountId)
        .eq('source', 'recurring')
        .gte(
          'transaction_date',
          fourteenDaysAgo.toIso8601String().substring(0, 10),
        );
    final recurringRows = [
      for (final r in recurringJson as List)
        (
          id: r['id'] as String,
          date: DateTime.parse(r['transaction_date'] as String),
          amount: (r['amount'] as num).toInt(),
        ),
    ];

    final matches = matchRecurringDuplicates(
      importRows: rows,
      recurringRows: recurringRows,
    );

    if (matches.isNotEmpty) {
      // Delete the matched scheduler rows in one round-trip so the
      // upsert that follows lands the bank's canonical entries
      // without ghost duplicates. Order doesn't matter; we're
      // deleting by primary key.
      await supabase
          .from('transactions')
          .delete()
          .inFilter(
            'id',
            [for (final m in matches) m.scheduledTransactionId],
          );
    }

    final enriched = rows.map((r) {
      return {
        ...r,
        'household_id': householdId,
        'account_id': accountId,
        'entered_by': enteredBy,
        'currency': 'USD',
        'source': 'import',
      };
    }).toList();

    // ignoreDuplicates: true makes the upsert behave like INSERT … ON
    // CONFLICT DO NOTHING. The returned select() then contains only the
    // rows that were actually written, so we can report a truthful count.
    final returned = await supabase
        .from('transactions')
        .upsert(
          enriched,
          onConflict: 'account_id,external_id',
          ignoreDuplicates: true,
        )
        .select('id');

    final inserted = returned.length;
    return BulkImportResult(
      inserted: inserted,
      skipped: enriched.length - inserted,
      reconciled: matches.length,
    );
  }
}

/// Outcome of a [TransactionsRepository.bulkImport] call.
///
/// The UI shows `inserted` as the primary number; `skipped` and
/// `reconciled` may be surfaced separately so the user understands
/// why the import count doesn't match the CSV row count.
class BulkImportResult {
  const BulkImportResult({
    required this.inserted,
    required this.skipped,
    this.reconciled = 0,
  });

  /// Rows newly inserted into `transactions`.
  final int inserted;

  /// Rows the bank had already given us — UNIQUE (account_id,
  /// external_id) rejected them. The user re-imported the same CSV.
  final int skipped;

  /// Scheduler-emitted (source='recurring') rows the import
  /// replaced — recurring-transactions slice 3 dedup. A Spotify
  /// rule that materialised a row on the 1st gets reconciled with
  /// the bank's actual Spotify charge when the statement lands,
  /// instead of leaving two near-identical entries on the ledger.
  final int reconciled;
}

/// Match between an imported row and a scheduler-emitted row that
/// represents the same real-world charge. Pure-data shape so
/// `matchRecurringDuplicates` can be unit-tested independently of
/// the repository.
class RecurringDuplicateMatch {
  const RecurringDuplicateMatch({
    required this.importRowIndex,
    required this.scheduledTransactionId,
  });

  final int importRowIndex;
  final String scheduledTransactionId;
}

/// Pairs each import row with at most one scheduler-emitted row
/// from [recurringRows] representing the same real-world charge.
///
/// Match criteria:
///   * same account is enforced upstream — both lists come from
///     a single account-scoped fetch;
///   * `amount` is exactly equal (signed cents); a Spotify -$9.99
///     rule must reconcile against a -$9.99 bank charge, not a
///     +$9.99 refund;
///   * dates within ±[dateTolerance] of each other so bank
///     posting lag doesn't defeat the match.
///
/// Each scheduler row is claimed at most once per call — duplicates
/// in the import (e.g. an oddly-formatted CSV with two $9.99 rows
/// on the same day) only get to claim a scheduler row ONCE. Ties
/// are broken by closest date, then by first-seen scheduler row id
/// so the result is deterministic.
List<RecurringDuplicateMatch> matchRecurringDuplicates({
  required List<Map<String, dynamic>> importRows,
  required List<({String id, DateTime date, int amount})> recurringRows,
  Duration dateTolerance = const Duration(days: 1),
}) {
  // Normalise both sides to UTC calendar-day midnights before
  // diffing. The recurring rows arrive as `transaction_date` DATE
  // values (no time/zone), and the import rows come from
  // ISO-format date strings — comparing raw DateTimes mixes naive
  // and zoned values and can off-by-one across a local timezone
  // boundary. Stripping to (y, m, d) keeps the comparison a true
  // calendar diff.
  DateTime day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  final matches = <RecurringDuplicateMatch>[];
  final claimed = <String>{};
  for (var i = 0; i < importRows.length; i++) {
    final row = importRows[i];
    final amount = row['amount'] as int?;
    final dateStr = row['transaction_date'] as String?;
    if (amount == null || dateStr == null) continue;
    final date = day(DateTime.parse(dateStr));

    String? bestId;
    Duration? bestDelta;
    for (final r in recurringRows) {
      if (claimed.contains(r.id)) continue;
      if (r.amount != amount) continue;
      final delta = (day(r.date).difference(date)).abs();
      if (delta > dateTolerance) continue;
      if (bestDelta == null || delta < bestDelta) {
        bestId = r.id;
        bestDelta = delta;
      }
    }
    if (bestId != null) {
      claimed.add(bestId);
      matches.add(RecurringDuplicateMatch(
        importRowIndex: i,
        scheduledTransactionId: bestId,
      ));
    }
  }
  return matches;
}
