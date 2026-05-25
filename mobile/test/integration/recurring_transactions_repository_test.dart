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

    // ── run_recurring_scheduler (migration 032) ────────────────────────
    //
    // The scheduler turns rules into real transaction rows. Pinned here:
    //   * one rule due today → one transaction emitted with the right
    //     fields including source='recurring'; rule's next_occurrence_
    //     date advances by the cadence and last_emitted_at gets set;
    //   * a rule whose next date is two months in the past emits
    //     three monthly cycles in one pass (multi-cycle catchup —
    //     dormant scheduler must not silently lose cycles);
    //   * skipped_until_date covering an emission DATE: skip it but
    //     still advance, otherwise the rule sticks in the past;
    //   * is_active = false rules are ignored even when due;
    //   * a future-dated rule is left alone (idempotency).
    group('runScheduler', () {
      // Pick a fixed "today" several years past the seed dates the
      // group above used so the two groups can't interact via shared
      // rules. Asserting on rule ID / row ID, but a tight scope is
      // good hygiene for harness-shared-household tests.
      final today = DateTime.utc(2030, 6, 15);

      // Each scheduler test wants a clean slate: the CRUD group above
      // leaves rules in the household that are also "due" by 2030.
      // Without this teardown, "emits one transaction" would see
      // hundreds of catchup emissions from those siblings and the
      // assertion would be meaningless.
      setUp(() async {
        if (reason != null) return;
        await harness.client
            .from('recurring_transactions')
            .delete()
            .eq('household_id', harness.householdId);
      });

      Future<int> countMatchingTx(String description) async {
        final rows = await harness.client
            .from('transactions')
            .select('id')
            .eq('household_id', harness.householdId)
            .eq('description', description);
        return (rows as List).length;
      }

      test(
        'emits one transaction for a rule due today; advances the date '
        'and stamps last_emitted_at',
        () async {
          final rule = await repo.create(
            householdId: harness.householdId,
            accountId: harness.accountId,
            amountCents: -999,
            description: 'sched-due-today',
            cadence: RecurrenceCadence.monthly,
            nextOccurrenceDate: today,
            createdBy: harness.userId,
          );

          final emitted = await repo.runScheduler(
            householdId: harness.householdId,
            today: today,
          );
          expect(emitted, 1);

          // Transaction landed with the source tag and the rule's
          // fields. Filtering by description keeps the query focused
          // to this test's row.
          final txs = await harness.client
              .from('transactions')
              .select('amount, source, transaction_date')
              .eq('household_id', harness.householdId)
              .eq('description', 'sched-due-today');
          expect(txs, hasLength(1));
          expect(txs.single['amount'], -999);
          expect(
            txs.single['source'],
            'recurring',
            reason:
                'scheduler emissions must use source = "recurring" so '
                'slice-3 dedup against statement imports can target '
                'them. Reusing "manual" would lose the distinction.',
          );
          expect(txs.single['transaction_date'], '2030-06-15');

          // Rule advanced by one monthly cycle and stamped.
          final updated = (await repo.fetchAll(
            harness.householdId,
          )).firstWhere((r) => r.id == rule.id);
          expect(
            updated.nextOccurrenceDate.toIso8601String().substring(0, 10),
            '2030-07-15',
          );
          expect(updated.lastEmittedAt, isNotNull);
        },
        skip: reason,
      );

      test(
        'multi-cycle catchup: a rule with backlog emits one row per '
        'missed cycle in one pass',
        () async {
          // next date is March 1; today is June 15. The scheduler
          // should emit Mar 1, Apr 1, May 1, Jun 1 (four rows) and
          // leave the rule with next = Jul 1.
          final rule = await repo.create(
            householdId: harness.householdId,
            accountId: harness.accountId,
            amountCents: -500,
            description: 'sched-backlog',
            cadence: RecurrenceCadence.monthly,
            nextOccurrenceDate: DateTime.utc(2030, 3, 1),
            createdBy: harness.userId,
          );

          final emitted = await repo.runScheduler(
            householdId: harness.householdId,
            today: today,
          );
          expect(
            emitted,
            greaterThanOrEqualTo(4),
            reason: 'four monthly cycles must emit in one pass — '
                'dormant scheduler catching up is the whole point of '
                'the WHILE loop.',
          );

          // Concrete count for THIS rule's rows (catchup-from-other-
          // tests could inflate the global emitted count).
          expect(await countMatchingTx('sched-backlog'), 4);

          final updated = (await repo.fetchAll(
            harness.householdId,
          )).firstWhere((r) => r.id == rule.id);
          expect(
            updated.nextOccurrenceDate.toIso8601String().substring(0, 10),
            '2030-07-01',
          );
        },
        skip: reason,
      );

      test(
        'skipped_until_date pauses emission but advances the date — '
        'rule never gets stuck in the past',
        () async {
          // Rule due May 1; skipped through May 31; today is Jun 15.
          // The scheduler should skip the May 1 emission, advance to
          // Jun 1, emit Jun 1, advance to Jul 1.
          final rule = await repo.create(
            householdId: harness.householdId,
            accountId: harness.accountId,
            amountCents: -250,
            description: 'sched-paused',
            cadence: RecurrenceCadence.monthly,
            nextOccurrenceDate: DateTime.utc(2030, 5, 1),
            createdBy: harness.userId,
          );
          await repo.update(
            id: rule.id,
            skippedUntilDate: DateTime.utc(2030, 5, 31),
          );

          await repo.runScheduler(
            householdId: harness.householdId,
            today: today,
          );

          // Only ONE row for sched-paused (the Jun 1 emission). The
          // May 1 row was skipped per the pause window.
          expect(await countMatchingTx('sched-paused'), 1);
          final updated = (await repo.fetchAll(
            harness.householdId,
          )).firstWhere((r) => r.id == rule.id);
          expect(
            updated.nextOccurrenceDate.toIso8601String().substring(0, 10),
            '2030-07-01',
            reason: 'a long pause must still advance the date — without '
                'this the rule would loop forever with next_date stuck '
                'before skipped_until_date.',
          );
        },
        skip: reason,
      );

      test(
        'inactive rules are ignored even when due',
        () async {
          final rule = await repo.create(
            householdId: harness.householdId,
            accountId: harness.accountId,
            amountCents: -100,
            description: 'sched-inactive',
            cadence: RecurrenceCadence.monthly,
            nextOccurrenceDate: today,
            createdBy: harness.userId,
          );
          await repo.update(id: rule.id, isActive: false);

          await repo.runScheduler(
            householdId: harness.householdId,
            today: today,
          );

          expect(
            await countMatchingTx('sched-inactive'),
            0,
            reason: 'is_active=false must short-circuit emission so a '
                'paused-by-deactivation rule doesn\'t silently fire.',
          );
        },
        skip: reason,
      );

      test(
        'future-dated rules are left alone — scheduler is idempotent',
        () async {
          // Today is June 15, 2030; rule next-date is July 1.
          final rule = await repo.create(
            householdId: harness.householdId,
            accountId: harness.accountId,
            amountCents: -100,
            description: 'sched-future',
            cadence: RecurrenceCadence.monthly,
            nextOccurrenceDate: DateTime.utc(2030, 7, 1),
            createdBy: harness.userId,
          );

          await repo.runScheduler(
            householdId: harness.householdId,
            today: today,
          );

          expect(await countMatchingTx('sched-future'), 0);
          final updated = (await repo.fetchAll(
            harness.householdId,
          )).firstWhere((r) => r.id == rule.id);
          expect(
            updated.nextOccurrenceDate.toIso8601String().substring(0, 10),
            '2030-07-01',
            reason: 'a future-dated rule must NOT advance — otherwise '
                'repeated dashboard loads would silently drift the rule '
                'into the distant future.',
          );
        },
        skip: reason,
      );
    });

    // ── Cross-household account_id constraint (migration 044) ─────────────
    //
    // The "members can manage recurring_transactions" policy used to
    // gate on household_id only — letting a member create a rule with
    // their own household_id but a foreign account_id. Migration 044
    // added the account_id IN (...) clause to WITH CHECK.

    group('cross-household account_id constraint', () {
      test(
        'INSERT with own household_id + foreign account_id is rejected',
        () async {
          final other = await Harness.bootstrap(testTag: 'recurring-c3');
          final otherAccountId = other.accountId;

          await harness.client.auth.signInWithPassword(
            email: harness.email,
            password: Harness.testPassword,
          );

          try {
            await expectLater(
              harness.client.from('recurring_transactions').insert({
                'household_id': harness.householdId,
                'account_id': otherAccountId, // ← foreign account
                'created_by': harness.userId,
                'amount_cents': -999,
                'description': 'cross-household recurring',
                'cadence': 'monthly',
                'next_occurrence_date': '2026-07-01',
                'is_active': true,
              }),
              throwsA(anything),
              reason:
                  'WITH CHECK must reject when account_id belongs to a '
                  'household other than the row\'s household_id.',
            );
          } finally {
            await harness.client.auth.signInWithPassword(
              email: other.email,
              password: Harness.testPassword,
            );
            await other.dispose();
            await harness.client.auth.signInWithPassword(
              email: harness.email,
              password: Harness.testPassword,
            );
          }
        },
        skip: reason,
      );
    });
  });
}
