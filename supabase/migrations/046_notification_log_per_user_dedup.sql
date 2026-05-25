-- ============================================================
-- Per-user notification dedup.
--
-- Pre-fix: notification_log keyed on (household_id, dedup_key).
-- Any household member could pre-claim any dedup_key — the keys
-- are derivable from RLS-visible data (budget id + period start,
-- or transaction id) — and the loser silently dropped its
-- notification. So a child-role member could silence a parent's
-- "Over budget: Dining" alert by claiming the key first. Audit
-- H4 calls this out.
--
-- Fix: add `user_id` to the PK so each member dedup-s in their
-- own namespace. Member A claiming a key doesn't affect member B
-- — B's INSERT for the same (household_id, dedup_key) but with
-- B's user_id is a different PK tuple and lands as a new row.
--
-- Schema details:
--   * `user_id` is NOT NULL with a sentinel default of the zero
--     UUID. The sentinel marks "this row predates per-user
--     dedup" (the backfill writes it on every existing row) AND
--     covers any future legacy code path that forgets to pass
--     user_id explicitly. New writes from both engines pass a
--     real user_id (the in-app side from auth.uid(), the Edge
--     Function from the device token's owner).
--   * No FK from user_id to auth.users(id) — the sentinel value
--     would violate it, and the column's purpose is namespacing
--     dedup space, not auditing identity. RLS still scopes
--     writes to auth.uid() so a real user_id has to be the
--     caller's own.
--   * PK becomes (household_id, dedup_key, user_id). The old
--     two-column PK is dropped and recreated three-column —
--     no surrogate id, the dedup contract is still the PK
--     directly.
--   * INSERT RLS tightens: client writes must have
--     user_id = auth.uid(). The sentinel is reserved for the
--     server's service-role path (which bypasses RLS anyway).
--
-- Audit reference: H4.
-- ============================================================

-- Step 1: add the column nullable so the backfill can run.
ALTER TABLE notification_log ADD COLUMN user_id UUID;

-- Step 2: backfill — every existing row goes to the sentinel.
-- These are pre-fix rows: under the old keying they were
-- household-wide dedup keys, which is exactly what the sentinel
-- represents going forward. No data loss; the loser-side
-- "silenced alert" behaviour stays as it was for any key fired
-- before this migration.
UPDATE notification_log
  SET user_id = '00000000-0000-0000-0000-000000000000'::uuid
  WHERE user_id IS NULL;

-- Step 3: lock the column down + give the sentinel as default
-- so legacy callers that forget to pass user_id still produce
-- valid rows (degraded to broadcast dedup rather than crashing).
ALTER TABLE notification_log
  ALTER COLUMN user_id SET NOT NULL,
  ALTER COLUMN user_id SET DEFAULT '00000000-0000-0000-0000-000000000000'::uuid;

-- Step 4: re-key. Drop the old two-column PK and recreate as
-- three. ON CONFLICT in the upsert path naturally follows the
-- new tuple — caller just has to start passing user_id in the
-- INSERT row.
ALTER TABLE notification_log DROP CONSTRAINT notification_log_pkey;
ALTER TABLE notification_log ADD PRIMARY KEY (household_id, dedup_key, user_id);

-- Step 5: tighten the INSERT policy. Pre-fix any member could
-- INSERT any household_id row; combined with the dedup_key
-- collision that's the silencing attack. Post-fix the row's
-- user_id must equal the caller's own auth.uid() — i.e. you
-- can only claim YOUR dedup space, not someone else's.
--
-- The server path is unaffected: the Edge Function uses the
-- service role, which bypasses RLS entirely.
DROP POLICY IF EXISTS "notification_log household-insert" ON notification_log;

CREATE POLICY "notification_log household-insert"
  ON notification_log FOR INSERT
  WITH CHECK (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
    AND user_id = auth.uid()
  );
