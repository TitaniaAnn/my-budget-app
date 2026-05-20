-- ============================================================
-- Recurring scheduler: materialise due rules into real
-- transactions.
--
-- Slice 2 of the recurring-transactions arc. Migration 031
-- landed the rules table; this migration adds the SQL plumbing
-- that turns those rules into ledger entries. A Dart-on-open
-- trigger calls the RPC once per app process; the scheduler is
-- idempotent on subsequent passes because the rule's
-- `next_occurrence_date` advances each time it emits.
--
-- Three pieces:
--
--   1. `transaction_source` enum gains the `'recurring'` value
--      so scheduler-emitted rows are distinguishable from
--      'manual' / 'import'. Slice 3's dedup pass (statement
--      imports vs scheduler emissions) will key off this.
--
--   2. `advance_recurrence_date` is a small immutable helper —
--      one source of truth for "what does +1 cycle mean for this
--      cadence?" Postgres' `+ INTERVAL '1 month'` already
--      handles the month-end edge case correctly (Jan 31 +
--      1 month → Feb 28/29), so the helper is just a CASE.
--
--   3. `run_recurring_scheduler` is the scheduler proper. For
--      every active rule whose next_occurrence_date is on or
--      before today, it loops emitting + advancing until the
--      next date is in the future. Multi-cycle catchup is
--      explicit because a user who hasn't opened the app for
--      two months should see all the missed emissions on the
--      next launch — silently skipping them would misrepresent
--      their cash flow.
--
--      Pause windows are honored: when `skipped_until_date`
--      covers the next occurrence, the scheduler advances the
--      date WITHOUT emitting. Otherwise a long pause would
--      make the rule stuck (next_occurrence forever in the
--      past) and the next pass would dump every cycle since.
--
--      Runs as the caller (no SECURITY DEFINER), so the
--      INSERTs into `transactions` are subject to the user's
--      RLS — they can only emit into their own household. The
--      function passes household_id verbatim from the rule, so
--      a cross-household exploit isn't possible.
--
-- Atomicity: the function runs in its own implicit transaction.
-- A failure half-way through (RLS rejects an insert, a bad
-- constraint, etc.) rolls EVERYTHING back. The user sees the
-- error on next pass; nothing partially emitted. That's the
-- right tradeoff vs per-rule sub-transactions, which would
-- need savepoints and would split a logically-atomic "all
-- household rules for today" into pieces.
-- ============================================================

ALTER TYPE transaction_source ADD VALUE IF NOT EXISTS 'recurring';

CREATE OR REPLACE FUNCTION advance_recurrence_date(
  p_date    DATE,
  p_cadence recurrence_cadence
)
RETURNS DATE
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT (CASE p_cadence
    WHEN 'weekly'    THEN p_date + INTERVAL '7 days'
    WHEN 'biweekly'  THEN p_date + INTERVAL '14 days'
    WHEN 'monthly'   THEN p_date + INTERVAL '1 month'
    WHEN 'quarterly' THEN p_date + INTERVAL '3 months'
    WHEN 'annual'    THEN p_date + INTERVAL '1 year'
  END)::DATE;
$$;

CREATE OR REPLACE FUNCTION run_recurring_scheduler(
  p_household_id UUID,
  p_today        DATE
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_rule    RECORD;
  v_next    DATE;
  v_emitted INTEGER := 0;
BEGIN
  FOR v_rule IN
    SELECT * FROM recurring_transactions
    WHERE household_id = p_household_id
      AND is_active
      AND next_occurrence_date <= p_today
  LOOP
    v_next := v_rule.next_occurrence_date;
    WHILE v_next <= p_today LOOP
      IF v_rule.skipped_until_date IS NULL
         OR v_next > v_rule.skipped_until_date THEN
        INSERT INTO transactions (
          household_id, account_id, amount, currency, description,
          merchant, category_id, transaction_date, pending, source,
          entered_by
        ) VALUES (
          v_rule.household_id, v_rule.account_id, v_rule.amount_cents,
          v_rule.currency, v_rule.description, v_rule.merchant,
          v_rule.category_id, v_next, false, 'recurring',
          v_rule.created_by
        );
        v_emitted := v_emitted + 1;
      END IF;
      v_next := advance_recurrence_date(v_next, v_rule.cadence);
    END LOOP;

    UPDATE recurring_transactions
       SET next_occurrence_date = v_next,
           last_emitted_at = now()
     WHERE id = v_rule.id;
  END LOOP;

  RETURN v_emitted;
END;
$$;

-- Mirrors the posture of create_transfer (migration 030) and
-- save_receipt_line_items (migration 028): grant EXECUTE to
-- regular roles, let RLS on the underlying tables do the gating.
GRANT EXECUTE ON FUNCTION advance_recurrence_date     TO anon, authenticated;
GRANT EXECUTE ON FUNCTION run_recurring_scheduler     TO anon, authenticated;
