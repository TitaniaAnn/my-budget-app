-- ============================================================
-- Multi-currency foundation — slice 1 of N.
--
-- Today every aggregation assumes one currency: net worth sums
-- `accounts.current_balance` directly, budgets compare against
-- `transactions.amount` without conversion, the monthly report
-- and dashboard charts run on raw cents. This migration lands
-- the storage and the rates the future aggregations will read,
-- and wires `households.display_currency` so we know what to
-- convert TO.
--
-- Explicitly NOT in this migration (because the conversions
-- touch more code than fits one slice):
--   * `get_category_spending` does NOT yet FX-convert
--     transactions in non-display currencies — slice 3.
--   * Budget caps stay in whatever currency the user typed —
--     slice 3.
--   * Receipt line items inherit currency from the receipt's
--     paired transaction's account; no change yet.
--
-- Slice 1 wires only the dashboard's NET WORTH math (Dart-side)
-- to use rates from this table when accounts span multiple
-- currencies. A USD-only household sees no behavioural change.
--
-- Schema choices:
--   * `households.display_currency` defaults to 'USD' so every
--     existing row gets a sane value at the moment of column
--     addition. CHAR(3) matches accounts.currency.
--   * `fx_rates` stores rate as NUMERIC(18,8) — not integer cents,
--     because exchange rates ARE the multiplier, and storing
--     them as integer "rate × 10^8" would mean every read needs
--     a divide. NUMERIC at fixed precision keeps arithmetic
--     exact without IEEE-754 surprises.
--   * Primary key on (from_currency, to_currency, as_of_date)
--     — many rates per pair (one per day) is the v1 user model;
--     "fetch the most recent rate at or before X" is the hot
--     query.
--   * Household-scoped so each household can curate its own
--     rates. RLS shared across members like other dictionary
--     tables (transaction_tags, target_allocations).
-- ============================================================

ALTER TABLE households
  ADD COLUMN display_currency CHAR(3) NOT NULL DEFAULT 'USD';

CREATE TABLE fx_rates (
  household_id    UUID    NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  from_currency   CHAR(3) NOT NULL,
  to_currency     CHAR(3) NOT NULL,
  as_of_date      DATE    NOT NULL,
  rate            NUMERIC(18, 8) NOT NULL
                  CHECK (rate > 0),
  created_by      UUID REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (household_id, from_currency, to_currency, as_of_date),
  -- Same-currency rate is meaningless and would dilute lookups.
  CHECK (from_currency <> to_currency)
);

-- The lookup pattern is "what's the most recent rate from X to Y
-- on or before date Z" — DESC index on as_of_date answers it with
-- a single index seek.
CREATE INDEX fx_rates_pair_recent_idx
  ON fx_rates (household_id, from_currency, to_currency, as_of_date DESC);

-- ─── Row Level Security ────────────────────────────────────
ALTER TABLE fx_rates ENABLE ROW LEVEL SECURITY;

-- Shared household state — any member can read or curate rates.
-- Same posture as transaction_tags / target_allocations.
CREATE POLICY "fx_rates visibility"
  ON fx_rates FOR SELECT
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "members can manage fx_rates"
  ON fx_rates FOR ALL
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

CREATE TRIGGER fx_rates_updated_at
  BEFORE UPDATE ON fx_rates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
