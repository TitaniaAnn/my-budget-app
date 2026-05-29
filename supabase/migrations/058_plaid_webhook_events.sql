-- ============================================================
-- Plaid Phase 4: webhook event log.
--
-- The `plaid-webhook` Edge Function (this slice's sibling) is
-- the public endpoint Plaid POSTs to when an Item changes
-- state — new transactions available, item-login required,
-- consent expiring, etc. Plaid signs the request with a JWT
-- in the `Plaid-Verification` header; the function verifies
-- that signature, then writes ONE row here per event and
-- routes on (webhook_type, webhook_code) to do any reactive
-- work (flagging re-auth state, etc.).
--
-- The table exists for three reasons:
--
--   1. Audit trail: a user complaining "I never got a sync"
--      can be answered with "Plaid never sent us a webhook,
--      see plaid_webhook_events" — distinct from "we got the
--      webhook but failed to act on it" (processed_at IS NULL)
--      vs "we got it AND acted on it" (processed_at IS NOT NULL).
--
--   2. Replay: if the webhook function ever crashes mid-batch,
--      a follow-up script can re-process every row where
--      processed_at IS NULL.
--
--   3. Debugging unknown webhook codes: Plaid occasionally
--      adds new webhook_type/code combinations. Logging
--      everything (even unknown shapes) means we can grep
--      for them later instead of needing to redeploy logging
--      after the fact.
--
-- No client-facing RLS policy. This table is service-role-only:
-- the Edge Function writes, an admin reads via the dashboard
-- if needed. The default-deny posture (RLS enabled + no policy)
-- prevents any anon / authenticated SELECT.
--
-- FK cascade: deleting the parent plaid_items row cascades
-- through here so a user unlinking a bank wipes their
-- associated event history too. Important for "delete my
-- data" compliance.
-- ============================================================

CREATE TABLE plaid_webhook_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Internal plaid_items.id, NOT Plaid's `item_id` string.
  -- Nullable because the Edge Function logs the row BEFORE
  -- resolving Plaid's item_id to our internal one — if the
  -- lookup misses (unknown Item, possibly a webhook for an
  -- Item we already deleted), we still want the audit trail.
  plaid_item_id UUID REFERENCES plaid_items(id) ON DELETE CASCADE,

  -- Plaid's webhook_type, e.g. 'TRANSACTIONS', 'ITEM'.
  webhook_type  TEXT NOT NULL,

  -- Plaid's webhook_code, e.g. 'SYNC_UPDATES_AVAILABLE',
  -- 'ERROR', 'PENDING_EXPIRATION'.
  webhook_code  TEXT NOT NULL,

  -- Full Plaid POST body. Useful for replay + debugging.
  payload       JSONB NOT NULL,

  -- Set when the routing logic finishes. NULL means we got the
  -- webhook but haven't acted on it yet (either crashed
  -- mid-handler or the code was unknown and we logged-only).
  processed_at  TIMESTAMPTZ,

  received_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE plaid_webhook_events ENABLE ROW LEVEL SECURITY;
-- Intentionally NO policies. Default-deny for anon + authenticated.

-- Hot-path index: "show me the most recent events for this Item"
-- (debugging) and "any unprocessed rows?" (replay script).
CREATE INDEX plaid_webhook_events_item_received_idx
  ON plaid_webhook_events(plaid_item_id, received_at DESC);

CREATE INDEX plaid_webhook_events_unprocessed_idx
  ON plaid_webhook_events(received_at)
  WHERE processed_at IS NULL;
