-- ============================================================
-- Per-security tracking inside investment accounts.
--
-- The investment account types (brokerage / IRA / 401k / 529 /
-- HSA) already contribute to net worth via their currentBalance
-- — but until now there was no way to record what they're
-- actually holding. This migration adds a `holdings` table that
-- coexists with the existing balance column rather than
-- replacing it (audit's "approach 2", lower migration risk: the
-- balance stays manual and authoritative, holdings are a detail
-- view inside the account).
--
-- No price-feed integration in v1. current_value is user-
-- entered, same posture as the rest of the app's no-Plaid
-- stance. last_priced_at is provided as a "when did the user
-- last touch this" hint for stale-value warnings later.
-- ============================================================

-- ─── Asset class enum ─────────────────────────────────────
-- A short, fixed taxonomy that maps onto common pie-slice
-- groupings. Kept as an enum (rather than free text) so the
-- dashboard's allocation donut doesn't have to dedupe variants
-- like "Equity" vs "US Equity" vs "us-equity".
CREATE TYPE asset_class AS ENUM (
  'us_equity',
  'intl_equity',
  'bond',
  'real_estate',
  'cash',
  'crypto',
  'other'
);

-- ─── Holdings table ───────────────────────────────────────
CREATE TABLE holdings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  account_id      UUID NOT NULL REFERENCES accounts(id)   ON DELETE CASCADE,

  -- Ticker, fund symbol, or short crypto code. Case-preserved
  -- on input (the user writes "VTSAX" or "btc-usd" as they
  -- please); display layer is free to upper-case.
  symbol          TEXT NOT NULL,

  -- Optional full name ("Vanguard Total Stock Market Admiral",
  -- "Apple Inc.") for cards that have room beyond the ticker.
  description     TEXT,

  -- Share / unit count. NUMERIC(20,8) holds 8 decimal places
  -- — more than enough for fractional shares and standard
  -- crypto precision. Note the Dart side uses `double`, which
  -- has ~15-17 significant digits; positions with both huge
  -- units AND 8-decimal precision could see rounding at the
  -- model layer. Accepted for v1 (nobody holds a billion
  -- satoshis at fractional precision in this app).
  quantity        NUMERIC(20, 8) NOT NULL,

  -- Total cost basis in cents. Optional — a user backfilling
  -- holdings into an existing account often doesn't have it,
  -- and the lots-and-tax-basis system that would need it
  -- properly is out of scope.
  cost_basis      INTEGER,

  -- Current value in cents. Required: net worth has to mean
  -- something. User enters or updates this manually.
  current_value   INTEGER NOT NULL,

  asset_class     asset_class,

  -- When the user last entered/updated current_value. Used by
  -- a future "stale price" warning to nudge a refresh on
  -- positions that haven't been re-marked recently.
  last_priced_at  TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX holdings_account_idx  ON holdings(account_id);
CREATE INDEX holdings_household_idx ON holdings(household_id);

-- ─── updated_at trigger ───────────────────────────────────
CREATE TRIGGER holdings_updated_at BEFORE UPDATE ON holdings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── Row Level Security ───────────────────────────────────
-- Same pattern as the transactions / accounts / receipts
-- tables: visibility and management both scoped to membership
-- in the holdings' household.
ALTER TABLE holdings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members can read holdings"
  ON holdings FOR SELECT
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "members can manage holdings"
  ON holdings FOR ALL
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );
