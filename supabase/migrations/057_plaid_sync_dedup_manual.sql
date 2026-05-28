-- ============================================================
-- Plaid Phase 1 follow-up: dedup `added` rows against existing
-- manual / CSV-import transactions on the same account before
-- inserting them.
--
-- Without this, a household that's been entering transactions
-- manually (or importing CSV statements) gets every Plaid-
-- synced transaction as a NEW row even when the real-world
-- charge already exists in the ledger. Two rows per real
-- charge = double-counted dashboards, doubled spending, every
-- downstream rollup wrong.
--
-- Same shape as the recurring-scheduler dedup
-- (matchRecurringDuplicates in transactions_repository.dart):
-- claim-once bipartite matching on (account, amount, date
-- window). Lives in the RPC rather than the Edge Function so
-- the match-then-insert is atomic — a manual row landing
-- between the Edge Function's match-check and the RPC's INSERT
-- would otherwise produce the duplicate we're trying to avoid.
--
-- Match criteria (a Plaid added row claims an existing row IFF):
--   * same account_id
--   * exact amount (cents)
--   * transaction_date within ±3 days
--     (covers pending→posted shifts + weekend posting lag;
--     existing recurring-matcher uses ±1 day but that path
--     also constrains on the recurring-rule cadence, so the
--     larger window here is the right level of slack)
--   * existing row's source IN ('manual', 'import')
--     (never re-merge an already-Plaid row)
--   * existing row's external_id IS NULL
--     (leaves CSV-import rows with their own bank-ID alone;
--     those have explicit external_id and would conflict on
--     INSERT anyway via the (account_id, external_id) UNIQUE)
--   * existing row's transfer_id IS NULL
--     (never disrupt manually-paired transfer legs — the
--     transfer-pairing logic in `create_transfer` is explicit
--     user intent)
--   * existing row's receipt_id IS NULL
--     (never disrupt receipt-paired rows; the Option B spend
--     rollup in `get_category_spending` depends on the pair
--     staying intact)
--
-- Claim-once: each existing row matched by at most ONE Plaid
-- tx, each Plaid tx matches at most ONE existing row. Picks
-- the closest date when multiple candidates compete; ties
-- broken by oldest (smallest id::text — deterministic,
-- arbitrary).
--
-- On match: UPDATE the existing row's external_id to the
-- Plaid id and flip source to 'plaid'. Subsequent
-- /transactions/sync passes will route this row through the
-- `modified` path (matched by external_id) and update Plaid-
-- owned columns naturally. User-owned columns (category_id,
-- category_assigned_by/_at, notes) are preserved by the
-- modified-path UPDATE's column selection.
--
-- Re-creates the function from migration 056 entirely. The
-- modified / removed paths are unchanged; only the added
-- path gains the dedup pre-pass.
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
  v_merged_count   INTEGER := 0;
BEGIN
  IF v_entered_by IS NULL THEN
    RAISE EXCEPTION 'upsert_plaid_transactions: caller is not authenticated';
  END IF;

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

  -- ── Pre-pass: dedup `added` against existing manual / import rows
  -- Each Plaid tx claims at most one existing row (closest date
  -- wins, ties broken by id::text DESC = oldest first since UUID
  -- v4s are roughly insertion-ordered for our purposes). Each
  -- existing row is claimed by at most one Plaid tx.
  --
  -- Implementation: build all (added_idx, candidate_id) pairs,
  -- rank by date proximity per added row AND per candidate row,
  -- keep the row where both ranks = 1. UPDATE the matched
  -- existing rows to carry the Plaid external_id; the regular
  -- INSERT below then ON-CONFLICT-skips those external_ids.
  WITH added_rows AS (
    SELECT
      idx,
      elem->>'plaid_transaction_id'                  AS external_id,
      (elem->>'amount_cents')::INTEGER               AS amount,
      (elem->>'date')::DATE                          AS transaction_date
    FROM jsonb_array_elements(COALESCE(p_added, '[]'::jsonb))
      WITH ORDINALITY AS t(elem, idx)
  ),
  candidates AS (
    -- Cross-join added rows with eligible existing rows on the
    -- account, then filter to the match window.
    SELECT
      a.idx,
      a.external_id AS plaid_external_id,
      t.id          AS existing_id,
      ABS(t.transaction_date - a.transaction_date) AS date_distance
    FROM added_rows a
    JOIN transactions t
      ON t.account_id  = p_account_id
     AND t.amount      = a.amount
     AND t.transaction_date BETWEEN
           a.transaction_date - INTERVAL '3 days'
           AND a.transaction_date + INTERVAL '3 days'
     AND t.source IN ('manual', 'import')
     AND t.external_id IS NULL
     AND t.transfer_id IS NULL
     AND t.receipt_id  IS NULL
  ),
  -- For each Plaid added row, rank candidates by date proximity
  -- (closest first), then by existing_id::text for a deterministic
  -- tiebreaker. Keep only rank 1 per added row.
  per_added AS (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY idx
        ORDER BY date_distance ASC, existing_id::text ASC
      ) AS plaid_pref
    FROM candidates
  ),
  -- For each candidate existing row, rank the Plaid rows wanting
  -- it (same ordering). Only the rank-1 Plaid row claims it.
  per_existing AS (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY existing_id
        ORDER BY date_distance ASC, plaid_external_id ASC
      ) AS existing_pref
    FROM per_added
    WHERE plaid_pref = 1
  ),
  -- Final matches: both sides rank-1 (the bipartite picks where
  -- both ends agree on each other).
  matched AS (
    SELECT plaid_external_id, existing_id
    FROM per_existing
    WHERE existing_pref = 1
  ),
  merge AS (
    UPDATE transactions t SET
      external_id = m.plaid_external_id,
      source      = 'plaid'::transaction_source
    FROM matched m
    WHERE t.id = m.existing_id
    RETURNING t.id
  )
  SELECT COUNT(*)::INTEGER INTO v_merged_count FROM merge;

  -- ── Added ─────────────────────────────────────────────────
  -- INSERT with ON CONFLICT skips any external_id we just merged
  -- onto an existing row (the conflict tuple matches now).
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

  PERFORM recalculate_account_balance(p_account_id);

  RETURN jsonb_build_object(
    'added',    v_added_count,
    'modified', v_modified_count,
    'removed',  v_removed_count,
    'merged',   v_merged_count
  );
END;
$$;
