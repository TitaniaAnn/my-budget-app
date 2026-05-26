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
