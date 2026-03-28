/**
 * Budget calculation utilities — pure functions, no I/O.
 */
import type { Budget, Transaction, Category } from "@budget/types";
import { addCents, formatCurrency } from "./money";

export interface BudgetProgress {
  budget: Budget;
  category: Category;
  planned: number; // cents
  actual: number; // cents (absolute value of spending)
  remaining: number; // cents (positive = under budget, negative = over)
  percent_used: number; // 0–100+
  is_over_budget: boolean;
}

/**
 * Calculate progress for each budget given a set of transactions
 * for the same period.
 */
export function calculateBudgetProgress(
  budgets: Budget[],
  transactions: Transaction[],
  categories: Category[]
): BudgetProgress[] {
  const categoryMap = new Map(categories.map((c) => [c.id, c]));

  return budgets.map((budget) => {
    const category = categoryMap.get(budget.category_id);
    if (!category) {
      throw new Error(`Category ${budget.category_id} not found`);
    }

    // Sum spending for this category (and any sub-categories)
    const relevant = transactions.filter(
      (t) =>
        t.category_id === budget.category_id ||
        // sub-category: its parent is this budget category
        (t.category_id &&
          categoryMap.get(t.category_id)?.parent_id === budget.category_id)
    );

    const actual = relevant
      .filter((t) => t.amount < 0) // debits only
      .reduce((sum, t) => addCents(sum, Math.abs(t.amount)), 0);

    const remaining = budget.amount - actual;
    const percent_used =
      budget.amount > 0 ? Math.round((actual / budget.amount) * 100) : 0;

    return {
      budget,
      category,
      planned: budget.amount,
      actual,
      remaining,
      percent_used,
      is_over_budget: actual > budget.amount,
    };
  });
}

/** Summarize spending by top-level category */
export interface CategorySpending {
  category_id: string;
  category_name: string;
  total: number; // cents
  transaction_count: number;
  percent_of_total: number;
}

export function summarizeSpendingByCategory(
  transactions: Transaction[],
  categories: Category[]
): CategorySpending[] {
  const categoryMap = new Map(categories.map((c) => [c.id, c]));
  const spending = new Map<string, number>();
  const counts = new Map<string, number>();

  for (const t of transactions) {
    if (!t.category_id || t.amount >= 0) continue;
    const cat = categoryMap.get(t.category_id);
    if (!cat) continue;
    // Roll up to parent if sub-category
    const topId = cat.parent_id ?? cat.id;
    spending.set(topId, addCents(spending.get(topId) ?? 0, Math.abs(t.amount)));
    counts.set(topId, (counts.get(topId) ?? 0) + 1);
  }

  const totalSpend = Array.from(spending.values()).reduce(
    (s, v) => addCents(s, v),
    0
  );

  return Array.from(spending.entries())
    .map(([category_id, total]) => ({
      category_id,
      category_name: categoryMap.get(category_id)?.name ?? "Unknown",
      total,
      transaction_count: counts.get(category_id) ?? 0,
      percent_of_total:
        totalSpend > 0 ? Math.round((total / totalSpend) * 1000) / 10 : 0,
    }))
    .sort((a, b) => b.total - a.total);
}
