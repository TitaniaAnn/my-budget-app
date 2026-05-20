// Integration tests for RecurringTransactionsRepository. This is the
// vocabulary CRUD for migration 031's `recurring_transactions` table
// — the scheduler that materialises rows from these into
// `transactions` is a follow-up.
//
// Pinned here:
//   * create persists every column we send and returns the canonical
//     row (including the DB-generated id / timestamps);
//   * fetchAll orders by next_occurrence_date ASC so the soonest-due
//     rule surfaces first — the UX intent is "what's coming up";
//   * update only touches the fields explicitly passed (the `?`
//     null-aware-marker pattern in the repo body relies on this);
//   * skipped_until_date has a clear-vs-set asymmetry: update can
//     SET it but not clear it (passing null in `update` is a no-op
//     on this field), so the explicit clearSkippedUntil exists;
//   * the DB CHECK rejects amount = 0 — keep this honest at the
//     boundary so a future model change can't silently invalidate
//     the constraint.
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY
// env vars aren't set.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/recurring/models/recurring_transaction.dart';
import 'package:mybudget/features/recurring/repositories/recurring_transactions_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('RecurringTransactionsRepository (integration)', () {
    late Harness harness;
    late RecurringTransactionsRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'recurring');
      repo = RecurringTransactionsRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    test(
      'create persists every field and returns the canonical row',
      () async {
        final row = await repo.create(
          householdId: harness.householdId,
          accountId: harness.accountId,
          amountCents: -999,
          description: 'Spotify',
          merchant: 'SPOTIFY USA',
          cadence: RecurrenceCadence.monthly,
          nextOccurrenceDate: DateTime.utc(2026, 6, 1),
          createdBy: harness.userId,
        );

        expect(row.id, isNotEmpty);
        expect(row.householdId, harness.householdId);
        expect(row.accountId, harness.accountId);
        expect(row.amountCents, -999);
        expect(row.description, 'Spotify');
        expect(row.merchant, 'SPOTIFY USA');
        expect(row.cadence, RecurrenceCadence.monthly);
        // DATE columns deserialise as naive local-time DateTimes, so
        // compare on the YYYY-MM-DD prefix — that's what actually
        // round-trips through the wire and survives a Postgres DATE.
        expect(
          row.nextOccurrenceDate.toIso8601String().substring(0, 10),
          '2026-06-01',
        );
        expect(
          row.isActive,
          isTrue,
          reason: 'is_active must default to true at the DB level — '
              'a freshly created rule should start emitting.',
        );
        expect(row.lastEmittedAt, isNull);
        expect(row.skippedUntilDate, isNull);
      },
      skip: reason,
    );

    test(
      'fetchAll orders by next_occurrence_date ascending',
      () async {
        // Three rules dated June 5 / June 1 / June 10 — the
        // returned list must be June 1, June 5, June 10.
        await repo.create(
          householdId: harness.householdId,
          accountId: harness.accountId,
          amountCents: -100,
          description: 'mid',
          cadence: RecurrenceCadence.monthly,
          nextOccurrenceDate: DateTime.utc(2026, 6, 5),
          createdBy: harness.userId,
        );
        await repo.create(
          householdId: harness.householdId,
          accountId: harness.accountId,
          amountCents: -200,
          description: 'earliest',
          cadence: RecurrenceCadence.monthly,
          nextOccurrenceDate: DateTime.utc(2026, 6, 1),
          createdBy: harness.userId,
        );
        await repo.create(
          householdId: harness.householdId,
          accountId: harness.accountId,
          amountCents: -300,
          description: 'latest',
          cadence: RecurrenceCadence.monthly,
          nextOccurrenceDate: DateTime.utc(2026, 6, 10),
          createdBy: harness.userId,
        );

        final all = await repo.fetchAll(harness.householdId);
        // Filter to the rules we just added by description so prior
        // tests in this group can't pollute the assertion.
        final ours = all
            .where(
              (r) => ['earliest', 'mid', 'latest'].contains(r.description),
            )
            .toList();
        expect(
          ours.map((r) => r.description),
          ['earliest', 'mid', 'latest'],
          reason: 'soonest-due rule must come first — that\'s what '
              'the future UI wants to surface at the top.',
        );
      },
      skip: reason,
    );

    test(
      'update touches only the fields explicitly passed',
      () async {
        final initial = await repo.create(
          householdId: harness.householdId,
          accountId: harness.accountId,
          amountCents: -500,
          description: 'before',
          merchant: 'OLD MERCHANT',
          cadence: RecurrenceCadence.monthly,
          nextOccurrenceDate: DateTime.utc(2026, 6, 15),
          createdBy: harness.userId,
        );

        // Update just description. Merchant, cadence, amount,
        // next_occurrence_date must all survive untouched.
        final updated = await repo.update(
          id: initial.id,
          description: 'after',
        );

        expect(updated.description, 'after');
        expect(
          updated.merchant,
          'OLD MERCHANT',
          reason: 'unspecified fields must NOT be overwritten — the '
              '`?` null-aware marker pattern in the repo body relies '
              'on this contract.',
        );
        expect(updated.amountCents, -500);
        expect(updated.cadence, RecurrenceCadence.monthly);
        expect(
          updated.nextOccurrenceDate.toIso8601String().substring(0, 10),
          '2026-06-15',
        );
      },
      skip: reason,
    );

    test(
      'skippedUntilDate set-vs-clear asymmetry: passing null in '
      'update does NOT clear; clearSkippedUntil does',
      () async {
        // The asymmetry is documented in the repository: in `update`,
        // null means "don't touch this field" because that's the only
        // way to distinguish from "leave alone" when the caller is
        // editing a subset of fields. clearSkippedUntil is the
        // explicit clear path.
        final initial = await repo.create(
          householdId: harness.householdId,
          accountId: harness.accountId,
          amountCents: -750,
          description: 'paused-rule',
          cadence: RecurrenceCadence.monthly,
          nextOccurrenceDate: DateTime.utc(2026, 6, 20),
          createdBy: harness.userId,
        );

        // Set the skip via update.
        var current = await repo.update(
          id: initial.id,
          skippedUntilDate: DateTime.utc(2026, 8, 1),
        );
        expect(
          current.skippedUntilDate?.toIso8601String().substring(0, 10),
          '2026-08-01',
        );

        // Calling update with skippedUntilDate omitted (= null) must
        // NOT clear it — the existing value stays.
        current = await repo.update(id: initial.id, description: 'still paused');
        expect(
          current.skippedUntilDate?.toIso8601String().substring(0, 10),
          '2026-08-01',
          reason:
              'a follow-up edit that doesn\'t mention skippedUntilDate '
              'must leave the previously-set value intact.',
        );

        // The explicit clear path nukes it.
        await repo.clearSkippedUntil(initial.id);
        final fetched = (await repo.fetchAll(
          harness.householdId,
        )).firstWhere((r) => r.id == initial.id);
        expect(fetched.skippedUntilDate, isNull);
      },
      skip: reason,
    );

    test(
      'DB rejects amount = 0 — recurring rules with no amount are invalid',
      () async {
        // Pin the CHECK constraint from migration 031. A future model
        // change that lets a zero amount through would silently start
        // emitting useless zero-amount transactions; the DB-level
        // check is the last line of defence.
        await expectLater(
          repo.create(
            householdId: harness.householdId,
            accountId: harness.accountId,
            amountCents: 0,
            description: 'zero is invalid',
            cadence: RecurrenceCadence.monthly,
            nextOccurrenceDate: DateTime.utc(2026, 6, 1),
            createdBy: harness.userId,
          ),
          throwsA(anything),
        );
      },
      skip: reason,
    );

    test(
      'delete removes the row',
      () async {
        final row = await repo.create(
          householdId: harness.householdId,
          accountId: harness.accountId,
          amountCents: -100,
          description: 'doomed',
          cadence: RecurrenceCadence.monthly,
          nextOccurrenceDate: DateTime.utc(2026, 6, 1),
          createdBy: harness.userId,
        );
        await repo.delete(row.id);
        final all = await repo.fetchAll(harness.householdId);
        expect(all.any((r) => r.id == row.id), isFalse);
      },
      skip: reason,
    );
  });
}
