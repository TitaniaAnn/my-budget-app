-- ============================================================
-- Replay protection for plaid_webhook_events (review item #17).
--
-- Plaid retries webhooks on slow 200s + transient infra
-- failures. The pre-fix plaid-webhook function logged every
-- delivery to plaid_webhook_events, so a single Plaid event
-- redelivered after our function returned slowly produced two
-- audit-log rows + double-fired the (small) routing side-
-- effects (re-stamping plaid_items.last_sync_error to the same
-- value). Mostly harmless, but pollutes the audit log we're
-- supposed to use for "did we get this event?" debugging.
--
-- Fix: add a `dedup_hash` column (SHA-256 of the raw POST
-- body) and a UNIQUE index on (plaid_item_id, dedup_hash). The
-- Edge Function computes the hash, then does:
--
--   INSERT … ON CONFLICT (plaid_item_id, dedup_hash) DO NOTHING
--     RETURNING id
--
-- If no row returned → replay → skip routing entirely.
--
-- Why hash-of-body instead of JWT `jti`: Plaid's JWT doesn't
-- include a `jti` claim. The body hash is what the JWT itself
-- already signs (`request_body_sha256` claim), so we know it's
-- bound to one delivered payload — perfect dedup key.
--
-- Why include plaid_item_id in the UNIQUE: two different Items
-- could legitimately produce identical bodies (e.g. two
-- HISTORICAL_UPDATE webhooks with no payload diff). Scoping
-- the UNIQUE to (item, hash) avoids false-positive collisions.
-- NULL plaid_item_id (webhook for an Item we don't have) is
-- treated as a distinct key under PostgreSQL's UNIQUE NULL
-- semantics — every NULL is different — which means an unknown
-- Item's replays would still duplicate. Acceptable: those
-- aren't audit-trail-load-bearing.
-- ============================================================

ALTER TABLE plaid_webhook_events
  ADD COLUMN dedup_hash TEXT;

-- Partial UNIQUE: only enforces dedup when plaid_item_id IS NOT
-- NULL. NULL plaid_item_id rows (unknown Items, deleted Items,
-- different environments) don't participate.
CREATE UNIQUE INDEX plaid_webhook_events_dedup_idx
  ON plaid_webhook_events (plaid_item_id, dedup_hash)
  WHERE plaid_item_id IS NOT NULL AND dedup_hash IS NOT NULL;
