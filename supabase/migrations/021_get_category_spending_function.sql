-- ============================================================
-- Net spending per category over a date range.
--
-- The Dart repository previously SELECTed (category_id, amount)
-- for every transaction in the range and summed in Dart. That's
-- one round-trip but ships every row over the wire — a household
-- with five years of history can easily have 20k+ rows, all
-- discarded after summing.
--
-- This function returns one row per category with `net_cents`
-- already aggregated, callable via PostgREST RPC. Matches the
-- shape of the Dart-side return:
--   { category_id → net spent in cents (positive number) }
--
-- "Net" = debits offset by refunds posted to the same category.
-- Transactions store debits as negative cents and refunds as
-- positive, so SUM(amount) gives a value whose sign is the
-- opposite of "spent". We negate at the SQL boundary so the
-- caller sees `net_cents > 0` for ordinary spending; categories
-- where refunds exceed debits return a negative net_cents and
-- the budget UI clamps those to $0 spent.
--
-- Runs as the caller (no SECURITY DEFINER) so the existing RLS
-- on transactions still applies — same posture as 015 and 018.
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
  SELECT
    category_id,
    -SUM(amount)::INTEGER AS net_cents
  FROM transactions
  WHERE household_id = p_household_id
    AND category_id IS NOT NULL
    AND transaction_date >= p_from
    AND transaction_date <= p_to
  GROUP BY category_id;
$$;
