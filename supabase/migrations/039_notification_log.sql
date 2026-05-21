-- ============================================================
-- Server-side notification dedup log.
--
-- Problem this solves: until now the in-app engine kept its
-- last-fired map in SharedPreferences per device, and the server-
-- side dispatcher (Edge Function send-notification) kept no record
-- at all. Two failure modes followed:
--
--   1. User is online → in-app engine fires `budget_over:b1:2026-05-01`
--      → server runs an hour later and re-fires the same alert as
--      a push, even though the user already saw it in-app.
--   2. Two scheduler invocations land close together (cron retry,
--      manual nudge) and both try to push the same key.
--
-- A shared (household_id, dedup_key) ledger fixes both. INSERT ON
-- CONFLICT DO NOTHING is the atomic check-and-insert: whichever
-- side wins the race writes the row, the loser sees a 0-row
-- RETURNING and skips the push. The Dart side now also reads
-- recent keys back to merge into its `lastFiredByKey` map, so
-- the in-app engine respects server fires too.
--
-- Schema choices:
--   * PK on (household_id, dedup_key) — that's the dedup contract,
--     directly enforced. No surrogate id needed.
--   * `source TEXT` (server / client) is debug-only — useful when
--     poking at why an alert did or didn't fire. Not enum'd because
--     this is a leaf table and adding sources shouldn't cost a
--     migration.
--   * `fired_at TIMESTAMPTZ DEFAULT now()` — the prune window
--     wants this. Index on (household_id, fired_at DESC) supports
--     the "recent keys" read pattern and the eventual prune scan.
--
-- Cleanup: a future pg_cron job (or just an Edge Function pass)
-- can DELETE rows older than 90 days — the in-app `recordFired`
-- already prunes its own map at that boundary so anything older
-- is dead weight here too. Not in this migration.
-- ============================================================

CREATE TABLE notification_log (
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  dedup_key     TEXT NOT NULL,
  fired_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  source        TEXT NOT NULL DEFAULT 'server',
  PRIMARY KEY (household_id, dedup_key)
);

-- "Give me every dedup_key fired in this household since cutoff X"
-- is the Dart-side merge read; the same index also answers the
-- prune scan.
CREATE INDEX notification_log_household_recent_idx
  ON notification_log (household_id, fired_at DESC);

-- ─── Row Level Security ────────────────────────────────────
ALTER TABLE notification_log ENABLE ROW LEVEL SECURITY;

-- Any household member can read the log — needed so the in-app
-- engine merges server fires into its dedup map regardless of
-- which member's device the server pushed to.
CREATE POLICY "notification_log household-read"
  ON notification_log FOR SELECT
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

-- Members can insert their own fires (the in-app path). The
-- server-side dispatcher writes via the service role which
-- bypasses RLS, so no policy needed for that path.
CREATE POLICY "notification_log household-insert"
  ON notification_log FOR INSERT
  WITH CHECK (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

-- Members can delete entries from their household — supports a
-- "reset notifications" affordance and household-scoped pruning.
CREATE POLICY "notification_log household-delete"
  ON notification_log FOR DELETE
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );
