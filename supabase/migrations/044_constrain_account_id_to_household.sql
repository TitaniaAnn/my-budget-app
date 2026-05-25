-- ============================================================
-- Constrain account_id in account-referencing INSERT/UPDATE
-- policies to accounts that belong to the same household_id on
-- the row.
--
-- The original policies (migrations 001, 027, 031) checked only
-- the row's household_id against household_members. A partner-
-- role user could craft an INSERT where household_id matched
-- their own household but account_id referenced an account in
-- another household. The row would land, RLS visibility on the
-- victim's side (account_id IN SELECT id FROM accounts) would
-- expose it to them, and recalculate_account_balance — running
-- SECURITY INVOKER over `WHERE account_id = ...` — would silently
-- fold the rogue amount into the victim's current_balance on the
-- next dashboard refresh. Tampered balances; no audit trail.
--
-- This migration drops each affected policy and recreates it
-- with an additional clause:
--
--   AND account_id IN (
--     SELECT id FROM accounts WHERE household_id = <tbl>.household_id
--   )
--
-- For transactions the clause goes in WITH CHECK (INSERT-only
-- policy). For recurring_transactions and holdings the policies
-- are FOR ALL; PG uses USING as the implicit WITH CHECK when
-- one isn't given, so we add an explicit WITH CHECK to tighten
-- writes without affecting visibility of already-stored rows.
-- (A row that somehow predates this fix stays visible to its
-- household; subsequent writes that would re-violate are
-- rejected.)
--
-- Audit reference: C3.
--
-- Note: the audit also listed `target_allocations` (migration
-- 035) for this fix. That table has NO account_id column — its
-- PK is (household_id, asset_class) — so there's nothing to
-- constrain there. The audit was wrong on that one.
--
-- create_transfer (migration 030) is the other cross-table
-- exposure; it's the H1 follow-up because it also needs the
-- caller-supplied UUIDs replaced with auth.uid() derivation.
-- ============================================================

-- ── transactions ─────────────────────────────────────────────
DROP POLICY IF EXISTS "members can insert transactions" ON transactions;

CREATE POLICY "members can insert transactions"
  ON transactions FOR INSERT
  WITH CHECK (
    household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
    AND account_id IN (
      SELECT id FROM accounts WHERE household_id = transactions.household_id
    )
    AND (
      get_household_role(household_id) IN ('owner', 'partner')
      OR EXISTS (
        SELECT 1 FROM account_visibility_grants
        WHERE account_id = transactions.account_id
          AND granted_to = auth.uid()
          AND can_add_transactions = true
      )
    )
  );

-- ── recurring_transactions ───────────────────────────────────
DROP POLICY IF EXISTS "members can manage recurring_transactions"
  ON recurring_transactions;

CREATE POLICY "members can manage recurring_transactions"
  ON recurring_transactions FOR ALL
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
    AND account_id IN (
      SELECT id FROM accounts WHERE household_id = recurring_transactions.household_id
    )
  );

-- ── holdings ─────────────────────────────────────────────────
DROP POLICY IF EXISTS "members can manage holdings" ON holdings;

CREATE POLICY "members can manage holdings"
  ON holdings FOR ALL
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
    AND account_id IN (
      SELECT id FROM accounts WHERE household_id = holdings.household_id
    )
  );
