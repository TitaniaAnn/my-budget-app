// Pure-business-logic tests for PlaidSyncOrchestrator.
//
// Orchestrator-side behaviour we pin:
//   * syncAll sequentially dispatches per item; counts aggregate.
//   * a single failing item doesn't kill the batch.
//   * requires_reauth on an item lands in itemsRequiringReauth.
//   * empty items list returns a no-op summary.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/plaid/models/plaid_item.dart';
import 'package:mybudget/features/plaid/models/plaid_link_result.dart';
import 'package:mybudget/features/plaid/repositories/plaid_repository.dart';
import 'package:mybudget/features/plaid/services/plaid_sync_orchestrator.dart';

void main() {
  PlaidItem item(String id, {String? institution}) => PlaidItem(
    id: id,
    householdId: 'h1',
    createdBy: 'u1',
    plaidItemId: 'plaid-$id',
    institutionName: institution ?? 'Bank $id',
    environment: PlaidEnvironment.sandbox,
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  group('PlaidSyncOrchestrator.syncAll', () {
    test('empty items list → empty summary, no dispatch', () async {
      final repo = _StubRepo(items: const []);
      final orch = PlaidSyncOrchestrator(repository: repo);
      final summary = await orch.syncAll();
      expect(summary.items, isEmpty);
      expect(summary.hasChanges, isFalse);
      expect(repo.syncCallsFor, isEmpty);
    });

    test('aggregates counts across multiple items', () async {
      final repo = _StubRepo(
        items: [item('a'), item('b')],
        syncResults: {
          'a': const PlaidSyncResult(added: 5, modified: 2, removed: 0, merged: 1),
          'b': const PlaidSyncResult(added: 3, modified: 0, removed: 4, merged: 0),
        },
      );
      final summary = await PlaidSyncOrchestrator(repository: repo).syncAll();
      expect(summary.totalAdded, 8);
      expect(summary.totalModified, 2);
      expect(summary.totalRemoved, 4);
      expect(summary.totalMerged, 1);
      expect(summary.hasChanges, isTrue);
      expect(summary.itemsRequiringReauth, isEmpty);
      expect(summary.failedItems, isEmpty);
      expect(repo.syncCallsFor, ['a', 'b']);
    });

    test('item returning requires_reauth lands in the reauth list', () async {
      final repo = _StubRepo(
        items: [item('a', institution: 'Chase'), item('b', institution: 'Amex')],
        syncResults: {
          'a': const PlaidSyncResult(added: 1),
          'b': const PlaidSyncResult(
            requiresReauth: true,
            errorCode: 'ITEM_LOGIN_REQUIRED',
          ),
        },
      );
      final summary = await PlaidSyncOrchestrator(repository: repo).syncAll();
      expect(summary.itemsRequiringReauth.length, 1);
      expect(summary.itemsRequiringReauth.single.institutionName, 'Amex');
      expect(summary.failedItems, isEmpty);
    });

    test('a thrown sync on one item doesn\'t kill the batch', () async {
      final repo = _StubRepo(
        items: [item('a'), item('b'), item('c')],
        syncResults: {
          'a': const PlaidSyncResult(added: 1),
          'c': const PlaidSyncResult(added: 3),
        },
        // 'b' has no syncResult → stub throws StateError when asked.
      );
      final summary = await PlaidSyncOrchestrator(repository: repo).syncAll();
      expect(summary.totalAdded, 4, reason: 'a + c counted; b dropped');
      expect(summary.failedItems.length, 1);
      expect(summary.failedItems.single.id, 'b');
      expect(repo.syncCallsFor, ['a', 'b', 'c']);
    });
  });

  group('PlaidItem.requiresReauth', () {
    test('flags known re-auth error codes', () {
      for (final code in const [
        'ITEM_LOGIN_REQUIRED',
        'PENDING_EXPIRATION',
        'PENDING_DISCONNECT',
      ]) {
        final i = item('x').copyWith(lastSyncError: code);
        expect(
          i.requiresReauth,
          isTrue,
          reason: '$code should flip requiresReauth',
        );
      }
    });

    test('other error codes do NOT flag re-auth', () {
      final i = item('x').copyWith(lastSyncError: 'RATE_LIMIT_EXCEEDED');
      expect(i.requiresReauth, isFalse);
    });

    test('null error → not re-auth', () {
      expect(item('x').requiresReauth, isFalse);
    });
  });
}

/// Test double for PlaidRepository. Captures the per-item
/// sync() calls in order so we can assert dispatch sequence.
class _StubRepo implements PlaidRepository {
  _StubRepo({required this.items, this.syncResults = const {}});

  final List<PlaidItem> items;
  final Map<String, PlaidSyncResult> syncResults;
  final List<String> syncCallsFor = [];

  @override
  Future<List<PlaidItem>> fetchActiveItems() async => items;

  @override
  Future<PlaidSyncResult> sync(String plaidItemRowId) async {
    syncCallsFor.add(plaidItemRowId);
    final r = syncResults[plaidItemRowId];
    if (r == null) {
      throw StateError('stub has no result for $plaidItemRowId');
    }
    return r;
  }

  // Methods the orchestrator doesn't touch — assert they're not
  // called as a contract reminder.
  @override
  Future<String> createLinkToken() =>
      throw StateError('orchestrator should not mint link tokens');

  @override
  Future<String> createUpdateLinkToken(String plaidItemRowId) =>
      throw StateError('orchestrator should not mint update tokens');

  @override
  Future<PlaidExchangeResult> exchangePublicToken({
    required String publicToken,
    required dynamic institution,
    required dynamic accounts,
  }) =>
      throw StateError('orchestrator should not exchange tokens');
}
