-- ============================================================
-- Auto-create household and owner membership when a new user
-- signs up via Supabase Auth.
--
-- Reads display_name and household_name from auth.users.raw_user_meta_data
-- (set during signUp in the mobile app).
-- ============================================================

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_household_id UUID;
  v_display_name TEXT;
  v_household_name TEXT;
BEGIN
  -- Extract metadata passed during registration
  v_display_name   := COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1));
  v_household_name := COALESCE(NEW.raw_user_meta_data->>'household_name', v_display_name || '''s Household');

  -- Create the household
  INSERT INTO households (name, created_by)
  VALUES (v_household_name, NEW.id)
  RETURNING id INTO v_household_id;

  -- Add the user as owner
  INSERT INTO household_members (household_id, user_id, role, display_name)
  VALUES (v_household_id, NEW.id, 'owner', v_display_name);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fire after every new user in auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
