-- ============================================================
-- Debt-payoff scenario kind.
--
-- A "debt payoff" scenario plans paying down one or more debt
-- accounts (credit cards, loans, mortgages, any combination)
-- under a chosen strategy and monthly budget. It's a NEW scenario
-- kind — the existing "general" kind keeps its
-- events-on-a-timeline shape and renders the projection chart the
-- same way it always has. Debt-payoff scenarios swap to a
-- multi-debt amortisation projection.
--
-- Why not just multiple EventType.payoff events on a general
-- scenario: those events take a FIXED monthly payment per debt
-- and run independently. A real-world debt-payoff plan reallocates
-- freed-up payment capacity as each debt clears, AND wants to
-- compare strategies (avalanche / snowball). Modelling both in the
-- general-scenario shape would fight the engine; a dedicated kind
-- is cleaner.
--
-- Schema choices:
--   * `kind TEXT NOT NULL DEFAULT 'general'` rather than an enum
--     so future kinds don't need a migration to add. App-side
--     validates against a Dart enum.
--   * `debt_payoff_targets JSONB` carries the per-debt config
--     (account_id, min_payment, captured APR). JSON over a join
--     table because the list is short, read-with-the-scenario,
--     and never queried independently.
--   * APRs are captured per-target so a saved plan stays stable
--     even if the underlying account's interest_rate changes — same
--     reasoning as scenario_events.payoff_apr_bps (migration 041).
--   * `debt_payoff_strategy` is plain TEXT: 'avalanche' / 'snowball'
--     / 'custom'. Validated app-side.
--   * `debt_payoff_monthly_budget_cents` — the total monthly $ the
--     user is committing across all debts in the plan.
--
-- All four columns are NULL for kind='general' scenarios; the app
-- enforces the kind→fields mapping rather than a SQL CHECK so a
-- partial-write during slice rollouts doesn't reject rows.
-- ============================================================

ALTER TABLE scenarios
  ADD COLUMN kind                                TEXT    NOT NULL DEFAULT 'general',
  ADD COLUMN debt_payoff_targets                 JSONB,
  ADD COLUMN debt_payoff_strategy                TEXT,
  ADD COLUMN debt_payoff_monthly_budget_cents    INTEGER
    CHECK (debt_payoff_monthly_budget_cents IS NULL
        OR debt_payoff_monthly_budget_cents >= 0);
