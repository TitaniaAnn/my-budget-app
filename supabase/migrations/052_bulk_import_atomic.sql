-- ============================================================
-- Atomic bulk import: delete reconciled scheduler rows + upsert
-- bank rows in a single transaction.
--
-- Audit H4: pre-fix the Dart `bulkImport` did
--   1. SELECT scheduler rows in the import window
--   2. DELETE the matched scheduler rows           ← commits
--   3. UPSERT the bank rows                        ← may fail
-- If step 3 failed (network blip, RLS hiccup, CHECK violation
-- on an enriched row), the scheduler rows were already gone
-- forever — `next_occurrence_date` had already advanced past
-- today on the rule itself, so nothing re-emitted. The user's
-- ledger silently lost the recurring entry AND the bank charge.
--
-- This RPC folds (delete + insert) into one transaction so a
-- failure rolls both back. The Dart side still computes the
-- reconciliation matches (matchRecurringDuplicates — pure /
-- well-tested) and just hands the resolved IDs + bank rows
-- across. Returns the count of newly-inserted rows so the UI
-- can report "Imported N transactions (M reconciled)" without
-- a second SELECT.
--
-- JSONB-shaped input means we can grow new optional columns
-- on the import without bumping the RPC signature — the SELECT
-- pulls `e->>'foo'` and the row plain-skips an absent key
-- (extract returns NULL, NULLIF normalises empty strings the
-- same way the Dart JSON encoder would emit them).
--
-- Runs under the caller's RLS — no SECURITY DEFINER. The
-- household_id / account_id checks in the existing RLS
-- policies still gate every write the same way they did
-- pre-fix; this RPC just makes the multi-statement sequence
-- transactional.
-- ============================================================

CREATE OR REPLACE FUNCTION public.bulk_import_transactions(
  p_rows JSONB,
  p_reconciled_ids UUID[] DEFAULT ARRAY[]::UUID[]
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_inserted INTEGER;
BEGIN
  -- Delete reconciled scheduler rows first under the caller's
  -- RLS scope. ID-based filter; rows the caller can't see
  -- silently don't match (no error). When the array is empty
  -- we skip the DELETE entirely so a no-reconciliation import
  -- doesn't even open a write path.
  IF array_length(p_reconciled_ids, 1) > 0 THEN
    DELETE FROM transactions
      WHERE id = ANY(p_reconciled_ids);
  END IF;

  -- Insert the bank rows. ON CONFLICT mirrors the prior
  -- upsert(onConflict: 'account_id,external_id', ignoreDuplicates: true)
  -- shape — re-runs of the same import are idempotent.
  WITH ins AS (
    INSERT INTO transactions (
      household_id, account_id, entered_by,
      description, amount, currency, transaction_date,
      external_id, pending, source,
      category_id, category_assigned_by, category_assigned_at,
      ml_model_confidence
    )
    SELECT
      (e->>'household_id')::UUID,
      (e->>'account_id')::UUID,
      (e->>'entered_by')::UUID,
      e->>'description',
      (e->>'amount')::INTEGER,
      COALESCE(e->>'currency', 'USD'),
      (e->>'transaction_date')::DATE,
      e->>'external_id',
      COALESCE((e->>'pending')::BOOLEAN, false),
      COALESCE((e->>'source')::transaction_source, 'import'),
      NULLIF(e->>'category_id', '')::UUID,
      NULLIF(e->>'category_assigned_by', '')::category_assignment_source,
      NULLIF(e->>'category_assigned_at', '')::TIMESTAMPTZ,
      NULLIF(e->>'ml_model_confidence', '')::INTEGER
    FROM jsonb_array_elements(p_rows) AS e
    ON CONFLICT (account_id, external_id) DO NOTHING
    RETURNING id
  )
  SELECT COUNT(*)::INTEGER INTO v_inserted FROM ins;

  RETURN v_inserted;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.bulk_import_transactions(JSONB, UUID[])
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.bulk_import_transactions(JSONB, UUID[])
  TO authenticated;
