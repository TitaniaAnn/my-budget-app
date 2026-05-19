-- ============================================================
-- save_receipt_line_items v2: preserve IDs of rows that already
-- exist instead of nuking them on every save.
--
-- The original (migration 018) did `DELETE FROM receipt_line_items
-- WHERE receipt_id = ?` followed by a fresh INSERT — atomic, but
-- destructive to any FK that pointed at the rows being replaced.
-- The `receipt_line_item_tag_assignments` table (migration 020)
-- has exactly such an FK: cascade-deleting tag assignments every
-- time the user edited a line item meant tags on line items were
-- a write-only feature.
--
-- This redefinition takes an optional `id` per input item:
--   - non-null id: UPDATE the existing row in place (FKs survive)
--   - null id:     INSERT a new row with a fresh UUID
-- Rows owned by the receipt that aren't in the input set are
-- deleted. End result is the same "atomic replace" contract from
-- the caller's perspective, but stable IDs let downstream tables
-- keep referencing them.
--
-- Backward-compatible with migration 018 callers: an item map
-- without an `id` field still INSERTs a fresh row, matching the
-- original behavior. The repository wrapper rolls out `id` for
-- existing line items as a separate change.
--
-- Atomicity matches 018: the DELETE + INSERT...ON CONFLICT runs
-- inside the function's implicit transaction, so a mid-call
-- failure rolls everything back.
-- ============================================================

CREATE OR REPLACE FUNCTION save_receipt_line_items(
  p_receipt_id UUID,
  p_items      JSONB
)
RETURNS SETOF receipt_line_items
LANGUAGE plpgsql
AS $$
DECLARE
  v_keep_ids UUID[];
BEGIN
  -- Empty input collapses to "delete every line item on this
  -- receipt" — matches the original short-circuit.
  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    DELETE FROM receipt_line_items WHERE receipt_id = p_receipt_id;
    RETURN;
  END IF;

  -- Collect the non-null ids the caller intends to keep. Rows for
  -- this receipt whose ids AREN'T in this set get deleted —
  -- typically rows the user removed from the editor list. New
  -- rows (id NULL) don't enter this set; they're created fresh.
  SELECT array_agg(NULLIF(item->>'id', '')::UUID)
    INTO v_keep_ids
    FROM jsonb_array_elements(p_items) AS item
   WHERE COALESCE(NULLIF(item->>'id', ''), '') <> '';

  DELETE FROM receipt_line_items
   WHERE receipt_id = p_receipt_id
     AND (v_keep_ids IS NULL OR NOT (id = ANY(v_keep_ids)));

  -- Single statement handles both INSERT and UPDATE:
  --   * caller supplied id and row exists → ON CONFLICT updates
  --   * caller supplied id but row was deleted concurrently →
  --     INSERT re-creates it with that id (rare; single-user
  --     editor doesn't hit this)
  --   * caller didn't supply id → gen_random_uuid() creates a
  --     fresh row, matching migration 018 semantics
  RETURN QUERY
  INSERT INTO receipt_line_items (
    id, receipt_id, description, amount, quantity, unit_price,
    category_id, is_tax, is_tip, is_discount, sort_order
  )
  SELECT
    COALESCE(NULLIF(item->>'id', '')::UUID, gen_random_uuid()),
    p_receipt_id,
    (item->>'description')::TEXT,
    (item->>'amount')::INTEGER,
    NULLIF(item->>'quantity', '')::NUMERIC,
    NULLIF(item->>'unit_price', '')::INTEGER,
    NULLIF(item->>'category_id', '')::UUID,
    COALESCE((item->>'is_tax')::BOOLEAN, false),
    COALESCE((item->>'is_tip')::BOOLEAN, false),
    COALESCE((item->>'is_discount')::BOOLEAN, false),
    (ordinality::INTEGER - 1)
  FROM jsonb_array_elements(p_items) WITH ORDINALITY AS t(item, ordinality)
  ON CONFLICT (id) DO UPDATE SET
    description = EXCLUDED.description,
    amount      = EXCLUDED.amount,
    quantity    = EXCLUDED.quantity,
    unit_price  = EXCLUDED.unit_price,
    category_id = EXCLUDED.category_id,
    is_tax      = EXCLUDED.is_tax,
    is_tip      = EXCLUDED.is_tip,
    is_discount = EXCLUDED.is_discount,
    sort_order  = EXCLUDED.sort_order
  RETURNING *;
END;
$$;
