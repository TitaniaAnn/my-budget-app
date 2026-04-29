-- Add starting_balance to accounts.
-- This records the account balance before any tracked transactions so the app
-- can show a running balance as transactions are applied.
-- current_balance remains the computed total (starting_balance + sum of transactions).

ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS starting_balance INTEGER NOT NULL DEFAULT 0;
