-- ============================================================
-- Recurring transactions: the proactive side of subscription
-- tracking.
--
-- The dashboard already detects probable subscriptions in
-- retrospect via SubscriptionDriftRule, but the user still has
-- to enter each Spotify charge manually as it lands. This
-- migration adds the table that captures the rule itself:
-- "this transaction repeats on this cadence, here's where to
-- file it." A scheduler that materialises due rows into
-- `transactions` is a follow-up; this migration ships just the
-- vocabulary so Dart code can talk about recurring entries
-- and the table is in place when the scheduler arrives.
--
-- Schema choices:
--   * `amount_cents` is signed exactly like `transactions.amount`
--     — a recurring rule can model either an outflow (Spotify)
--     or an inflow (paycheck, dividend, allowance) without a
--     separate "is_credit" flag;
--   * `cadence` gets a new enum (`recurrence_cadence`) instead
--     of reusing `budget_period`, because the latter includes
--     `semiannual` which essentially never appears as a real
--     subscription, and excludes `quarterly` which does (think
--     insurance premiums). Five values is the right set;
--   * `skipped_until_date` lets a user say "no charge this
--     month" without deleting the rule — Spotify pausing a
--     subscription is a real workflow that ought not require
--     re-creating the rule when service resumes;
--   * `last_emitted_at` is what the scheduler will update each
--     time it materialises a `transactions` row; null until the
--     first emission. Separate from `next_occurrence_date`
--     because the scheduler may sit dormant for days and the
--     `last_emitted` audit trail is still useful.
-- ============================================================

CREATE TYPE recurrence_cadence AS ENUM (
  'weekly',
  'biweekly',
  'monthly',
  'quarterly',
  'annual'
);

CREATE TABLE recurring_transactions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id         UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  account_id           UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  amount_cents         INTEGER NOT NULL,                   -- signed; debit < 0
  currency             CHAR(3) NOT NULL DEFAULT 'USD',
  description          TEXT NOT NULL,
  merchant             TEXT,
  category_id          UUID REFERENCES categories(id) ON DELETE SET NULL,
  cadence              recurrence_cadence NOT NULL,
  next_occurrence_date DATE NOT NULL,
  last_emitted_at      TIMESTAMPTZ,                        -- null until first emit
  skipped_until_date   DATE,                               -- null = never skip
  is_active            BOOLEAN NOT NULL DEFAULT true,
  created_by           UUID REFERENCES auth.users(id),
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- A zero-amount recurring rule is almost certainly a user mistake
  -- (or a placeholder the user forgot to fill in); the scheduler
  -- would emit useless zero-amount transaction rows. Treat it as
  -- invalid input rather than papering over it at emission time.
  CHECK (amount_cents <> 0)
);

-- The scheduler's hot query is "what active rules in this
-- household are due on or before today" — a composite index keyed
-- by (household_id, is_active, next_occurrence_date) keeps that
-- pruned without scanning the table.
CREATE INDEX recurring_transactions_due_idx
  ON recurring_transactions (household_id, is_active, next_occurrence_date);

-- ─── Row Level Security ────────────────────────────────────
ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;

-- Visible to all household members; any member can create / edit /
-- delete. Mirrors the posture of `transaction_tags` (migration 020)
-- — the recurring-rules set is shared household state, not
-- owner-only like budgets.
CREATE POLICY "recurring_transactions visibility"
  ON recurring_transactions FOR SELECT
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "members can manage recurring_transactions"
  ON recurring_transactions FOR ALL
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

-- Keep updated_at honest. Matches the trigger pattern used on
-- `transactions`, `accounts`, etc. — without this an UPDATE that
-- doesn't explicitly set updated_at leaves the column stale.
CREATE TRIGGER recurring_transactions_updated_at
  BEFORE UPDATE ON recurring_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
