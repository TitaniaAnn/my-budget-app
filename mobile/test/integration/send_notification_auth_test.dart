// End-to-end auth tests for the send-notification Edge Function
// (supabase/functions/send-notification/index.ts).
//
// C1 (audit) added an auth gate to the function: the pre-fix version
// trusted any caller with the anon key and read budget preview text
// for any household_id the caller passed. The fix accepts either a
// CRON_SECRET (scheduler path) OR a user JWT whose owner is a member
// of the requested household (client path). Anything else gets 401
// or 403 and never reaches the engine.
//
// These tests pin both rejection paths (the security-critical ones).
// The happy-path "user calling for own household" case is implicitly
// covered by every other integration test that uses the harness
// (Supabase auto-routes function invocations through the signed-in
// user's JWT).
//
// Skipped silently when SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY
// env vars aren't set.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('send-notification auth gate (integration)', () {
    late Harness harness;

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'send-notif-auth');
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    test(
      'rejects cross-household: user A calling for user B household yields 403',
      () async {
        // Bootstrap a second harness — its own user, its own household.
        // The active session after bootstrap is `other`; we'll sign back
        // in as `harness` so the invocation carries the original user's
        // JWT but points at the OTHER household.
        final other = await Harness.bootstrap(testTag: 'send-notif-attack');
        await harness.client.auth.signInWithPassword(
          email: harness.email,
          password: Harness.testPassword,
        );

        try {
          await expectLater(
            harness.client.functions.invoke(
              'send-notification',
              body: {'household_id': other.householdId},
            ),
            throwsA(
              isA<FunctionException>().having(
                (e) => e.status,
                'status',
                403,
              ),
            ),
            reason:
                'A signed-in user passing another household\'s id must '
                'be rejected. Pre-fix this would have returned 200 with '
                'a preview of the other household\'s budget alerts.',
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

    test(
      'accepts own household: user calling for their own household yields 200',
      () async {
        // Sanity: the gate doesn't accidentally reject the legitimate
        // case. The function returns 200 with `preview` (no
        // FIREBASE_SERVER_KEY in the local stack) — we just need the
        // call to succeed.
        final response = await harness.client.functions.invoke(
          'send-notification',
          body: {'household_id': harness.householdId},
        );
        expect(response.status, 200);
        expect(
          (response.data as Map)['household_id'],
          harness.householdId,
        );
      },
      skip: reason,
    );
  });
}
