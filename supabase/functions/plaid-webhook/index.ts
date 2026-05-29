// Receives Plaid webhooks. Verifies the JWT signature in the
// `Plaid-Verification` header (without which anyone with the
// URL could forge events), logs the raw event to
// `plaid_webhook_events`, and routes on (webhook_type,
// webhook_code) for any reactive work.
//
// Phase 4 scope:
//   * Always: log to plaid_webhook_events. Audit trail +
//     debugging for unknown codes.
//   * ITEM/ERROR with re-auth-style error codes
//     (ITEM_LOGIN_REQUIRED / PENDING_EXPIRATION /
//     PENDING_DISCONNECT) → update plaid_items.last_sync_error
//     so the dashboard's ReauthBanner surfaces immediately
//     (without waiting for the next failed sync to discover
//     the state).
//   * TRANSACTIONS/SYNC_UPDATES_AVAILABLE → log only. Real-
//     time sync triggering requires either:
//       - FCM to wake a backgrounded app (FCM is blocked on
//         out-of-repo provisioning per existing CLAUDE.md), or
//       - A service-role sync path (would need refactoring
//         plaid-transactions-sync + upsert_plaid_transactions
//         to not require auth.uid(); deferred).
//     The existing "sync on dashboard load" trigger covers
//     the common active-user case.
//   * Other webhook_codes → log only. Re-handling can be added
//     later without redeploying the function in panic mode.
//
// Invocation: Plaid POSTs to this URL with body:
//   {
//     "webhook_type": "TRANSACTIONS" | "ITEM" | ...,
//     "webhook_code": "SYNC_UPDATES_AVAILABLE" | "ERROR" | ...,
//     "item_id": "<Plaid's opaque item_id>",
//     "error": { ... } | null,
//     ... other type-specific fields
//   }
// Headers:
//   Plaid-Verification: <JWT signed by Plaid>
//
// The function returns 200 even when verification fails (after
// logging the failure) so Plaid doesn't retry indefinitely on
// our config errors. Only true server faults (DB unreachable
// etc.) return 5xx for retry.

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { jsonError, verifyPlaidWebhook } from "../_shared/plaid.ts";

interface PlaidWebhookBody {
  webhook_type: string;
  webhook_code: string;
  item_id?: string;
  error?: { error_code?: string; error_message?: string } | null;
  [key: string]: unknown;
}

const REAUTH_ERROR_CODES = new Set([
  "ITEM_LOGIN_REQUIRED",
  "PENDING_EXPIRATION",
  "PENDING_DISCONNECT",
]);

serve(async (req) => {
  if (req.method !== "POST") return jsonError(405, "method not allowed");

  // Read the raw body BEFORE parsing — the signature verifies
  // against the exact byte sequence Plaid signed, not the
  // re-stringified JSON.
  const rawBody = await req.text();

  // Verify the Plaid signature. Failure here means either:
  //   * a forged request (most likely) — return 200 so we don't
  //     give the attacker probe-able timing differences from
  //     a successful path
  //   * our PLAID_CLIENT_ID / PLAID_SECRET is misconfigured —
  //     also 200, the logs will surface this
  const verificationHeader = req.headers.get("Plaid-Verification");
  if (!verificationHeader) {
    console.warn("[plaid-webhook] missing Plaid-Verification header");
    return Response.json({ received: false, reason: "missing header" });
  }
  try {
    await verifyPlaidWebhook(verificationHeader, rawBody);
  } catch (err) {
    console.error(
      "[plaid-webhook] signature verification failed",
      err instanceof Error ? err.message : err,
    );
    return Response.json({ received: false, reason: "invalid signature" });
  }

  // Parse the body — verification confirmed the byte sequence
  // matches the signature, so JSON.parse can't be exploited here.
  let body: PlaidWebhookBody;
  try {
    body = JSON.parse(rawBody) as PlaidWebhookBody;
  } catch {
    return jsonError(400, "invalid JSON body");
  }
  if (!body.webhook_type || !body.webhook_code) {
    return jsonError(400, "missing webhook_type or webhook_code");
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Resolve Plaid's item_id to our internal plaid_items.id.
  // The log row records the internal id when known; NULL when
  // the webhook references an Item we don't have (already
  // deleted / from a different environment / never seen).
  let internalItemId: string | null = null;
  let householdId: string | null = null;
  if (body.item_id) {
    const { data: itemRow } = await supabase
      .from("plaid_items")
      .select("id, household_id")
      .eq("plaid_item_id", body.item_id)
      .maybeSingle();
    if (itemRow) {
      internalItemId = itemRow.id as string;
      householdId = itemRow.household_id as string;
    }
  }

  // Compute SHA-256 of the raw body for replay protection
  // (review fix #17). Migration 060 added a UNIQUE on
  // (plaid_item_id, dedup_hash) so a redelivered webhook
  // ON-CONFLICT-skips the INSERT — RETURNING comes back empty
  // and we exit early without re-firing the routing
  // side-effects.
  const bodyHashBuf = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(rawBody),
  );
  const dedupHash = Array.from(new Uint8Array(bodyHashBuf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  // Always log first — even unknown webhook codes go in the
  // audit table so we can grep for them later. Use upsert with
  // ignoreDuplicates so a replay returns no rows.
  const { data: logRows, error: logErr } = await supabase
    .from("plaid_webhook_events")
    .upsert(
      {
        plaid_item_id: internalItemId,
        webhook_type: body.webhook_type,
        webhook_code: body.webhook_code,
        payload: body,
        dedup_hash: dedupHash,
      },
      {
        onConflict: "plaid_item_id,dedup_hash",
        ignoreDuplicates: true,
      },
    )
    .select("id");
  if (logErr) {
    console.error("[plaid-webhook] event log insert failed", logErr);
    return jsonError(500, "could not record webhook event");
  }
  if (!logRows || logRows.length === 0) {
    // Replay detected — Plaid retried a previously-handled
    // delivery. Skip routing entirely. Return 200 so Plaid
    // stops retrying.
    console.log(
      `[plaid-webhook] replay detected for item ${internalItemId} ` +
        `(${body.webhook_type}/${body.webhook_code}); skipping`,
    );
    return Response.json({
      received: true,
      replay: true,
      plaid_item_id: internalItemId,
    });
  }
  const logRow = logRows[0];

  // ── Routing ───────────────────────────────────────────────
  const isItemError = body.webhook_type === "ITEM" &&
    (body.webhook_code === "ERROR" ||
      body.webhook_code === "PENDING_EXPIRATION" ||
      body.webhook_code === "PENDING_DISCONNECT");
  const errorCode = body.webhook_code === "ERROR"
    ? body.error?.error_code
    : body.webhook_code; // PENDING_EXPIRATION etc. are themselves the code

  if (
    isItemError &&
    internalItemId &&
    errorCode &&
    REAUTH_ERROR_CODES.has(errorCode)
  ) {
    await supabase
      .from("plaid_items")
      .update({ last_sync_error: errorCode })
      .eq("id", internalItemId);
  }

  // TRANSACTIONS/SYNC_UPDATES_AVAILABLE: log only for Phase 4.
  // The next time the user opens the app, the dashboard's
  // plaidSyncTriggerProvider will fire and pick up the new
  // data. Real-time push requires FCM (out of repo).

  // Mark processed regardless of whether routing did anything —
  // "we got this event and we made our routing decision."
  // Unprocessed rows (processed_at IS NULL) only exist on
  // crash, which the unprocessed-events index helps find.
  await supabase
    .from("plaid_webhook_events")
    .update({ processed_at: new Date().toISOString() })
    .eq("id", logRow.id);

  return Response.json({
    received: true,
    event_id: logRow.id,
    plaid_item_id: internalItemId,
    household_id: householdId,
  });
});

