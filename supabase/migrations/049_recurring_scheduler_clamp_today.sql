-- ============================================================
-- Clamp `p_today` in run_recurring_scheduler.
--
-- Pre-fix: the scheduler accepts caller-supplied `p_today` and
-- emits one row per missed cycle from each rule's
-- `next_occurrence_date` up through `p_today`. A member could
-- pass `p_today := '2099-12-31'` and emit decades of catch-up
-- rows in one call — thousands of synthetic transactions
-- polluting the ledger, budget rollups, and dashboard charts
-- for everyone in the household.
--
-- The parameter exists for testability — fixed-date tests can
-- drive the emission window without freezing the system clock.
-- That's still useful, but the parameter should never be
-- interpretable as "the future." Clamp via LEAST(p_today,
-- CURRENT_DATE) so passing tomorrow / 2099 silently caps at
-- today's actual date, while a normal "today" call is a no-op
-- of the clamp.
--
-- Audit reference: M3.
-- ============================================================

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
  v_today   DATE := LEAST(p_today, CURRENT_DATE);
BEGIN
  FOR v_rule IN
    SELECT * FROM recurring_transactions
    WHERE household_id = p_household_id
      AND is_active
      AND next_occurrence_date <= v_today
  LOOP
    v_next := v_rule.next_occurrence_date;
    WHILE v_next <= v_today LOOP
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
