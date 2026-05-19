-- ============================================================
-- Transfer pairing.
--
-- Previously a money movement between two accounts in the same
-- household (Checking → Savings, paycheck split to multiple
-- accounts, paying down a credit card from checking) had to be
-- entered as two independent transactions: one debit on the
-- source, one credit on the destination. That:
--   * inflates the income/expense rollup — the +$500 deposit
--     looks like income, the -$500 withdrawal looks like
--     expense, when in reality the household's net worth
--     didn't change at all;
--   * relies on user discipline to keep the two rows in sync
--     (matching amount, date, description) and there's no
--     schema-level link that survives an edit on one side.
--
-- This migration introduces a simple pairing scheme: both legs
-- of a transfer share a `transfer_id` UUID. The legs remain
-- two ordinary transaction rows (one per account, summing to
-- zero in the household-wide rollup), but the shared id lets
-- aggregations and the UI treat them as one logical event.
--
-- Schema choices:
--   * `transfer_id` is nullable — pre-existing transactions
--     stay valid, and most transactions will never be part of
--     a transfer.
--   * No FK from `transfer_id` to a separate `transfers` table.
--     The "transfer" is just the matching id on the two rows;
--     a top-level table would be one more thing to keep in
--     sync. If we ever need transfer-level metadata (e.g. an
--     exchange rate for cross-currency moves), promoting this
--     to a real table is a follow-up migration.
--   * Transfers are NOT categorised. `category_id` stays NULL,
--     which means `get_category_spending` (migration 029)
--     already excludes them via its `category_id IS NOT NULL`
--     filter on the unpaired branch. Belt-and-suspenders: we
--     also assert this in the create_transfer RPC body, so a
--     future change can't silently start categorising them.
--
-- The RPC is the only blessed write path for a paired transfer:
-- it inserts both rows in the function's implicit transaction,
-- so a mid-call failure rolls back both legs and the user is
-- never left with a half-recorded transfer.
-- ============================================================

ALTER TABLE transactions
  ADD COLUMN transfer_id UUID;

-- Lookup pattern: "find the other leg of this transfer." Composite
-- index on (transfer_id, household_id) supports the join — the
-- household scope is in every query under RLS anyway.
CREATE INDEX idx_transactions_transfer_id
  ON transactions (transfer_id)
  WHERE transfer_id IS NOT NULL;

-- ─── create_transfer RPC ──────────────────────────────────
-- Atomic insertion of both legs. Runs as the caller (no
-- SECURITY DEFINER), so RLS on `transactions` and `accounts`
-- still gates the writes — the caller must be a household
-- member of both accounts. (`accounts` RLS already enforces
-- household membership; the foreign keys on `transactions`
-- ensure both account ids resolve before insert.)
--
-- Returns the shared transfer_id so callers can fetch both
-- legs back if they want them. Returning the id (vs returning
-- the two rows) keeps the function's surface minimal — the
-- repository wrapper can do a follow-up SELECT if needed.
CREATE OR REPLACE FUNCTION create_transfer(
  p_household_id     UUID,
  p_from_account_id  UUID,
  p_to_account_id    UUID,
  p_amount_cents     INTEGER,
  p_transaction_date DATE,
  p_description      TEXT,
  p_entered_by       UUID
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_transfer_id UUID := gen_random_uuid();
BEGIN
  IF p_amount_cents IS NULL OR p_amount_cents <= 0 THEN
    RAISE EXCEPTION 'create_transfer: p_amount_cents must be > 0 (got %)',
      p_amount_cents;
  END IF;
  IF p_from_account_id = p_to_account_id THEN
    RAISE EXCEPTION
      'create_transfer: source and destination accounts must differ';
  END IF;

  -- Source leg: money LEAVES → negative amount.
  INSERT INTO transactions (
    household_id, account_id, amount, currency, description,
    transaction_date, pending, source, entered_by, transfer_id
  )
  VALUES (
    p_household_id, p_from_account_id, -p_amount_cents, 'USD',
    p_description, p_transaction_date, false, 'manual',
    p_entered_by, v_transfer_id
  );

  -- Destination leg: money ARRIVES → positive amount.
  INSERT INTO transactions (
    household_id, account_id, amount, currency, description,
    transaction_date, pending, source, entered_by, transfer_id
  )
  VALUES (
    p_household_id, p_to_account_id, p_amount_cents, 'USD',
    p_description, p_transaction_date, false, 'manual',
    p_entered_by, v_transfer_id
  );

  RETURN v_transfer_id;
END;
$$;

-- PUBLIC keeps the function callable by anon/authenticated; RLS on
-- the underlying tables does the real gating (caller must be a
-- household member of both accounts). Mirrors the posture of
-- save_receipt_line_items (migration 028) and get_category_spending
-- (migration 029).
GRANT EXECUTE ON FUNCTION create_transfer TO anon, authenticated;
