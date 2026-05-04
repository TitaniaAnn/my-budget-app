-- ============================================================
-- Tags: a second dimension on transactions and receipt line items.
--
-- Categories answer "what kind of expense is this?" — there's
-- exactly one answer per row. Tags answer "what context does
-- this expense belong to?" and a row can have multiple. The
-- motivating use case is the Contractor tab: the same Costco
-- run can be tagged 'contractor' and 'pottery_studio' without
-- forcing a category collision, and a tax-time CSV export is a
-- WHERE filter on the assignment table.
--
-- Two assignment tables (one for transactions, one for receipt
-- line items) so tagging works at whichever granularity makes
-- sense. A receipt with a $200 transaction tagged 'contractor'
-- AND $40 of pottery line items tagged 'pottery_studio' both
-- get accounted correctly without splitting the transaction.
-- ============================================================

-- ─── Tag dictionary ────────────────────────────────────────
CREATE TABLE transaction_tags (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  color         CHAR(7),                              -- hex, optional
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (household_id, name)                         -- no dup names per household
);

CREATE INDEX transaction_tags_household_idx
  ON transaction_tags(household_id);

-- ─── Transaction ↔ tag join table ──────────────────────────
CREATE TABLE transaction_tag_assignments (
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  tag_id         UUID NOT NULL REFERENCES transaction_tags(id) ON DELETE CASCADE,
  assigned_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (transaction_id, tag_id)
);

CREATE INDEX transaction_tag_assignments_tag_idx
  ON transaction_tag_assignments(tag_id);

-- ─── Receipt line item ↔ tag join table ────────────────────
CREATE TABLE receipt_line_item_tag_assignments (
  line_item_id UUID NOT NULL REFERENCES receipt_line_items(id) ON DELETE CASCADE,
  tag_id       UUID NOT NULL REFERENCES transaction_tags(id) ON DELETE CASCADE,
  assigned_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (line_item_id, tag_id)
);

CREATE INDEX receipt_line_item_tag_assignments_tag_idx
  ON receipt_line_item_tag_assignments(tag_id);

-- ─── Row Level Security ────────────────────────────────────
ALTER TABLE transaction_tags                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_tag_assignments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipt_line_item_tag_assignments   ENABLE ROW LEVEL SECURITY;

-- Tag dictionary: visible to all household members; any member can
-- create / rename / delete (the dictionary is small and shared, so
-- the owner-only restriction we apply to budgets would be overkill).
CREATE POLICY "tag visibility"
  ON transaction_tags FOR SELECT
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "members can manage tags"
  ON transaction_tags FOR ALL
  USING (
    household_id IN (
      SELECT household_id FROM household_members WHERE user_id = auth.uid()
    )
  );

-- Transaction ↔ tag assignments: visible/manageable when the
-- underlying transaction is. RLS on transactions already enforces
-- the household-scoping, so we just defer to it via IN (...).
CREATE POLICY "transaction tag visibility"
  ON transaction_tag_assignments FOR SELECT
  USING (transaction_id IN (SELECT id FROM transactions));

CREATE POLICY "transaction tag management"
  ON transaction_tag_assignments FOR ALL
  USING (transaction_id IN (SELECT id FROM transactions));

-- Line item ↔ tag assignments: same pattern, deferring to the
-- existing line-item visibility policy from migration 001.
CREATE POLICY "line item tag visibility"
  ON receipt_line_item_tag_assignments FOR SELECT
  USING (line_item_id IN (SELECT id FROM receipt_line_items));

CREATE POLICY "line item tag management"
  ON receipt_line_item_tag_assignments FOR ALL
  USING (line_item_id IN (SELECT id FROM receipt_line_items));
