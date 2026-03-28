-- ============================================================
-- Household Invites
--
-- Owners generate a short code that family members enter to
-- join the household. Codes expire after 7 days.
-- ============================================================

CREATE TABLE household_invites (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  invited_by    UUID NOT NULL REFERENCES auth.users(id),
  invited_email TEXT NOT NULL,
  role          household_role NOT NULL DEFAULT 'child',
  code          TEXT NOT NULL UNIQUE,
  expires_at    TIMESTAMPTZ NOT NULL DEFAULT now() + INTERVAL '7 days',
  used_at       TIMESTAMPTZ,
  used_by       UUID REFERENCES auth.users(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE household_invites ENABLE ROW LEVEL SECURITY;

-- Owner can see and manage invites for their household
CREATE POLICY "owner can manage invites"
  ON household_invites FOR ALL
  USING (get_household_role(household_id) = 'owner');

-- ─── create_invite ────────────────────────────────────────────────────────────
-- Called by the owner. Returns the 8-character invite code.
CREATE OR REPLACE FUNCTION create_invite(
  p_household_id UUID,
  p_email        TEXT,
  p_role         household_role
)
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_code TEXT;
BEGIN
  IF get_household_role(p_household_id) != 'owner' THEN
    RAISE EXCEPTION 'Only household owners can create invites';
  END IF;

  v_code := upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 8));

  -- Delete any prior unused invite for the same email in this household
  DELETE FROM household_invites
  WHERE household_id = p_household_id
    AND invited_email = lower(p_email)
    AND used_at IS NULL;

  INSERT INTO household_invites (household_id, invited_by, invited_email, role, code)
  VALUES (p_household_id, auth.uid(), lower(p_email), p_role, v_code);

  RETURN v_code;
END;
$$;

-- ─── accept_invite ────────────────────────────────────────────────────────────
-- Called by the invitee. Moves them from their auto-created household
-- into the invited household and marks the invite used.
CREATE OR REPLACE FUNCTION accept_invite(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_invite        household_invites%ROWTYPE;
  v_old_hh_id     UUID;
  v_display_name  TEXT;
  v_user_email    TEXT;
BEGIN
  SELECT email INTO v_user_email FROM auth.users WHERE id = auth.uid();

  SELECT * INTO v_invite
  FROM household_invites
  WHERE code = upper(trim(p_code))
    AND used_at IS NULL
    AND expires_at > now()
    AND invited_email = lower(v_user_email);

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'error', 'Invalid or expired invite code. Check the code and try again.'
    );
  END IF;

  -- Capture current display_name before leaving old household
  SELECT household_id, display_name
  INTO v_old_hh_id, v_display_name
  FROM household_members
  WHERE user_id = auth.uid()
  LIMIT 1;

  -- Leave old household
  IF v_old_hh_id IS NOT NULL THEN
    DELETE FROM household_members
    WHERE user_id = auth.uid() AND household_id = v_old_hh_id;

    -- Clean up the auto-created solo household if now empty
    DELETE FROM households
    WHERE id = v_old_hh_id
      AND created_by = auth.uid()
      AND NOT EXISTS (
        SELECT 1 FROM household_members WHERE household_id = v_old_hh_id
      );
  END IF;

  -- Join new household
  INSERT INTO household_members (household_id, user_id, role, display_name, invited_by)
  VALUES (
    v_invite.household_id,
    auth.uid(),
    v_invite.role,
    COALESCE(v_display_name, split_part(v_user_email, '@', 1)),
    v_invite.invited_by
  );

  -- Mark invite used
  UPDATE household_invites
  SET used_at = now(), used_by = auth.uid()
  WHERE id = v_invite.id;

  RETURN jsonb_build_object('success', true, 'household_id', v_invite.household_id);
END;
$$;
