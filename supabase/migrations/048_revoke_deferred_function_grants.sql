-- ============================================================
-- Apply the deferred PUBLIC EXECUTE revokes from migration 024.
--
-- Migration 024 closed the same exposure on `account_household_id`
-- but explicitly deferred the older SECURITY DEFINER helpers it
-- called out at the bottom: `get_household_role` (migration 001)
-- and `create_invite` / `accept_invite` (migration 008). 24
-- migrations later, still deferred — close them now.
--
-- The exposure shape is the same as 024 described: PostgREST
-- exposes every public-schema function as an RPC reachable by
-- authenticated (and historically anon) clients. SECURITY
-- DEFINER bypasses RLS during execution, so a function that
-- looks up a household_id or grants membership can be called by
-- the wrong identity. Each function below has its own concrete
-- concern:
--
--   * get_household_role — reveals the caller's role in ANY
--     household given the household's UUID. Account UUIDs are
--     unguessable in practice, but a former member who still
--     has the household id can probe their old position.
--
--   * create_invite — restricted at the body level
--     (`get_household_role(...) != 'owner'` raises), but the
--     function shouldn't be reachable by anon at all. REVOKE
--     prevents the body from even running for an anon caller.
--
--   * accept_invite — the function takes an 8-char hex code.
--     Two concerns: (1) anon shouldn't be able to call it at all;
--     (2) the 8-hex space (4.3B values) under Supabase's default
--     rate limits is brute-forceable over time — the 7-day expiry
--     is the only bound. Closing PUBLIC EXECUTE doesn't fix (2),
--     but the audit flagged it; a per-user rate limit on this RPC
--     is the natural follow-up (would need a counter table or a
--     `pg_throttle`-style extension).
--
-- After the REVOKE, GRANT EXECUTE to `authenticated` so the
-- Dart client (signed-in user) can still call the user-facing
-- RPCs. The `postgres` role retains implicit EXECUTE on all
-- public-schema functions, so RLS policies that call
-- get_household_role keep working.
--
-- Audit reference: M2.
-- ============================================================

-- Revoke from PUBLIC (the implicit grant from CREATE FUNCTION) AND
-- from `anon` explicitly. Supabase auto-grants EXECUTE on every
-- public-schema function to anon + authenticated as direct grants,
-- not via PUBLIC inheritance — a `REVOKE FROM PUBLIC` alone leaves
-- anon's explicit grant intact and the function still callable
-- without auth. (Verified via `routine_privileges`: every public
-- function shows up with explicit grants to anon, authenticated,
-- postgres, and service_role.)
--
-- `authenticated` keeps its grant — the Dart client calls
-- create_invite / accept_invite via supabase.rpc(), and RLS
-- policies that call get_household_role execute as `postgres`
-- which retains its implicit grant either way.
REVOKE EXECUTE ON FUNCTION public.get_household_role(UUID)
  FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.create_invite(UUID, TEXT, household_role)
  FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.accept_invite(TEXT)
  FROM PUBLIC, anon;

-- Re-affirm the authenticated grant in case a prior REVOKE ALL
-- pattern ever sweeps it.
GRANT EXECUTE ON FUNCTION public.get_household_role(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_invite(UUID, TEXT, household_role)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_invite(TEXT) TO authenticated;
