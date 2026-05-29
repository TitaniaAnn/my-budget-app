-- ============================================================
-- Audit 2026-05-26 C4: the upsert_plaid_transactions "removed"
-- branch DELETEs every row Plaid says is gone, including rows
-- where the user manually categorized, added a note, attached a
-- receipt, or paired the row as a transfer leg. Plaid removes
-- often (pending → posted rewrites the transaction_id) — every
-- removal here destroys user work.
--
-- Worst-case scenario from the audit:
--   * Transfer legs share `transfer_id` (no FK constraint).
--   * Plaid removes one leg.
--   * Surviving leg keeps its `transfer_id` value, now dangling.
--   * Dashboard cash-flow math excludes `transfer_id IS NOT NULL`
--     rows — silently drops a legit income/expense leg from
--     the report.
--
-- Fix:
--   * Rows with NO user state (no notes, no receipt, no
--     transfer_id, category_assigned_by != 'user'): hard-delete,
--     matching Plaid's intent + the historical behavior.
--   * Rows WITH user state: soft-archive by clearing the Plaid
--     linkage (set external_id = NULL, source = 'import') so the
--     row continues to appear in the user's ledger with all
--     edits intact, but is no longer treated as Plaid-managed.
--     A future Plaid sync that re-adds the same external_id
--     will see it as new — dedup pre-pass can still merge by
--     amount+date+account if they happen to match.
--   * Transfer legs: also clear the partner leg's transfer_id
--     so the survivor stops being filtered out of cash-flow
--     rollups.
--
-- Returns: v_removed_count is hard-deletes only (matches the
-- prior shape); v_archived_count is the new soft-archive count.
-- Callers that don't read the new field stay correct.
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
  v_archived_count INTEGER := 0;
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

  -- ── Dedup pre-pass (migration 061 — unchanged) ────────────
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
      ORDER BY date_distance ASC, a.external_id ASC, t.id::text ASC
    LOOP
      IF EXISTS (SELECT 1 FROM _claimed_plaid WHERE external_id = rec.plaid_external_id)
      THEN
        CONTINUE;
      END IF;
      IF EXISTS (SELECT 1 FROM _claimed_existing WHERE id = rec.existing_id)
      THEN
        CONTINUE;
      END IF;

      UPDATE transactions
        SET external_id = rec.plaid_external_id,
            source      = 'plaid'::transaction_source
        WHERE id = rec.existing_id;

      INSERT INTO _claimed_plaid(external_id) VALUES (rec.plaid_external_id);
      INSERT INTO _claimed_existing(id) VALUES (rec.existing_id);
      v_merged_count := v_merged_count + 1;
    END LOOP;
  END;

  -- ── Added (unchanged from migration 061) ─────────────────
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

  -- ── Modified (unchanged from migration 061) ──────────────
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

  -- ── Removed — user-state-preserving (audit C4) ───────────
  IF p_removed_external_ids IS NOT NULL
     AND array_length(p_removed_external_ids, 1) > 0
  THEN
    -- Snapshot the rows Plaid wants gone so the partner-leg
    -- transfer_id unset + the user-state split can both target
    -- the same candidate set in one transaction.
    CREATE TEMP TABLE _removal_candidates ON COMMIT DROP AS
      SELECT
        id,
        transfer_id,
        category_assigned_by,
        notes,
        receipt_id
      FROM transactions
      WHERE account_id  = p_account_id
        AND external_id = ANY(p_removed_external_ids);

    -- Partner-leg unpair: when one leg of a transfer is being
    -- removed, clear transfer_id on the surviving leg so it
    -- stops being filtered out by cash-flow rollups (which
    -- exclude transfer_id IS NOT NULL).
    UPDATE transactions t
      SET transfer_id = NULL
      FROM _removal_candidates c
      WHERE t.transfer_id = c.transfer_id
        AND t.id <> c.id
        AND c.transfer_id IS NOT NULL;

    -- Soft-archive: rows with user state survive but lose
    -- Plaid attribution. The next Plaid sync that re-adds the
    -- same external_id sees it as a fresh row (dedup pre-pass
    -- may still merge if amount+date+account match).
    WITH archived AS (
      UPDATE transactions
        SET external_id = NULL,
            source      = 'import'::transaction_source
        WHERE id IN (
          SELECT id FROM _removal_candidates
          WHERE category_assigned_by = 'user'
             OR notes IS NOT NULL
             OR receipt_id IS NOT NULL
             OR transfer_id IS NOT NULL
        )
        RETURNING id
    )
    SELECT COUNT(*)::INTEGER INTO v_archived_count FROM archived;

    -- Hard-delete: rows with no user state. Matches Plaid's
    -- intent + the historical behavior for the common case.
    --
    -- `IS DISTINCT FROM 'user'` (not `<> 'user'`) is load-
    -- bearing: category_assigned_by defaults to NULL for fresh
    -- Plaid inserts, and `NULL <> 'user'` returns NULL not
    -- TRUE under three-valued logic. Without IS DISTINCT FROM,
    -- every clean (no-user-state) row would also miss the
    -- archive branch and silently stay in the table.
    WITH del AS (
      DELETE FROM transactions
        WHERE id IN (
          SELECT id FROM _removal_candidates
          WHERE category_assigned_by IS DISTINCT FROM 'user'
            AND notes IS NULL
            AND receipt_id IS NULL
            AND transfer_id IS NULL
        )
        RETURNING id
    )
    SELECT COUNT(*)::INTEGER INTO v_removed_count FROM del;

    DROP TABLE _removal_candidates;
  END IF;

  PERFORM recalculate_account_balance(p_account_id);

  DROP TABLE IF EXISTS _claimed_plaid;
  DROP TABLE IF EXISTS _claimed_existing;

  RETURN jsonb_build_object(
    'added',    v_added_count,
    'modified', v_modified_count,
    'removed',  v_removed_count,
    'archived', v_archived_count,
    'merged',   v_merged_count
  );
END;
$$;
