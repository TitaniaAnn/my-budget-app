-- ============================================================
-- Track ML prediction confidence per categorised transaction.
--
-- Migration 017 added `category_assigned_by` to record provenance
-- (user / keyword_matcher / ml_model). It does not record HOW
-- confident the model was — so the active-learning UX can't tell
-- a 0.95 prediction apart from a 0.56 one.
--
-- This adds `ml_model_confidence` as a small integer column in
-- basis points (0–10000, where 10000 == 1.00). Basis points
-- preserve the cents-everywhere INTEGER invariant we use for
-- money — there's no `numeric` or `float` for derived numerics.
--
-- The column is nullable: rows assigned by the user or the
-- keyword matcher don't have a meaningful confidence and we
-- don't fabricate one. Only `category_assigned_by = 'ml_model'`
-- rows should populate it.
-- ============================================================

ALTER TABLE transactions
  ADD COLUMN ml_model_confidence INTEGER
    CHECK (ml_model_confidence IS NULL
           OR (ml_model_confidence BETWEEN 0 AND 10000));

COMMENT ON COLUMN transactions.ml_model_confidence IS
  'ML top-class probability in basis points (0-10000). NULL when '
  'category_assigned_by is not ''ml_model''.';

-- Partial index: the active-learning Review surface filters on
-- `category_assigned_by = ''ml_model'' AND confidence < <threshold>`.
-- Indexing only the ML rows keeps the index small (most rows are
-- user-assigned in steady state).
CREATE INDEX transactions_ml_uncertain_idx
  ON transactions (household_id, ml_model_confidence)
  WHERE category_assigned_by = 'ml_model';
