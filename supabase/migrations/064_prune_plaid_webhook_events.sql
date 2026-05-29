-- ============================================================
-- Audit 2026-05-26 M4: plaid_webhook_events retention.
--
-- Migration 058 added the audit table; nothing prunes it. Plaid
-- sends webhooks per item per sync; a heavy household with
-- many institutions grows unbounded. Mirror the
-- prune_notification_log(retention_days) shape (migration 040).
--
-- 90 days default. Per item the realistic event volume is
-- modest (transaction syncs + occasional item-error notifications),
-- so a year of retention would still be small — but 90 days
-- matches the in-repo precedent and is long enough to
-- investigate any production incident a quarter back.
--
-- SECURITY DEFINER because plaid_webhook_events has no client-
-- facing RLS (default-deny — the table is service-role-only).
-- Without DEFINER an authenticated caller couldn't reach the
-- table at all, even to call the prune. Function search_path
-- pinned to public so a hostile temp table can't shadow our
-- target.
-- ============================================================

CREATE OR REPLACE FUNCTION prune_plaid_webhook_events(
  p_retention_days INTEGER DEFAULT 90
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted INTEGER;
BEGIN
  DELETE FROM plaid_webhook_events
    WHERE received_at < now() - make_interval(days => p_retention_days);
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

-- Restrict EXECUTE to the service role only; this is an admin /
-- ops function, not something a client should be able to invoke.
REVOKE EXECUTE ON FUNCTION prune_plaid_webhook_events(INTEGER)
  FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION prune_plaid_webhook_events(INTEGER)
  TO service_role;
