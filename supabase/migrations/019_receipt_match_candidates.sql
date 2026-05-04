-- ============================================================
-- Find candidate transactions to pair with a receipt.
--
-- The receipt detail screen shows a "Pair to Transaction" sheet
-- that needs to surface plausible matches. Doing this in SQL
-- (instead of fetching all transactions and filtering in Dart)
-- means we only ship the top N rows over the wire and we never
-- have to over-fetch on small mobile connections.
--
-- Returns up to p_max_results transactions in the same household,
-- within ±p_date_window_days of the receipt's date, whose absolute
-- amount is within p_amount_tolerance_pct of the receipt's total
-- (or any amount if the total is unknown). Excludes transactions
-- already paired to a different receipt — pairing should never
-- silently break an existing link.
--
-- Score is the sum of two halves so each contributes 0–0.5:
--   * date proximity: 0.5 at exact match, 0 at edge of window
--   * amount proximity: 0.5 at exact match, 0 at edge of tolerance,
--                       0 if the receipt has no total yet
-- A perfect match scores 1.0; the worst row in the result set is
-- still bounded above 0 thanks to the WHERE filters.
--
-- Runs as the caller (no SECURITY DEFINER) so RLS on transactions
-- and receipts is preserved — same posture as migration 018.
-- ============================================================

CREATE OR REPLACE FUNCTION find_receipt_match_candidates(
  p_receipt_id UUID,
  p_max_results INTEGER DEFAULT 5,
  p_date_window_days INTEGER DEFAULT 3,
  p_amount_tolerance_pct NUMERIC DEFAULT 0.05
)
RETURNS TABLE (
  transaction_id   UUID,
  account_id       UUID,
  transaction_date DATE,
  amount           INTEGER,
  description      TEXT,
  merchant         TEXT,
  score            NUMERIC
)
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  v_receipt        receipts%ROWTYPE;
  v_anchor_date    DATE;
  v_target_amount  INTEGER;
BEGIN
  -- Fetching through RLS: if the user can't see this receipt, v_receipt
  -- stays NULL and we return an empty set. No info leak.
  SELECT * INTO v_receipt FROM receipts WHERE id = p_receipt_id;
  IF v_receipt IS NULL THEN
    RETURN;
  END IF;

  -- Confirmed receipt_date wins; fall back to upload date so newly-added
  -- receipts can still find candidates before OCR runs.
  v_anchor_date   := COALESCE(v_receipt.receipt_date, v_receipt.uploaded_at::DATE);
  v_target_amount := v_receipt.total_amount;

  RETURN QUERY
    SELECT
      t.id,
      t.account_id,
      t.transaction_date,
      t.amount,
      t.description,
      t.merchant,
      (
        -- Date half: linear falloff inside the window.
        (1.0 - (ABS(t.transaction_date - v_anchor_date)::NUMERIC
                / GREATEST(p_date_window_days, 1))) * 0.5
        +
        -- Amount half: 0 if the receipt has no total yet (date-only ranking),
        -- 0.5 at exact match, linear falloff to 0 at the edge of tolerance.
        CASE
          WHEN v_target_amount IS NULL THEN 0
          WHEN ABS(t.amount) = v_target_amount THEN 0.5
          ELSE GREATEST(
            0,
            (1.0 - (ABS(ABS(t.amount) - v_target_amount)::NUMERIC
                    / NULLIF(v_target_amount * p_amount_tolerance_pct, 0)))
          ) * 0.5
        END
      )::NUMERIC AS score
    FROM transactions t
    WHERE t.household_id = v_receipt.household_id
      AND t.receipt_id IS NULL
      AND t.transaction_date BETWEEN v_anchor_date - p_date_window_days
                                 AND v_anchor_date + p_date_window_days
      AND (
        v_target_amount IS NULL
        OR ABS(ABS(t.amount) - v_target_amount)
           -- Tolerance has a 1-dollar floor so a $5 coffee receipt can still
           -- match a $5.04 transaction (5% of 500 cents = 25 cents otherwise).
           <= GREATEST(v_target_amount * p_amount_tolerance_pct, 100)
      )
    ORDER BY score DESC, t.transaction_date DESC
    LIMIT p_max_results;
END;
$$;
