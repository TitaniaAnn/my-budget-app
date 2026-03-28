-- Add 'biweekly' and 'semiannual' to the budget_period enum.
-- ALTER TYPE … ADD VALUE cannot run inside a transaction, so this must be
-- executed outside BEGIN/COMMIT (Supabase SQL Editor does this automatically).
ALTER TYPE budget_period ADD VALUE IF NOT EXISTS 'biweekly';
ALTER TYPE budget_period ADD VALUE IF NOT EXISTS 'semiannual';
