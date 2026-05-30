// Pulls /transactions/sync deltas from Plaid for ONE Item and
// hands them to the `upsert_plaid_transactions` RPC (one call
// per Plaid account in the delta). Triggered on every dashboard
// load (Phase 3 orchestrator) AND on pull-to-refresh AND from
// the webhook (Phase 4) when a TRANSACTIONS:SYNC_UPDATES_AVAILABLE
// event lands.
//
// Flow:
//   1. Mobile calls supabase.functions.invoke(
//        'plaid-transactions-sync', body: { plaid_item_id })
//   2. Function authenticates the JWT, loads the plaid_items row
//      via service role (the access_token column is invisible to
//      client SELECT — see migration 054), AND confirms the
//      caller's household_id matches the item's. Belt-and-
//      suspenders: the body's plaid_item_id alone isn't trusted.
//   3. Function loops calling Plaid /transactions/sync with
//      { access_token, cursor } until has_more = false. Each
//      response gives added/modified/removed arrays + a new
//      cursor.
//   4. Function groups the deltas by Plaid account_id, looks up
//      the matching internal `accounts.id` for each, transforms
//      (sign-flip, cents conversion, currency map), and calls
//      upsert_plaid_transactions ONCE per account with the user's
//      JWT so RLS still applies inside the RPC.
//   5. Function writes the new cursor + last_sync_at back to
//      plaid_items. On Plaid error, writes last_sync_error and
//      reports `requires_reauth: true` if the error code matches
//      the re-auth shapes the mobile UI watches for.
//
// Invocation:
//   POST /functions/v1/plaid-transactions-sync
//   Headers: Authorization: Bearer <user JWT>
//   Body: { plaid_item_id: '<internal uuid, NOT the Plaid id>' }
//
// Response:
//   {
//     added: number,
//     modified: number,
//     removed: number,
//     merged: number,             // dedup merges (migration 057)
//     accounts_synced: string[],  // internal accounts.id list
//     requires_reauth: boolean,
//   }

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  jsonError,
  plaidAmountToCents,
  plaidPost,
  PlaidApiError,
  requireAuthedUser,
} from "../_shared/plaid.ts";

interface RequestBody {
  plaid_item_id: string;
}

interface PlaidTransaction {
  transaction_id: string;
  account_id: string;
  amount: number;
  iso_currency_code: string | null;
  unofficial_currency_code: string | null;
  date: string;
  name: string;
  merchant_name: string | null;
  pending: boolean;
}

interface PlaidSyncResponse {
  added: PlaidTransaction[];
  modified: PlaidTransaction[];
  removed: Array<{ transaction_id: string; account_id: string }>;
  next_cursor: string;
  has_more: boolean;
  request_id: string;
}

/// Error codes that signal "user needs to re-link this Item via
/// Plaid Link in update mode." The mobile orchestrator branches
/// on `requires_reauth: true` and surfaces the re-auth prompt.
const REAUTH_ERROR_CODES = new Set([
  "ITEM_LOGIN_REQUIRED",
  "PENDING_EXPIRATION",
  "PENDING_DISCONNECT",
]);

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
  if (!body.plaid_item_id) {
    return jsonError(400, "plaid_item_id is required");
  }

  // Service-role client to read access_token + write cursor /
  // last_sync_at. The access_token column is invisible to the
  // anon / authenticated role — only the service role can read
  // it. Belt-and-suspenders: the auth check below verifies the
  // caller actually belongs to this item's household, so service
  // role doesn't widen the trust boundary.
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Load the item row + verify caller's household membership.
  // Pulls last_sync_error too so the success-path UPDATE can
  // guard against the sync-vs-webhook race (review fix #9): if
  // a webhook arrives mid-sync and writes a fresh error, our
  // success-clear shouldn't clobber it.
  const { data: itemRow, error: itemErr } = await serviceClient
    .from("plaid_items")
    .select("id, household_id, sync_cursor, last_sync_error")
    .eq("id", body.plaid_item_id)
    .maybeSingle();
  if (itemErr) return jsonError(500, String(itemErr));
  if (!itemRow) return jsonError(404, "plaid_item not found");
  const lastSyncErrorAtStart = itemRow.last_sync_error as string | null;

  // Audit 2026-05-26 M2: access_token column was dropped in
  // migration 066. Fetch the plaintext via the get_plaid_access_token
  // RPC, which decrypts the ciphertext server-side using a
  // vault-managed key. The plaintext never lives in a row in
  // the table — it transits as the RPC return value only.
  const { data: accessTokenData, error: tokenErr } = await serviceClient
    .rpc("get_plaid_access_token", { p_item_id: itemRow.id });
  if (tokenErr) return jsonError(500, String(tokenErr));
  const accessToken = accessTokenData as string | null;
  if (!accessToken) {
    return jsonError(
      500,
      "plaid_item has no access_token — re-link the institution",
    );
  }

  // User-scoped client for household-membership lookup. RLS on
  // household_members returns rows only where user_id = auth.uid(),
  // so a foreign item's household_id returns no row → 403.
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: `Bearer ${auth.auth.token}` } } },
  );
  const { data: memberRows } = await userClient
    .from("household_members")
    .select("household_id")
    .eq("household_id", itemRow.household_id)
    .limit(1);
  if (!memberRows || memberRows.length === 0) {
    return jsonError(
      403,
      "caller is not a member of this Plaid Item's household",
    );
  }

  // Build a Plaid-account-id → internal-accounts.id lookup ONCE.
  // The /transactions/sync deltas carry Plaid's account_id; the
  // RPC takes our internal id.
  const { data: accountRows, error: accountErr } = await serviceClient
    .from("accounts")
    .select("id, plaid_account_id, currency")
    .eq("plaid_item_id", itemRow.id);
  if (accountErr) return jsonError(500, String(accountErr));
  const accountByPlaidId = new Map<
    string,
    { id: string; currency: string }
  >();
  for (const a of accountRows ?? []) {
    if (a.plaid_account_id) {
      accountByPlaidId.set(a.plaid_account_id, {
        id: a.id as string,
        currency: ((a.currency as string | null) ?? "USD").toUpperCase(),
      });
    }
  }

  // ── Pull deltas from Plaid ──────────────────────────────────
  // /transactions/sync is cursor-paged: loop until has_more=false.
  // We carry the per-page deltas through to one big aggregated
  // set then dispatch per-account at the end (rather than one
  // RPC per page) so a high-volume initial sync doesn't pay
  // round-trip latency for every 100-row page.
  const allAdded: PlaidTransaction[] = [];
  const allModified: PlaidTransaction[] = [];
  const allRemoved: Array<{ transaction_id: string; account_id: string }> = [];
  let cursor = (itemRow.sync_cursor as string | null) ?? null;
  let requiresReauth = false;

  try {
    // Hard upper bound on pages to defend against a Plaid bug
    // that never sets has_more=false. 50 pages × 500 rows/page =
    // 25k transactions per single sync, which exceeds any
    // realistic family-scale Item's lifetime backfill.
    for (let page = 0; page < 50; page++) {
      const resp = await plaidPost<PlaidSyncResponse>("/transactions/sync", {
        access_token: accessToken,
        ...(cursor === null ? {} : { cursor }),
      });
      allAdded.push(...resp.added);
      allModified.push(...resp.modified);
      allRemoved.push(...resp.removed);
      cursor = resp.next_cursor;
      if (!resp.has_more) break;
    }
  } catch (err) {
    if (err instanceof PlaidApiError) {
      const errorCode = err.errorCode ?? "UNKNOWN";
      console.error("[plaid-transactions-sync] Plaid error", {
        plaid_item_id: itemRow.id,
        status: err.status,
        errorCode,
        errorType: err.errorType,
        requestId: err.requestId,
      });
      // Same race-guard as the success path (review fix #9).
      // A webhook that landed during this sync may have set a
      // more authoritative error; only overwrite if no one
      // else changed last_sync_error in the meantime.
      //
      // Audit 2026-05-26 H7: never downgrade a reauth code. If
      // the captured value was already a reauth code AND the
      // new error code isn't, omit last_sync_error from the
      // patch. The cursor + last_sync_at still update.
      const isDowngrade = lastSyncErrorAtStart !== null &&
        REAUTH_ERROR_CODES.has(lastSyncErrorAtStart) &&
        !REAUTH_ERROR_CODES.has(errorCode);
      const errPayload: Record<string, unknown> = {
        last_sync_at: new Date().toISOString(),
      };
      if (!isDowngrade) {
        errPayload.last_sync_error = errorCode;
      }
      let plaidErrUpdate = serviceClient
        .from("plaid_items")
        .update(errPayload)
        .eq("id", itemRow.id);
      plaidErrUpdate = lastSyncErrorAtStart === null
        ? plaidErrUpdate.is("last_sync_error", null)
        : plaidErrUpdate.eq("last_sync_error", lastSyncErrorAtStart);
      await plaidErrUpdate;
      requiresReauth = REAUTH_ERROR_CODES.has(errorCode);
      return Response.json({
        added: 0,
        modified: 0,
        removed: 0,
        merged: 0,
        accounts_synced: [],
        requires_reauth: requiresReauth,
        error_code: errorCode,
      }, { status: requiresReauth ? 200 : 502 });
    }
    console.error("[plaid-transactions-sync] unexpected error", err);
    return jsonError(500, "internal error");
  }

  // ── Group by Plaid account_id and call the RPC per account ──
  // The RPC's auth check requires the caller to own the account,
  // so we use the USER client here — RLS verifies household
  // membership AND the explicit guard in the RPC raises 42501 if
  // anything's off.
  const byAccount = new Map<
    string,
    {
      internalAccountId: string;
      currency: string;
      added: Record<string, unknown>[];
      modified: Record<string, unknown>[];
      removed: string[];
    }
  >();
  const ensureBucket = (plaidAccountId: string) => {
    let b = byAccount.get(plaidAccountId);
    if (!b) {
      const internal = accountByPlaidId.get(plaidAccountId);
      if (!internal) return null; // delta for an account we don't have
      b = {
        internalAccountId: internal.id,
        currency: internal.currency,
        added: [],
        modified: [],
        removed: [],
      };
      byAccount.set(plaidAccountId, b);
    }
    return b;
  };

  for (const t of allAdded) {
    const b = ensureBucket(t.account_id);
    if (!b) continue;
    // unofficial_currency_code = crypto / non-ISO. We drop and
    // log rather than coerce — silently mapping NXT to USD would
    // wreck the multi-currency rollups.
    if (t.unofficial_currency_code && !t.iso_currency_code) {
      console.warn(
        `[plaid-transactions-sync] dropping unofficial_currency_code row ${t.transaction_id}`,
      );
      continue;
    }
    b.added.push({
      plaid_transaction_id: t.transaction_id,
      amount_cents: plaidAmountToCents(t.amount),
      currency: (t.iso_currency_code ?? b.currency).toUpperCase(),
      description: t.name,
      merchant: t.merchant_name,
      date: t.date,
      pending: t.pending,
    });
  }
  for (const t of allModified) {
    const b = ensureBucket(t.account_id);
    if (!b) continue;
    // Same exclude-not-lie contract as the added path above.
    if (t.unofficial_currency_code && !t.iso_currency_code) {
      console.warn(
        `[plaid-transactions-sync] dropping unofficial_currency_code modified row ${t.transaction_id}`,
      );
      continue;
    }
    b.modified.push({
      plaid_transaction_id: t.transaction_id,
      amount_cents: plaidAmountToCents(t.amount),
      currency: (t.iso_currency_code ?? b.currency).toUpperCase(),
      description: t.name,
      merchant: t.merchant_name,
      date: t.date,
      pending: t.pending,
    });
  }
  for (const r of allRemoved) {
    const b = ensureBucket(r.account_id);
    if (!b) continue;
    b.removed.push(r.transaction_id);
  }

  let totalAdded = 0;
  let totalModified = 0;
  let totalRemoved = 0;
  let totalMerged = 0;
  const accountsSynced: string[] = [];
  const failedAccountIds: string[] = [];

  for (const [_plaidAccountId, bucket] of byAccount) {
    if (
      bucket.added.length === 0 &&
      bucket.modified.length === 0 &&
      bucket.removed.length === 0
    ) {
      continue;
    }
    const { data: rpcResult, error: rpcErr } = await userClient.rpc(
      "upsert_plaid_transactions",
      {
        p_account_id: bucket.internalAccountId,
        p_added: bucket.added,
        p_modified: bucket.modified,
        p_removed_external_ids: bucket.removed,
      },
    );
    if (rpcErr) {
      console.error(
        "[plaid-transactions-sync] RPC failed for account " +
          bucket.internalAccountId,
        rpcErr,
      );
      failedAccountIds.push(bucket.internalAccountId);
      continue;
    }
    const r = rpcResult as {
      added: number;
      modified: number;
      removed: number;
      merged: number;
    };
    totalAdded += r.added ?? 0;
    totalModified += r.modified ?? 0;
    totalRemoved += r.removed ?? 0;
    totalMerged += r.merged ?? 0;
    accountsSynced.push(bucket.internalAccountId);
  }

  // Code-review fix (review item #2): gate cursor persistence on
  // every per-account RPC succeeding. Pre-fix, a failing RPC for
  // account B would still advance the cursor — next sync would
  // start past B's deltas and B's transactions would be silently
  // missing forever.
  //
  // Two persistence paths now:
  //   * All RPCs succeeded → save new cursor, clear last_sync_error.
  //   * One or more failed → keep the OLD cursor so the next sync
  //     re-fetches the same deltas. Stamp a PARTIAL_FAILURE error
  //     code so the dashboard surfaces "sync stalled — will retry."
  //     A repeated failure on the same account means the user
  //     sees the error on every dashboard load until either the
  //     underlying issue clears or they unlink the account.
  //
  // last_sync_at updates either way so "we tried" is observable.
  const allSucceeded = failedAccountIds.length === 0;

  // Review fix #9: sync-vs-webhook race. If a webhook arrived
  // mid-sync (typically ITEM_LOGIN_REQUIRED) it stamped
  // `last_sync_error` to a value MORE authoritative than
  // anything we know — the webhook signal means the user has
  // to re-auth before any further syncs work, so our success-
  // clear or PARTIAL_FAILURE-stamp would lie about the state.
  //
  // Gate the UPDATE on `last_sync_error IS NOT DISTINCT FROM
  // <what we saw at start>`. If anyone else (webhook, parallel
  // sync) wrote a different value in the meantime, the filter
  // matches zero rows and our UPDATE no-ops. The next sync
  // attempt re-reads the (now webhook-set) state and acts on
  // it.
  // Audit 2026-05-26 H7: never DOWNGRADE a reauth code.
  // Scenario: a webhook fired BEFORE this function's line-125
  // read and set last_sync_error=ITEM_LOGIN_REQUIRED. We
  // captured that as lastSyncErrorAtStart. Our Plaid sync may
  // still 200 (the user re-authed in the meantime, or the call
  // raced past the bad state). Without this guard, the success
  // path would clear the reauth code via
  // `.eq('last_sync_error', 'ITEM_LOGIN_REQUIRED')` matching —
  // wiping the reauth state until the next sync re-fetches it.
  // Solution: omit last_sync_error from the patch when the
  // captured value was a reauth code AND the new value (null
  // on success, 'PARTIAL_FAILURE' on partial) is not. Cursor
  // and last_sync_at still update.
  const newErrValue = allSucceeded ? null : "PARTIAL_FAILURE";
  const isReauthDowngrade = lastSyncErrorAtStart !== null &&
    REAUTH_ERROR_CODES.has(lastSyncErrorAtStart) &&
    (newErrValue === null ||
      !REAUTH_ERROR_CODES.has(newErrValue));
  const updatePayload: Record<string, unknown> = {
    sync_cursor: allSucceeded ? cursor : itemRow.sync_cursor,
    last_sync_at: new Date().toISOString(),
  };
  if (!isReauthDowngrade) {
    updatePayload.last_sync_error = newErrValue;
  }
  let updateQuery = serviceClient
    .from("plaid_items")
    .update(updatePayload)
    .eq("id", itemRow.id);
  // PostgREST: .eq(col, null) becomes "col IS NULL" which
  // matches the IS-NOT-DISTINCT semantics for null-vs-null.
  // For non-null captured values, regular .eq works.
  updateQuery = lastSyncErrorAtStart === null
    ? updateQuery.is("last_sync_error", null)
    : updateQuery.eq("last_sync_error", lastSyncErrorAtStart);
  await updateQuery;

  return Response.json({
    added: totalAdded,
    modified: totalModified,
    removed: totalRemoved,
    merged: totalMerged,
    accounts_synced: accountsSynced,
    failed_account_ids: failedAccountIds,
    requires_reauth: false,
    // Surfaces in the mobile orchestrator's PlaidSyncSummary so
    // a UI banner can show "1 account didn't sync — retry."
    partial_failure: !allSucceeded,
  });
});
