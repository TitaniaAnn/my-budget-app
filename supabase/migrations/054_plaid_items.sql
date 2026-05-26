-- ============================================================
-- Plaid integration — Phase 1, slice 1: `plaid_items` table.
--
-- One row per linked Item (Plaid's concept = a single bank
-- connection that may back multiple `accounts` rows). Holds the
-- long-lived `access_token`, the `/transactions/sync` cursor, and
-- the per-item sync error state.
--
-- The `access_token` is the credential that lets the Edge
-- Functions read the user's bank — leaking it is a credential
-- compromise. Two defences in this migration:
--
--   1. Column-level grant: clients reading the table NEVER see
--      `access_token`. We REVOKE SELECT on that one column from
--      anon + authenticated, leaving the other columns
--      selectable for the household-members UI.
--   2. Row-level no-INSERT/UPDATE/DELETE: the absence of any
--      mutation policy means client-side writes are denied by
--      default. The Edge Functions use the service role to
--      mutate, which bypasses RLS — that's the only path that
--      writes `plaid_items`.
--
-- Spec follow-up: pgcrypto-wrap `access_token` with a key in
-- Supabase Vault for at-rest belt-and-suspenders. Deferred to a
-- separate migration so this one stays focused on the schema.
--
-- Audit references: PLAID_INTEGRATION Phase 1 / Migration 050
-- (renumbered to 054 — the audit batch consumed 050-053 before
-- this work started).
-- ============================================================

CREATE TYPE plaid_environment AS ENUM (
  'sandbox',
  'development',
  'production'
);

CREATE TABLE plaid_items (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id         UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  created_by           UUID NOT NULL REFERENCES auth.users(id),
  plaid_item_id        TEXT NOT NULL,
  plaid_institution_id TEXT,
  institution_name     TEXT,

  -- The crown-jewel column. Column-level REVOKE below removes it
  -- from client SELECT. Stored plaintext for Phase 1; the
  -- pgcrypto + Vault wrap is a documented follow-up.
  access_token         TEXT NOT NULL,

  environment          plaid_environment NOT NULL,

  -- /transactions/sync cursor. NULL = initial pull pending.
  -- Edge Function loops calling /transactions/sync with this
  -- cursor until has_more=false, then writes back the new one.
  sync_cursor          TEXT,

  last_sync_at         TIMESTAMPTZ,

  -- Plaid error code from the most recent sync attempt, or NULL
  -- on success. Sync errors that mean "user must re-auth"
  -- (ITEM_LOGIN_REQUIRED, PENDING_EXPIRATION) drive the UI's
  -- re-auth prompt in Phase 3.
  last_sync_error      TEXT,

  -- Plaid surfaces a consent expiry for some institutions. Store
  -- it so the UI can warn before the user hits a forced re-auth.
  consent_expires_at   TIMESTAMPTZ,

  is_active            BOOLEAN NOT NULL DEFAULT true,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- One Item per (household, plaid_item_id). A re-link of the
  -- same institution from the same household should UPDATE this
  -- row, not stack duplicates.
  UNIQUE (household_id, plaid_item_id)
);

-- updated_at trigger — same pattern as transactions / accounts.
CREATE TRIGGER plaid_items_updated_at
  BEFORE UPDATE ON plaid_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

ALTER TABLE plaid_items ENABLE ROW LEVEL SECURITY;

-- SELECT: every household member can see that an Item exists +
-- its institution / sync status. Combined with the column-level
-- access_token REVOKE below, clients see everything they need
-- for the UI and nothing they need to never see.
CREATE POLICY plaid_items_select ON plaid_items FOR SELECT
  USING (
    household_id IN (
      SELECT hm.household_id
        FROM household_members hm
        WHERE hm.user_id = auth.uid()
    )
  );

-- INSERT / UPDATE / DELETE: no client policy → denied by default.
-- Edge Functions use the service role which bypasses RLS.

-- Column-level grant: lock down `access_token` so even
-- SELECT * by a client role omits it. The pattern is "revoke
-- table-level SELECT, then re-grant SELECT on the safe
-- columns" — a column-level REVOKE alone is a no-op against
-- Supabase's default table-level GRANT TO authenticated. Re-
-- granting omits access_token, so PostgREST drops it from
-- every client response.
--
-- INSERT / UPDATE / DELETE stay denied at the policy level
-- (no policy = denied) AND we don't re-grant the mutation
-- privileges here, so the column-level approach doesn't
-- accidentally open a write path.
REVOKE SELECT ON plaid_items FROM anon, authenticated;
GRANT SELECT (
  id,
  household_id,
  created_by,
  plaid_item_id,
  plaid_institution_id,
  institution_name,
  environment,
  sync_cursor,
  last_sync_at,
  last_sync_error,
  consent_expires_at,
  is_active,
  created_at,
  updated_at
) ON plaid_items TO anon, authenticated;

-- Hot lookup: "load the item by household + plaid_item_id" from
-- the webhook + sync paths.
CREATE INDEX plaid_items_household_active_idx
  ON plaid_items(household_id, is_active)
  WHERE is_active = true;
