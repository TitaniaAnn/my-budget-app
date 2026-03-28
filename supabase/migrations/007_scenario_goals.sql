-- Add goal-tracking fields to the scenarios table.
-- A scenario becomes a "goal" when is_goal = true.
-- target_amount is in cents; target_date is when you want to reach it.
ALTER TABLE scenarios
  ADD COLUMN IF NOT EXISTS is_goal       BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS target_amount INTEGER,   -- cents
  ADD COLUMN IF NOT EXISTS target_date   DATE;
