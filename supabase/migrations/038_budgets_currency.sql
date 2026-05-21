-- ============================================================
-- Per-budget currency (multi-currency arc, slice 3).
--
-- Until now budgets.amount has been implicitly denominated in the
-- household's display currency. That works fine while the user
-- has a single currency, but a household with mixed-currency
-- accounts may want to think "I want to spend at most €500 on
-- groceries" alongside a USD budget for something else — without
-- mentally re-converting at every glance.
--
-- This migration adds the column. The comparison math (budget cap
-- vs spending) moves to Dart-side in BudgetWithSpending: the
-- budget's `amount` converts to the household's display currency
-- via the existing FX rates before being compared with the
-- spending total the RPC already returns in display currency.
-- Storing the budget in its own currency preserves the user's
-- intent ("I budgeted €500") through display-currency changes.
--
-- Default 'USD' so every existing row gets a sane value at column
-- addition. Existing budgets continue to be compared in USD; new
-- budgets default to USD too unless the UI opts in to picking.
-- ============================================================

ALTER TABLE budgets
  ADD COLUMN currency CHAR(3) NOT NULL DEFAULT 'USD';
