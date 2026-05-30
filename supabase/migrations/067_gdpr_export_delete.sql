-- ============================================================
-- Audit 2026-05-26 M3: GDPR Right to Access (Art. 15) +
-- Right to Erasure (Art. 17).
--
-- The audit_2026_05_25 C3 fix renamed the destructive Settings
-- button from "Delete Account" (which didn't delete anything) to
-- "Sign Out & Request Deletion" — honest about not auto-
-- deleting. This migration is the actual implementation.
--
-- Two RPCs:
--   * `export_my_data()` — returns one JSONB blob containing
--     every row the caller can see across every user-data
--     table. SECURITY DEFINER so RLS already does the
--     scoping; we just aggregate.
--   * `delete_my_household(p_household_id UUID)` — caller must
--     be the household owner; cascades wire the rest. The auth
--     user record itself isn't deleted here (needs the admin
--     API); the matching edge function
--     `supabase/functions/delete-my-account/` wraps both steps
--     so the UI gets a single call.
--
-- What's NOT in the export (deliberately):
--   * `plaid_items.access_token_encrypted` — encrypted at rest
--     (migration 066) and not portable across deployments
--     anyway; users export their bank-linked metadata
--     (institution name, item id) without the credential.
--   * Image bytes from the receipts bucket — JSON-bundling
--     megabytes of binary doesn't make sense. The `storage_path`
--     is included so the user could request the images
--     separately if needed.
--   * `pending_writes` queue — local-only state on the user's
--     device, not server-canonical.
--
-- Both RPCs are REVOKE/GRANT'd so only `authenticated` can call.
-- ============================================================

-- ── export_my_data() ─────────────────────────────────────────

-- SECURITY DEFINER (not INVOKER): the function needs to read
-- auth.users (for the user row) which the authenticated role
-- doesn't hold SELECT on by default. Every nested query still
-- filters by auth.uid() or household_id constrained by
-- household_members.user_id = auth.uid(), so the function's
-- output is scoped to what the caller already owns.
CREATE OR REPLACE FUNCTION public.export_my_data()
RETURNS JSONB
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
    my_households AS (
      SELECT h.*
        FROM households h
        JOIN household_members hm ON hm.household_id = h.id
        WHERE hm.user_id = auth.uid()
    ),
    my_household_ids AS (
      SELECT id FROM my_households
    )
  SELECT jsonb_build_object(
    'exported_at',  now(),
    'user_id',      auth.uid(),
    'user', (
      -- No dedicated profiles table; user-level info lives on
      -- auth.users. Pull the safe fields (skip credentials and
      -- internal Supabase columns).
      SELECT jsonb_build_object(
        'id',                  u.id,
        'email',               u.email,
        'created_at',          u.created_at,
        'last_sign_in_at',     u.last_sign_in_at,
        'raw_user_meta_data',  u.raw_user_meta_data
      )
      FROM auth.users u
      WHERE u.id = auth.uid()
    ),
    'households', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'household', row_to_json(h),
          'members', (
            SELECT COALESCE(jsonb_agg(row_to_json(m)), '[]'::jsonb)
              FROM household_members m
              WHERE m.household_id = h.id
          ),
          'accounts', (
            SELECT COALESCE(jsonb_agg(row_to_json(a)), '[]'::jsonb)
              FROM accounts a
              WHERE a.household_id = h.id
          ),
          'transactions', (
            SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb)
              FROM transactions t
              WHERE t.household_id = h.id
          ),
          'categories', (
            SELECT COALESCE(jsonb_agg(row_to_json(c)), '[]'::jsonb)
              FROM categories c
              WHERE c.household_id = h.id
          ),
          'budgets', (
            SELECT COALESCE(jsonb_agg(row_to_json(b)), '[]'::jsonb)
              FROM budgets b
              WHERE b.household_id = h.id
          ),
          'receipts', (
            SELECT COALESCE(jsonb_agg(row_to_json(r)), '[]'::jsonb)
              FROM receipts r
              WHERE r.household_id = h.id
          ),
          'receipt_line_items', (
            SELECT COALESCE(jsonb_agg(row_to_json(li)), '[]'::jsonb)
              FROM receipt_line_items li
              JOIN receipts r ON r.id = li.receipt_id
              WHERE r.household_id = h.id
          ),
          'holdings', (
            SELECT COALESCE(jsonb_agg(row_to_json(hld)), '[]'::jsonb)
              FROM holdings hld
              WHERE hld.household_id = h.id
          ),
          'recurring_transactions', (
            SELECT COALESCE(jsonb_agg(row_to_json(rt)), '[]'::jsonb)
              FROM recurring_transactions rt
              WHERE rt.household_id = h.id
          ),
          'fx_rates', (
            SELECT COALESCE(jsonb_agg(row_to_json(fr)), '[]'::jsonb)
              FROM fx_rates fr
              WHERE fr.household_id = h.id
          ),
          'transaction_tags', (
            SELECT COALESCE(jsonb_agg(row_to_json(tt)), '[]'::jsonb)
              FROM transaction_tags tt
              WHERE tt.household_id = h.id
          ),
          'transaction_tag_assignments', (
            SELECT COALESCE(jsonb_agg(row_to_json(tta)), '[]'::jsonb)
              FROM transaction_tag_assignments tta
              JOIN transactions t ON t.id = tta.transaction_id
              WHERE t.household_id = h.id
          ),
          'receipt_line_item_tag_assignments', (
            SELECT COALESCE(jsonb_agg(row_to_json(rta)), '[]'::jsonb)
              FROM receipt_line_item_tag_assignments rta
              JOIN receipt_line_items li ON li.id = rta.line_item_id
              JOIN receipts r ON r.id = li.receipt_id
              WHERE r.household_id = h.id
          ),
          'plaid_items', (
            -- access_token_encrypted deliberately omitted
            SELECT COALESCE(jsonb_agg(
              jsonb_build_object(
                'id',                 pi.id,
                'household_id',       pi.household_id,
                'created_by',         pi.created_by,
                'plaid_item_id',      pi.plaid_item_id,
                'plaid_institution_id', pi.plaid_institution_id,
                'institution_name',   pi.institution_name,
                'environment',        pi.environment,
                'last_sync_at',       pi.last_sync_at,
                'last_sync_error',    pi.last_sync_error,
                'consent_expires_at', pi.consent_expires_at,
                'is_active',          pi.is_active,
                'created_at',         pi.created_at,
                'updated_at',         pi.updated_at
              )), '[]'::jsonb)
              FROM plaid_items pi
              WHERE pi.household_id = h.id
          ),
          'scenarios', (
            SELECT COALESCE(jsonb_agg(row_to_json(s)), '[]'::jsonb)
              FROM scenarios s
              WHERE s.household_id = h.id
          ),
          'scenario_events', (
            SELECT COALESCE(jsonb_agg(row_to_json(se)), '[]'::jsonb)
              FROM scenario_events se
              JOIN scenarios s ON s.id = se.scenario_id
              WHERE s.household_id = h.id
          )
        )
      ), '[]'::jsonb)
        FROM my_households h
    ),
    'device_push_tokens', (
      SELECT COALESCE(jsonb_agg(row_to_json(dpt)), '[]'::jsonb)
        FROM device_push_tokens dpt
        WHERE dpt.user_id = auth.uid()
    )
  );
$$;

REVOKE EXECUTE ON FUNCTION public.export_my_data()
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.export_my_data()
  TO authenticated;

-- ── delete_my_household(p_household_id) ──────────────────────

-- SECURITY DEFINER so the DELETE bypasses RLS on `households`
-- (which has no FOR DELETE policy by default). The function's
-- get_household_role() check is the actual authorization gate
-- and runs BEFORE the DELETE — non-owners hit 42501.
CREATE OR REPLACE FUNCTION public.delete_my_household(
  p_household_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'delete_my_household: caller is not authenticated'
      USING ERRCODE = '42501';
  END IF;

  -- Only the owner can wipe the household. Partners and
  -- children must request the owner to delete on their behalf,
  -- or sign themselves out as members via household_members
  -- (covered by the existing leave_household flow).
  v_role := get_household_role(p_household_id);
  IF v_role IS DISTINCT FROM 'owner' THEN
    RAISE EXCEPTION
      'delete_my_household: caller is not the owner of household %',
      p_household_id
      USING ERRCODE = '42501';
  END IF;

  -- Cascades from migration 001 wire most of the deletion:
  --   * household_members ON DELETE CASCADE
  --   * accounts ON DELETE CASCADE → transactions cascade
  --   * categories ON DELETE CASCADE
  --   * budgets ON DELETE CASCADE
  --   * receipts ON DELETE CASCADE → receipt_line_items cascade
  --   * holdings, target_allocations, recurring_transactions
  --   * scenarios → scenario_events
  --   * transaction_tags → assignments
  --   * fx_rates, plaid_items, plaid_webhook_events
  -- One DELETE statement covers the whole graph.
  DELETE FROM households WHERE id = p_household_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_my_household(UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_my_household(UUID)
  TO authenticated;
