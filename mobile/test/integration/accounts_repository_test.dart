// Integration tests for AccountsRepository methods that depend on
// SQL semantics — the recalculateBalance path specifically, because
// migration 015's atomicity claim is exactly the kind of contract
// mocks can't honestly verify (does the RPC actually sum + write in
// one transaction?).
//
// Audit T2 flagged this surface as untested. Pinned here:
//
//   * recalculateBalance sums signed transaction amounts (debits
//     negative, credits positive) and writes the total into
//     current_balance — overrides whatever stale value was there.
//   * starting_balance is included in the sum (the RPC's contract
//     is current = starting + sum(tx), not just sum(tx)).
//   * an account with NO transactions resolves to starting_balance
//     (the SUM is NULL → coalesced to 0).
//   * recalculate is idempotent — running it twice in a row with
//     no intervening writes leaves the balance unchanged.
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY
// env vars aren't set.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/accounts/repositories/accounts_repository.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('AccountsRepository.recalculateBalance (integration)', () {
    late Harness harness;
    late AccountsRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'accts-recalc');
      repo = AccountsRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    Future<int> readBalance(String accountId) async {
      final row = await harness.client
          .from('accounts')
          .select('current_balance')
          .eq('id', accountId)
          .single();
      return row['current_balance'] as int;
    }

    Future<String> insertAccount({
      String name = 'recalc-test',
      int startingBalance = 0,
      int currentBalance = 0,
    }) async {
      final row = await harness.client
          .from('accounts')
          .insert({
            'household_id': harness.householdId,
            'owner_user_id': harness.userId,
            'name': name,
            'account_type': 'checking',
            'currency': 'USD',
            'starting_balance': startingBalance,
            'current_balance': currentBalance,
          })
          .select('id')
          .single();
      return row['id'] as String;
    }

    test('sums signed transaction amounts into current_balance '
        '(starting_balance + sum(tx))', () async {
      // Account starts at $100; transactions net -$25; expected
      // current = $75 (7500 cents). Pre-set current_balance to a
      // wrong value so we know the RPC actually overwrote it
      // rather than the assertion passing by accident.
      final accountId = await insertAccount(
        name: 'recalc-signed-sum',
        startingBalance: 10000,
        currentBalance: 999999, // bogus; recalc must overwrite
      );

      await harness.client.from('transactions').insert([
        {
          'household_id': harness.householdId,
          'account_id': accountId,
          'entered_by': harness.userId,
          'amount': -5000, // -$50
          'currency': 'USD',
          'description': 'groceries',
          'transaction_date': '2026-05-01',
          'pending': false,
          'source': 'manual',
        },
        {
          'household_id': harness.householdId,
          'account_id': accountId,
          'entered_by': harness.userId,
          'amount': 3000, // +$30
          'currency': 'USD',
          'description': 'refund',
          'transaction_date': '2026-05-02',
          'pending': false,
          'source': 'manual',
        },
        {
          'household_id': harness.householdId,
          'account_id': accountId,
          'entered_by': harness.userId,
          'amount': 500, // +$5
          'currency': 'USD',
          'description': 'cashback',
          'transaction_date': '2026-05-03',
          'pending': false,
          'source': 'manual',
        },
      ]);

      await repo.recalculateBalance(accountId);

      // starting_balance ($100) + sum(-$50, +$30, +$5) = $85.
      expect(
        await readBalance(accountId),
        8500,
        reason:
            'recalculate_account_balance must compute starting + '
            'sum(amount) and overwrite the bogus 999999 we seeded. '
            'A drift here would mean the dashboard rolls up stale '
            'numbers after an import.',
      );
    }, skip: reason);

    test('an account with no transactions resolves to starting_balance '
        '(SUM is NULL, coalesced to 0)', () async {
      // Pre-fix bug-class: if the RPC used SUM(amount) without
      // COALESCE the result would be NULL on an empty ledger and
      // current_balance would write NULL — corrupting the column
      // for every subsequent read. The contract is "no tx → just
      // starting_balance".
      final accountId = await insertAccount(
        name: 'recalc-empty',
        startingBalance: 25000, // $250
        currentBalance: -1, // bogus sentinel
      );

      await repo.recalculateBalance(accountId);

      expect(await readBalance(accountId), 25000);
    }, skip: reason);

    test(
      'recalculate is idempotent — running twice yields the same balance',
      () async {
        // The whole point of the RPC is that current_balance is a
        // pure function of starting_balance + transactions. Running
        // it twice with no intervening writes must produce the same
        // result. Catches a regression where the RPC accidentally
        // double-counted by adding to current_balance instead of
        // overwriting.
        final accountId = await insertAccount(
          name: 'recalc-idempotent',
          startingBalance: 5000,
        );
        await harness.client.from('transactions').insert({
          'household_id': harness.householdId,
          'account_id': accountId,
          'entered_by': harness.userId,
          'amount': -1500,
          'currency': 'USD',
          'description': 'tx',
          'transaction_date': '2026-05-01',
          'pending': false,
          'source': 'manual',
        });

        await repo.recalculateBalance(accountId);
        final first = await readBalance(accountId);
        await repo.recalculateBalance(accountId);
        final second = await readBalance(accountId);

        expect(first, 3500);
        expect(
          second,
          first,
          reason:
              'running recalculate twice without intervening writes '
              'must be a no-op. A drift here would double-count '
              'transactions on every refresh.',
        );
      },
      skip: reason,
    );
  });
}
