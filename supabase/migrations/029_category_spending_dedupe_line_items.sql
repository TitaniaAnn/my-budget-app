-- ============================================================
-- get_category_spending v3: count each line item once regardless
-- of how many transactions pair to its receipt.
--
-- Migration 026 introduced the Option B rollup using a JOIN:
--
--   FROM receipt_line_items li
--   JOIN transactions t ON t.receipt_id = li.receipt_id
--   WHERE t.transaction_date BETWEEN p_from AND p_to
--
-- That join produces one row per (line_item × paired transaction)
-- combination. The schema allows a receipt to back multiple
-- transactions (an installment plan, a bill split across two
-- charges — see the comment on
-- TransactionsRepository.setReceiptId), and the audit's Option B
-- doesn't specify how to handle that. The 026 implementation
-- silently multiplies the line-item amounts by the pairing count
-- — a $200 receipt paid as 2 x $100 installments would add $400
-- to budgets.
--
-- This migration replaces the JOIN with an EXISTS subquery, so a
-- line item counts exactly once when ANY paired transaction for
-- its receipt sits in the window. That under-attributes the
-- spend to a single window when payments straddle months (the
-- full receipt amount lands in whichever window first sees a
-- paired transaction) — the cleanest correct interpretation
-- short of a "weight by 1/N pairings" scheme that would need its
-- own conceptual buy-in. Tests in budget_repository_test.dart
-- pin the no-double-count invariant.
--
-- Unpaired transactions and the math elsewhere are unchanged.
-- ============================================================

CREATE OR REPLACE FUNCTION get_category_spending(
  p_household_id UUID,
  p_from         DATE,
  p_to           DATE
)
RETURNS TABLE (
  category_id UUID,
  net_cents   INTEGER
)
LANGUAGE sql
AS $$
  WITH parts AS (
    -- Transactions with NO receipt: unchanged from migration 026.
    SELECT
      t.category_id,
      -SUM(t.amount)::INTEGER AS net_cents
    FROM transactions t
    WHERE t.household_id = p_household_id
      AND t.category_id IS NOT NULL
      AND t.receipt_id IS NULL
      AND t.transaction_date BETWEEN p_from AND p_to
    GROUP BY t.category_id

    UNION ALL

    -- Line items: each one counts ONCE per receipt, gated by an
    -- EXISTS check against the paired transactions. The earlier
    -- JOIN duplicated rows when a receipt had multiple paired
    -- transactions in the window.
    SELECT
      li.category_id,
      SUM(CASE WHEN li.is_discount THEN -li.amount ELSE li.amount END)
        ::INTEGER AS net_cents
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
