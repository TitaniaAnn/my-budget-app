-- ============================================================
-- Notification log pruning.
--
-- Migration 039 added notification_log as the shared dedup ledger
-- between the in-app engine and the server-side dispatcher. The
-- in-app side already prunes its SharedPreferences map at 90 days
-- (see recordFired in notification_settings_provider.dart); the
-- DB table needs an equivalent so a long-running install doesn't
-- accumulate dead keys forever.
--
-- 90 days mirrors the in-app cap. At that point the underlying
-- event (transaction id, budget period) is well outside any
-- evaluation window, so dropping the dedup row can't re-fire
-- anything that's still relevant.
--
-- The function takes household_id as input and runs as the caller
-- (SECURITY INVOKER, the default). RLS still gates the DELETE so
-- a member can only prune their own household's rows. The server-
-- side dispatcher can call it the same way via the service role.
--
-- Returns the number of rows deleted so callers can log or assert
-- on it.
-- ============================================================

CREATE OR REPLACE FUNCTION prune_notification_log(
  p_household_id    UUID,
  p_retention_days  INTEGER DEFAULT 90
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_deleted INTEGER;
BEGIN
  DELETE FROM notification_log
  WHERE household_id = p_household_id
    AND fired_at < now() - make_interval(days => p_retention_days);
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;
