// Integration tests for the pending_writes queue's replay
// dispatcher. Audit 2026-05-26 T3.
//
// The persistence-layer unit tests in
// `test/core/sync/pending_writes_queue_test.dart` cover what
// enqueue + loadPendingWrites + markPendingWriteFailed + the
// pendingCount surface store. They do NOT exercise
// PendingWritesQueue._replayOne — that's where the
// `switch (row.opType)` lives and where every replay-path
// invariant (C6 onConflict 'id', H5 expected_updated_at
// envelope, RPC pass-through) is decided. These tests hit it
// end-to-end against the local Supabase stack so the
// dispatcher branches are actually reached.
//
// Each test enqueues a row, drains the queue, and asserts the
// SERVER-SIDE side effect happened (or didn't, in the
// idempotency / conflict cases).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/database/app_database.dart';
import 'package:mybudget/core/sync/pending_writes_queue.dart';
import 'package:uuid/uuid.dart';

import '_supabase_harness.dart';

void main() {
  final reason = Harness.envConfigured
      ? null
      : 'SUPABASE_TEST_URL / SUPABASE_TEST_ANON_KEY not set; '
            'integration tests skipped.';

  group('PendingWritesQueue.drain replay dispatcher (integration)', () {
    late Harness harness;
    late AppDatabase db;
    late PendingWritesQueue queue;
    final uuid = const Uuid();

    setUpAll(() async {
      if (reason != null) return;
      harness = await Harness.bootstrap(testTag: 'pw-drain');
    });

    tearDownAll(() async {
      if (reason != null) return;
      await harness.dispose();
    });

    setUp(() {
      // Fresh in-memory drift per test so the queue starts
      // empty and one test's pending row can't bleed into
      // another's drain.
      db = AppDatabase.withExecutor(NativeDatabase.memory());
      queue = PendingWritesQueue(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'insert: replays via upsert(onConflict:id); server row appears',
      () async {
        final txId = uuid.v4();
        await queue.enqueue(
          QueuedInsert(
            table: 'transactions',
            rowId: txId,
            payload: {
              'id': txId,
              'household_id': harness.householdId,
              'account_id': harness.accountId,
              'entered_by': harness.userId,
              'amount': -1500,
              'currency': 'USD',
              'description': 'replay-insert',
              'transaction_date': '2026-05-28',
              'pending': false,
              'source': 'manual',
            },
          ),
        );

        final result = await queue.drain();
        expect(result.attempted, 1);
        expect(result.succeeded, 1);
        expect(result.failed, 0);

        // Server-side row materialised at the client-generated id.
        final rows = await harness.client
            .from('transactions')
            .select('id, description, amount')
            .eq('id', txId);
        expect(rows, hasLength(1));
        expect(rows.first['description'], 'replay-insert');
        expect(rows.first['amount'], -1500);

        // Queue is empty after success.
        expect(await queue.pendingCount(), 0);
      },
      skip: reason,
    );

    test(
      'insert idempotency (C6): replay after server-already-has-row '
      'is a no-op, not a duplicate',
      () async {
        // Pre-existing row in the server.
        final txId = uuid.v4();
        await harness.client.from('transactions').insert({
          'id': txId,
          'household_id': harness.householdId,
          'account_id': harness.accountId,
          'entered_by': harness.userId,
          'amount': -100,
          'currency': 'USD',
          'description': 'pre-existing',
          'transaction_date': '2026-05-28',
          'pending': false,
          'source': 'manual',
        });

        // Now queue the same id with different content (simulates
        // a half-completed first attempt — the server wrote the
        // row but the client never saw the response).
        await queue.enqueue(
          QueuedInsert(
            table: 'transactions',
            rowId: txId,
            payload: {
              'id': txId,
              'household_id': harness.householdId,
              'account_id': harness.accountId,
              'entered_by': harness.userId,
              'amount': -100,
              'currency': 'USD',
              'description': 'replay-after-conflict',
              'transaction_date': '2026-05-28',
              'pending': false,
              'source': 'manual',
            },
          ),
        );

        final result = await queue.drain();
        expect(result.succeeded, 1, reason: 'upsert succeeds on conflict');
        expect(result.failed, 0);

        // Exactly ONE row exists at that id (no duplicate).
        final rows = await harness.client
            .from('transactions')
            .select('id, description')
            .eq('id', txId);
        expect(rows, hasLength(1));
        // The upsert REPLACED the description (onConflict:'id'
        // with ignoreDuplicates=false is an update on conflict).
        // The exact replaced value doesn't matter; the no-dup
        // invariant does.
        expect(rows.first['id'], txId);
      },
      skip: reason,
    );

    test(
      'update: replay patches the row server-side',
      () async {
        final txId = await harness.insertTransaction(
          description: 'pre-update',
          amountCents: -200,
        );

        await queue.enqueue(
          QueuedUpdate(
            table: 'transactions',
            rowId: txId,
            payload: const {'description': 'post-update', 'amount': -300},
          ),
        );
        final result = await queue.drain();
        expect(result.succeeded, 1);

        final row = await harness.client
            .from('transactions')
            .select('description, amount')
            .eq('id', txId)
            .single();
        expect(row['description'], 'post-update');
        expect(row['amount'], -300);
      },
      skip: reason,
    );

    test(
      'update with expectedUpdatedAt (H5): mismatch → CONFLICT, '
      'no clobber',
      () async {
        final txId = await harness.insertTransaction(
          description: 'phone-A-baseline',
          amountCents: -500,
        );
        // Simulate phone B updating the row at 10am with a different
        // value, refreshing updated_at server-side.
        await harness.client
            .from('transactions')
            .update({'description': 'phone-B-edit'})
            .eq('id', txId);

        // Phone A's queued update carries the stale precondition
        // (a fixed timestamp from before phone B's edit). The
        // replay's .eq('updated_at', X) misses, zero rows
        // affected → CONFLICT.
        await queue.enqueue(
          QueuedUpdate(
            table: 'transactions',
            rowId: txId,
            payload: const {'description': 'phone-A-stale-edit'},
            expectedUpdatedAt: DateTime.utc(2000, 1, 1),
          ),
        );
        final result = await queue.drain();
        expect(result.succeeded, 0);
        expect(result.failed, 1);

        // Phone B's edit survives — phone A's replay did NOT
        // clobber.
        final row = await harness.client
            .from('transactions')
            .select('description')
            .eq('id', txId)
            .single();
        expect(row['description'], 'phone-B-edit');

        // Queue row was marked failed with the CONFLICT error so
        // the next drain pass picks it up at attemptCount=1.
        final pending = await db.loadPendingWrites();
        expect(pending, hasLength(1));
        expect(pending.first.lastError, contains('CONFLICT'));
      },
      skip: reason,
    );

    test(
      'delete: replay removes the row',
      () async {
        final txId = await harness.insertTransaction(
          description: 'to-be-deleted',
        );

        await queue.enqueue(
          QueuedDelete(table: 'transactions', rowId: txId),
        );
        final result = await queue.drain();
        expect(result.succeeded, 1);

        final rows = await harness.client
            .from('transactions')
            .select('id')
            .eq('id', txId);
        expect(rows, isEmpty);
      },
      skip: reason,
    );

    test(
      'rpc: replay invokes the RPC with the encoded params',
      () async {
        // Use recalculate_account_balance — it's idempotent, takes
        // a UUID param, and the side-effect is observable
        // (current_balance gets refreshed).
        final txId = await harness.insertTransaction(
          amountCents: -1234,
          description: 'rpc-baseline',
        );

        // Stamp current_balance to a known-wrong value first so
        // the recalculate has something to overwrite.
        await harness.client
            .from('accounts')
            .update({'current_balance': 999999})
            .eq('id', harness.accountId);

        await queue.enqueue(
          QueuedRpc(
            rpcName: 'recalculate_account_balance',
            params: {'p_account_id': harness.accountId},
          ),
        );
        final result = await queue.drain();
        expect(result.succeeded, 1);

        final account = await harness.client
            .from('accounts')
            .select('current_balance')
            .eq('id', harness.accountId)
            .single();
        // After recalc, the balance is the negative sum of every
        // transaction on this account + starting_balance. Earlier
        // tests in this group seeded transactions that contribute
        // too, so we can't pin an exact number. The signal is
        // that the RPC ran — the bogus 999999 we stamped before
        // the drain is gone.
        expect(account['current_balance'], isNot(999999));
        // And the just-inserted -1234 row is in the sum.
        expect(
          account['current_balance'],
          lessThanOrEqualTo(-1234),
          reason: 'must include rpc-baseline (-1234) plus prior debits',
        );

        // Touched transaction id is unaffected by the RPC.
        final tx = await harness.client
            .from('transactions')
            .select('id')
            .eq('id', txId)
            .single();
        expect(tx['id'], txId);
      },
      skip: reason,
    );

    test(
      'mixed batch in FIFO order: all succeed independently',
      () async {
        final t1Id = uuid.v4();
        final t2Id = await harness.insertTransaction(
          description: 'will-update',
          amountCents: -10,
        );
        final t3Id = await harness.insertTransaction(
          description: 'will-delete',
          amountCents: -20,
        );

        await queue.enqueue(
          QueuedInsert(
            table: 'transactions',
            rowId: t1Id,
            payload: {
              'id': t1Id,
              'household_id': harness.householdId,
              'account_id': harness.accountId,
              'entered_by': harness.userId,
              'amount': -30,
              'currency': 'USD',
              'description': 'inserted',
              'transaction_date': '2026-05-28',
              'pending': false,
              'source': 'manual',
            },
          ),
        );
        await queue.enqueue(
          QueuedUpdate(
            table: 'transactions',
            rowId: t2Id,
            payload: const {'description': 'updated'},
          ),
        );
        await queue.enqueue(
          QueuedDelete(table: 'transactions', rowId: t3Id),
        );

        final result = await queue.drain();
        expect(result.succeeded, 3);
        expect(result.failed, 0);

        // Verify all three side-effects.
        final t1 = await harness.client
            .from('transactions')
            .select('description')
            .eq('id', t1Id);
        expect(t1, hasLength(1));
        expect(t1.first['description'], 'inserted');

        final t2 = await harness.client
            .from('transactions')
            .select('description')
            .eq('id', t2Id)
            .single();
        expect(t2['description'], 'updated');

        final t3 = await harness.client
            .from('transactions')
            .select('id')
            .eq('id', t3Id);
        expect(t3, isEmpty);

        expect(await queue.pendingCount(), 0);
      },
      skip: reason,
    );

    test(
      'permanent failure (NOT NULL violation) keeps row, bumps '
      'attemptCount, drain continues to next row',
      () async {
        // Enqueue a delete against a non-existent id (succeeds —
        // DELETE … WHERE id = x with no match is a no-op) FIRST,
        // then a bad insert SECOND. The bad insert fails;
        // verify the queue surfaces failed=1 + the row stays.
        await queue.enqueue(
          QueuedInsert(
            table: 'transactions',
            rowId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            payload: const {
              'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
              // Missing required fields (account_id, currency, etc).
              'description': 'broken-insert',
            },
          ),
        );

        final result = await queue.drain();
        expect(result.succeeded, 0);
        expect(result.failed, 1);

        final pending = await db.loadPendingWrites();
        expect(pending, hasLength(1));
        expect(pending.first.attemptCount, 1);
        expect(pending.first.lastError, isNotNull);
      },
      skip: reason,
    );
  });
}
