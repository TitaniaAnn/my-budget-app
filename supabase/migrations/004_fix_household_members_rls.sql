-- ============================================================
-- Fix: infinite recursion in household_members RLS policy
--
-- The "members can read household_members" policy queried
-- household_members from within itself, triggering the same
-- policy recursively (code 42P17).
--
-- Fix: replace the self-referencing subquery with a call to
-- get_household_role(), which is SECURITY DEFINER and therefore
-- bypasses RLS when it reads household_members.
-- ============================================================

DROP POLICY IF EXISTS "members can read household_members" ON household_members;

CREATE POLICY "members can read household_members"
  ON household_members FOR SELECT
  USING (get_household_role(household_id) IS NOT NULL);
