-- ============================================================
-- Scenario events: payoff-plan APR field.
--
-- A scenario event with event_type='payoff' models paying down a
-- specific debt account (account_id) over time. The math needs an
-- APR; we capture it on the event row rather than reading
-- accounts.interest_rate at projection time for two reasons:
--
--   1. A scenario is a what-if — the user may want to plan against
--      a different APR than today's (refinance scenarios). Letting
--      the rate live on the event keeps the plan stable.
--   2. If the underlying account's APR changes later, an already-
--      saved payoff plan shouldn't silently re-shape its timeline.
--
-- Basis points (10000 = 100%) rather than a float — same convention
-- as `ml_model_confidence` in migration 022 and the project's "no
-- floats for money/probability" rule.
--
-- Nullable because regular event types (income / expense / …)
-- don't carry an APR. The app validates on the Dart side that
-- event_type='payoff' rows have a non-null payoff_apr_bps.
-- ============================================================

ALTER TABLE scenario_events
  ADD COLUMN payoff_apr_bps INTEGER
  CHECK (payoff_apr_bps IS NULL OR payoff_apr_bps >= 0);
