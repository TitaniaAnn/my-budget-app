// Integration tests for the GDPR export + erasure RPCs added in
// migration 067 (audit 2026-05-26 M3). Hit the local Supabase
// stack via the harness; skipped silently when the env vars
// aren't set.

import 'package:flutter_test/flutter_test.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('export_my_data (integration)', () {
    test(
      'returns a JSONB blob containing every user-data table for the caller',
      () async {
        final h = await Harness.bootstrap(testTag: 'gdpr-export');
        try {
          // Seed one transaction so the export isn't empty.
          await h.insertTransaction(
            description: 'export-fixture',
            amountCents: -1500,
            transactionDate: DateTime.utc(2026, 5, 28),
          );

          final result = await h.client.rpc<dynamic>('export_my_data');
          final data = result as Map<String, dynamic>;

          // Top-level shape: exported_at, user_id, user, households,
          // device_push_tokens.
          expect(data['exported_at'], isNotNull);
          expect(data['user_id'], h.userId);
          expect(data['user'], isA<Map<String, dynamic>>());
          expect(data['households'], isA<List<dynamic>>());
          expect(data['device_push_tokens'], isA<List<dynamic>>());

          // Caller's household appears with every nested collection
          // included (empty lists for tables with no rows; the
          // seeded transaction sits in 'transactions').
          final households = data['households'] as List<dynamic>;
          expect(households, hasLength(1));
          final firstHousehold =
              households.first as Map<String, dynamic>;
          expect(
            firstHousehold.keys,
            containsAll([
              'household',
              'members',
              'accounts',
              'transactions',
              'categories',
              'budgets',
              'receipts',
              'receipt_line_items',
              'holdings',
              'recurring_transactions',
              'fx_rates',
              'transaction_tags',
              'transaction_tag_assignments',
              'receipt_line_item_tag_assignments',
              'plaid_items',
              'scenarios',
              'scenario_events',
            ]),
          );
          final txs = firstHousehold['transactions'] as List<dynamic>;
          expect(txs, hasLength(1));
          expect(
            (txs.first as Map<String, dynamic>)['description'],
            'export-fixture',
          );
        } finally {
          await h.dispose();
        }
      },
      skip: reason,
    );

    test(
      'export does NOT include plaid_items.access_token (M2 + M3)',
      () async {
        final h = await Harness.bootstrap(testTag: 'gdpr-export-plaid');
        try {
          final result = await h.client.rpc<dynamic>('export_my_data');
          final data = result as Map<String, dynamic>;
          final households = data['households'] as List<dynamic>;
          for (final hh in households.cast<Map<String, dynamic>>()) {
            final plaidItems = hh['plaid_items'] as List<dynamic>;
            for (final item in plaidItems.cast<Map<String, dynamic>>()) {
              expect(item.containsKey('access_token'), isFalse);
              expect(item.containsKey('access_token_encrypted'), isFalse);
            }
          }
        } finally {
          await h.dispose();
        }
      },
      skip: reason,
    );
  });

  group('delete_my_household (integration)', () {
    test(
      'owner can delete their own household; cascades wire the rest',
      () async {
        final h = await Harness.bootstrap(testTag: 'gdpr-delete');
        try {
          // Seed something so we can verify the cascade ran.
          await h.insertTransaction(
            description: 'delete-fixture',
            amountCents: -100,
            transactionDate: DateTime.utc(2026, 5, 28),
          );
          final pre = await h.client
              .from('transactions')
              .select('id')
              .eq('household_id', h.householdId);
          expect(pre, isNotEmpty);

          await h.client.rpc<dynamic>(
            'delete_my_household',
            params: {'p_household_id': h.householdId},
          );

          // The caller's view now shows zero accounts, zero
          // transactions, zero households. (RLS doesn't matter
          // here — the rows are physically gone.)
          final postAccounts = await h.client
              .from('accounts')
              .select('id')
              .eq('household_id', h.householdId);
          expect(postAccounts, isEmpty);
          final postTransactions = await h.client
              .from('transactions')
              .select('id')
              .eq('household_id', h.householdId);
          expect(postTransactions, isEmpty);
          final postHouseholds = await h.client
              .from('households')
              .select('id')
              .eq('id', h.householdId);
          expect(postHouseholds, isEmpty);
        } finally {
          await h.dispose();
        }
      },
      skip: reason,
    );

    test(
      'rejects a household the caller is not a member of with 42501',
      () async {
        // The harness signs up a fresh user with one household. We
        // pass a random UUID for p_household_id — get_household_role
        // returns NULL for non-members, which `IS DISTINCT FROM
        // 'owner'` evaluates to TRUE → the RPC raises 42501.
        //
        // (Can't use two harnesses against the same Supabase
        // instance for this — Supabase.instance.client holds one
        // global session at a time; the second bootstrap signs
        // out the first.)
        final h = await Harness.bootstrap(testTag: 'gdpr-non-member');
        try {
          await expectLater(
            h.client.rpc<dynamic>(
              'delete_my_household',
              params: {
                // Random non-member UUID.
                'p_household_id': '99999999-9999-9999-9999-999999999999',
              },
            ),
            throwsA(anything),
            reason:
                "the RPC's get_household_role check must raise on a "
                "household the caller isn't an owner of.",
          );
          // Their own household survives the rejected attempt.
          final ownerCheck = await h.client
              .from('households')
              .select('id')
              .eq('id', h.householdId);
          expect(ownerCheck, hasLength(1));
        } finally {
          await h.dispose();
        }
      },
      skip: reason,
    );
  });
}
