-- ============================================================
-- Hot-path indexes for the queries that table-scan today.
--
-- 2026-05-25 audit P1: none of these is a user-visible
-- performance problem yet, but they're the dashboard refresh,
-- the category-spending RPC, the scenario walkback, the
-- monthly-report builder, the bulk-import reconciliation, and
-- the per-account balance recalc. With seq-scan they cost
-- O(rows) per query; with these indexes O(log n) — the gap
-- widens as the household accumulates transactions. Closing
-- before they bite saves a panicked rollout migration later.
--
-- Per-index rationale:
--
--   transactions(household_id, transaction_date DESC) —
--     leading filter on every dashboard / report / scenario
--     query. DESC matches the natural order ("most recent
--     first") so a LIMIT-N + ORDER BY can do an index-only
--     scan without a sort step. `get_category_spending` and
--     `recalculate_account_balance` both benefit.
--
--   transactions(receipt_id) WHERE NOT NULL —
--     partial index because the overwhelming majority of rows
--     have NULL receipt_id and we never query for them. The
--     EXISTS subquery in `get_category_spending` (migration
--     029, dedupe-safe across multi-paired receipts) probes
--     this; so do `fetchByReceiptId`,
--     `find_receipt_match_candidates`, and
--     `fetch_unpaired_receipts`.
--
--   transactions(account_id, transaction_date DESC) —
--     account-detail views, `bulkImport` reconciliation
--     window, balance recalc. The existing UNIQUE
--     (account_id, external_id) doesn't cover the
--     date-ordered queries.
--
--   transactions(category_id) WHERE NOT NULL —
--     budget aggregation, category drill-down. The existing
--     `idx_transactions_user_labelled` is gated on
--     category_assigned_by='user', so ML-classified rows
--     fall back to seq scan for category-keyed reads.
--
--   receipt_line_items(receipt_id) —
--     opens on every receipt detail screen, every
--     `save_receipt_line_items` DELETE (preserves IDs for
--     surviving rows so FKs from tag assignments aren't
--     cascade-killed), and the inner EXISTS in
--     `get_category_spending`'s dedupe path.
--
--   receipts(household_id, uploaded_at DESC) —
--     the receipts grid's primary list query. Same pattern
--     as transactions(household_id, date): leading filter +
--     descending sort = index-only scan.
--
--   receipts(storage_path) —
--     every storage object operation triggers the delete
--     policy (`receipts_storage_delete_policy`) which scans
--     `receipts` to verify ownership. Without an index this
--     is O(rows-per-household) per storage delete.
--
-- And one drop:
--
--   target_allocations_household_idx — redundant with the PK
--     (household_id, asset_class) since `household_id` is the
--     leading column. Postgres will use the PK for any query
--     that filters on household_id alone, so the extra index
--     buys nothing and costs INSERT/UPDATE work.
--
-- All CREATE INDEX statements use the unqualified form (not
-- CONCURRENTLY) because Supabase migrations run inside a
-- transaction and CONCURRENTLY isn't allowed in one. The
-- table sizes today are tiny — these will complete in <100ms
-- even on a hot prod DB. If a future migration needs to add
-- an index to a table with millions of rows, that's the
-- moment to split it out and run CONCURRENTLY manually.
-- ============================================================

CREATE INDEX IF NOT EXISTS transactions_household_date_idx
  ON public.transactions(household_id, transaction_date DESC);

CREATE INDEX IF NOT EXISTS transactions_receipt_id_idx
  ON public.transactions(receipt_id)
  WHERE receipt_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS transactions_account_date_idx
  ON public.transactions(account_id, transaction_date DESC);

CREATE INDEX IF NOT EXISTS transactions_category_id_idx
  ON public.transactions(category_id)
  WHERE category_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS receipt_line_items_receipt_id_idx
  ON public.receipt_line_items(receipt_id);

CREATE INDEX IF NOT EXISTS receipts_household_uploaded_idx
  ON public.receipts(household_id, uploaded_at DESC);

CREATE INDEX IF NOT EXISTS receipts_storage_path_idx
  ON public.receipts(storage_path);

DROP INDEX IF EXISTS public.target_allocations_household_idx;
