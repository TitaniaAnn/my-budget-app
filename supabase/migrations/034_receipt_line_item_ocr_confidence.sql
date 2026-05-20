-- ============================================================
-- OCR per-line-item confidence + review surface.
--
-- The receipt_line_items table doesn't carry a confidence value
-- today — the OCR Edge Function writes line items but the
-- "how sure was the recognizer?" signal stops at the function
-- boundary. This migration adds an INTEGER basis-points column
-- (mirroring `ml_model_confidence` on transactions) so the
-- review screen has something to sort on.
--
-- Schema choice:
--   * INTEGER basis points (0–10000) for the same reason
--     ml_model_confidence is — float comparisons in active-
--     learning thresholds were error-prone.
--   * Nullable. Existing rows have no confidence value; rows
--     the user types in manually also won't (only OCR sets
--     this). NULL == "no recognizer ran" so the review query
--     gates on `IS NOT NULL` to exclude them.
--
-- save_receipt_line_items has to learn to forward the new
-- column. Redefining the function entirely so the column list
-- stays a single source of truth — adding a column without
-- touching the RPC would silently drop the value on every save.
-- ============================================================

ALTER TABLE receipt_line_items
  ADD COLUMN ocr_confidence_bp INTEGER
  CHECK (ocr_confidence_bp IS NULL
         OR (ocr_confidence_bp >= 0 AND ocr_confidence_bp <= 10000));

-- Index supports the review-screen query "uncertain line items in
-- this household, oldest first." Partial-on-confidence + receipt-
-- joinable, but the join cost is small so we keep the index narrow.
CREATE INDEX receipt_line_items_uncertain_idx
  ON receipt_line_items (ocr_confidence_bp)
  WHERE ocr_confidence_bp IS NOT NULL;

-- ─── Redefine save_receipt_line_items to carry confidence ────
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
  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    DELETE FROM receipt_line_items WHERE receipt_id = p_receipt_id;
    RETURN;
  END IF;

  SELECT array_agg(NULLIF(item->>'id', '')::UUID)
    INTO v_keep_ids
    FROM jsonb_array_elements(p_items) AS item
   WHERE COALESCE(NULLIF(item->>'id', ''), '') <> '';

  DELETE FROM receipt_line_items
   WHERE receipt_id = p_receipt_id
     AND (v_keep_ids IS NULL OR NOT (id = ANY(v_keep_ids)));

  RETURN QUERY
  INSERT INTO receipt_line_items (
    id, receipt_id, description, amount, quantity, unit_price,
    category_id, is_tax, is_tip, is_discount, sort_order,
    ocr_confidence_bp
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
    (ordinality::INTEGER - 1),
    NULLIF(item->>'ocr_confidence_bp', '')::INTEGER
  FROM jsonb_array_elements(p_items) WITH ORDINALITY AS t(item, ordinality)
  ON CONFLICT (id) DO UPDATE SET
    description       = EXCLUDED.description,
    amount            = EXCLUDED.amount,
    quantity          = EXCLUDED.quantity,
    unit_price        = EXCLUDED.unit_price,
    category_id       = EXCLUDED.category_id,
    is_tax            = EXCLUDED.is_tax,
    is_tip            = EXCLUDED.is_tip,
    is_discount       = EXCLUDED.is_discount,
    sort_order        = EXCLUDED.sort_order,
    ocr_confidence_bp = EXCLUDED.ocr_confidence_bp
  RETURNING *;
END;
$$;
