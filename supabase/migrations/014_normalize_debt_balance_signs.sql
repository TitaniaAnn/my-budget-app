-- ============================================================
-- Normalize debt-account balance sign convention.
--
-- Convention going forward: account.current_balance and
-- account.starting_balance are SIGNED.
--   • assets (checking, savings, brokerage, …)  → positive
--   • liabilities (credit_card, mortgage)        → negative
--
-- This matches the transactions.amount convention (negative = debit),
-- so recalculating a balance is just starting_balance + SUM(amount).
-- Net worth = SUM(current_balance) across all accounts; no special-casing.
--
-- Existing data: if any liability account has a positive balance it was
-- entered with the old "amount owed" convention. Flip those rows so the
-- new readers (dashboard net worth, etc.) compute correctly.
-- ============================================================

UPDATE accounts
   SET starting_balance = -ABS(starting_balance),
       current_balance  = -ABS(current_balance)
 WHERE account_type IN ('credit_card', 'mortgage')
   AND (starting_balance > 0 OR current_balance > 0);
