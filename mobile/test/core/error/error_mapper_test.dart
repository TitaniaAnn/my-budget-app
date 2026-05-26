// Pin the error → user-facing mapping for each branch the mapper
// recognises. Each test names the wire-level shape it simulates so
// a future reader can grep for the actual error code without
// hunting through Supabase docs.
//
// The contract this enforces: every branch maps to (a) a clean
// user-facing message that never echoes raw framework jargon, and
// (b) the correct [requiresReauth] flag — flipping that flag is
// the difference between "snackbar + stay" and "snackbar + bounce
// to /login", so unit-testing it directly is the cheapest way to
// keep audit C6 honest.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/error/error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapError — ConcurrentUpdateException', () {
    test('maps to refresh-and-retry copy', () {
      // Audit H7: when the optimistic-lock filter matches zero rows
      // we throw this — the user must see a clean "refresh" prompt
      // rather than a raw `ConcurrentUpdateException` stack.
      final mapped = mapError(const ConcurrentUpdateException());
      expect(mapped.userMessage, contains('edited from another device'));
      expect(mapped.requiresReauth, isFalse);
    });
  });

  group('mapError — CategoryHasBudgetsException', () {
    test('maps to "remove the budget first" copy', () {
      // Audit D1: budgets.category_id is NOT NULL and migration 053
      // couldn't SET NULL it — the repo guards explicitly and the
      // mapper surfaces the friendly message instead of a raw 23503.
      final mapped = mapError(const CategoryHasBudgetsException());
      expect(mapped.userMessage, contains('budget'));
      expect(mapped.userMessage, contains('Remove'));
      expect(mapped.requiresReauth, isFalse);
    });
  });

  group('mapError — PostgrestException', () {
    test('PGRST301 (JWT expired) flips requiresReauth', () {
      final mapped = mapError(
        const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
      );
      expect(mapped.userMessage, contains('session expired'));
      expect(mapped.requiresReauth, isTrue);
    });

    test('42501 (RLS denial) does not flip requiresReauth', () {
      final mapped = mapError(
        const PostgrestException(
          message: 'permission denied for table accounts',
          code: '42501',
        ),
      );
      expect(mapped.userMessage, contains("don't have access"));
      expect(mapped.requiresReauth, isFalse);
    });

    test('PGRST116 (no/multiple rows) becomes "not found"', () {
      final mapped = mapError(
        const PostgrestException(
          message: 'JSON object requested, multiple (or no) rows returned',
          code: 'PGRST116',
        ),
      );
      expect(mapped.userMessage, contains("couldn't find"));
      expect(mapped.requiresReauth, isFalse);
    });

    test('23505 (unique violation) becomes "already exists"', () {
      final mapped = mapError(
        const PostgrestException(
          message: 'duplicate key value violates unique constraint …',
          code: '23505',
        ),
      );
      expect(mapped.userMessage, contains('already exists'));
    });

    test('23503 (FK violation) suggests refresh', () {
      final mapped = mapError(
        const PostgrestException(
          message: 'insert or update on table … violates foreign key',
          code: '23503',
        ),
      );
      expect(mapped.userMessage.toLowerCase(), contains('refresh'));
    });

    test('unknown Postgrest code falls through to generic copy', () {
      final mapped = mapError(
        const PostgrestException(
          message: 'something exotic',
          code: 'XX999',
        ),
      );
      expect(mapped.userMessage, 'Something went wrong.');
      expect(mapped.requiresReauth, isFalse);
    });
  });

  group('mapError — AuthException', () {
    test('AuthSessionMissingException flips requiresReauth', () {
      final mapped = mapError(AuthSessionMissingException());
      expect(mapped.requiresReauth, isTrue);
      expect(mapped.userMessage, contains('session expired'));
    });

    test('AuthInvalidJwtException flips requiresReauth', () {
      final mapped = mapError(AuthInvalidJwtException('bad jwt'));
      expect(mapped.requiresReauth, isTrue);
    });

    test('invalid_jwt code flips requiresReauth', () {
      final mapped = mapError(
        const AuthException(
          'JWT verification failed',
          code: 'invalid_jwt',
        ),
      );
      expect(mapped.requiresReauth, isTrue);
    });

    test('generic AuthException surfaces its message verbatim', () {
      // Login-time failures: "Invalid login credentials" is exactly
      // what we want the user to see — the login screen is the
      // right place to read it, and we don't want to rewrite it to
      // "Something went wrong."
      final mapped = mapError(
        const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );
      expect(mapped.userMessage, 'Invalid login credentials');
      expect(mapped.requiresReauth, isFalse);
    });
  });

  group('mapError — network', () {
    test('SocketException becomes connection copy', () {
      final mapped = mapError(const SocketException('host unreachable'));
      expect(mapped.userMessage, contains('Check your connection'));
      expect(mapped.requiresReauth, isFalse);
    });

    test('TimeoutException becomes connection copy', () {
      final mapped = mapError(TimeoutException('slow API', Duration(seconds: 30)));
      expect(mapped.userMessage, contains('Check your connection'));
    });
  });

  group('mapError — fallthrough shapes', () {
    test('String error is passed through verbatim', () {
      // Several catch sites do `context.showErrorSnackBar(e.message)`
      // — the caller has already chosen the copy and the mapper
      // mustn't second-guess it.
      final mapped = mapError('Amount must be greater than zero');
      expect(mapped.userMessage, 'Amount must be greater than zero');
    });

    test('unknown exception class falls through to generic copy', () {
      final mapped = mapError(Exception('totally novel shape'));
      expect(mapped.userMessage, 'Something went wrong.');
      expect(mapped.requiresReauth, isFalse);
    });
  });
}
