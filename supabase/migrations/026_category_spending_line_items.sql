-- ============================================================
-- Spending aggregation: Option B — line items override the
-- transaction-level category when a receipt is attached.
--
-- The original `get_category_spending` (migration 021) summed
-- transactions.amount per transactions.category_id. That worked
-- fine when every transaction had exactly one category, but it
-- can't represent a $200 Home Depot run split across "Home
-- Repair" and "Pottery Studio Supplies" — the budget shows
-- everything under whichever category was filed on the parent
-- transaction.
--
-- Option B treats the transaction's category_id as filing only.
-- When a transaction has a receipt attached, its line items
-- dictate the budget impact: each item's category_id is the
-- one that gets the spend, the discount lines subtract.
-- Unpaired transactions (most of them) still aggregate
-- directly from transactions.
--
-- Math, per category C inside the date window:
--   spending(C) =  -SUM(t.amount)            over unpaired transactions in C
--               +  SUM(±li.amount)           over line items in C of
--                                            receipts whose paired tx
--                                            falls in the date window
--                                            (sign flipped for is_discount)
--
-- Caveats — deliberate, per the audit's Option B:
-- 1. A paired transaction whose receipt has zero line items
--    contributes nothing to any budget. The fix is to add at
--    least one line item to the receipt (now possible via the
--    LineItemsEditorScreen).
-- 2. If line item amounts don't sum to the transaction amount
--    (e.g. tax not itemised), the difference quietly drops out.
--    Accepted: same-pattern of "explicit line items are the
--    source of truth once they exist" used elsewhere in the
--    schema.
-- 3. Refunds and discount lines both flip sign by their own
--    convention — transactions store debits as negative cents,
--    line items use is_discount + a positive amount. Both
--    converge on "positive net_cents = money out" at the
--    function boundary.
--
-- Runs as the caller (no SECURITY DEFINER) so RLS on
-- transactions, receipts, and receipt_line_items still applies.
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
    -- Transactions with NO receipt: count directly under their
    -- own category_id. Negate amount so a debit (stored as
    -- negative cents) becomes positive "spent".
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

    -- Receipts whose paired transaction falls in the window:
    -- count the line items instead. Discount lines subtract.
    -- A receipt with multiple paired transactions still counts
    -- its line items once per pairing — same semantics as
    -- counting the parent transaction once per pairing in the
    -- unpaired branch.
    SELECT
      li.category_id,
      SUM(CASE WHEN li.is_discount THEN -li.amount ELSE li.amount END)
        ::INTEGER AS net_cents
    FROM receipt_line_items li
    JOIN transactions t ON t.receipt_id = li.receipt_id
    WHERE t.household_id = p_household_id
      AND li.category_id IS NOT NULL
      AND t.transaction_date BETWEEN p_from AND p_to
    GROUP BY li.category_id
  )
  SELECT
    category_id,
    SUM(net_cents)::INTEGER AS net_cents
  FROM parts
  GROUP BY category_id;
$$;
