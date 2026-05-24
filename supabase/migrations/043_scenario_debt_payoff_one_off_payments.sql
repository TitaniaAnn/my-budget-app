-- ============================================================
-- One-off (lump-sum) extra payments for debt-payoff scenarios.
--
-- A debt-payoff plan's monthly budget is the steady-state cash the
-- user can commit. Real life isn't steady — tax refunds, bonuses,
-- side gigs, sold-the-couch — and routing those through the plan
-- meaningfully changes the debt-free date. This column captures
-- those events.
--
-- Each entry: { date, amount_cents, account_id? }.
--   * date         — calendar date the lump-sum lands. The simulator
--                    bucks it to the iteration whose monthEnd shares
--                    the same (year, month).
--   * amount_cents — magnitude (positive). Added to that month's
--                    extra-payment budget.
--   * account_id   — OPTIONAL. When set, the lump-sum pre-pays that
--                    specific debt (bypassing the strategy). When
--                    null, it flows through avalanche / snowball /
--                    custom like the rest of the extra budget.
--
-- Stored as JSONB on the scenarios row for the same reasons as
-- debt_payoff_targets: short list, read with the scenario, never
-- queried independently. NULL for kind='general' scenarios and
-- typically null for kind='debt_payoff' until the user adds one.
-- The app validates shape; no SQL CHECK because partial-write
-- rollouts shouldn't reject rows.
-- ============================================================

ALTER TABLE scenarios
  ADD COLUMN debt_payoff_one_off_payments JSONB;
