-- ============================================================
-- Audit 2026-05-26 M9: consistent updated_at across tables that
-- callers actually mutate. The original schema added updated_at
-- + trigger on the ledger-style tables (households, accounts,
-- transactions, scenarios); later migrations added it on
-- holdings, recurring_transactions, target_allocations,
-- plaid_items, and fx_rates. This migration fills the four
-- remaining gaps:
--   * budgets
--   * categories
--   * receipts
--   * receipt_line_items
--
-- Why these four:
--   * budgets — caller-mutable amount/period/currency; the
--     H5-style optimistic-lock precondition that the audit
--     reuses across the queue needs updated_at to be reliable
--     here too.
--   * categories — household-specific categories can be
--     renamed/recoloured by the user. System rows
--     (household_id IS NULL) are immutable in practice; the
--     trigger is harmless on them.
--   * receipts — metadata is editable (merchant, date, total).
--   * receipt_line_items — atomic replace via
--     save_receipt_line_items (migration 028) preserves ids;
--     the row identity survives edits and updated_at gives
--     callers a reliable "last touched" timestamp.
--
-- Explicitly NOT added: notification_settings (lives in
-- mobile SharedPreferences, no server table).
--
-- The original update_updated_at() helper (migration 001:219)
-- is reused — schema-pinned, side-effect-free.
-- ============================================================

-- ── Add column to tables that don't have it yet ──

ALTER TABLE budgets
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE categories
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE receipts
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE receipt_line_items
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- ── Triggers ──

DROP TRIGGER IF EXISTS budgets_updated_at ON budgets;
CREATE TRIGGER budgets_updated_at
  BEFORE UPDATE ON budgets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS categories_updated_at ON categories;
CREATE TRIGGER categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS receipts_updated_at ON receipts;
CREATE TRIGGER receipts_updated_at
  BEFORE UPDATE ON receipts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS receipt_line_items_updated_at ON receipt_line_items;
CREATE TRIGGER receipt_line_items_updated_at
  BEFORE UPDATE ON receipt_line_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
