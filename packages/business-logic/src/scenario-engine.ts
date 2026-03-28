/**
 * Scenario projection engine.
 * Pure functions — no I/O. Takes current balances + scenario events,
 * projects them forward month by month.
 */
import Decimal from "decimal.js";
import type { ScenarioEvent, ScenarioProjection } from "@budget/types";
import { addCents, monthlyInterest } from "./money";

export interface AccountSnapshot {
  account_id: string;
  balance: number; // cents
  account_type: string;
  apr_percent?: number; // for credit cards
}

export interface ProjectionInput {
  start_date: string; // ISO date (YYYY-MM-DD)
  end_date: string;
  snapshots: AccountSnapshot[];
  events: ScenarioEvent[];
  monthly_income: number; // cents — baseline recurring income
  monthly_expenses: number; // cents — baseline recurring expenses
}

export interface ProjectionOutput {
  projections: ScenarioProjection[];
  summary: {
    starting_net_worth: number;
    ending_net_worth: number;
    net_change: number;
  };
}

function parseDate(iso: string): Date {
  const [y, m, d] = iso.split("-").map(Number) as [number, number, number];
  return new Date(y, (m as number) - 1, d as number);
}

function toIsoMonth(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-01`;
}

function addMonths(date: Date, n: number): Date {
  const d = new Date(date);
  d.setMonth(d.getMonth() + n);
  return d;
}

/** Get all events that fall within a given month */
function eventsInMonth(events: ScenarioEvent[], monthStart: Date): ScenarioEvent[] {
  const year = monthStart.getFullYear();
  const month = monthStart.getMonth();
  return events.filter((e) => {
    const d = parseDate(e.event_date);
    return d.getFullYear() === year && d.getMonth() === month;
  });
}

export function runProjection(input: ProjectionInput): ProjectionOutput {
  const start = parseDate(input.start_date);
  const end = parseDate(input.end_date);

  // Mutable balance map: account_id → cents
  const balances = new Map<string, number>(
    input.snapshots.map((s) => [s.account_id, s.balance])
  );
  const aprMap = new Map<string, number>(
    input.snapshots
      .filter((s) => s.apr_percent !== undefined)
      .map((s) => [s.account_id, s.apr_percent!])
  );

  const projections: ScenarioProjection[] = [];

  let cursor = new Date(start);
  while (cursor <= end) {
    // 1. Apply baseline monthly income/expenses to first checking account
    const firstAccount = input.snapshots[0];
    if (firstAccount) {
      const current = balances.get(firstAccount.account_id) ?? 0;
      balances.set(
        firstAccount.account_id,
        addCents(current, input.monthly_income - input.monthly_expenses)
      );
    }

    // 2. Apply credit card interest
    for (const [accountId, apr] of aprMap) {
      const balance = balances.get(accountId) ?? 0;
      if (balance < 0) {
        // debit balance on credit card = carrying a balance
        const interest = monthlyInterest(balance, apr);
        balances.set(accountId, balance - interest);
      }
    }

    // 3. Apply scenario events falling in this month
    for (const event of eventsInMonth(input.events, cursor)) {
      if (event.account_id) {
        const current = balances.get(event.account_id) ?? 0;
        balances.set(event.account_id, addCents(current, event.amount));
      } else {
        // No specific account — apply to first account
        const acc = input.snapshots[0];
        if (acc) {
          const current = balances.get(acc.account_id) ?? 0;
          balances.set(acc.account_id, addCents(current, event.amount));
        }
      }
    }

    // 4. Record per-account projections
    const monthLabel = toIsoMonth(cursor);
    for (const [accountId, balance] of balances) {
      projections.push({
        date: monthLabel,
        account_id: accountId,
        projected_balance: balance,
      });
    }

    // 5. Record total net worth projection
    const netWorth = Array.from(balances.values()).reduce(
      (sum, b) => addCents(sum, b),
      0
    );
    projections.push({
      date: monthLabel,
      account_id: null,
      projected_balance: netWorth,
    });

    cursor = addMonths(cursor, 1);
  }

  const startNetWorth = input.snapshots.reduce((sum, s) => addCents(sum, s.balance), 0);
  const endNetWorth =
    projections
      .filter((p) => p.account_id === null)
      .at(-1)?.projected_balance ?? startNetWorth;

  return {
    projections,
    summary: {
      starting_net_worth: startNetWorth,
      ending_net_worth: endNetWorth,
      net_change: endNetWorth - startNetWorth,
    },
  };
}
