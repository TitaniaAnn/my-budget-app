// Integration tests for SettingsRepository.acceptInvite — the path
// that moves a user out of their auto-created solo household into an
// owner-created invited household. This is RLS-sensitive (auth.uid()
// drives both the email match and the membership write) and the RPC
// returns shapes the wrapper unwraps — exactly the kind of contract
// mocks can't honestly verify.
//
// Audit T3 flagged this surface as untested. Pinned here:
//
//   * happy path: matching email + unexpired + unused invite →
//     wrapper returns null (success), the user joins the new
//     household, and their solo household is cleaned up;
//   * wrong code returns the documented error string;
//   * email-mismatch invite returns the error string (someone with
//     a different email can't redeem a code addressed to another
//     user — the wrapper sees the same generic message as a
//     bad-code result so the path doesn't leak whether the code is
//     real);
//   * used invite returns the error string (can't replay).
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY
// env vars aren't set.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/settings/providers/settings_provider.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('SettingsRepository.acceptInvite (integration)', () {
    late Harness ownerHarness;
    late SettingsRepository repo;

    setUpAll(() async {
      if (reason != null) return;
      ownerHarness = await Harness.bootstrap(testTag: 'invite-owner');
      repo = SettingsRepository();
    });

    tearDownAll(() async {
      if (reason != null) return;
      // Sign back in as owner for cleanup — earlier tests sign out
      // / sign in as the invitee.
      await ownerHarness.client.auth.signInWithPassword(
        email: ownerHarness.email,
        password: Harness.testPassword,
      );
      await ownerHarness.dispose();
    });

    /// Sign-in helpers — the shared Supabase client's session is
    /// global, so each test that wants the invitee perspective has
    /// to sign in as them explicitly. Keep these short to avoid
    /// boilerplate in each test.
    Future<void> signInOwner() async {
      await ownerHarness.client.auth.signInWithPassword(
        email: ownerHarness.email,
        password: Harness.testPassword,
      );
    }

    Future<void> signInAs(String email) async {
      await ownerHarness.client.auth.signInWithPassword(
        email: email,
        password: Harness.testPassword,
      );
    }

    /// Creates an invite for [inviteeEmail] in the owner's household
    /// and returns the 8-char code. Caller must be signed in as the
    /// owner before invoking.
    Future<String> createInviteForEmail(String inviteeEmail) async {
      final code = await ownerHarness.client.rpc(
        'create_invite',
        params: {
          'p_household_id': ownerHarness.householdId,
          'p_email': inviteeEmail,
          'p_role': 'partner',
        },
      );
      return code as String;
    }

    test('happy path: matching email + unused + unexpired invite returns '
        'null and the invitee joins the new household', () async {
      // Bootstrap an invitee (their bootstrap signs them in
      // immediately; we'll capture the email then switch back to
      // the owner to create an invite addressed to them).
      final invitee = await Harness.bootstrap(testTag: 'invite-happy');
      final inviteeEmail = invitee.email;
      final inviteeUserId = invitee.userId;

      await signInOwner();
      final code = await createInviteForEmail(inviteeEmail);

      // Sign back in as the invitee and redeem.
      await signInAs(inviteeEmail);
      final err = await repo.acceptInvite(code);

      expect(
        err,
        isNull,
        reason:
            'wrapper returns null on success; an error string '
            'would mean the RPC reported a problem the test should '
            'see (most commonly: clock skew, RLS mis-scope, or '
            'the email match failing).',
      );

      // Confirm the invitee is now in the owner's household. RLS
      // gates SELECT on household_members to the caller's own
      // memberships, so this query as the invitee returns the new
      // row.
      final rows = await ownerHarness.client
          .from('household_members')
          .select('household_id, role')
          .eq('user_id', inviteeUserId);
      expect(rows, hasLength(1));
      expect(
        rows[0]['household_id'],
        ownerHarness.householdId,
        reason:
            'the invitee must be moved INTO the owner\'s '
            'household, not just added on top of their solo one.',
      );
      expect(rows[0]['role'], 'partner');
    }, skip: reason);

    test('wrong code returns the documented error string', () async {
      // The RPC's contract surfaces a structured `{error: "..."}`
      // result rather than raising. The wrapper unwraps that into
      // a non-null String. UI tests rely on this shape (the
      // settings sheet shows the error directly).
      final invitee = await Harness.bootstrap(testTag: 'invite-bad-code');
      await signInAs(invitee.email);

      final err = await repo.acceptInvite('NOTREAL1');

      expect(err, isNotNull);
      expect(
        err,
        contains('Invalid or expired'),
        reason:
            'the error message string is the public contract — '
            'the settings UI displays it verbatim. A change to '
            'the wording should be intentional.',
      );
    }, skip: reason);

    test(
      'email mismatch returns the same error (no information leak)',
      () async {
        // Owner creates an invite for one email; a DIFFERENT user
        // tries to redeem it. The RPC returns the same generic
        // error as a bad code — by design, the function shouldn't
        // confirm whether a code exists for someone else's email
        // (would let an attacker probe the address book).
        await signInOwner();
        final code = await createInviteForEmail('someone-else@example.test');

        final attacker = await Harness.bootstrap(testTag: 'invite-attacker');
        await signInAs(attacker.email);

        final err = await repo.acceptInvite(code);

        expect(err, isNotNull);
        expect(
          err,
          contains('Invalid or expired'),
          reason:
              'an email-mismatched invite must return the SAME '
              'generic error as a non-existent code. Otherwise a '
              'caller could discriminate by error message and probe '
              'which emails have been invited.',
        );
      },
      skip: reason,
    );

    test(
      'used invite returns the error string on the second attempt',
      () async {
        // First redemption succeeds; the second sees used_at IS NOT
        // NULL and the WHERE clause filters it out → "Invalid or
        // expired" branch fires.
        final invitee = await Harness.bootstrap(testTag: 'invite-reuse');
        await signInOwner();
        final code = await createInviteForEmail(invitee.email);

        await signInAs(invitee.email);
        final first = await repo.acceptInvite(code);
        expect(first, isNull, reason: 'sanity: first redemption works');

        // Second attempt with the same code from the same user (the
        // realistic re-press of the "Join" button after the first
        // press succeeded).
        final second = await repo.acceptInvite(code);
        expect(
          second,
          isNotNull,
          reason:
              'used_at IS NULL gate must filter consumed invites — '
              'otherwise a re-pressed button could double-move the '
              'user or write a duplicate membership row.',
        );
      },
      skip: reason,
    );
  });
}
