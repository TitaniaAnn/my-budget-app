-- ============================================================
-- Audit 2026-05-26 C3: non-owner household members can never
-- sync Plaid items because the `accounts` SELECT policy from
-- migration 001 denies them unless they own the account, hold
-- an explicit visibility grant, or are a partner with
-- full_access. The Plaid exchange function (migration 054) sets
-- `owner_user_id = auth.uid()` of the linker, so a partner who
-- didn't link the bank fails the SELECT → upsert_plaid_transactions
-- raises 42501 → orchestrator sees a perpetual "couldn't sync"
-- error that's actually an auth wall, not transient.
--
-- Fix: add an ADDITIONAL policy (Postgres ORs policies across
-- rows) that grants every household member SELECT on accounts
-- that are Plaid-linked. The rationale matches the audit's:
-- bank data is already shared with the bank, so the trust bar
-- for "show this row to a partner who shares the household" is
-- lower than for a manually-created hidden account.
--
-- The existing "account visibility" policy stays in place
-- unchanged — manual accounts continue to follow the owner /
-- grant / partner-full-access model. Only the Plaid-backed
-- subset gets this widened visibility.
--
-- INSERT/UPDATE/DELETE are unaffected; the existing "owner can
-- manage accounts" policy stays the sole write path. A partner
-- still can't rename or delete a Plaid account they didn't link.
-- ============================================================

CREATE POLICY "plaid accounts visible to household"
  ON accounts FOR SELECT
  USING (
    plaid_account_id IS NOT NULL
    AND household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );
