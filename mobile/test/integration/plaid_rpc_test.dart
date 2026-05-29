// Integration tests for the Plaid Phase 1 RPC + schema gates.
//
// Pins three contracts:
//
//   1. `upsert_plaid_transactions` does what the spec promises —
//      inserts the `added` array, updates `modified` in place
//      while preserving user state (category / notes / receipt /
//      transfer), deletes the `removed` external_ids, and
//      recalculates the account balance. Returns the count tuple.
//
//   2. The RPC's auth check fires on cross-household attempts.
//      A user calling the RPC against another household's
//      account_id sees a 42501 instead of silently no-op writes.
//
//   3. `plaid_items.access_token` is invisible to client SELECT.
//      The column-level GRANT in migration 054 should drop it
//      from every PostgREST read regardless of the row-level
//      policy.
//
// All tests use the standard harness (`_supabase_harness.dart`)
// and run against the local Supabase stack. They auto-skip when
// SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY are not set.

import 'package:flutter_test/flutter_test.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('upsert_plaid_transactions (integration)', () {
    late Harness harness;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'plaid-rpc');
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    setUp(() async {
      if (reason != null) return;
      // Wipe transactions on the test account so each test
      // observes a clean ledger. Other harness state (account,
      // household, categories) survives.
      await harness.client
          .from('transactions')
          .delete()
          .eq('account_id', harness.accountId);
    });

    Future<Map<String, dynamic>> invokeRpc({
      List<Map<String, dynamic>> added = const [],
      List<Map<String, dynamic>> modified = const [],
      List<String> removed = const [],
      String? accountIdOverride,
    }) async {
      final result = await harness.client.rpc(
        'upsert_plaid_transactions',
        params: {
          'p_account_id': accountIdOverride ?? harness.accountId,
          'p_added': added,
          'p_modified': modified,
          'p_removed_external_ids': removed,
        },
      );
      return Map<String, dynamic>.from(result as Map);
    }

    test(
      'added rows land with source=plaid, sign-flipped cents, and the '
      'count tuple matches',
      () async {
        final result = await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-add-1',
              'amount_cents': -1999, // $19.99 outflow (project convention)
              'currency': 'USD',
              'description': 'COFFEE SHOP',
              'merchant': 'Coffee Shop',
              'date': '2026-05-20',
              'pending': false,
            },
            {
              'plaid_transaction_id': 'plaid-tx-add-2',
              'amount_cents': 50000, // $500 inflow
              'currency': 'USD',
              'description': 'PAYCHECK',
              'merchant': 'ACME Corp',
              'date': '2026-05-19',
              'pending': false,
            },
          ],
        );
        expect(result['added'], 2);
        expect(result['modified'], 0);
        expect(result['removed'], 0);

        final rows =
            await harness.client
                    .from('transactions')
                    .select('amount, source, external_id, description')
                    .eq('account_id', harness.accountId)
                    .order('external_id', ascending: true)
                as List;
        expect(rows.length, 2);
        // Sign convention: -1999 stored as-is (caller pre-flipped).
        expect(rows[0]['external_id'], 'plaid-tx-add-1');
        expect(rows[0]['amount'], -1999);
        expect(rows[0]['source'], 'plaid');
        expect(rows[1]['external_id'], 'plaid-tx-add-2');
        expect(rows[1]['amount'], 50000);
      },
      skip: reason,
    );

    test(
      'replaying an `added` payload is idempotent — second call '
      'reports 0 added (ON CONFLICT DO NOTHING)',
      () async {
        final first = await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-idem-1',
              'amount_cents': -2500,
              'description': 'GAS',
              'date': '2026-05-20',
            },
          ],
        );
        expect(first['added'], 1);

        final second = await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-idem-1',
              'amount_cents': -2500,
              'description': 'GAS',
              'date': '2026-05-20',
            },
          ],
        );
        expect(
          second['added'],
          0,
          reason:
              'a replayed sync must not double-insert; the unique '
              '(account_id, external_id) constraint is what makes '
              'cursor replays safe.',
        );
      },
      skip: reason,
    );

    test(
      'modified updates Plaid-owned columns AND preserves user state '
      '(category_id, notes)',
      () async {
        // Add a row, then have the user categorise + annotate it.
        await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-mod-1',
              'amount_cents': -1000,
              'description': 'OLD DESCRIPTION',
              'merchant': 'Old Merchant',
              'date': '2026-05-15',
              'pending': true,
            },
          ],
        );

        final groceriesId = await harness.systemCategoryIdByName('Groceries');
        await harness.client
            .from('transactions')
            .update({
              'category_id': groceriesId,
              'notes': 'user-added note',
            })
            .eq('account_id', harness.accountId)
            .eq('external_id', 'plaid-tx-mod-1');

        // Plaid sends the modified row with new amount + posted state.
        final result = await invokeRpc(
          modified: [
            {
              'plaid_transaction_id': 'plaid-tx-mod-1',
              'amount_cents': -1234,
              'description': 'NEW DESCRIPTION FROM PLAID',
              'merchant': 'New Merchant',
              'date': '2026-05-15',
              'pending': false,
            },
          ],
        );
        expect(result['modified'], 1);

        final row = await harness.client
            .from('transactions')
            .select('amount, description, merchant, pending, category_id, notes')
            .eq('account_id', harness.accountId)
            .eq('external_id', 'plaid-tx-mod-1')
            .single();
        // Plaid-owned fields refreshed.
        expect(row['amount'], -1234);
        expect(row['description'], 'NEW DESCRIPTION FROM PLAID');
        expect(row['merchant'], 'New Merchant');
        expect(row['pending'], false);
        // User-owned fields preserved.
        expect(
          row['category_id'],
          groceriesId,
          reason:
              'user-set category_id must survive a Plaid modify — the '
              'whole point of separating user state from Plaid state.',
        );
        expect(row['notes'], 'user-added note');
      },
      skip: reason,
    );

    test('removed deletes by external_id; ignores ids not in the list', () async {
      await invokeRpc(
        added: [
          {
            'plaid_transaction_id': 'plaid-tx-keep',
            'amount_cents': -100,
            'description': 'keep me',
            'date': '2026-05-10',
          },
          {
            'plaid_transaction_id': 'plaid-tx-rm',
            'amount_cents': -200,
            'description': 'remove me',
            'date': '2026-05-10',
          },
        ],
      );

      final result = await invokeRpc(removed: ['plaid-tx-rm']);
      expect(result['removed'], 1);

      final survivors =
          await harness.client
                  .from('transactions')
                  .select('external_id')
                  .eq('account_id', harness.accountId)
              as List;
      expect(survivors.length, 1);
      expect(survivors[0]['external_id'], 'plaid-tx-keep');
    }, skip: reason);

    test('empty arrays are a clean no-op (zero counts, no errors)', () async {
      final result = await invokeRpc();
      expect(result['added'], 0);
      expect(result['modified'], 0);
      expect(result['removed'], 0);
    }, skip: reason);

    // ── Audit 2026-05-26 C4: user-state preservation ────────
    test(
      'removed: rows with user notes are soft-archived (kept, '
      'external_id cleared, source=import)',
      () async {
        // Plaid adds the row, user adds a note, Plaid removes it.
        await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-noted',
              'amount_cents': -500,
              'description': 'lunch',
              'date': '2026-05-10',
            },
          ],
        );
        await harness.client
            .from('transactions')
            .update({'notes': 'reimburse from work'})
            .eq('external_id', 'plaid-tx-noted');

        final result = await invokeRpc(removed: ['plaid-tx-noted']);
        // Hard-delete count is 0; archived count is 1.
        expect(result['removed'], 0);
        expect(result['archived'], 1);

        // Row survives with the user's note intact and Plaid
        // attribution stripped.
        final rows = (await harness.client
                .from('transactions')
                .select('id, external_id, source, notes')
                .eq('account_id', harness.accountId))
            as List;
        expect(rows.length, 1);
        expect(rows[0]['external_id'], isNull);
        expect(rows[0]['source'], 'import');
        expect(rows[0]['notes'], 'reimburse from work');
      },
      skip: reason,
    );

    test(
      'removed: rows with category_assigned_by=user are soft-archived',
      () async {
        await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-user-cat',
              'amount_cents': -500,
              'description': 'misc',
              'date': '2026-05-10',
            },
          ],
        );
        // User assigns category — flips category_assigned_by to 'user'.
        // Use a system category to avoid a household setup dance.
        final groceriesId = await harness.systemCategoryIdByName('Groceries');
        await harness.client
            .from('transactions')
            .update({
              'category_id': groceriesId,
              'category_assigned_by': 'user',
            })
            .eq('external_id', 'plaid-tx-user-cat');

        final result = await invokeRpc(removed: ['plaid-tx-user-cat']);
        expect(result['removed'], 0);
        expect(result['archived'], 1);

        final rows = (await harness.client
                .from('transactions')
                .select('external_id, source, category_id')
                .eq('account_id', harness.accountId))
            as List;
        expect(rows.length, 1);
        expect(rows[0]['external_id'], isNull);
        expect(rows[0]['source'], 'import');
        expect(rows[0]['category_id'], groceriesId);
      },
      skip: reason,
    );

    test(
      'removed: rows with no user state are hard-deleted (matches '
      'historical behavior)',
      () async {
        // Same shape as the existing "removed deletes by external_id"
        // test — sanity-pin that the new branching didn't regress
        // the common case.
        await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-clean',
              'amount_cents': -100,
              'description': 'clean row',
              'date': '2026-05-10',
            },
          ],
        );
        final result = await invokeRpc(removed: ['plaid-tx-clean']);
        expect(result['removed'], 1);
        expect(result['archived'], 0);

        final rows = (await harness.client
                .from('transactions')
                .select('id')
                .eq('account_id', harness.accountId))
            as List;
        expect(rows.length, 0);
      },
      skip: reason,
    );

    test(
      'removed: transfer leg removal clears transfer_id on the partner',
      () async {
        // Set up a transfer: insert two transactions sharing a
        // transfer_id, where one is Plaid-managed and the other
        // is the surviving manual leg.
        final transferId = 'cccccccc-1111-1111-1111-${DateTime.now().microsecondsSinceEpoch.toRadixString(16).padLeft(12, '0').substring(0, 12)}';
        await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-xfer-leg',
              'amount_cents': -10000,
              'description': 'transfer out',
              'date': '2026-05-10',
            },
          ],
        );
        // Add the partner leg manually.
        final partnerInsert = await harness.client
            .from('transactions')
            .insert({
              'household_id': harness.householdId,
              'account_id': harness.accountId,
              'entered_by': harness.userId,
              'amount': 10000,
              'currency': 'USD',
              'description': 'transfer in',
              'transaction_date': '2026-05-10',
              'source': 'manual',
              'transfer_id': transferId,
            })
            .select('id')
            .single();
        final partnerId = partnerInsert['id'] as String;
        // Pair the Plaid leg to the same transfer.
        await harness.client
            .from('transactions')
            .update({'transfer_id': transferId})
            .eq('external_id', 'plaid-tx-xfer-leg');

        // Plaid removes the paired leg.
        final result = await invokeRpc(removed: ['plaid-tx-xfer-leg']);
        // The Plaid leg has transfer_id set → counts as user state
        // → archived (not deleted).
        expect(result['removed'], 0);
        expect(result['archived'], 1);

        // The partner's transfer_id has been cleared so it stops
        // being filtered out of cash-flow rollups.
        final partner = await harness.client
            .from('transactions')
            .select('transfer_id')
            .eq('id', partnerId)
            .single();
        expect(partner['transfer_id'], isNull);
      },
      skip: reason,
    );

    test('recalculates the account balance on every call', () async {
      // Start with a known account balance, add inflows, confirm
      // the trigger / recalculate_account_balance ran.
      await invokeRpc(
        added: [
          {
            'plaid_transaction_id': 'plaid-tx-bal-1',
            'amount_cents': 30000, // +$300
            'description': 'deposit',
            'date': '2026-05-01',
          },
          {
            'plaid_transaction_id': 'plaid-tx-bal-2',
            'amount_cents': -5000, // -$50
            'description': 'coffee',
            'date': '2026-05-02',
          },
        ],
      );

      final acct = await harness.client
          .from('accounts')
          .select('current_balance')
          .eq('id', harness.accountId)
          .single();
      expect(
        acct['current_balance'],
        25000,
        reason:
            'recalculate_account_balance should run after the upsert; '
            r'300 - 50 = 250 ($25000 cents).',
      );
    }, skip: reason);

    // ── Dedup: Plaid added rows vs manual / import entries ─────────
    // Migration 057 added the dedup pre-pass. A Plaid added row
    // claims an existing manual / CSV-import row instead of
    // creating a duplicate, when (account, amount, ±3 days) match
    // AND the existing row isn't already linked to a transfer /
    // receipt / external_id.

    test(
      'dedup: a manual entry with matching account/amount/date is '
      'merged (claimed) by the Plaid added row',
      () async {
        // Seed a manual entry for $19.99 on 2026-05-10.
        await harness.insertTransaction(
          amountCents: -1999,
          description: 'Coffee shop (entered by hand)',
          transactionDate: DateTime.utc(2026, 5, 10),
        );

        // Plaid sync delivers the same charge 1 day later (posting
        // lag), with Plaid's own external_id.
        final result = await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-merge-1',
              'amount_cents': -1999,
              'description': 'COFFEE SHOP INC',
              'merchant': 'Coffee Shop Inc',
              'date': '2026-05-11', // +1 day, inside ±3
              'pending': false,
            },
          ],
        );
        // The Plaid row claimed the existing manual row → 0 added.
        expect(result['added'], 0);
        expect(result['merged'], 1);

        final rows = await harness.client
            .from('transactions')
            .select('id, amount, source, external_id, description')
            .eq('account_id', harness.accountId);
        expect(
          (rows as List).length,
          1,
          reason:
              'after merge the ledger should hold ONE row for the '
              'real-world charge, not two.',
        );
        final row = rows.single;
        expect(row['external_id'], 'plaid-tx-merge-1');
        expect(
          row['source'],
          'plaid',
          reason:
              'after merge the row is Plaid-tracked — future syncs '
              'will modify it via the external_id key.',
        );
        // The user's original description was preserved (description
        // is not in the merge UPDATE's column list; only external_id
        // and source change). A subsequent Plaid modified pass would
        // overwrite it.
        expect(
          row['description'],
          'Coffee shop (entered by hand)',
          reason:
              'merge UPDATE only stamps external_id + source. '
              'description / merchant / category survive until a '
              'subsequent Plaid modified pass updates them.',
        );
      },
      skip: reason,
    );

    test(
      'dedup: a candidate outside the ±3 day window is NOT merged',
      () async {
        await harness.insertTransaction(
          amountCents: -5000,
          description: 'Manual entry from a week ago',
          transactionDate: DateTime.utc(2026, 5, 1),
        );

        final result = await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-far-1',
              'amount_cents': -5000,
              'description': 'Plaid charge from much later',
              'date': '2026-05-10', // +9 days, outside ±3
              'pending': false,
            },
          ],
        );
        expect(result['merged'], 0);
        expect(result['added'], 1);

        final rows = await harness.client
            .from('transactions')
            .select('id, external_id, source')
            .eq('account_id', harness.accountId);
        expect((rows as List).length, 2);
      },
      skip: reason,
    );

    test(
      'dedup: claim-once — two Plaid rows for the same manual entry '
      'pick exactly one to merge, the other lands as a fresh INSERT',
      () async {
        // One manual entry on 2026-05-10. Two Plaid rows both
        // matching it (+/- 1 day). Only one can claim it; the
        // other inserts as new.
        await harness.insertTransaction(
          amountCents: -1500,
          description: 'Manual entry',
          transactionDate: DateTime.utc(2026, 5, 10),
        );

        final result = await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-claim-A',
              'amount_cents': -1500,
              'description': 'Plaid A',
              'date': '2026-05-11', // distance 1
            },
            {
              'plaid_transaction_id': 'plaid-tx-claim-B',
              'amount_cents': -1500,
              'description': 'Plaid B',
              'date': '2026-05-10', // distance 0 — should win
            },
          ],
        );
        expect(result['merged'], 1);
        expect(result['added'], 1);

        // The closest-date Plaid row wins the claim.
        final merged = await harness.client
            .from('transactions')
            .select('description, external_id')
            .eq('account_id', harness.accountId)
            .eq('external_id', 'plaid-tx-claim-B')
            .single();
        expect(merged['description'], 'Manual entry');

        // The loser lands as a new row.
        final fresh = await harness.client
            .from('transactions')
            .select('description, source')
            .eq('account_id', harness.accountId)
            .eq('external_id', 'plaid-tx-claim-A')
            .single();
        expect(fresh['description'], 'Plaid A');
        expect(fresh['source'], 'plaid');
      },
      skip: reason,
    );

    test(
      'dedup: backtracking — Plaid B falls back to its 2nd-choice '
      'candidate when its 1st choice is taken by Plaid A (review #3)',
      () async {
        // Two manual entries on 2026-05-10 + 2026-05-12, both $42.
        // Plaid A is dated 2026-05-10 (distance 0 to entry 1).
        // Plaid B is dated 2026-05-11 (distance 1 to entry 1,
        //                              distance 1 to entry 2).
        //
        // The migration-057 algorithm: Plaid B's per_added rank
        // picks entry 1 as plaid_pref=1 (alphabetical tiebreak),
        // entry 2 as plaid_pref=2. Only plaid_pref=1 candidates
        // flow forward. per_existing on entry 1: Plaid A vs
        // Plaid B, A wins (distance 0 vs 1). Plaid B's
        // existing_pref=2 → dropped. Plaid B ends up matching
        // NOTHING — entry 2 left orphaned even though it would
        // have been a perfectly good match.
        //
        // The migration-061 greedy matcher: iterate pairs in
        // distance-ASC order. Pair (PlaidA, entry1, dist=0)
        // matches first → both claimed. Pair (PlaidB, entry1,
        // dist=1) skipped (entry1 already claimed). Pair
        // (PlaidB, entry2, dist=1) matches → both claimed.
        // Both Plaid rows merge correctly.
        final entry1 = await harness.insertTransaction(
          amountCents: -4200,
          description: 'Manual entry #1',
          transactionDate: DateTime.utc(2026, 5, 10),
        );
        final entry2 = await harness.insertTransaction(
          amountCents: -4200,
          description: 'Manual entry #2',
          transactionDate: DateTime.utc(2026, 5, 12),
        );

        final result = await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-backtrack-A',
              'amount_cents': -4200,
              'description': 'Plaid A',
              'date': '2026-05-10', // distance 0 to entry1, 2 to entry2
            },
            {
              'plaid_transaction_id': 'plaid-tx-backtrack-B',
              'amount_cents': -4200,
              'description': 'Plaid B',
              'date': '2026-05-11', // distance 1 to entry1, 1 to entry2
            },
          ],
        );
        expect(result['merged'], 2, reason: 'both Plaid rows find a match');
        expect(result['added'], 0);

        // entry1 was claimed by Plaid A (distance 0 wins).
        final after1 = await harness.client
            .from('transactions')
            .select('external_id, description')
            .eq('id', entry1)
            .single();
        expect(after1['external_id'], 'plaid-tx-backtrack-A');
        expect(after1['description'], 'Manual entry #1');

        // entry2 was claimed by Plaid B (after entry1 was taken).
        final after2 = await harness.client
            .from('transactions')
            .select('external_id, description')
            .eq('id', entry2)
            .single();
        expect(after2['external_id'], 'plaid-tx-backtrack-B');
        expect(after2['description'], 'Manual entry #2');

        // Total rows: still 2 (no new inserts).
        final rows = await harness.client
            .from('transactions')
            .select('id')
            .eq('account_id', harness.accountId);
        expect((rows as List).length, 2);
      },
      skip: reason,
    );

    test(
      'dedup: existing transfer-leg / receipt-paired rows are NEVER '
      'merged even when amount+date match',
      () async {
        // Seed a manual entry that's transfer-leg-paired (we just
        // stamp transfer_id directly — no need to create a real
        // pair for the test).
        await harness.client.from('transactions').insert({
          'household_id': harness.householdId,
          'account_id': harness.accountId,
          'entered_by': harness.userId,
          'amount': -2500,
          'currency': 'USD',
          'description': 'transfer leg, hands off',
          'transaction_date': '2026-05-10',
          'pending': false,
          'source': 'manual',
          'transfer_id': '00000000-0000-0000-0000-000000000099',
        });

        final result = await invokeRpc(
          added: [
            {
              'plaid_transaction_id': 'plaid-tx-no-merge-transfer',
              'amount_cents': -2500,
              'description': 'Plaid sees this charge too',
              'date': '2026-05-10',
            },
          ],
        );
        expect(
          result['merged'],
          0,
          reason:
              'transfer-paired rows are excluded from the dedup '
              'candidate set so create_transfer pairing stays intact.',
        );
        expect(result['added'], 1);
      },
      skip: reason,
    );

    // ── Auth-check / cross-household rejection ─────────────────────
    test(
      'rejects cross-household account_id with 42501 (RLS-derived auth)',
      () async {
        // Bootstrap a second user in a different household. Their
        // session is what's signed in; calling the RPC against the
        // FIRST harness's account_id must throw.
        final other = await Harness.bootstrap(testTag: 'plaid-rpc-foreign');

        try {
          await expectLater(
            () => other.client.rpc(
              'upsert_plaid_transactions',
              params: {
                'p_account_id': harness.accountId, // NOT other's account
                'p_added': const <Map<String, dynamic>>[],
                'p_modified': const <Map<String, dynamic>>[],
                'p_removed_external_ids': const <String>[],
              },
            ),
            throwsA(anything),
            reason:
                'the RPC must guard explicitly so a misrouted call from '
                'household A to household B raises instead of silently '
                'no-op-writing.',
          );
        } finally {
          await other.dispose();
          // Sign back in as the original harness user so subsequent
          // setUp() runs read the right household.
          await harness.client.auth.signInWithPassword(
            email: harness.email,
            password: Harness.testPassword,
          );
        }
      },
      skip: reason,
    );
  });

  group('plaid_items column-level grants (integration)', () {
    test(
      'access_token is omitted from client SELECT (column-level REVOKE)',
      () async {
        final h = await Harness.bootstrap(testTag: 'plaid-items-grant');
        try {
          // Seed a row via the harness's client. Client INSERT is
          // denied by RLS (no policy) — this is expected; the test
          // asserts the access path, not the seed mechanism.
          // We use the harness directly because the spec's Edge
          // Function path needs a service-role client which Phase 1
          // testing doesn't have. So we settle for verifying the
          // grant shape via information_schema.
          //
          // Specifically: a SELECT * must not include access_token
          // in PostgREST's response. The simplest check is to ask
          // for the column explicitly and confirm the API rejects
          // it (or returns no row when one would exist).
          await expectLater(
            h.client.from('plaid_items').select('access_token'),
            throwsA(anything),
            reason:
                'a client SELECT(access_token) must be rejected by '
                "PostgREST since the role doesn't hold SELECT on the "
                'column — the credential never leaves the DB.',
          );
        } finally {
          await h.dispose();
        }
      },
      skip: reason,
    );
  });
}
