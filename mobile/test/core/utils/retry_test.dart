// Pin the retryTransient contract — which shapes retry, which
// shapes fail through immediately, how many attempts the backoff
// allows. The cheap-shape audit-L3 wrapper trades a few hundred
// milliseconds of added worst-case latency for visibility into
// transient blips; the boundary between "transient" and "real"
// is what these tests lock in.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/utils/retry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('retryTransient', () {
    test('returns the value on first success without retrying', () async {
      var calls = 0;
      final result = await retryTransient(() async {
        calls += 1;
        return 42;
      });
      expect(result, 42);
      expect(calls, 1);
    });

    test(
      'retries SocketException up to maxAttempts then rethrows',
      () async {
        var calls = 0;
        await expectLater(
          () => retryTransient(
            () async {
              calls += 1;
              throw const SocketException('connection reset');
            },
            initialBackoff: Duration.zero,
          ),
          throwsA(isA<SocketException>()),
        );
        expect(calls, 3, reason: 'default maxAttempts is 3');
      },
    );

    test('retries TimeoutException then rethrows', () async {
      var calls = 0;
      await expectLater(
        () => retryTransient(
          () async {
            calls += 1;
            throw TimeoutException('slow API');
          },
          initialBackoff: Duration.zero,
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(calls, 3);
    });

    test('succeeds on a retry after one transient failure', () async {
      var calls = 0;
      final result = await retryTransient(() async {
        calls += 1;
        if (calls == 1) throw const SocketException('blip');
        return 'ok';
      }, initialBackoff: Duration.zero);
      expect(result, 'ok');
      expect(calls, 2);
    });

    test(
      'fails through on non-transient errors WITHOUT retrying',
      () async {
        // RLS / CHECK / auth errors won't change on retry; fail fast
        // so the user sees the real error.
        var calls = 0;
        await expectLater(
          () => retryTransient(
            () async {
              calls += 1;
              throw const PostgrestException(
                message: 'permission denied for table accounts',
                code: '42501',
              );
            },
            initialBackoff: Duration.zero,
          ),
          throwsA(isA<PostgrestException>()),
        );
        expect(calls, 1, reason: 'RLS denial must not retry');
      },
    );

    test('retries PostgREST 5xx-shaped codes', () async {
      var calls = 0;
      final result = await retryTransient(
        () async {
          calls += 1;
          if (calls == 1) {
            throw const PostgrestException(
              message: 'upstream timed out',
              code: 'PGRST504',
            );
          }
          return 'recovered';
        },
        initialBackoff: Duration.zero,
      );
      expect(result, 'recovered');
      expect(calls, 2);
    });

    test(
      'respects custom maxAttempts',
      () async {
        var calls = 0;
        await expectLater(
          () => retryTransient(
            () async {
              calls += 1;
              throw const SocketException('blip');
            },
            maxAttempts: 5,
            initialBackoff: Duration.zero,
          ),
          throwsA(isA<SocketException>()),
        );
        expect(calls, 5);
      },
    );
  });
}
