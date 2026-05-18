-- ============================================================
-- Find receipts in the caller's household that no transaction is
-- currently pointing at.
--
-- The transaction edit sheet needs a list to offer when a user
-- wants to attach a receipt from the transaction side. Doing this
-- in PostgREST is awkward because the filter ("no row in
-- transactions has receipt_id = r.id") doesn't fit the URL-filter
-- grammar — `NOT EXISTS` against another table needs SQL.
--
-- Returns receipts ordered by upload time (newest first) — recent
-- uploads are by far the most common pairing target. The limit
-- keeps the picker responsive on a household that has accumulated
-- hundreds of un-OCR'd captures.
--
-- Runs as the caller (no SECURITY DEFINER) so RLS on `receipts`
-- scopes the result to the caller's household. Same posture as
-- migration 019.
-- ============================================================

CREATE OR REPLACE FUNCTION fetch_unpaired_receipts(
  p_limit INTEGER DEFAULT 20
)
RETURNS SETOF receipts
LANGUAGE sql STABLE
AS $$
  SELECT r.*
  FROM receipts r
  WHERE NOT EXISTS (
    SELECT 1 FROM transactions t WHERE t.receipt_id = r.id
  )
  ORDER BY r.uploaded_at DESC
  LIMIT p_limit;
$$;
