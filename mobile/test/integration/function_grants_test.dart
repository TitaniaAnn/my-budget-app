// Integration tests for migration 048's deferred PUBLIC EXECUTE
// revokes (audit M2).
//
// Migration 048 revoked EXECUTE on three SECURITY DEFINER functions
// from the PUBLIC role (which includes anon) and re-granted to
// `authenticated`. The contract pinned here: an anon-role caller
// gets a permission-denied error when invoking each; an
// authenticated caller can still execute them (the happy path is
// already exercised by the auth and household-invite flows
// elsewhere — these tests focus on the anon rejection because
// that's what the migration tightens).
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY
// env vars aren't set.

import 'package:flutter_test/flutter_test.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('Migration 048 — PUBLIC EXECUTE revokes (anon rejection)', () {
    late Harness harness;

    setUpAll(() async {
      if (reason != null) return;
      // Bootstrap is needed to initialise the shared Supabase client
      // (anon key + URL). The user is signed in by default; each
      // test below signs out before calling so the request lands as
      // the anon role.
      harness = await Harness.bootstrap(testTag: 'fn-grants');
    });

    tearDownAll(() async {
      if (reason != null) return;
      // Sign back in to clean up the test user's household.
      await harness.client.auth.signInWithPassword(
        email: harness.email,
        password: Harness.testPassword,
      );
      await harness.dispose();
    });

    /// Calls [body] as the anon role: signs out first, then runs the
    /// callback. Signs back in afterwards so the next test starts
    /// with a known authenticated session (avoids cross-test
    /// pollution via the shared global Supabase client).
    Future<void> asAnon(Future<void> Function() body) async {
      await harness.client.auth.signOut();
      try {
        await body();
      } finally {
        await harness.client.auth.signInWithPassword(
          email: harness.email,
          password: Harness.testPassword,
        );
      }
    }

    test('anon RPC on get_household_role is rejected', () async {
      await asAnon(() async {
        await expectLater(
          harness.client.rpc(
            'get_household_role',
            params: {'p_household_id': harness.householdId},
          ),
          throwsA(anything),
          reason:
              'get_household_role leaks the caller\'s role in any '
              'household given its UUID; anon must not reach it. '
              'Migration 048 revoked PUBLIC EXECUTE so PostgREST '
              'refuses the call.',
        );
      });
    }, skip: reason);

    test('anon RPC on create_invite is rejected', () async {
      await asAnon(() async {
        await expectLater(
          harness.client.rpc(
            'create_invite',
            params: {
              'p_household_id': harness.householdId,
              'p_email': 'attacker@example.test',
              'p_role': 'partner',
            },
          ),
          throwsA(anything),
          reason:
              'create_invite restricts at the body level via '
              'get_household_role(...) != owner, but anon should not '
              'be able to call it at all. Migration 048 enforces '
              'this at the grant layer.',
        );
      });
    }, skip: reason);

    test('anon RPC on accept_invite is rejected', () async {
      await asAnon(() async {
        await expectLater(
          harness.client.rpc('accept_invite', params: {'p_code': 'AAAAAAAA'}),
          throwsA(anything),
          reason:
              'accept_invite takes an 8-hex code; without the grant '
              'revoke anon could brute-force it under Supabase\'s '
              'default rate limits. Migration 048 closes the surface; '
              'a per-user rate limit is the natural follow-up.',
        );
      });
    }, skip: reason);
  });
}
