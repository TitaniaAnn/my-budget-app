// Pure-function tests for `_shared/plaid.ts`. Runs under
// Deno's built-in test runner — no network, no Plaid creds
// needed.
//
//   deno test --allow-env supabase/functions/_shared/plaid_test.ts
//
// These pin the two transforms that the Edge Functions can't
// get wrong without breaking the entire sync:
//
//   * plaidAmountToCents — Plaid's float-dollars positive-
//     outflow shape to this project's int-cents negative-
//     outflow shape. Float drift on the cents conversion would
//     mean every row off by ±1 cent.
//
//   * mapPlaidAccountType — Plaid's (type, subtype) pair to
//     the `account_type` enum in migration 001. A missed
//     subtype here means the user gets "no mapping" in the
//     UI's skipped_accounts list rather than a wrongly-typed
//     account.

import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.208.0/assert/mod.ts";

import {
  mapPlaidAccountType,
  plaidAmountToCents,
} from "./plaid.ts";

// ── plaidAmountToCents ─────────────────────────────────────────

Deno.test("plaidAmountToCents: positive (outflow) → negative cents", () => {
  // Plaid: positive amount = outflow (user paid).
  // Project: negative amount = outflow.
  assertEquals(plaidAmountToCents(19.99), -1999);
  assertEquals(plaidAmountToCents(1234.56), -123456);
  assertEquals(plaidAmountToCents(0.01), -1);
});

Deno.test("plaidAmountToCents: negative (inflow) → positive cents", () => {
  // Plaid: negative amount = inflow (e.g. refund, paycheck).
  assertEquals(plaidAmountToCents(-19.99), 1999);
  assertEquals(plaidAmountToCents(-1234.56), 123456);
  assertEquals(plaidAmountToCents(-0.01), 1);
});

Deno.test("plaidAmountToCents: zero is zero", () => {
  assertEquals(plaidAmountToCents(0), 0);
  assertEquals(plaidAmountToCents(-0), 0);
});

Deno.test("plaidAmountToCents: avoids float-multiply drift", () => {
  // 19.99 * 100 in JS is 1998.9999999999998 — naive Math.round
  // gives 1999 which happens to be right, but 0.07 * 100 is
  // 7.000000000000001 and 0.29 * 100 is 28.999999999999996. The
  // string-parse path sidesteps all of this.
  assertEquals(plaidAmountToCents(0.07), -7);
  assertEquals(plaidAmountToCents(0.29), -29);
  assertEquals(plaidAmountToCents(2.05), -205);
  assertEquals(plaidAmountToCents(99.99), -9999);
});

Deno.test("plaidAmountToCents: large amounts (year of grocery spend)", () => {
  assertEquals(plaidAmountToCents(9999.99), -999999);
  assertEquals(plaidAmountToCents(-9999.99), 999999);
});

Deno.test("plaidAmountToCents: rejects NaN / Infinity", () => {
  assertThrows(() => plaidAmountToCents(NaN));
  assertThrows(() => plaidAmountToCents(Infinity));
  assertThrows(() => plaidAmountToCents(-Infinity));
});

// ── mapPlaidAccountType ────────────────────────────────────────

Deno.test("mapPlaidAccountType: depository subtypes", () => {
  assertEquals(mapPlaidAccountType("depository", "checking"), "checking");
  assertEquals(mapPlaidAccountType("depository", "savings"), "savings");
  assertEquals(mapPlaidAccountType("depository", "cash management"), "cash");
  assertEquals(mapPlaidAccountType("depository", "money market"), "savings");
});

Deno.test("mapPlaidAccountType: credit card", () => {
  assertEquals(mapPlaidAccountType("credit", "credit card"), "credit_card");
});

Deno.test("mapPlaidAccountType: investment subtypes", () => {
  assertEquals(mapPlaidAccountType("investment", "ira"), "ira_traditional");
  assertEquals(mapPlaidAccountType("investment", "roth"), "ira_roth");
  assertEquals(mapPlaidAccountType("investment", "roth ira"), "ira_roth");
  assertEquals(mapPlaidAccountType("investment", "401k"), "retirement_401k");
  assertEquals(mapPlaidAccountType("investment", "403b"), "retirement_403b");
  assertEquals(mapPlaidAccountType("investment", "hsa"), "hsa");
  assertEquals(mapPlaidAccountType("investment", "529"), "college_529");
  assertEquals(mapPlaidAccountType("investment", "brokerage"), "brokerage");
  assertEquals(
    mapPlaidAccountType("investment", "non-taxable brokerage account"),
    "brokerage",
  );
});

Deno.test("mapPlaidAccountType: loan / mortgage", () => {
  assertEquals(mapPlaidAccountType("loan", "mortgage"), "mortgage");
});

Deno.test("mapPlaidAccountType: case-insensitive on type AND subtype", () => {
  assertEquals(mapPlaidAccountType("DEPOSITORY", "CHECKING"), "checking");
  assertEquals(mapPlaidAccountType("Credit", "Credit Card"), "credit_card");
});

Deno.test("mapPlaidAccountType: unmapped shapes return null (NOT coerced)", () => {
  // Silently mapping unknowns to a default would hide bugs and
  // distort downstream rollups. Null is the contract for "surface
  // in the UI for manual choice."
  assertEquals(mapPlaidAccountType("brokerage", "stock"), null);
  assertEquals(mapPlaidAccountType("loan", "student"), null);
  assertEquals(mapPlaidAccountType("investment", "annuity"), null);
  assertEquals(mapPlaidAccountType("other", "other"), null);
  assertEquals(mapPlaidAccountType(null, null), null);
  assertEquals(mapPlaidAccountType("depository", null), null);
});
