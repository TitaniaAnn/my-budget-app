-- Allow household owners and the transaction's original enterer to delete.
CREATE POLICY "owners and enterers can delete transactions"
  ON transactions FOR DELETE
  USING (
    get_household_role(household_id) = 'owner'
    OR entered_by = auth.uid()
  );
