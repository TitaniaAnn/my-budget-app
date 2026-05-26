-- ============================================================
-- Plaid integration — Phase 1, slice 2: link `accounts` to
-- Plaid.
--
-- An account is either manual (`plaid_item_id IS NULL`,
-- `plaid_account_id IS NULL`) or Plaid-backed (both set). The
-- pair lives on `accounts` rather than in a join table because
-- the relationship is 1:0..1 and every account-side query needs
-- to know "is this a Plaid account?" without a join.
--
-- ON DELETE SET NULL on `plaid_item_id`: if the user removes a
-- Plaid Item (unlinks the bank), the existing transactions and
-- account row survive — they just lose the Plaid pointer. The
-- account becomes a manual-edit account from that point. This
-- matches the audit-D1 pattern of "preserve user data when the
-- parent reference goes away."
--
-- The (plaid_item_id, plaid_account_id) UNIQUE is partial: it
-- only constrains rows where plaid_account_id IS NOT NULL.
-- Without the partial filter every manual account would have
-- (NULL, NULL) and Postgres would consider them all equal under
-- the unique constraint — blocking inserts after the first
-- manual account.
--
-- Audit references: PLAID_INTEGRATION Phase 1 / Migration 051
-- (renumbered).
-- ============================================================

ALTER TABLE accounts
  ADD COLUMN plaid_item_id    UUID REFERENCES plaid_items(id) ON DELETE SET NULL,
  ADD COLUMN plaid_account_id TEXT;

-- Partial unique: a given Plaid Item + Plaid account_id pair
-- maps to exactly one `accounts` row. Re-running the
-- exchange flow for an already-imported account should
-- UPDATE in place, not stack duplicates.
CREATE UNIQUE INDEX accounts_plaid_account_id_unique
  ON accounts (plaid_item_id, plaid_account_id)
  WHERE plaid_account_id IS NOT NULL;
