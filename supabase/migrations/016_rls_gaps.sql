-- ============================================================
-- Fill in RLS policies that were missing from the initial schema.
--
-- Tables with RLS enabled but no policies behave as "deny everything",
-- which silently broke several features (visibility grants, partner
-- permissions, custom categories for non-owners, receipt edits).
-- ============================================================

-- ─── account_visibility_grants ──────────────────────────────────────────────
-- Owner can manage; the user the grant is for can read it.
CREATE POLICY "owner can manage visibility grants"
  ON account_visibility_grants FOR ALL
  USING (
    account_id IN (
      SELECT id FROM accounts
       WHERE get_household_role(household_id) = 'owner'
    )
  );

CREATE POLICY "grantee can read visibility grants"
  ON account_visibility_grants FOR SELECT
  USING (granted_to = auth.uid());

-- ─── partner_permissions ────────────────────────────────────────────────────
-- Owner can manage; the partner the permission applies to can read it.
CREATE POLICY "owner can manage partner permissions"
  ON partner_permissions FOR ALL
  USING (get_household_role(household_id) = 'owner');

CREATE POLICY "partner can read own permissions"
  ON partner_permissions FOR SELECT
  USING (partner_user_id = auth.uid());

-- ─── categories ─────────────────────────────────────────────────────────────
-- Original schema only allowed owners to create/edit/delete categories.
-- The Add Category sheet is shown to all members; broaden to any household
-- member for their own household's custom categories. System defaults
-- (household_id IS NULL) are still untouchable.
DROP POLICY IF EXISTS "owner can manage categories" ON categories;

CREATE POLICY "members can manage household categories"
  ON categories FOR ALL
  USING (
    household_id IS NOT NULL
    AND household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    household_id IS NOT NULL
    AND household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

-- ─── receipts ───────────────────────────────────────────────────────────────
-- The original schema had SELECT and INSERT but no UPDATE or DELETE policy,
-- so updateReceipt() and deleteReceipt() silently no-op'd for everyone.
CREATE POLICY "uploader or owner can update receipts"
  ON receipts FOR UPDATE
  USING (
    uploaded_by = auth.uid()
    OR get_household_role(household_id) = 'owner'
  );

CREATE POLICY "uploader or owner can delete receipts"
  ON receipts FOR DELETE
  USING (
    uploaded_by = auth.uid()
    OR get_household_role(household_id) = 'owner'
  );

-- ─── storage.objects: receipts bucket delete ────────────────────────────────
-- The 005 policy was named "uploader can delete" but actually allowed ANY
-- household member to delete anyone's receipt image. Re-scope it to the
-- uploader (looked up via the receipts table) or the household owner.
DROP POLICY IF EXISTS "uploader can delete receipt images" ON storage.objects;

CREATE POLICY "uploader or owner can delete receipt images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'receipts'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.receipts r
       WHERE r.storage_path = storage.objects.name
         AND (
           r.uploaded_by = auth.uid()
           OR get_household_role(r.household_id) = 'owner'
         )
    )
  );
