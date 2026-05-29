-- ============================================================
-- Plaid items: code-review cleanup of the column grants + the
-- household-active index.
--
-- (#15) Trim `sync_cursor` from the client SELECT grant. The
-- column is an opaque /transactions/sync state string used only
-- by the Edge Function — the mobile UI never reads it. Removing
-- it from the client grant shrinks the surface and makes the
-- column-grant list match its semantic ("metadata clients show
-- in the UI") rather than "everything except access_token."
--
-- (#16) Replace the composite (household_id, is_active) WHERE
-- is_active=true index with a simpler partial on is_active
-- alone. The Dart `fetchActiveItems` only filters on is_active
-- (household_id is enforced by RLS, not by the query). The
-- household_id leading column in the prior index was unused.
--
-- Both are pure hygiene — neither closes a bug, neither
-- changes user-visible behaviour. Reviewing them in one
-- migration keeps the changelog tidy.
-- ============================================================

-- (#15) Re-REVOKE everything from the client roles and re-GRANT
-- only the columns the client UI actually needs. sync_cursor
-- drops out. Other columns unchanged.
REVOKE SELECT ON plaid_items FROM anon, authenticated;
GRANT SELECT (
  id,
  household_id,
  created_by,
  plaid_item_id,
  plaid_institution_id,
  institution_name,
  environment,
  last_sync_at,
  last_sync_error,
  consent_expires_at,
  is_active,
  created_at,
  updated_at
) ON plaid_items TO anon, authenticated;

-- (#16) Drop the over-broad index and replace with the
-- partial that matches the actual query shape.
DROP INDEX IF EXISTS plaid_items_household_active_idx;

CREATE INDEX IF NOT EXISTS plaid_items_active_idx
  ON plaid_items(institution_name)
  WHERE is_active = true;
-- Index key is institution_name so the fetchActiveItems
-- ORDER BY institution_name can use this index for both the
-- filter AND the sort in one walk.
