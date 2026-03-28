import { z } from "zod";

// ─── Reusable primitives ──────────────────────────────────────────────────────

const uuid = z.string().uuid();
const isoDate = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Must be YYYY-MM-DD");
const cents = z.number().int("Amount must be in whole cents");
const hexColor = z.string().regex(/^#[0-9A-Fa-f]{6}$/).optional();

// ─── Household ────────────────────────────────────────────────────────────────

export const CreateHouseholdSchema = z.object({
  name: z.string().min(1).max(100),
});

export const InviteMemberSchema = z.object({
  email: z.string().email(),
  role: z.enum(["partner", "child"]),
  display_name: z.string().min(1).max(100),
  date_of_birth: isoDate.optional(),
});

export const UpdateMemberSchema = z.object({
  display_name: z.string().min(1).max(100).optional(),
  date_of_birth: isoDate.optional().nullable(),
  avatar_url: z.string().url().optional().nullable(),
});

// ─── Accounts ─────────────────────────────────────────────────────────────────

const ACCOUNT_TYPES = [
  "checking",
  "savings",
  "credit_card",
  "brokerage",
  "ira_traditional",
  "ira_roth",
  "retirement_401k",
  "retirement_403b",
  "hsa",
  "college_529",
  "cash",
] as const;

export const CreateAccountSchema = z.object({
  owner_user_id: uuid,
  name: z.string().min(1).max(150),
  institution: z.string().max(150).optional(),
  account_type: z.enum(ACCOUNT_TYPES),
  last_four: z.string().length(4).regex(/^\d{4}$/).optional(),
  currency: z.string().length(3).default("USD"),
  credit_limit: cents.optional().nullable(),
  color: hexColor,
});

export const UpdateAccountSchema = CreateAccountSchema.partial().omit({
  owner_user_id: true,
  account_type: true,
});

export const GrantAccountVisibilitySchema = z.object({
  granted_to: uuid,
  can_view: z.boolean().default(true),
  can_add_transactions: z.boolean().default(false),
});

// ─── Transactions ─────────────────────────────────────────────────────────────

export const CreateTransactionSchema = z.object({
  account_id: uuid,
  amount: cents,
  currency: z.string().length(3).default("USD"),
  description: z.string().min(1).max(500),
  merchant: z.string().max(200).optional(),
  category_id: uuid.optional().nullable(),
  transaction_date: isoDate,
  posted_date: isoDate.optional().nullable(),
  pending: z.boolean().default(false),
  notes: z.string().max(1000).optional().nullable(),
  receipt_id: uuid.optional().nullable(),
});

export const UpdateTransactionSchema = CreateTransactionSchema.partial().omit({
  account_id: true,
});

export const BulkCategorizeSchema = z.object({
  transaction_ids: z.array(uuid).min(1).max(100),
  category_id: uuid,
});

// ─── Categories ───────────────────────────────────────────────────────────────

export const CreateCategorySchema = z.object({
  name: z.string().min(1).max(100),
  parent_id: uuid.optional().nullable(),
  icon: z.string().max(50).optional(),
  color: hexColor,
  is_income: z.boolean().default(false),
});

// ─── Receipts ─────────────────────────────────────────────────────────────────

export const UpdateReceiptSchema = z.object({
  merchant_name: z.string().max(200).optional().nullable(),
  receipt_date: isoDate.optional().nullable(),
  total_amount: cents.optional().nullable(),
});

export const CreateReceiptLineItemSchema = z.object({
  description: z.string().min(1).max(300),
  amount: cents,
  quantity: z.number().positive().optional().nullable(),
  unit_price: cents.optional().nullable(),
  category_id: uuid.optional().nullable(),
  is_tax: z.boolean().default(false),
  is_tip: z.boolean().default(false),
  is_discount: z.boolean().default(false),
  sort_order: z.number().int().default(0),
});

export const PairReceiptSchema = z.object({
  transaction_id: uuid,
});

// ─── Budgets ──────────────────────────────────────────────────────────────────

export const CreateBudgetSchema = z.object({
  category_id: uuid,
  amount: cents.positive("Budget amount must be positive"),
  period: z.enum(["weekly", "monthly", "annual"]).default("monthly"),
  start_date: isoDate,
  end_date: isoDate.optional().nullable(),
});

// ─── Statement Import ─────────────────────────────────────────────────────────

export const ImportStatementSchema = z.object({
  account_id: uuid,
  file_format: z.enum(["csv", "ofx", "qfx"]),
  // CSV column mapping (user-defined during import wizard)
  column_map: z
    .object({
      date: z.string(),
      amount: z.string(),
      description: z.string(),
      balance: z.string().optional(),
      category: z.string().optional(),
    })
    .optional(),
});

// ─── Scenarios ────────────────────────────────────────────────────────────────

export const CreateScenarioSchema = z.object({
  name: z.string().min(1).max(150),
  description: z.string().max(500).optional(),
  base_date: isoDate,
  parent_id: uuid.optional().nullable(),
  color: hexColor,
});

export const CreateScenarioEventSchema = z.object({
  event_type: z.enum([
    "income_change",
    "one_time_expense",
    "recurring_expense_change",
    "large_purchase",
    "debt_payoff",
    "investment_contribution",
    "job_change",
    "account_open",
    "account_close",
  ]),
  label: z.string().min(1).max(200),
  event_date: isoDate,
  amount: cents,
  account_id: uuid.optional().nullable(),
  is_recurring: z.boolean().default(false),
  recurrence_rule: z.string().max(500).optional().nullable(),
  parameters: z.record(z.unknown()).default({}),
});

// ─── Auth ─────────────────────────────────────────────────────────────────────

export const SignUpSchema = z.object({
  email: z.string().email(),
  password: z
    .string()
    .min(8, "Password must be at least 8 characters")
    .regex(/[A-Z]/, "Password must contain an uppercase letter")
    .regex(/[0-9]/, "Password must contain a number"),
  display_name: z.string().min(1).max(100),
  household_name: z.string().min(1).max(100),
});

export const SignInSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

// ─── Inferred types ───────────────────────────────────────────────────────────

export type CreateHouseholdInput = z.infer<typeof CreateHouseholdSchema>;
export type InviteMemberInput = z.infer<typeof InviteMemberSchema>;
export type CreateAccountInput = z.infer<typeof CreateAccountSchema>;
export type UpdateAccountInput = z.infer<typeof UpdateAccountSchema>;
export type CreateTransactionInput = z.infer<typeof CreateTransactionSchema>;
export type UpdateTransactionInput = z.infer<typeof UpdateTransactionSchema>;
export type CreateCategoryInput = z.infer<typeof CreateCategorySchema>;
export type CreateBudgetInput = z.infer<typeof CreateBudgetSchema>;
export type ImportStatementInput = z.infer<typeof ImportStatementSchema>;
export type CreateScenarioInput = z.infer<typeof CreateScenarioSchema>;
export type CreateScenarioEventInput = z.infer<typeof CreateScenarioEventSchema>;
export type SignUpInput = z.infer<typeof SignUpSchema>;
export type SignInInput = z.infer<typeof SignInSchema>;
