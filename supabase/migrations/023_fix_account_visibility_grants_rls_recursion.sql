-- ============================================================
-- Fix RLS recursion between accounts and account_visibility_grants.
--
-- Migration 016 added this policy on account_visibility_grants:
--
--   USING (
--     account_id IN (
--       SELECT id FROM accounts                            -- ← queries accounts
--        WHERE get_household_role(household_id) = 'owner'
--     )
--   )
--
-- And the SELECT policy on accounts (from migration 001) does:
--
--   USING (
--     household_id IN (...)
--     AND (
--       ...
--       OR EXISTS (
--         SELECT 1 FROM account_visibility_grants ...      -- ← queries grants
--       )
--       ...
--     )
--   )
--
-- Result: any query that touches both tables under the user's RLS
-- triggers Postgres error 42P17 (infinite recursion). Same shape of
-- bug migration 004 fixed for household_members. Surfaced when an
-- integration test tried to insert an account and immediately read
-- it back with `.select()`.
--
-- Fix: introduce a SECURITY DEFINER helper that resolves an account's
-- household_id without entering the user's RLS path. Replace the
-- recursive policy on account_visibility_grants with one that uses
-- the helper.
-- ============================================================

-- Helper: account_id → household_id, bypassing RLS. Mirrors the
-- existing get_household_role() pattern from migration 001.
CREATE OR REPLACE FUNCTION account_household_id(p_account_id UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT household_id FROM accounts WHERE id = p_account_id;
$$;

-- Replace the recursive policy. Equivalent intent — the household
-- owner can manage visibility grants — but resolved through the
-- SECURITY DEFINER helper so we don't re-enter accounts' RLS.
DROP POLICY IF EXISTS "owner can manage visibility grants"
  ON account_visibility_grants;

CREATE POLICY "owner can manage visibility grants"
  ON account_visibility_grants FOR ALL
  USING (
    get_household_role(account_household_id(account_id)) = 'owner'
  );

-- Grantees can still read their own grants. This policy doesn't query
-- accounts, so no recursion.
CREATE POLICY "grantees can read own grants"
  ON account_visibility_grants FOR SELECT
  USING (granted_to = auth.uid());
