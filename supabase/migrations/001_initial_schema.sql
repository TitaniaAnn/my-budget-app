-- ============================================================
-- myBudgetApp — Initial Schema
-- All monetary values stored as INTEGER cents (e.g. $12.34 = 1234)
-- ============================================================

-- ─── Extensions ──────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── Enums ───────────────────────────────────────────────────────────────────
CREATE TYPE household_role AS ENUM ('owner', 'partner', 'child');

CREATE TYPE account_type AS ENUM (
  'checking', 'savings', 'credit_card', 'brokerage',
  'ira_traditional', 'ira_roth', 'retirement_401k', 'retirement_403b',
  'hsa', 'college_529', 'cash'
);

CREATE TYPE ocr_status AS ENUM ('pending', 'processing', 'complete', 'failed');
CREATE TYPE import_status AS ENUM ('pending', 'processing', 'complete', 'failed');
CREATE TYPE import_format AS ENUM ('csv', 'ofx', 'qfx');
CREATE TYPE transaction_source AS ENUM ('manual', 'import', 'plaid');
CREATE TYPE budget_period AS ENUM ('weekly', 'monthly', 'annual');

-- ─── Households ──────────────────────────────────────────────────────────────
CREATE TABLE households (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  created_by  UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Household Members ───────────────────────────────────────────────────────
CREATE TABLE household_members (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role          household_role NOT NULL DEFAULT 'child',
  display_name  TEXT NOT NULL,
  date_of_birth DATE,
  avatar_url    TEXT,
  invited_by    UUID REFERENCES auth.users(id),
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (household_id, user_id)
);

-- ─── Partner Permissions (coarse-grained) ────────────────────────────────────
CREATE TABLE partner_permissions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  partner_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  permission      TEXT NOT NULL CHECK (permission IN ('full_access', 'view_only')),
  granted_by      UUID NOT NULL REFERENCES auth.users(id),
  granted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (household_id, partner_user_id, permission)
);

-- ─── Financial Accounts ──────────────────────────────────────────────────────
CREATE TABLE accounts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  owner_user_id   UUID NOT NULL REFERENCES auth.users(id),
  name            TEXT NOT NULL,
  institution     TEXT,
  account_type    account_type NOT NULL,
  last_four       CHAR(4),
  currency        CHAR(3) NOT NULL DEFAULT 'USD',
  current_balance INTEGER NOT NULL DEFAULT 0,       -- cents
  credit_limit    INTEGER,                          -- cents, credit cards only
  is_active       BOOLEAN NOT NULL DEFAULT true,
  color           CHAR(7),                          -- hex color
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Fine-grained account visibility grants (partner/child overrides)
CREATE TABLE account_visibility_grants (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id           UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  granted_to           UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  granted_by           UUID NOT NULL REFERENCES auth.users(id),
  can_view             BOOLEAN NOT NULL DEFAULT true,
  can_add_transactions BOOLEAN NOT NULL DEFAULT false,
  granted_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (account_id, granted_to)
);

-- ─── Categories ──────────────────────────────────────────────────────────────
CREATE TABLE categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  UUID REFERENCES households(id) ON DELETE CASCADE, -- NULL = system default
  name          TEXT NOT NULL,
  parent_id     UUID REFERENCES categories(id),
  icon          TEXT,
  color         CHAR(7),
  is_income     BOOLEAN NOT NULL DEFAULT false,
  sort_order    INTEGER NOT NULL DEFAULT 0
);

-- ─── Receipts ─────────────────────────────────────────────────────────────────
-- Defined before transactions because transactions have a receipt_id FK
CREATE TABLE receipts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  uploaded_by     UUID NOT NULL REFERENCES auth.users(id),
  storage_path    TEXT NOT NULL,
  thumbnail_path  TEXT,
  merchant_name   TEXT,
  receipt_date    DATE,
  total_amount    INTEGER,                          -- cents
  ocr_status      ocr_status NOT NULL DEFAULT 'pending',
  ocr_raw         JSONB,
  uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── Transactions ────────────────────────────────────────────────────────────
CREATE TABLE transactions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id     UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  account_id       UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  amount           INTEGER NOT NULL,                -- cents; negative = debit
  currency         CHAR(3) NOT NULL DEFAULT 'USD',
  description      TEXT NOT NULL,
  merchant         TEXT,
  category_id      UUID REFERENCES categories(id),
  transaction_date DATE NOT NULL,
  posted_date      DATE,
  pending          BOOLEAN NOT NULL DEFAULT false,
  source           transaction_source NOT NULL DEFAULT 'manual',
  entered_by       UUID REFERENCES auth.users(id),
  receipt_id       UUID REFERENCES receipts(id),
  notes            TEXT,
  external_id      TEXT,                            -- bank-assigned ID for dedup
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (account_id, external_id)                  -- prevents duplicate imports
);

-- Full-text search index on transactions
CREATE INDEX transactions_search_idx ON transactions
  USING gin(to_tsvector('english', description || ' ' || COALESCE(merchant, '')));

-- ─── Receipt Line Items ───────────────────────────────────────────────────────
CREATE TABLE receipt_line_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  receipt_id   UUID NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
  description  TEXT NOT NULL,
  amount       INTEGER NOT NULL,                    -- cents
  quantity     NUMERIC(10, 3),
  unit_price   INTEGER,                             -- cents
  category_id  UUID REFERENCES categories(id),
  is_tax       BOOLEAN NOT NULL DEFAULT false,
  is_tip       BOOLEAN NOT NULL DEFAULT false,
  is_discount  BOOLEAN NOT NULL DEFAULT false,
  sort_order   INTEGER NOT NULL DEFAULT 0
);

-- ─── Statement Import Batches ─────────────────────────────────────────────────
CREATE TABLE import_batches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  account_id      UUID NOT NULL REFERENCES accounts(id),
  uploaded_by     UUID NOT NULL REFERENCES auth.users(id),
  file_name       TEXT NOT NULL,
  file_format     import_format NOT NULL,
  storage_path    TEXT NOT NULL,
  status          import_status NOT NULL DEFAULT 'pending',
  row_count       INTEGER,
  imported_count  INTEGER,
  duplicate_count INTEGER,
  error_log       JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at    TIMESTAMPTZ
);

-- ─── Budgets ──────────────────────────────────────────────────────────────────
CREATE TABLE budgets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  category_id     UUID NOT NULL REFERENCES categories(id),
  amount          INTEGER NOT NULL,                 -- cents
  period          budget_period NOT NULL DEFAULT 'monthly',
  start_date      DATE NOT NULL,
  end_date        DATE,
  created_by      UUID NOT NULL REFERENCES auth.users(id),
  UNIQUE (household_id, category_id, start_date, period)
);

-- ─── Scenarios ────────────────────────────────────────────────────────────────
CREATE TABLE scenarios (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  created_by    UUID NOT NULL REFERENCES auth.users(id),
  parent_id     UUID REFERENCES scenarios(id),
  name          TEXT NOT NULL,
  description   TEXT,
  base_date     DATE NOT NULL,
  is_baseline   BOOLEAN NOT NULL DEFAULT false,
  color         CHAR(7),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE scenario_events (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_id      UUID NOT NULL REFERENCES scenarios(id) ON DELETE CASCADE,
  event_type       TEXT NOT NULL,
  label            TEXT NOT NULL,
  event_date       DATE NOT NULL,
  amount           INTEGER NOT NULL,                -- cents
  account_id       UUID REFERENCES accounts(id),
  is_recurring     BOOLEAN NOT NULL DEFAULT false,
  recurrence_rule  TEXT,                            -- iCal RRULE
  parameters       JSONB NOT NULL DEFAULT '{}',
  sort_order       INTEGER NOT NULL DEFAULT 0
);

-- ─── Updated-at triggers ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER households_updated_at BEFORE UPDATE ON households
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER accounts_updated_at BEFORE UPDATE ON accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER transactions_updated_at BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER scenarios_updated_at BEFORE UPDATE ON scenarios
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── Helper function: get current user's role in a household ─────────────────
CREATE OR REPLACE FUNCTION get_household_role(p_household_id UUID)
RETURNS household_role AS $$
  SELECT role FROM household_members
  WHERE household_id = p_household_id AND user_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ─── Row Level Security ───────────────────────────────────────────────────────
ALTER TABLE households               ENABLE ROW LEVEL SECURITY;
ALTER TABLE household_members        ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_permissions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE account_visibility_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories               ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions             ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipts                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE receipt_line_items       ENABLE ROW LEVEL SECURITY;
ALTER TABLE import_batches           ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE scenarios                ENABLE ROW LEVEL SECURITY;
ALTER TABLE scenario_events          ENABLE ROW LEVEL SECURITY;

-- Households: any member can read; only owner can update/delete
CREATE POLICY "members can read household"
  ON households FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM household_members
    WHERE household_id = households.id AND user_id = auth.uid()
  ));

CREATE POLICY "owner can update household"
  ON households FOR UPDATE
  USING (get_household_role(id) = 'owner');

CREATE POLICY "creator can insert household"
  ON households FOR INSERT
  WITH CHECK (created_by = auth.uid());

-- Household members: visible to all household members
CREATE POLICY "members can read household_members"
  ON household_members FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM household_members hm
    WHERE hm.household_id = household_members.household_id AND hm.user_id = auth.uid()
  ));

CREATE POLICY "owner can manage household_members"
  ON household_members FOR ALL
  USING (get_household_role(household_id) = 'owner');

-- Accounts: layered visibility based on role
CREATE POLICY "account visibility"
  ON accounts FOR SELECT
  USING (
    -- User is a member of this household
    household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
    AND (
      -- Household owner sees all accounts
      get_household_role(household_id) = 'owner'
      -- User owns this account
      OR owner_user_id = auth.uid()
      -- Explicit visibility grant
      OR EXISTS (
        SELECT 1 FROM account_visibility_grants
        WHERE account_id = accounts.id AND granted_to = auth.uid() AND can_view = true
      )
      -- Partner with full_access permission
      OR (
        get_household_role(household_id) = 'partner'
        AND EXISTS (
          SELECT 1 FROM partner_permissions
          WHERE household_id = accounts.household_id
            AND partner_user_id = auth.uid()
            AND permission = 'full_access'
        )
      )
    )
  );

CREATE POLICY "owner can manage accounts"
  ON accounts FOR ALL
  USING (get_household_role(household_id) = 'owner');

-- Transactions: visible if the account is visible
CREATE POLICY "transaction visibility"
  ON transactions FOR SELECT
  USING (
    account_id IN (SELECT id FROM accounts)  -- RLS on accounts applies
  );

CREATE POLICY "members can insert transactions"
  ON transactions FOR INSERT
  WITH CHECK (
    household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
    AND (
      get_household_role(household_id) IN ('owner', 'partner')
      OR EXISTS (
        SELECT 1 FROM account_visibility_grants
        WHERE account_id = transactions.account_id
          AND granted_to = auth.uid()
          AND can_add_transactions = true
      )
    )
  );

CREATE POLICY "owners and enterers can update transactions"
  ON transactions FOR UPDATE
  USING (
    get_household_role(household_id) = 'owner'
    OR entered_by = auth.uid()
  );

-- Categories: system categories visible to all; custom categories to household
CREATE POLICY "category visibility"
  ON categories FOR SELECT
  USING (
    household_id IS NULL  -- system defaults
    OR household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
  );

CREATE POLICY "owner can manage categories"
  ON categories FOR ALL
  USING (
    household_id IN (
      SELECT household_id FROM household_members
      WHERE user_id = auth.uid() AND role = 'owner'
    )
  );

-- Receipts: household members can view; uploader or owner can manage
CREATE POLICY "receipt visibility"
  ON receipts FOR SELECT
  USING (
    household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
  );

CREATE POLICY "members can upload receipts"
  ON receipts FOR INSERT
  WITH CHECK (
    household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
    AND uploaded_by = auth.uid()
  );

-- Receipt line items: visible if receipt is visible
CREATE POLICY "line item visibility"
  ON receipt_line_items FOR SELECT
  USING (
    receipt_id IN (SELECT id FROM receipts)
  );

CREATE POLICY "line item management"
  ON receipt_line_items FOR ALL
  USING (
    receipt_id IN (
      SELECT id FROM receipts WHERE uploaded_by = auth.uid()
      UNION
      SELECT r.id FROM receipts r
      JOIN household_members hm ON hm.household_id = r.household_id
      WHERE hm.user_id = auth.uid() AND hm.role = 'owner'
    )
  );

-- Budgets: household members can view; owner can manage
CREATE POLICY "budget visibility"
  ON budgets FOR SELECT
  USING (
    household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
  );

CREATE POLICY "owner can manage budgets"
  ON budgets FOR ALL
  USING (get_household_role(household_id) = 'owner');

-- Scenarios: household members can view; creator or owner can manage
CREATE POLICY "scenario visibility"
  ON scenarios FOR SELECT
  USING (
    household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
  );

CREATE POLICY "scenario management"
  ON scenarios FOR ALL
  USING (
    get_household_role(household_id) = 'owner'
    OR created_by = auth.uid()
  );

CREATE POLICY "scenario events visibility"
  ON scenario_events FOR SELECT
  USING (
    scenario_id IN (SELECT id FROM scenarios)
  );

CREATE POLICY "scenario events management"
  ON scenario_events FOR ALL
  USING (
    scenario_id IN (
      SELECT id FROM scenarios
      WHERE get_household_role(household_id) = 'owner'
         OR created_by = auth.uid()
    )
  );

-- Import batches
CREATE POLICY "import batch visibility"
  ON import_batches FOR SELECT
  USING (
    household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
  );

CREATE POLICY "members can create import batches"
  ON import_batches FOR INSERT
  WITH CHECK (
    household_id IN (SELECT household_id FROM household_members WHERE user_id = auth.uid())
    AND uploaded_by = auth.uid()
  );
