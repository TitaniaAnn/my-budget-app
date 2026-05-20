-- ============================================================
-- Target asset-class allocations for rebalance suggestions.
--
-- One row per (household, asset_class) sets the household's target
-- weight as basis points (0–10000, matching ml_model_confidence
-- and ocr_confidence_bp). The dashboard's rebalance surface
-- compares these against the actual allocation (computed from
-- holdings.current_value sums per class) and surfaces classes
-- that have drifted past a threshold.
--
-- Schema choices:
--   * Stored as integer basis points so the math (drift = current
--     - target) is exact, consistent with the rest of the app's
--     "no float for percentages" stance.
--   * PK on (household_id, asset_class) — each class has at most
--     one target per household. Setting a 0% target IS valid
--     (the household has decided not to hold this class).
--   * No row-level CHECK that targets sum to 100% across classes
--     — that's a cross-row invariant Postgres can't enforce
--     cheaply, and the UI gates submission instead. A partial set
--     (only stocks + bonds defined, no cash) is still useful as
--     "treat undefined classes as 0% target."
-- ============================================================

CREATE TABLE target_allocations (
  household_id   UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  asset_class    asset_class NOT NULL,
  target_pct_bp  INTEGER NOT NULL
                 CHECK (target_pct_bp BETWEEN 0 AND 10000),
  created_by     UUID REFERENCES auth.users(id),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (household_id, asset_class)
);

CREATE INDEX target_allocations_household_idx
  ON target_allocations(household_id);

-- ─── Row Level Security ────────────────────────────────────
ALTER TABLE target_allocations ENABLE ROW LEVEL SECURITY;

-- Targets are shared household state. Any member can read or
-- edit — same posture as transaction_tags / recurring_transactions.
CREATE POLICY "target_allocations visibility"
  ON target_allocations FOR SELECT
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "members can manage target_allocations"
  ON target_allocations FOR ALL
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

CREATE TRIGGER target_allocations_updated_at
  BEFORE UPDATE ON target_allocations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();
