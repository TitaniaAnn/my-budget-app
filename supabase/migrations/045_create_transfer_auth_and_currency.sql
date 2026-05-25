-- ============================================================
-- create_transfer: derive auth + household + currency server-side.
--
-- The original RPC (migration 030) trusted caller-supplied
-- `p_household_id`, `p_entered_by`, and the currency hardcoded to
-- 'USD'. Three real problems with that:
--
--   1. **Attribution forgery** — a partner-role user could pass
--      ANOTHER user's id as `p_entered_by`, leaving rows whose
--      ledger says "created by Bob" when Alice actually wrote
--      them. The audit log (such as it is) lied.
--
--   2. **Cross-household transfers** — the RPC didn't verify the
--      two account ids belonged to the same household, nor that
--      either belonged to the caller's household. RLS on the
--      INSERTed rows used to catch only the household_id check;
--      pre-migration 044 a member could plant a transfer leg on
--      a victim household's account by passing their own
--      household_id with a foreign account_id. Migration 044's
--      RLS tightening closes that hole at the INSERT layer, but
--      raising explicitly here gives a clearer error and a
--      tighter security boundary.
--
--   3. **Currency lies** — a non-USD household had every transfer
--      tagged 'USD' regardless of the accounts' actual currencies.
--      Cash-flow rollups survived (transfer_id filter), but per-
--      account history showed wrong currency, and FX-aware views
--      either surfaced spurious "missing USD→EUR rate" banners
--      or silently converted the amount.
--
-- This migration drops + recreates the function with:
--
--   * Removed parameters: `p_household_id`, `p_entered_by`. The
--     Dart wrapper is updated in the same change set; no other
--     production callers exist (only the AddTransferSheet UI).
--   * `v_entered_by := auth.uid()` — attribution is whoever's
--     signed in, period.
--   * Source + destination accounts are looked up via SELECT
--     under the caller's RLS scope. An account the caller can't
--     see returns no row → RAISE. This is the explicit cross-
--     household rejection.
--   * Both accounts MUST share a household_id (sanity check —
--     RLS would reject anyway, but the error is clearer here).
--   * Both accounts MUST share a currency. Cross-currency
--     transfers are deliberately rejected: real-world bank
--     conversions use opaque internal rates the user can't
--     predict, so the right shape is two separate transactions
--     (one in each currency) the user enters themselves. If we
--     ever want to support in-app cross-currency, that's a
--     separate `create_cross_currency_transfer` RPC with an
--     explicit FX rate parameter, not a flag on this one.
--   * Both legs use the resolved currency (source == dest, so
--     either works).
--
-- Audit references: H1 (auth derivation) + H3 (currency).
-- ============================================================

-- DROP first because the old + new signatures don't match — the
-- removed parameters change the function's call shape.
DROP FUNCTION IF EXISTS create_transfer(
  UUID, UUID, UUID, INTEGER, DATE, TEXT, UUID
);

CREATE OR REPLACE FUNCTION create_transfer(
  p_from_account_id  UUID,
  p_to_account_id    UUID,
  p_amount_cents     INTEGER,
  p_transaction_date DATE,
  p_description      TEXT
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_transfer_id  UUID := gen_random_uuid();
  v_entered_by   UUID := auth.uid();
  v_from_hh      UUID;
  v_to_hh        UUID;
  v_from_ccy     CHAR(3);
  v_to_ccy       CHAR(3);
BEGIN
  IF v_entered_by IS NULL THEN
    RAISE EXCEPTION 'create_transfer: caller is not authenticated';
  END IF;
  IF p_amount_cents IS NULL OR p_amount_cents <= 0 THEN
    RAISE EXCEPTION 'create_transfer: p_amount_cents must be > 0 (got %)',
      p_amount_cents;
  END IF;
  IF p_from_account_id = p_to_account_id THEN
    RAISE EXCEPTION
      'create_transfer: source and destination accounts must differ';
  END IF;

  -- Lookups run under the caller's RLS scope. An account the
  -- caller can't see returns NULL → the IS NULL branch raises.
  -- This is the explicit cross-household-attack rejection.
  SELECT household_id, currency INTO v_from_hh, v_from_ccy
    FROM accounts WHERE id = p_from_account_id;
  IF v_from_hh IS NULL THEN
    RAISE EXCEPTION
      'create_transfer: source account % is not visible to the caller',
      p_from_account_id;
  END IF;

  SELECT household_id, currency INTO v_to_hh, v_to_ccy
    FROM accounts WHERE id = p_to_account_id;
  IF v_to_hh IS NULL THEN
    RAISE EXCEPTION
      'create_transfer: destination account % is not visible to the caller',
      p_to_account_id;
  END IF;

  IF v_from_hh <> v_to_hh THEN
    RAISE EXCEPTION
      'create_transfer: source and destination accounts must be in the '
      'same household (% vs %)', v_from_hh, v_to_hh;
  END IF;

  IF v_from_ccy <> v_to_ccy THEN
    RAISE EXCEPTION
      'create_transfer: cross-currency transfers are not supported '
      '(source=%, destination=%). Record this as two separate '
      'transactions in their respective currencies.',
      v_from_ccy, v_to_ccy;
  END IF;

  -- Source leg: money LEAVES → negative amount.
  INSERT INTO transactions (
    household_id, account_id, amount, currency, description,
    transaction_date, pending, source, entered_by, transfer_id
  )
  VALUES (
    v_from_hh, p_from_account_id, -p_amount_cents, v_from_ccy,
    p_description, p_transaction_date, false, 'manual',
    v_entered_by, v_transfer_id
  );

  -- Destination leg: money ARRIVES → positive amount.
  -- Currency matches source by construction (we just rejected the
  -- mismatch case above).
  INSERT INTO transactions (
    household_id, account_id, amount, currency, description,
    transaction_date, pending, source, entered_by, transfer_id
  )
  VALUES (
    v_to_hh, p_to_account_id, p_amount_cents, v_to_ccy,
    p_description, p_transaction_date, false, 'manual',
    v_entered_by, v_transfer_id
  );

  RETURN v_transfer_id;
END;
$$;

GRANT EXECUTE ON FUNCTION create_transfer(
  UUID, UUID, INTEGER, DATE, TEXT
) TO anon, authenticated;
