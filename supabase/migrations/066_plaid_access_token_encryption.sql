-- ============================================================
-- Audit 2026-05-26 M2: encrypt plaid_items.access_token at rest.
--
-- Migration 054 deferred this with the comment "Stored plaintext
-- for Phase 1; pgcrypto + Vault wrap is a documented follow-up."
-- This is that follow-up. The audit calls out three threats the
-- prior column-level REVOKE did NOT cover:
--   1. Service-role compromise (an exposed service key reads
--      the plaintext token).
--   2. Accidental dump exposure (pg_dump, backup retrieval, a
--      copy-paste into a support ticket).
--   3. Insider access via the Supabase Studio UI.
--
-- Pattern: pgcrypto's pgp_sym_encrypt + a key stored in
-- vault.secrets. Two SECURITY DEFINER accessor functions on
-- public — set_plaid_access_token / get_plaid_access_token —
-- mediate every write and every read. The edge functions stop
-- touching the column directly. The plaintext column is dropped.
--
-- Why pgcrypto + Vault (not pgsodium directly):
--   * pgcrypto.pgp_sym_encrypt is universally available across
--     Supabase tiers.
--   * Vault keeps the symmetric key out of pg_dump (it's stored
--     encrypted at rest using the project's master key).
--   * SECURITY DEFINER + REVOKE EXECUTE FROM anon,authenticated
--     keeps the API surface tight — only service_role can
--     invoke. The edge functions use a service-role client.
--
-- Dev vs production keys:
--   * For local development, the DO block below seeds a
--     placeholder key if `plaid_access_token_key` doesn't
--     already exist. The literal value is documented in the
--     comment so future devs know it's not a real secret.
--   * For production, the operator MUST run
--     `select vault.update_secret(...)` (or rotate via the
--     Supabase dashboard) BEFORE deploying this migration to
--     prevent any production token ever being encrypted under
--     the dev placeholder. The migration is idempotent: if a
--     real key already exists with the same name, the seed is
--     skipped.
-- ============================================================

-- ── Extensions ──────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS supabase_vault;

-- ── Key seed (dev fallback; production rotates before deploy) ─

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM vault.secrets WHERE name = 'plaid_access_token_key'
  ) THEN
    PERFORM vault.create_secret(
      'dev-only-replace-before-production-deploy-32b',
      'plaid_access_token_key',
      'Symmetric key for plaid_items.access_token encryption ' ||
      '(migration 066, audit 2026-05-26 M2). Rotate via dashboard ' ||
      'before any production token is written.'
    );
  END IF;
END $$;

-- ── Encrypted column + accessors ─────────────────────────────

ALTER TABLE plaid_items
  ADD COLUMN IF NOT EXISTS access_token_encrypted BYTEA;

-- Write path: edge functions call this RPC after upserting the
-- plaid_items row. Takes the row id + plaintext token, looks up
-- the key from vault, stores the ciphertext.
--
-- SECURITY DEFINER runs as the migration's owner (postgres /
-- supabase_admin) so the function can READ vault.decrypted_secrets
-- regardless of which role is calling. The EXECUTE grant
-- gates which roles can CALL the function — service_role only.
CREATE OR REPLACE FUNCTION public.set_plaid_access_token(
  p_item_id UUID,
  p_token   TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, extensions
AS $$
DECLARE
  v_key TEXT;
BEGIN
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
    WHERE name = 'plaid_access_token_key';
  IF v_key IS NULL THEN
    RAISE EXCEPTION
      'set_plaid_access_token: plaid_access_token_key not in vault';
  END IF;

  UPDATE plaid_items
    SET access_token_encrypted =
      extensions.pgp_sym_encrypt(p_token, v_key, 'cipher-algo=aes256')
    WHERE id = p_item_id;
END;
$$;

-- Read path: edge functions call this RPC to fetch the plaintext
-- token for use against Plaid's API. Returns NULL when the row
-- doesn't exist OR no ciphertext is stored (defensive — should
-- never happen in practice after the migration step below).
CREATE OR REPLACE FUNCTION public.get_plaid_access_token(
  p_item_id UUID
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, extensions
AS $$
DECLARE
  v_key   TEXT;
  v_token TEXT;
BEGIN
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
    WHERE name = 'plaid_access_token_key';
  IF v_key IS NULL THEN
    RAISE EXCEPTION
      'get_plaid_access_token: plaid_access_token_key not in vault';
  END IF;

  SELECT extensions.pgp_sym_decrypt(access_token_encrypted, v_key)
    INTO v_token
    FROM plaid_items
    WHERE id = p_item_id
      AND access_token_encrypted IS NOT NULL;

  RETURN v_token;
END;
$$;

-- ── Backfill existing plaintext tokens ───────────────────────

DO $$
DECLARE
  v_key TEXT;
BEGIN
  SELECT decrypted_secret INTO v_key
    FROM vault.decrypted_secrets
    WHERE name = 'plaid_access_token_key';
  IF v_key IS NULL THEN
    RAISE EXCEPTION
      'backfill: plaid_access_token_key not in vault';
  END IF;

  UPDATE plaid_items
    SET access_token_encrypted =
      extensions.pgp_sym_encrypt(access_token, v_key, 'cipher-algo=aes256')
    WHERE access_token IS NOT NULL
      AND access_token_encrypted IS NULL;
END $$;

-- ── Drop the plaintext column ────────────────────────────────

ALTER TABLE plaid_items DROP COLUMN IF EXISTS access_token;

-- ── Permission lockdown on the accessors ─────────────────────

REVOKE EXECUTE ON FUNCTION public.set_plaid_access_token(UUID, TEXT)
  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_plaid_access_token(UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.set_plaid_access_token(UUID, TEXT)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.get_plaid_access_token(UUID)
  TO service_role;
