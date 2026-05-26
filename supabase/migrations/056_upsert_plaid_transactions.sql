-- ============================================================
-- Plaid integration — Phase 1, slice 3: atomic upsert RPC.
--
-- The Edge Function `plaid-transactions-sync` (Phase 2) loops
-- calling Plaid's /transactions/sync, aggregates the
-- added / modified / removed arrays per Plaid account, then
-- calls this RPC ONCE per account with the resolved deltas.
--
-- Three writes happen in one transaction:
--   1. INSERT … ON CONFLICT DO NOTHING for the added array.
--      Sync replays land idempotently — a re-run of the same
--      cursor never doubles up rows.
--   2. UPDATE for the modified array. Preserves user intent
--      (category_id, notes, receipt_id, transfer_id) — those
--      are user state, not Plaid state. Plaid only owns
--      amount, currency, description, merchant, transaction_date,
--      pending.
--   3. DELETE for removed[]. Phase 1 deletes unconditionally —
--      a user-edited row that Plaid later removes loses its
--      edits. Caveat documented; reconciliation UI is a follow-up.
-- Then recalculates the account balance.
--
-- Auth model: runs as the caller (no SECURITY DEFINER) so the
-- existing RLS on `accounts` + `transactions` still applies. The
-- explicit guard at the top (`account_id` must belong to one
-- of the caller's households) is belt-and-suspenders — RLS
-- would reject the writes anyway, but raising 42501 here gives
-- a clearer error than three silent zero-row writes.
--
-- The Edge Function calls this with the user's JWT (not the
-- service role) precisely so this guard fires — the service role
-- bypasses RLS and would let a misrouted call write to the wrong
-- household.
--
-- JSONB row shape (added + modified):
--   {
--     plaid_transaction_id: text,
--     amount_cents: int,    -- already in cents, already sign-flipped
--                           -- (negative = outflow per project convention)
--     currency: text,       -- ISO 4217; defaults to 'USD' if absent
--     description: text,
--     merchant: text | null,
--     date: text,           -- YYYY-MM-DD
--     pending: bool         -- defaults to false
--   }
--
-- Returns { added: int, modified: int, removed: int } so the
-- caller can surface a "synced N rows" toast without a follow-up
-- SELECT.
--
-- Audit references: PLAID_INTEGRATION Phase 1 / Migration 052.
-- ============================================================

CREATE OR REPLACE FUNCTION public.upsert_plaid_transactions(
  p_account_id           UUID,
  p_added                JSONB,
  p_modified             JSONB,
  p_removed_external_ids TEXT[]
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_household_id   UUID;
  v_entered_by     UUID := auth.uid();
  v_added_count    INTEGER := 0;
  v_modified_count INTEGER := 0;
  v_removed_count  INTEGER := 0;
BEGIN
  IF v_entered_by IS NULL THEN
    RAISE EXCEPTION 'upsert_plaid_transactions: caller is not authenticated';
  END IF;

  -- Auth check: account must exist AND belong to one of the
  -- caller's households. The SELECT runs under RLS so an account
  -- the caller can't see returns no row → NULL → raise.
  SELECT a.household_id INTO v_household_id
    FROM accounts a
    WHERE a.id = p_account_id
      AND a.household_id IN (
        SELECT hm.household_id
          FROM household_members hm
          WHERE hm.user_id = auth.uid()
      );
  IF v_household_id IS NULL THEN
    RAISE EXCEPTION
      'upsert_plaid_transactions: account % not found or not authorized',
      p_account_id
      USING ERRCODE = '42501';
  END IF;

  -- ── Added ─────────────────────────────────────────────────
  -- INSERT … ON CONFLICT (account_id, external_id) DO NOTHING
  -- so replaying a sync doesn't double-insert. ROW_COUNT after
  -- the WITH CTE counts ONLY the rows that actually landed.
  WITH new_rows AS (
    SELECT
      v_household_id                                 AS household_id,
      p_account_id                                   AS account_id,
      v_entered_by                                   AS entered_by,
      (elem->>'amount_cents')::INTEGER               AS amount,
      COALESCE(elem->>'currency', 'USD')             AS currency,
      elem->>'description'                           AS description,
      elem->>'merchant'                              AS merchant,
      (elem->>'date')::DATE                          AS transaction_date,
      COALESCE((elem->>'pending')::BOOLEAN, false)   AS pending,
      elem->>'plaid_transaction_id'                  AS external_id
    FROM jsonb_array_elements(COALESCE(p_added, '[]'::jsonb)) AS elem
  ),
  ins AS (
    INSERT INTO transactions (
      household_id, account_id, entered_by,
      amount, currency, description, merchant,
      transaction_date, pending, source, external_id
    )
    SELECT
      household_id, account_id, entered_by,
      amount, currency, description, merchant,
      transaction_date, pending, 'plaid'::transaction_source, external_id
    FROM new_rows
    ON CONFLICT (account_id, external_id) DO NOTHING
    RETURNING id
  )
  SELECT COUNT(*)::INTEGER INTO v_added_count FROM ins;

  -- ── Modified ──────────────────────────────────────────────
  -- Update the Plaid-owned columns only. Preserve user intent:
  -- category_id, category_assigned_by, category_assigned_at,
  -- notes, receipt_id, transfer_id, tags.
  WITH mod_rows AS (
    SELECT
      elem->>'plaid_transaction_id'                  AS external_id,
      (elem->>'amount_cents')::INTEGER               AS amount,
      COALESCE(elem->>'currency', 'USD')             AS currency,
      elem->>'description'                           AS description,
      elem->>'merchant'                              AS merchant,
      (elem->>'date')::DATE                          AS transaction_date,
      COALESCE((elem->>'pending')::BOOLEAN, false)   AS pending
    FROM jsonb_array_elements(COALESCE(p_modified, '[]'::jsonb)) AS elem
  ),
  upd AS (
    UPDATE transactions t SET
      amount           = m.amount,
      currency         = m.currency,
      description      = m.description,
      merchant         = m.merchant,
      transaction_date = m.transaction_date,
      pending          = m.pending
    FROM mod_rows m
    WHERE t.account_id  = p_account_id
      AND t.external_id = m.external_id
    RETURNING t.id
  )
  SELECT COUNT(*)::INTEGER INTO v_modified_count FROM upd;

  -- ── Removed ───────────────────────────────────────────────
  -- Phase 1: unconditional delete. A user-edited row that Plaid
  -- later removes loses the edits. The spec calls this out as
  -- the known-acceptable-for-v1 caveat; the reconciliation UI
  -- (preserve rows with user state, surface a "Plaid says this
  -- no longer exists, keep or delete?" prompt) is a follow-up.
  IF p_removed_external_ids IS NOT NULL
     AND array_length(p_removed_external_ids, 1) > 0
  THEN
    WITH del AS (
      DELETE FROM transactions
        WHERE account_id  = p_account_id
          AND external_id = ANY(p_removed_external_ids)
        RETURNING id
    )
    SELECT COUNT(*)::INTEGER INTO v_removed_count FROM del;
  END IF;

  -- Recalculate the account balance via the existing helper
  -- (migration 015). Cheap when nothing changed; correct when
  -- anything did.
  PERFORM recalculate_account_balance(p_account_id);

  RETURN jsonb_build_object(
    'added',    v_added_count,
    'modified', v_modified_count,
    'removed',  v_removed_count
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.upsert_plaid_transactions(
  UUID, JSONB, JSONB, TEXT[]
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_plaid_transactions(
  UUID, JSONB, JSONB, TEXT[]
) TO authenticated;
