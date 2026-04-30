-- ============================================================
-- Track HOW a transaction's category was assigned (vs. how the
-- transaction was created — that's `transactions.source`).
--
-- Needed because the upcoming ML categorizer is trained only on
-- ground-truth labels: rows where the user explicitly chose the
-- category (manual entry, manual edit, or accepting a suggestion).
-- Predictions made by the keyword matcher or the ML model itself
-- must NOT feed back into training, or the model will overfit to
-- its own past mistakes.
-- ============================================================

CREATE TYPE category_assignment_source AS ENUM (
  'user',             -- user picked the category explicitly (ground truth)
  'keyword_matcher',  -- assigned by the legacy CategoryMatcher
  'ml_model'          -- assigned by the on-device ML classifier
);

ALTER TABLE transactions
  ADD COLUMN category_assigned_by category_assignment_source,
  ADD COLUMN category_assigned_at TIMESTAMPTZ;

-- Backfill: best-effort guess for existing rows.
--   • Imported rows whose category was set at insert time and never
--     touched since (updated_at == created_at) were almost certainly
--     pre-filled by the keyword matcher in import_statement_sheet.
--   • Everything else with a category is treated as user-assigned —
--     either created manually, or edited at least once after import.
UPDATE transactions
   SET category_assigned_by = CASE
         WHEN source = 'import' AND updated_at = created_at
              THEN 'keyword_matcher'::category_assignment_source
         ELSE 'user'::category_assignment_source
       END,
       category_assigned_at = updated_at
 WHERE category_id IS NOT NULL;

-- Partial index: speeds up the training-data dump query
--   (SELECT ... WHERE category_assigned_by = 'user' AND category_id IS NOT NULL).
CREATE INDEX idx_transactions_user_labelled
  ON transactions (household_id, category_id)
  WHERE category_assigned_by = 'user' AND category_id IS NOT NULL;
