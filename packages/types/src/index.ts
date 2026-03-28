// ─── Enums ────────────────────────────────────────────────────────────────────

export type HouseholdRole = "owner" | "partner" | "child";

export type AccountType =
  | "checking"
  | "savings"
  | "credit_card"
  | "brokerage"
  | "ira_traditional"
  | "ira_roth"
  | "retirement_401k"
  | "retirement_403b"
  | "hsa"
  | "college_529"
  | "cash";

export type OcrStatus = "pending" | "processing" | "complete" | "failed";

export type TransactionSource = "manual" | "import" | "plaid";

// ─── Household ────────────────────────────────────────────────────────────────

export interface Household {
  id: string;
  name: string;
  created_by: string;
  created_at: string;
  updated_at: string;
}

export interface HouseholdMember {
  id: string;
  household_id: string;
  user_id: string;
  role: HouseholdRole;
  display_name: string;
  date_of_birth: string | null;
  avatar_url: string | null;
  invited_by: string | null;
  joined_at: string;
}

export interface PartnerPermission {
  id: string;
  household_id: string;
  partner_user_id: string;
  permission: "full_access" | "view_only";
  granted_by: string;
  granted_at: string;
}

// ─── Accounts ─────────────────────────────────────────────────────────────────

export interface Account {
  id: string;
  household_id: string;
  owner_user_id: string;
  name: string;
  institution: string | null;
  account_type: AccountType;
  last_four: string | null;
  currency: string;
  current_balance: number; // stored in cents (integer)
  credit_limit: number | null; // cents, credit cards only
  is_active: boolean;
  color: string | null;
  created_at: string;
  updated_at: string;
}

export interface AccountVisibilityGrant {
  id: string;
  account_id: string;
  granted_to: string;
  granted_by: string;
  can_view: boolean;
  can_add_transactions: boolean;
  granted_at: string;
}

// ─── Transactions ─────────────────────────────────────────────────────────────

export interface Category {
  id: string;
  household_id: string | null; // null = system default
  name: string;
  parent_id: string | null;
  icon: string | null;
  color: string | null;
  is_income: boolean;
  sort_order: number;
}

export interface Transaction {
  id: string;
  household_id: string;
  account_id: string;
  amount: number; // cents; negative = debit, positive = credit
  currency: string;
  description: string;
  merchant: string | null;
  category_id: string | null;
  transaction_date: string; // ISO date string
  posted_date: string | null;
  pending: boolean;
  source: TransactionSource;
  entered_by: string | null;
  receipt_id: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

// ─── Receipts ─────────────────────────────────────────────────────────────────

export interface Receipt {
  id: string;
  household_id: string;
  uploaded_by: string;
  storage_path: string;
  thumbnail_path: string | null;
  merchant_name: string | null;
  receipt_date: string | null;
  total_amount: number | null; // cents
  ocr_status: OcrStatus;
  ocr_raw: Record<string, unknown> | null;
  uploaded_at: string;
}

export interface ReceiptLineItem {
  id: string;
  receipt_id: string;
  description: string;
  amount: number; // cents
  quantity: number | null;
  unit_price: number | null; // cents
  category_id: string | null;
  is_tax: boolean;
  is_tip: boolean;
  is_discount: boolean;
  sort_order: number;
}

// ─── Budgets ──────────────────────────────────────────────────────────────────

export type BudgetPeriod = "weekly" | "monthly" | "annual";

export interface Budget {
  id: string;
  household_id: string;
  category_id: string;
  amount: number; // cents
  period: BudgetPeriod;
  start_date: string;
  end_date: string | null;
  created_by: string;
}

// ─── Scenarios ────────────────────────────────────────────────────────────────

export type ScenarioEventType =
  | "income_change"
  | "one_time_expense"
  | "recurring_expense_change"
  | "large_purchase"
  | "debt_payoff"
  | "investment_contribution"
  | "job_change"
  | "account_open"
  | "account_close";

export interface ScenarioEvent {
  id: string;
  scenario_id: string;
  event_type: ScenarioEventType;
  label: string;
  event_date: string;
  amount: number; // cents
  account_id: string | null;
  is_recurring: boolean;
  recurrence_rule: string | null; // iCal RRULE format
  parameters: Record<string, unknown>;
  sort_order: number;
}

export interface Scenario {
  id: string;
  household_id: string;
  created_by: string;
  parent_id: string | null; // for branched scenarios
  name: string;
  description: string | null;
  base_date: string;
  is_baseline: boolean;
  color: string | null;
  events?: ScenarioEvent[];
  created_at: string;
  updated_at: string;
}

export interface ScenarioProjection {
  date: string;
  account_id: string | null; // null = total net worth
  projected_balance: number; // cents
}

// ─── Statement Import ─────────────────────────────────────────────────────────

export type ImportFormat = "csv" | "ofx" | "qfx";
export type ImportStatus = "pending" | "processing" | "complete" | "failed";

export interface ImportBatch {
  id: string;
  account_id: string;
  household_id: string;
  uploaded_by: string;
  file_name: string;
  file_format: ImportFormat;
  storage_path: string;
  status: ImportStatus;
  row_count: number | null;
  imported_count: number | null;
  duplicate_count: number | null;
  error_log: unknown[] | null;
  created_at: string;
  completed_at: string | null;
}

// ─── API helpers ──────────────────────────────────────────────────────────────

export interface ApiError {
  code: string;
  message: string;
}

export interface PaginatedResponse<T> {
  data: T[];
  count: number;
  page: number;
  per_page: number;
}

// ─── Money helpers (display only — math uses decimal.js) ──────────────────────

/** Converts integer cents to a display string: 1234 → "12.34" */
export function centsToDecimal(cents: number): string {
  return (cents / 100).toFixed(2);
}

/** Converts a decimal string to integer cents: "12.34" → 1234 */
export function decimalToCents(value: string | number): number {
  return Math.round(parseFloat(String(value)) * 100);
}
