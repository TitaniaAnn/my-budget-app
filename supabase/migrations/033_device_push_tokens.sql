-- ============================================================
-- Device push-notification tokens.
--
-- Foundation for slice 2 of notifications: pushes that arrive
-- while the app is closed. The local engine (services/
-- notification_engine.dart) handles the in-app case; this table
-- gives a future Edge Function somewhere to look up the
-- destination tokens when it wants to send a real push.
--
-- This migration lands the storage and the access patterns. It
-- deliberately does NOT:
--   * call Firebase / APNS (no project credentials in this repo);
--   * add a delivery Edge Function (will live in
--     supabase/functions/send-notification/ in a follow-up
--     session once the Firebase project exists);
--   * add the server-side triggers that decide WHEN to send (will
--     port the Dart engine's logic to TS or SQL in the same
--     follow-up).
--
-- Schema choices:
--   * `platform` is plain text so we can grow into apns / web push
--     without an enum migration. The Dart side uses a
--     `DevicePushPlatform` enum that maps to a documented value
--     set (`fcm_android`, `fcm_ios`, …) — if the set ever
--     stabilises, a CHECK constraint or enum can be layered on.
--   * `household_id` is denormalised onto the row. The same column
--     lives on `auth.users` indirectly via `household_members`,
--     but joining through that table from a server-side push job
--     is one more query and one more RLS surface to think about.
--     The (small) duplication cost buys a simple "send to every
--     token in this household" query.
--   * UNIQUE (user_id, token) lets re-registering the same FCM
--     token (which the client does on every app start to keep
--     `last_seen_at` fresh) be a single idempotent upsert. A
--     token can in theory be reused across users on the same
--     device, hence keyed on (user_id, token) not token alone.
-- ============================================================

CREATE TABLE device_push_tokens (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  platform      TEXT NOT NULL,
  token         TEXT NOT NULL,
  last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, token)
);

-- The hot read pattern is "for this household, give me every
-- active device token across all members" — that's what the
-- future send-notification Edge Function will run when a trigger
-- fires. Composite (household_id, last_seen_at) supports both the
-- filter and an eventual "drop tokens unused for N days" prune.
CREATE INDEX device_push_tokens_household_seen_idx
  ON device_push_tokens (household_id, last_seen_at DESC);

-- ─── Row Level Security ────────────────────────────────────
ALTER TABLE device_push_tokens ENABLE ROW LEVEL SECURITY;

-- Users only see / manage THEIR OWN tokens. We don't expose the
-- whole household's tokens to every member because that's a
-- mild leak of "what devices does Alice carry?" — the server-
-- side delivery path will use the service role, which bypasses
-- RLS, so members never need cross-user reads.
CREATE POLICY "device_push_tokens self-read"
  ON device_push_tokens FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "device_push_tokens self-write"
  ON device_push_tokens FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
