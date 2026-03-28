-- Add interest_rate (annual percentage rate) to accounts.
-- Stored as NUMERIC(6,4) — e.g. 0.2499 = 24.99% APR.
-- NULL means no interest applies (e.g. checking, cash).
ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS interest_rate NUMERIC(6,4);
