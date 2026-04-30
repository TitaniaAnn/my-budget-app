-- ============================================================
-- Atomic balance recomputation.
--
-- The Dart repository previously did this in three round-trips
-- (read starting_balance, read all transactions, write back), which
-- is racy: a transaction inserted between the reads and the write
-- gets dropped from the recomputed total.
--
-- This function does the whole thing in a single statement and is
-- callable via PostgREST RPC: supabase.rpc('recalculate_account_balance').
--
-- It runs as the caller (no SECURITY DEFINER) so existing RLS on the
-- `accounts` and `transactions` tables still applies.
-- ============================================================

CREATE OR REPLACE FUNCTION recalculate_account_balance(p_account_id UUID)
RETURNS INTEGER
LANGUAGE sql
AS $$
  UPDATE accounts a
     SET current_balance = a.starting_balance
                         + COALESCE((
                             SELECT SUM(amount)::INTEGER
                               FROM transactions
                              WHERE account_id = a.id
                           ), 0)
   WHERE a.id = p_account_id
   RETURNING current_balance;
$$;
