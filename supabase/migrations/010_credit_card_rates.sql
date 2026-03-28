-- ============================================================
-- Credit card interest rates
--
-- A single credit card account can carry multiple simultaneous
-- rates: purchase APR, cash-advance APR, balance-transfer APR,
-- penalty APR, and any of those as an introductory (0% or low)
-- rate with an expiry date.
--
-- Transactions can be tagged to a specific rate so interest
-- calculations are accurate per charge type.
-- ============================================================

CREATE TYPE credit_rate_type AS ENUM (
  'purchase',
  'cash_advance',
  'balance_transfer',
  'penalty'
);

CREATE TABLE credit_card_rates (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id   UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  rate_type    credit_rate_type NOT NULL,
  rate         NUMERIC(6,4) NOT NULL,        -- e.g. 0.2499 = 24.99%
  is_intro     BOOLEAN NOT NULL DEFAULT false,
  intro_ends_on DATE,                        -- NULL if not an intro rate
  is_active    BOOLEAN NOT NULL DEFAULT true,
  label        TEXT,                         -- optional custom label
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT intro_needs_end_date
    CHECK (NOT is_intro OR intro_ends_on IS NOT NULL)
);

ALTER TABLE credit_card_rates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "household members can read rates"
  ON credit_card_rates FOR SELECT
  USING (
    account_id IN (
      SELECT id FROM accounts
      WHERE household_id IN (
        SELECT household_id FROM household_members WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "owner can manage rates"
  ON credit_card_rates FOR ALL
  USING (
    account_id IN (
      SELECT id FROM accounts
      WHERE get_household_role(household_id) = 'owner'
    )
  );

-- Link transactions to a specific rate (optional — NULL = default purchase rate)
ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS rate_id UUID REFERENCES credit_card_rates(id) ON DELETE SET NULL;
