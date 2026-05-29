// Unit tests for the offline write queue's persistence layer
// (Phase 3a). The drain dispatcher itself uses the global
// `supabase` singleton, so the network-side of replay is
// covered by integration tests against the local Supabase
// stack. These tests pin the AppDatabase-side guarantees:
//   * enqueue persists every op type's shape
//   * loadPendingWrites returns FIFO order
//   * deletePendingWrite removes one row by id
//   * markPendingWriteFailed bumps attemptCount + stores error
//   * pendingWritesCount matches reality

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/database/app_database.dart';
import 'package:mybudget/core/sync/pending_writes_queue.dart';

void main() {
  late AppDatabase db;
  late PendingWritesQueue queue;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    queue = PendingWritesQueue(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PendingWritesQueue.enqueue', () {
    test('persists a QueuedInsert with payload + table', () async {
      await queue.enqueue(
        QueuedInsert(
          table: 'transactions',
          // Audit 2026-05-26 C6: payload MUST contain 'id'
          // matching rowId so the replay UPSERT can conflict-
          // resolve idempotently. The runtime assert in
          // QueuedInsert enforces this.
          payload: const {
            'id': 'tx-client-uuid',
            'household_id': 'hh-1',
            'amount': -2500,
            'description': 'Coffee',
          },
          rowId: 'tx-client-uuid',
        ),
      );
      final rows = await db.loadPendingWrites();
      expect(rows, hasLength(1));
      final row = rows.single;
      expect(row.opType, 'insert');
      expect(row.targetTable, 'transactions');
      expect(row.rowId, 'tx-client-uuid');
      expect(row.rpcName, isNull);
      final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      expect(payload['household_id'], 'hh-1');
      expect(payload['amount'], -2500);
      expect(row.attemptCount, 0);
      expect(row.lastError, isNull);
    });

    test('persists a QueuedUpdate with rowId + patch', () async {
      await queue.enqueue(
        const QueuedUpdate(
          table: 'transactions',
          rowId: 'tx-1',
          payload: {'description': 'Renamed'},
        ),
      );
      final row = (await db.loadPendingWrites()).single;
      expect(row.opType, 'update');
      expect(row.targetTable, 'transactions');
      expect(row.rowId, 'tx-1');
      // Audit 2026-05-26 H5: payload is wrapped in an envelope
      // so the precondition can travel alongside. Unwrap before
      // asserting on the inner patch.
      final envelope = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      final patch = envelope['payload'] as Map<String, dynamic>;
      expect(patch['description'], 'Renamed');
      expect(envelope['expected_updated_at'], isNull);
    });

    test(
      'persists a QueuedUpdate with optimistic-lock precondition '
      '(H5 — survives the cross-device race)',
      () async {
        final precondition = DateTime.utc(2026, 5, 28, 10, 0, 0);
        await queue.enqueue(
          QueuedUpdate(
            table: 'transactions',
            rowId: 'tx-1',
            payload: const {'description': 'Espresso'},
            expectedUpdatedAt: precondition,
          ),
        );
        final row = (await db.loadPendingWrites()).single;
        final envelope = jsonDecode(row.payloadJson) as Map<String, dynamic>;
        expect((envelope['payload'] as Map<String, dynamic>)['description'],
            'Espresso');
        // ISO-8601 UTC with the Z suffix so the replay's .eq
        // filter compares string-equal to what Postgres returns.
        expect(envelope['expected_updated_at'], '2026-05-28T10:00:00.000Z');
      },
    );

    test('persists a QueuedDelete with rowId + empty payload', () async {
      await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'tx-1'),
      );
      final row = (await db.loadPendingWrites()).single;
      expect(row.opType, 'delete');
      expect(row.rowId, 'tx-1');
      expect(row.payloadJson, '{}');
    });

    test('persists a QueuedRpc with rpcName + params, null table', () async {
      await queue.enqueue(
        const QueuedRpc(
          rpcName: 'create_transfer',
          params: {
            'p_from_account_id': 'a-1',
            'p_to_account_id': 'a-2',
            'p_amount_cents': 5000,
          },
        ),
      );
      final row = (await db.loadPendingWrites()).single;
      expect(row.opType, 'rpc');
      expect(row.rpcName, 'create_transfer');
      expect(row.targetTable, isNull);
      expect(row.rowId, isNull);
      final params = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      expect(params['p_amount_cents'], 5000);
    });

    test('returns the generated id so callers can correlate', () async {
      final id = await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'tx-1'),
      );
      expect(id, isNotEmpty);
      final row = (await db.loadPendingWrites()).single;
      expect(row.id, id);
    });
  });

  group('AppDatabase.loadPendingWrites', () {
    test('returns rows in created_at ASC (FIFO)', () async {
      // Enqueue three with a tiny delay between to guarantee
      // ascending timestamps even on coarse-grained clocks.
      await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'first'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'second'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'third'),
      );
      final rows = await db.loadPendingWrites();
      expect(rows.map((r) => r.rowId), ['first', 'second', 'third']);
    });

    test('returns empty list when nothing is queued', () async {
      final rows = await db.loadPendingWrites();
      expect(rows, isEmpty);
    });
  });

  group('AppDatabase.deletePendingWrite', () {
    test('removes one row by id, leaves others alone', () async {
      final keepId = await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'keep'),
      );
      final dropId = await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'drop'),
      );
      await db.deletePendingWrite(dropId);
      final rows = await db.loadPendingWrites();
      expect(rows, hasLength(1));
      expect(rows.single.id, keepId);
      expect(rows.single.rowId, 'keep');
    });
  });

  group('AppDatabase.markPendingWriteFailed', () {
    test('bumps attemptCount + stores the error string', () async {
      final id = await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'tx-1'),
      );
      await db.markPendingWriteFailed(id: id, error: 'network blip');
      var row = (await db.loadPendingWrites()).single;
      expect(row.attemptCount, 1);
      expect(row.lastError, 'network blip');

      await db.markPendingWriteFailed(id: id, error: 'second attempt');
      row = (await db.loadPendingWrites()).single;
      expect(row.attemptCount, 2);
      expect(row.lastError, 'second attempt');
    });
  });

  group('PendingWritesQueue.pendingCount', () {
    test('matches the number of rows in the queue', () async {
      expect(await queue.pendingCount(), 0);
      await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'a'),
      );
      expect(await queue.pendingCount(), 1);
      await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'b'),
      );
      await queue.enqueue(
        const QueuedDelete(table: 'transactions', rowId: 'c'),
      );
      expect(await queue.pendingCount(), 3);
    });
  });
}
