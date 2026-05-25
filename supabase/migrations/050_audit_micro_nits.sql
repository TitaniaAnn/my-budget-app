-- ============================================================
-- Two micro-fixes surfaced by the 2026-05-25 verification pass
-- on the 044-049 audit batch. Neither is a live bug — both
-- close a "silently degrades to wrong behaviour" footgun where
-- the right behaviour should be a loud failure.
--
-- (1) `create_transfer` was granted to BOTH `anon` and
--     `authenticated`. The function's first guard
--     (`auth.uid() IS NULL → RAISE`) already rejects anon
--     callers, but granting EXECUTE to anon at all is the
--     wrong shape: an unauthenticated path should not be in
--     the function's reachable surface, period. Revoke from
--     PUBLIC + anon (Supabase grants both as direct grants —
--     see migration 048 for the same pattern + diagnosis) and
--     re-affirm the authenticated grant.
--
-- (2) Migration 046 set the default of
--     `notification_log.user_id` to the zero-UUID sentinel so
--     "legacy callers that forget to pass user_id still
--     produce valid rows (degraded to broadcast dedup rather
--     than crashing)." The 2026-05-25 verification confirmed
--     both production write paths — Dart's
--     `NotificationLogRepository.claimKeys` and the
--     `send-notification` Edge Function's `dispatchPerUser` —
--     always pass an explicit `user_id`. The default is dead.
--
--     Keeping it has a real cost: the sentinel is the
--     pre-046 dedup namespace (broadcast across the
--     household). A future code path that forgets to pass
--     user_id would silently re-introduce the silencing
--     attack 046 just fixed — a write under the service role
--     bypasses the RLS check that would otherwise reject the
--     mismatch (user_id != auth.uid()). Drop the default so
--     omitting user_id is a loud NOT NULL violation, not a
--     silent degradation.
--
-- The backfilled rows from 046 (which carry the sentinel)
-- stay untouched — `recentKeys` still reads them for legacy
-- dedup honouring. We're only removing the default for NEW
-- writes.
-- ============================================================

-- (1) create_transfer: authenticated-only.
REVOKE EXECUTE ON FUNCTION public.create_transfer(
  UUID, UUID, INTEGER, DATE, TEXT
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.create_transfer(
  UUID, UUID, INTEGER, DATE, TEXT
) TO authenticated;

-- (2) notification_log.user_id: drop the silent-degradation default.
ALTER TABLE notification_log
  ALTER COLUMN user_id DROP DEFAULT;
