// Exchanges Plaid Link's short-lived public_token for a long-
// lived access_token, then materialises the linked Item + the
// user-selected accounts into the database.
//
// Flow:
//   1. Mobile completes Link → onSuccess gives it
//      { publicToken, metadata: { institution, accounts } }
//   2. Mobile POSTs that body to this function.
//   3. Function calls Plaid /item/public_token/exchange to get
//      { access_token, item_id }.
//   4. Function inserts ONE plaid_items row (service role —
//      bypasses the no-INSERT-from-client policy).
//   5. Function inserts ONE accounts row per Plaid account in the
//      payload (using mapPlaidAccountType to translate Plaid's
//      type/subtype to this app's account_type enum). Unmapped
//      account types are skipped + reported in the response so
//      the mobile UI can prompt the user to map them manually.
//   6. Returns { plaid_item_id, accounts: [...] } so the mobile
//      orchestrator can immediately trigger plaid-transactions-sync.
//
// We DON'T inline the initial /transactions/sync here for two
// reasons: (a) keeps this function's worst-case latency bounded
// to the exchange + INSERTs; (b) the mobile-side orchestrator
// already has the trigger-after-exchange logic for Phase 3, so
// duplicating it server-side is wasted effort.
//
// Invocation:
//   POST /functions/v1/plaid-public-token-exchange
//   Headers: Authorization: Bearer <user JWT>
//   Body: {
//     publicToken: string,
//     institution: { id: string, name: string },
//     accounts: [{
//       id: string,        // Plaid account_id
//       name: string,
//       mask: string|null, // last 4 of the account number
//       type: string,      // Plaid's account type ('depository' etc.)
//       subtype: string,   // Plaid's account subtype
//       currency: string|null  // iso_currency_code from Plaid
//     }]
//   }

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  jsonError,
  mapPlaidAccountType,
  plaidEnvironment,
  plaidPost,
  PlaidApiError,
  requireAuthedUser,
} from "../_shared/plaid.ts";

interface RequestBody {
  publicToken: string;
  institution: { id: string; name: string };
  accounts: Array<{
    id: string;
    name: string;
    mask: string | null;
    type: string;
    subtype: string;
    currency?: string | null;
  }>;
  // Review fix #4: when the caller is a member of multiple
  // households, they MUST pass which one this Item belongs to.
  // Single-household callers (the common case) can omit it; the
  // function resolves automatically.
  householdId?: string;
}

interface PlaidExchangeResponse {
  access_token: string;
  item_id: string;
  request_id: string;
}

interface InsertedAccount {
  account_id: string; // internal accounts.id
  plaid_account_id: string;
  account_type: string;
  name: string;
}

interface SkippedAccount {
  plaid_account_id: string;
  name: string;
  plaid_type: string;
  plaid_subtype: string;
  reason: string;
}

serve(async (req) => {
  if (req.method !== "POST") return jsonError(405, "method not allowed");

  const auth = await requireAuthedUser(req);
  if (!auth.ok) return auth.response;

  let body: RequestBody;
  try {
    body = (await req.json()) as RequestBody;
  } catch {
    return jsonError(400, "invalid JSON body");
  }
  if (!body.publicToken || typeof body.publicToken !== "string") {
    return jsonError(400, "publicToken is required");
  }
  if (!body.institution?.id || !body.institution?.name) {
    return jsonError(400, "institution.id and institution.name are required");
  }
  if (!Array.isArray(body.accounts) || body.accounts.length === 0) {
    return jsonError(400, "accounts must be a non-empty array");
  }

  // Service-role client for the writes — plaid_items has no
  // client-facing INSERT policy by design. The household + owner
  // are derived from the caller's JWT below, never from the
  // request body, so a forged body can't write into someone
  // else's household.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Resolve the caller's household via household_members. Use
  // the user JWT explicitly so RLS guarantees this returns only
  // households the caller actually belongs to.
  //
  // Review fix #4: previously this took `.limit(1).maybeSingle()`
  // and silently picked whichever household Postgres returned
  // first. A user belonging to multiple households would land
  // their Plaid Item in an arbitrary one. Fix: enumerate all
  // memberships; if exactly one, use it; if more, require an
  // explicit `householdId` in the request body and verify the
  // caller is a member of it.
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: `Bearer ${auth.auth.token}` } } },
  );
  const { data: memberRows, error: memberErr } = await userClient
    .from("household_members")
    .select("household_id")
    .eq("user_id", auth.auth.userId);
  if (memberErr) return jsonError(500, String(memberErr));
  if (!memberRows || memberRows.length === 0) {
    return jsonError(403, "caller has no household");
  }
  const memberHouseholdIds = (memberRows as Array<{ household_id: string }>)
    .map((r) => r.household_id);
  let householdId: string;
  if (body.householdId) {
    if (!memberHouseholdIds.includes(body.householdId)) {
      return jsonError(
        403,
        "caller is not a member of the requested householdId",
      );
    }
    householdId = body.householdId;
  } else if (memberHouseholdIds.length === 1) {
    householdId = memberHouseholdIds[0];
  } else {
    return jsonError(
      409,
      `caller belongs to ${memberHouseholdIds.length} households; ` +
        "pass householdId in the request body to disambiguate",
    );
  }

  // Exchange the public_token for the long-lived access_token.
  // This is the only round-trip to Plaid in this function.
  let exchange: PlaidExchangeResponse;
  try {
    exchange = await plaidPost<PlaidExchangeResponse>(
      "/item/public_token/exchange",
      { public_token: body.publicToken },
    );
  } catch (err) {
    if (err instanceof PlaidApiError) {
      console.error("[plaid-public-token-exchange] Plaid error", {
        status: err.status,
        errorCode: err.errorCode,
        errorType: err.errorType,
        requestId: err.requestId,
      });
      return jsonError(
        err.status >= 500 ? 502 : 400,
        `Plaid public-token exchange failed (${err.errorCode ?? "unknown"})`,
      );
    }
    console.error("[plaid-public-token-exchange] unexpected error", err);
    return jsonError(500, "internal error");
  }

  // Upsert the plaid_items row. The (household_id, plaid_item_id)
  // UNIQUE means a re-link of the same institution refreshes
  // access_token + clears stale sync error without duplicating.
  const { data: itemRow, error: itemErr } = await supabase
    .from("plaid_items")
    .upsert(
      {
        household_id: householdId,
        created_by: auth.auth.userId,
        plaid_item_id: exchange.item_id,
        plaid_institution_id: body.institution.id,
        institution_name: body.institution.name,
        access_token: exchange.access_token,
        environment: plaidEnvironment(),
        is_active: true,
        last_sync_error: null,
      },
      { onConflict: "household_id,plaid_item_id" },
    )
    .select("id")
    .single();
  if (itemErr || !itemRow) {
    console.error(
      "[plaid-public-token-exchange] plaid_items upsert failed",
      itemErr,
    );
    return jsonError(500, "could not persist Plaid Item");
  }
  const plaidItemRowId = itemRow.id as string;

  // Review fix #8: thread the per-account currency from Plaid's
  // /accounts/get instead of defaulting everything to USD. The
  // plaid_flutter SDK's LinkAccount metadata doesn't surface
  // iso_currency_code; the server side is the only place that
  // can resolve it correctly. Build a lookup of
  // {plaid_account_id -> currency} from /accounts/get and the
  // per-account loop below reads from it.
  //
  // Failure here is non-fatal — if Plaid's /accounts/get errors
  // we still create the accounts (defaulted to USD); the user
  // can fix the currency in account settings later. Better than
  // failing the entire link over a currency lookup.
  const currencyByPlaidAccountId = new Map<string, string>();
  try {
    const accountsResp = await plaidPost<{
      accounts: Array<{
        account_id: string;
        balances?: {
          iso_currency_code?: string | null;
          unofficial_currency_code?: string | null;
        };
      }>;
    }>("/accounts/get", { access_token: exchange.access_token });
    for (const a of accountsResp.accounts) {
      const iso = a.balances?.iso_currency_code;
      if (iso) currencyByPlaidAccountId.set(a.account_id, iso.toUpperCase());
      // unofficial_currency_code (crypto, etc.) is deliberately
      // ignored — the existing sync path drops those rows
      // entirely; the account itself defaults to USD here.
    }
  } catch (err) {
    console.warn(
      "[plaid-public-token-exchange] /accounts/get failed; " +
        "all accounts will default to USD currency",
      err instanceof PlaidApiError ? err.errorCode : err,
    );
  }

  // For each account in the payload, INSERT (or UPSERT on the
  // partial unique index from migration 055) into accounts.
  // Unmapped account_type values are skipped and reported.
  const inserted: InsertedAccount[] = [];
  const skipped: SkippedAccount[] = [];
  for (const a of body.accounts) {
    const mappedType = mapPlaidAccountType(a.type, a.subtype);
    if (mappedType === null) {
      skipped.push({
        plaid_account_id: a.id,
        name: a.name,
        plaid_type: a.type,
        plaid_subtype: a.subtype,
        reason: "no mapping from Plaid type/subtype to account_type",
      });
      continue;
    }

    // Upsert by (plaid_item_id, plaid_account_id) — the partial
    // unique index from migration 055 makes a re-link of the
    // same account refresh in place rather than duplicate.
    //
    // Currency precedence: explicit body.accounts[i].currency >
    // Plaid's /accounts/get iso_currency_code > USD. The mobile
    // SDK doesn't surface currency, so in practice this resolves
    // to (a.currency ?? Plaid lookup ?? 'USD').
    const resolvedCurrency = (a.currency ??
      currencyByPlaidAccountId.get(a.id) ??
      "USD").toUpperCase();
    const { data: accountRow, error: accountErr } = await supabase
      .from("accounts")
      .upsert(
        {
          household_id: householdId,
          owner_user_id: auth.auth.userId,
          name: a.name,
          account_type: mappedType,
          last_four: a.mask ?? null,
          currency: resolvedCurrency,
          is_active: true,
          plaid_item_id: plaidItemRowId,
          plaid_account_id: a.id,
        },
        { onConflict: "plaid_item_id,plaid_account_id" },
      )
      .select("id")
      .single();
    if (accountErr || !accountRow) {
      console.error(
        "[plaid-public-token-exchange] accounts upsert failed for " + a.id,
        accountErr,
      );
      skipped.push({
        plaid_account_id: a.id,
        name: a.name,
        plaid_type: a.type,
        plaid_subtype: a.subtype,
        reason: `INSERT failed: ${accountErr?.message ?? "unknown"}`,
      });
      continue;
    }
    inserted.push({
      account_id: accountRow.id as string,
      plaid_account_id: a.id,
      account_type: mappedType,
      name: a.name,
    });
  }

  return Response.json({
    plaid_item_id: plaidItemRowId,
    institution: body.institution,
    inserted_accounts: inserted,
    skipped_accounts: skipped,
  });
});
