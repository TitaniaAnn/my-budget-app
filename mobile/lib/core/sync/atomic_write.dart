// Shared atomic-cache + queue-enqueue helper. Audit L1 Phase 3c.
//
// Every repository's offline-write path needs the same two-step
// dance: (1) write the optimistic row to the drift cache, (2)
// enqueue the deferred mutation in pending_writes. Audit H4
// established the atomicity invariant — both writes must commit
// together or neither does — and the AccountsRepository
// (Phase 3b template) implemented it via a private helper.
//
// Phase 3c extracts that helper here so every repository can
// import it instead of duplicating the four-arg drift
// transaction. Behavior is byte-for-byte equivalent to the
// AccountsRepository version; the API change is the caller
// passes [db] and [queue] explicitly instead of relying on a
// private field.
//
// Fall-through behavior (preserves the legacy zero-arg
// repository constructors used by older tests):
//   * db == null && queue != null  → enqueue only (no cache).
//   * db != null && queue == null  → cache write only.
//   * both null                    → no-op; caller carries on
//                                    as if neither were wired.

import '../database/app_database.dart';
import 'pending_writes_queue.dart';

Future<void> atomicCacheAndEnqueue({
  required AppDatabase? db,
  required PendingWritesQueue? queue,
  required Future<void> Function() write,
  required QueuedOp queueOp,
}) async {
  if (db == null) {
    await queue?.enqueue(queueOp);
    return;
  }
  if (queue == null) {
    await write();
    return;
  }
  await db.transaction(() async {
    await write();
    await queue.enqueue(queueOp);
  });
}
