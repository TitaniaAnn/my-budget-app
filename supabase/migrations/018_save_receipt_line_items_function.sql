-- ============================================================
-- Atomic replace of a receipt's line items.
--
-- The Dart repository previously did this in two round-trips
-- (DELETE old rows, INSERT new rows). If the insert failed after
-- the delete (network drop, validation, RLS), the receipt was
-- left with zero line items — same shape of bug that migration
-- 015 fixed for account-balance recalc.
--
-- This function does both inside a single Postgres transaction
-- and is callable via PostgREST RPC:
--   supabase.rpc('save_receipt_line_items', params: {
--     p_receipt_id: ...,
--     p_items: jsonb_array_of_items,
--   })
--
-- It runs as the caller (no SECURITY DEFINER) so existing RLS
-- on the receipts and receipt_line_items tables still applies.
-- ============================================================

CREATE OR REPLACE FUNCTION save_receipt_line_items(
  p_receipt_id UUID,
  p_items      JSONB
)
RETURNS SETOF receipt_line_items
LANGUAGE plpgsql
AS $$
BEGIN
  -- Replace, atomically.
  DELETE FROM receipt_line_items WHERE receipt_id = p_receipt_id;

  -- Empty array short-circuits — nothing to insert, return empty set.
  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RETURN;
  END IF;

  RETURN QUERY
    INSERT INTO receipt_line_items (
      receipt_id, description, amount, quantity, unit_price,
      category_id, is_tax, is_tip, is_discount, sort_order
    )
    SELECT
      p_receipt_id,
      (item->>'description')::TEXT,
      (item->>'amount')::INTEGER,
      NULLIF(item->>'quantity', '')::NUMERIC,
      NULLIF(item->>'unit_price', '')::INTEGER,
      NULLIF(item->>'category_id', '')::UUID,
      COALESCE((item->>'is_tax')::BOOLEAN, false),
      COALESCE((item->>'is_tip')::BOOLEAN, false),
      COALESCE((item->>'is_discount')::BOOLEAN, false),
      (ordinality::INTEGER) - 1
    FROM jsonb_array_elements(p_items) WITH ORDINALITY AS t(item, ordinality)
    RETURNING *;
END;
$$;
