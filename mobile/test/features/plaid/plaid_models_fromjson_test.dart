// Regression tests for the freezed fromJson factories on the
// Plaid models. Pins the contract that they consume the
// snake_case shapes the Edge Functions / `plaid_items` rows
// actually emit — NOT camelCase.
//
// History: an earlier version of PlaidRepository ran every
// response through a _camelize() helper before fromJson, which
// silently broke every parse because the project's
// `build.yaml` sets `json_serializable.field_rename: snake` —
// the generated fromJson reads `json['plaid_item_id']`, NOT
// `json['plaidItemId']`. None of the existing tests caught it
// because no test actually constructed a model from JSON. These
// fill that gap.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/plaid/models/plaid_item.dart';
import 'package:mybudget/features/plaid/models/plaid_link_result.dart';

void main() {
  group('PlaidItem.fromJson', () {
    test('parses a representative `plaid_items` row (snake_case keys)', () {
      // Shape mirrors what `supabase.from('plaid_items').select()`
      // returns to a client query — column names verbatim from
      // migration 054. Two columns are NOT in the response:
      //   * access_token — column-level REVOKE (migration 054)
      //   * sync_cursor  — column-level REVOKE (migration 059)
      // Both still exist in the model as nullable String?, so a
      // null comes through cleanly when the client SELECT skips
      // them.
      final row = {
        'id': '11111111-1111-1111-1111-111111111111',
        'household_id': '22222222-2222-2222-2222-222222222222',
        'created_by': '33333333-3333-3333-3333-333333333333',
        'plaid_item_id': 'plaid-item-abc123',
        'plaid_institution_id': 'ins_109508',
        'institution_name': 'First Platypus Bank',
        'environment': 'sandbox',
        'last_sync_at': '2026-05-25T12:34:56.789Z',
        'last_sync_error': null,
        'consent_expires_at': null,
        'is_active': true,
        'created_at': '2026-05-01T00:00:00Z',
        'updated_at': '2026-05-25T12:34:56.789Z',
      };
      final item = PlaidItem.fromJson(row);
      expect(item.id, '11111111-1111-1111-1111-111111111111');
      expect(item.householdId, '22222222-2222-2222-2222-222222222222');
      expect(item.createdBy, '33333333-3333-3333-3333-333333333333');
      expect(item.plaidItemId, 'plaid-item-abc123');
      expect(item.plaidInstitutionId, 'ins_109508');
      expect(item.institutionName, 'First Platypus Bank');
      expect(item.environment, PlaidEnvironment.sandbox);
      expect(
        item.syncCursor,
        isNull,
        reason:
            'sync_cursor is REVOKED from client SELECT (migration 059) — '
            'client gets null even when the column has a value.',
      );
      expect(item.lastSyncAt, DateTime.utc(2026, 5, 25, 12, 34, 56, 789));
      expect(item.lastSyncError, isNull);
      expect(item.consentExpiresAt, isNull);
      expect(item.isActive, isTrue);
      expect(item.requiresReauth, isFalse);
    });

    test('PlaidEnvironment values map to the right enum members', () {
      for (final pair in const [
        ('sandbox', PlaidEnvironment.sandbox),
        ('development', PlaidEnvironment.development),
        ('production', PlaidEnvironment.production),
      ]) {
        final json = _baseItemRow()..['environment'] = pair.$1;
        expect(PlaidItem.fromJson(json).environment, pair.$2);
      }
    });

    test('an item with a re-auth error code flips requiresReauth', () {
      final json = _baseItemRow()..['last_sync_error'] = 'ITEM_LOGIN_REQUIRED';
      expect(PlaidItem.fromJson(json).requiresReauth, isTrue);
    });

    test('an unknown error code does NOT flip requiresReauth', () {
      final json = _baseItemRow()..['last_sync_error'] = 'RATE_LIMIT_EXCEEDED';
      expect(PlaidItem.fromJson(json).requiresReauth, isFalse);
    });
  });

  group('PlaidExchangeResult.fromJson', () {
    test('parses the plaid-public-token-exchange response shape', () {
      // Shape mirrors what `supabase/functions/plaid-public-token-exchange`
      // returns. snake_case keys; the freezed-generated fromJson
      // honours field_rename: snake from build.yaml.
      final response = {
        'plaid_item_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'institution': {'id': 'ins_109508', 'name': 'First Platypus Bank'},
        'inserted_accounts': [
          {
            'account_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            'plaid_account_id': 'plaid-acct-1',
            'account_type': 'checking',
            'name': 'Plaid Checking',
          },
        ],
        'skipped_accounts': [
          {
            'plaid_account_id': 'plaid-acct-2',
            'name': 'Plaid Annuity',
            'plaid_type': 'investment',
            'plaid_subtype': 'annuity',
            'reason': 'no mapping from Plaid type/subtype to account_type',
          },
        ],
      };
      final result = PlaidExchangeResult.fromJson(response);
      expect(result.plaidItemId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(result.institution.name, 'First Platypus Bank');
      expect(result.insertedAccounts.length, 1);
      expect(result.insertedAccounts.single.accountId,
          'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
      expect(result.insertedAccounts.single.plaidAccountId, 'plaid-acct-1');
      expect(result.insertedAccounts.single.accountType, 'checking');
      expect(result.skippedAccounts.length, 1);
      expect(result.skippedAccounts.single.plaidSubtype, 'annuity');
    });

    test('empty inserted_accounts + skipped_accounts default to []', () {
      final result = PlaidExchangeResult.fromJson({
        'plaid_item_id': 'aaaa',
        'institution': {'id': 'i', 'name': 'n'},
      });
      expect(result.insertedAccounts, isEmpty);
      expect(result.skippedAccounts, isEmpty);
    });
  });

  group('PlaidSyncResult.fromJson', () {
    test('parses the happy-path sync response', () {
      final response = {
        'added': 5,
        'modified': 2,
        'removed': 1,
        'merged': 1,
        'accounts_synced': ['cccccccc-cccc-cccc-cccc-cccccccccccc'],
        'requires_reauth': false,
      };
      final result = PlaidSyncResult.fromJson(response);
      expect(result.added, 5);
      expect(result.modified, 2);
      expect(result.removed, 1);
      expect(result.merged, 1);
      expect(result.accountsSynced.length, 1);
      expect(result.requiresReauth, isFalse);
      expect(result.errorCode, isNull);
    });

    test('parses the requires_reauth response (Plaid error path)', () {
      final response = {
        'added': 0,
        'modified': 0,
        'removed': 0,
        'merged': 0,
        'accounts_synced': <String>[],
        'requires_reauth': true,
        'error_code': 'ITEM_LOGIN_REQUIRED',
      };
      final result = PlaidSyncResult.fromJson(response);
      expect(result.requiresReauth, isTrue);
      expect(result.errorCode, 'ITEM_LOGIN_REQUIRED');
    });

    test('missing counts default to 0; missing accounts_synced to []', () {
      // Future-proofing: if the Edge Function ever returns a
      // partial response shape, freezed defaults keep us alive.
      final result = PlaidSyncResult.fromJson({});
      expect(result.added, 0);
      expect(result.modified, 0);
      expect(result.removed, 0);
      expect(result.merged, 0);
      expect(result.accountsSynced, isEmpty);
      expect(result.requiresReauth, isFalse);
    });
  });
}

Map<String, dynamic> _baseItemRow() => {
      'id': '11111111-1111-1111-1111-111111111111',
      'household_id': '22222222-2222-2222-2222-222222222222',
      'created_by': '33333333-3333-3333-3333-333333333333',
      'plaid_item_id': 'plaid-item-abc123',
      'plaid_institution_id': 'ins_109508',
      'institution_name': 'First Platypus Bank',
      'environment': 'sandbox',
      // sync_cursor + access_token are REVOKED from client
      // SELECT (migrations 054 + 059); they don't appear in
      // production payloads at all.
      'last_sync_at': null,
      'last_sync_error': null,
      'consent_expires_at': null,
      'is_active': true,
      'created_at': '2026-05-01T00:00:00Z',
      'updated_at': '2026-05-25T12:34:56.789Z',
    };
