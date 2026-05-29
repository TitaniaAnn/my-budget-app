-- ============================================================
-- Replace upsert_plaid_transactions with a greedy procedural
-- matcher that handles the multi-candidate fallback case
-- (review item #3).
--
-- The migration-057 dedup used a two-stage ROW_NUMBER ranking
-- that drops candidates without backtracking. Concretely:
--
--   Plaid A → matches only Existing X (distance 0)
--   Plaid B → matches Existing X (distance 0) AND Y (distance 2)
--
-- The 057 pipeline kept only `plaid_pref=1` for each Plaid row,
-- so Plaid B's Y candidate was dropped immediately. Then the
-- `per_existing` stage picked Plaid A over Plaid B for X
-- (alphabetic tiebreaker). Plaid B ended up matching nothing —
-- even though Y was available.
--
-- The greedy fix processes candidates in (date_distance,
-- plaid_external_id) order and claims each as it goes,
-- skipping pairs where either side is already claimed. This
-- correctly falls back to second-best candidates.
--
--   for each (plaid_row, existing_row) ordered by date_distance:
--     if existing_row already claimed: skip
--     if plaid_row already claimed: skip
--     claim both → match this pair
--
-- O(N×M) per sync where N = added size, M = candidate pool,
-- both small in practice (one sync delivers tens of rows; the
-- candidate window is "manual+import rows on the same account
-- within ±3 days" — usually single digits).
--
-- The pure-greedy result isn't strictly optimal (the assignment
-- problem's optimal solution needs the Hungarian algorithm) but
-- it's correct in the "no Plaid row leaves a match on the
-- table" sense and matches what a user would expect.
--
-- Modified + removed paths are byte-for-byte unchanged from
-- migration 057.
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

  -- ── Dedup pre-pass: greedy bipartite matcher with backtrack ──
  -- Walk every (plaid_added_row, candidate_existing_row) pair in
  -- (date_distance ASC, plaid_external_id ASC, existing_id ASC)
  -- order. Maintain two sets of already-claimed ids; skip a pair
  -- if either side is taken. On match, UPDATE the existing row's
  -- external_id + source and add both ids to their claimed set.
  --
  -- Implementation note: PL/pgSQL doesn't have native "set" types
  -- but a temporary TABLE serves the same role + is automatically
  -- cleaned up at function exit.
  CREATE TEMP TABLE _claimed_plaid (external_id TEXT PRIMARY KEY)
    ON COMMIT DROP;
  CREATE TEMP TABLE _claimed_existing (id UUID PRIMARY KEY)
    ON COMMIT DROP;

  DECLARE
    rec RECORD;
  BEGIN
    FOR rec IN
      WITH added_rows AS (
        SELECT
          elem->>'plaid_transaction_id'                AS external_id,
          (elem->>'amount_cents')::INTEGER             AS amount,
          (elem->>'date')::DATE                        AS transaction_date
        FROM jsonb_array_elements(COALESCE(p_added, '[]'::jsonb)) AS elem
      )
      SELECT
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
      -- Greedy ordering: closest dates first, then deterministic
      -- tiebreaker by Plaid id then existing id. Stable across
      -- runs so the same payload always picks the same matches.
      ORDER BY date_distance ASC, a.external_id ASC, t.id::text ASC
    LOOP
      -- Skip pair if either side already claimed an earlier
      -- (closer-date) match.
      IF EXISTS (SELECT 1 FROM _claimed_plaid WHERE external_id = rec.plaid_external_id)
      THEN
        CONTINUE;
      END IF;
      IF EXISTS (SELECT 1 FROM _claimed_existing WHERE id = rec.existing_id)
      THEN
        CONTINUE;
      END IF;

      -- Match: stamp the existing row + mark both sides claimed.
      UPDATE transactions
        SET external_id = rec.plaid_external_id,
            source      = 'plaid'::transaction_source
        WHERE id = rec.existing_id;

      INSERT INTO _claimed_plaid(external_id) VALUES (rec.plaid_external_id);
      INSERT INTO _claimed_existing(id) VALUES (rec.existing_id);
      v_merged_count := v_merged_count + 1;
    END LOOP;
  END;

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

  -- Temp tables drop ON COMMIT automatically, but explicit DROP
  -- inside the same transaction frees them for a parallel call.
  DROP TABLE IF EXISTS _claimed_plaid;
  DROP TABLE IF EXISTS _claimed_existing;

  RETURN jsonb_build_object(
    'added',    v_added_count,
    'modified', v_modified_count,
    'removed',  v_removed_count,
    'merged',   v_merged_count
  );
END;
$$;
