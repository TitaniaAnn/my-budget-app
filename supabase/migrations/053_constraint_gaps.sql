-- ============================================================
-- Constraint-gap closure (audit D1 + D2).
--
-- D1 — Missing `ON DELETE` clauses on FKs
--
-- The initial schema (migration 001) declared several FKs with no
-- ON DELETE clause, which defaults to NO ACTION. That meant:
--
--   * deleteReceipt crashed when ANY transaction referenced the
--     receipt (FK violation) — the unpair-first dance was a
--     silent UX requirement nobody documented.
--   * deleteCategory crashed when ANY transaction referenced the
--     category — same shape, but the UI promised "transactions
--     will become uncategorized" which was a lie until now.
--   * Deleting a child category was rejected silently when other
--     categories had it as a parent.
--   * Removing an account left orphan import_batches that
--     prevented future re-imports against the same account_id.
--
-- This migration changes the four genuinely-optional FKs to
-- ON DELETE SET NULL — the referencing rows survive with NULL
-- pointing back at the gone parent, matching the existing UI
-- contracts. The NOT NULL FK on `budgets.category_id` can't take
-- SET NULL; it's handled with a Dart-side guard in the
-- transactions repo (`deleteCategory` checks for budget
-- references before issuing the delete and surfaces a friendly
-- error if any exist).
--
-- NOT TOUCHED in this pass:
--   * accounts.owner_user_id — the audit flagged this as
--     "blocks auth.users cascade." The right shape is SET NULL,
--     but that requires dropping NOT NULL which means the Dart
--     Account model needs a nullable ownerUserId. Out of scope
--     for a constraint-only migration; mark as deferred.
--   * transactions.entered_by, receipts.uploaded_by,
--     budgets.created_by, account_visibility_grants.granted_by,
--     fx_rates.created_by — same "tracks who did this" shape.
--     Each could SET NULL on user delete, but the model side
--     touches Account, Receipt, Budget, etc. — separate refactor.
--
-- D2 — Missing CHECK constraints
--
--   * holdings.quantity had NO check — negative-quantity holdings
--     are nonsense. A typo (-100 instead of 100) silently inverted
--     the position's contribution to net worth.
--   * fx_rates.rate had `> 0` but no upper bound. A typo (1000
--     when 1.0 intended) would silently inflate display-currency
--     net worth 1000× — visually startling but not loud enough
--     to immediately blame the rate. The 100000 ceiling is a
--     sanity guardrail, not a market-realistic bound (no real
--     FX pair has a rate > 100000; even ZWD→USD pre-redenomination
--     never hit that).
--
-- All ALTERs are idempotent via DROP CONSTRAINT IF EXISTS so a
-- re-run after a partial failure picks up cleanly.
-- ============================================================

-- ── D1: FK ON DELETE SET NULL ────────────────────────────────

ALTER TABLE transactions
  DROP CONSTRAINT IF EXISTS transactions_receipt_id_fkey,
  ADD CONSTRAINT transactions_receipt_id_fkey
    FOREIGN KEY (receipt_id) REFERENCES receipts(id) ON DELETE SET NULL;

ALTER TABLE transactions
  DROP CONSTRAINT IF EXISTS transactions_category_id_fkey,
  ADD CONSTRAINT transactions_category_id_fkey
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;

ALTER TABLE import_batches
  DROP CONSTRAINT IF EXISTS import_batches_account_id_fkey,
  ADD CONSTRAINT import_batches_account_id_fkey
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE SET NULL;

ALTER TABLE categories
  DROP CONSTRAINT IF EXISTS categories_parent_id_fkey,
  ADD CONSTRAINT categories_parent_id_fkey
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL;

-- Note: receipt_line_items.category_id is the same shape (optional
-- FK to categories) but pre-existing schema already left it with
-- the default NO ACTION; nothing currently calls deleteCategory
-- on a category that has line items, so the user-facing breakage
-- is the transactions table only. Closing for consistency too.
ALTER TABLE receipt_line_items
  DROP CONSTRAINT IF EXISTS receipt_line_items_category_id_fkey,
  ADD CONSTRAINT receipt_line_items_category_id_fkey
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;

-- ── D2: CHECK constraints ────────────────────────────────────

-- Negative-quantity holdings are nonsense. The CHECK guards
-- the typo case (entering -100 instead of 100) silently inverting
-- the position. Use IF NOT EXISTS via the DO block so a re-run
-- doesn't fail.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'holdings_quantity_nonneg_check'
      AND conrelid = 'public.holdings'::regclass
  ) THEN
    ALTER TABLE holdings
      ADD CONSTRAINT holdings_quantity_nonneg_check
      CHECK (quantity >= 0);
  END IF;
END $$;

-- Upper-bound guardrail on fx_rates.rate. The existing `rate > 0`
-- check stays in place (separate constraint name). 100000 is a
-- generous ceiling for any plausible FX pair.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'fx_rates_rate_max_check'
      AND conrelid = 'public.fx_rates'::regclass
  ) THEN
    ALTER TABLE fx_rates
      ADD CONSTRAINT fx_rates_rate_max_check
      CHECK (rate < 100000);
  END IF;
END $$;
