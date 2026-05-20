-- ============================================================
-- get_category_spending v4: FX-aware for multi-currency households.
--
-- Migration 029 sums transaction / line-item amounts assuming a
-- single currency. For households with accounts in multiple
-- currencies, the Dart side now (slice 1 of the multi-currency
-- arc) carries display_currency + fx_rates; this redefinition
-- lets the caller pass a `{currency: rate_to_display}` JSONB so
-- each row converts before summing.
--
-- Backward compatibility:
--   * `p_rates DEFAULT NULL` preserves migration 029's behavior.
--     Callers that don't supply rates (single-currency households,
--     or paths that haven't been upgraded yet) get the same
--     totals as before — `COALESCE((p_rates->>t.currency)::numeric,
--     1)` falls through to rate=1 for every row.
--   * When p_rates IS NOT NULL, missing currencies get rate=0
--     (the COALESCE branch flips) and effectively drop out of
--     the totals. The Dart caller already knows which currencies
--     it doesn't have rates for — it surfaces that warning
--     client-side, matching the monthly report's pattern.
--
-- Line-item currency comes from the receipt's paired transaction.
-- A receipt with multiple paired transactions (installments,
-- split bills) uses one arbitrarily — in practice all paired legs
-- charge the same card and share the currency, so LIMIT 1 is
-- correct.
-- ============================================================

-- DROP the migration 029 signature explicitly. Postgres allows
-- function overloading by signature; CREATE OR REPLACE only
-- matches an existing function with the SAME signature, so
-- adding the p_rates argument creates a sibling overload rather
-- than replacing the old one. PostgREST then sees both
-- candidates and can't pick, returning 300 Multiple Choices.
DROP FUNCTION IF EXISTS get_category_spending(UUID, DATE, DATE);

CREATE OR REPLACE FUNCTION get_category_spending(
  p_household_id UUID,
  p_from         DATE,
  p_to           DATE,
  p_rates        JSONB DEFAULT NULL
)
RETURNS TABLE (
  category_id UUID,
  net_cents   INTEGER
)
LANGUAGE sql
AS $$
  WITH parts AS (
    -- Unpaired transactions: each row converts via its account's
    -- currency. Account join is required for currency since
    -- transactions.currency was added on the receipt-OCR side
    -- earlier — for consistency with the line-item branch we
    -- read currency off the transaction row directly.
    SELECT
      t.category_id,
      -ROUND(
        SUM(
          t.amount *
          COALESCE(
            (p_rates->>t.currency)::numeric,
            CASE WHEN p_rates IS NULL THEN 1 ELSE 0 END
          )
        )
      )::INTEGER AS net_cents
    FROM transactions t
    WHERE t.household_id = p_household_id
      AND t.category_id IS NOT NULL
      AND t.receipt_id IS NULL
      AND t.transaction_date BETWEEN p_from AND p_to
    GROUP BY t.category_id

    UNION ALL

    -- Line items: each one counts ONCE per receipt (gated by an
    -- EXISTS check from migration 029). Currency comes from one
    -- of the receipt's paired transactions — LIMIT 1 is safe
    -- because installments / splits share a currency in practice.
    SELECT
      li.category_id,
      ROUND(
        SUM(
          (CASE WHEN li.is_discount THEN -li.amount ELSE li.amount END) *
          COALESCE(
            (p_rates->>(
              SELECT t.currency
              FROM transactions t
              WHERE t.receipt_id = li.receipt_id
                AND t.household_id = p_household_id
              LIMIT 1
            ))::numeric,
            CASE WHEN p_rates IS NULL THEN 1 ELSE 0 END
          )
        )
      )::INTEGER AS net_cents
    FROM receipt_line_items li
    WHERE li.category_id IS NOT NULL
      AND EXISTS (
        SELECT 1
        FROM transactions t
        WHERE t.receipt_id = li.receipt_id
          AND t.household_id = p_household_id
          AND t.transaction_date BETWEEN p_from AND p_to
      )
    GROUP BY li.category_id
  )
  SELECT
    category_id,
    SUM(net_cents)::INTEGER AS net_cents
  FROM parts
  GROUP BY category_id;
$$;
