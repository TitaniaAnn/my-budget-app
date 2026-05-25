// Server-side notification dispatcher — slice 2 of FCM.
//
// The Flutter app already evaluates the same triggers locally
// (lib/features/notifications/services/notification_engine.dart)
// and shows in-app notifications via flutter_local_notifications.
// THIS function exists for the "alert while the app is closed"
// case: a scheduler invokes it once a day per household, it
// evaluates the same rules server-side, and POSTs to FCM for any
// pending notification keyed off device_push_tokens (migration
// 033).
//
// Invocation:
//   POST /functions/v1/send-notification
//   Body: { "household_id": "<uuid>" }
//
// What this does NOT do (yet — needs Firebase project provisioned
// out of repo):
//   * The actual FCM HTTP call is gated on `FIREBASE_SERVER_KEY`.
//     When unset, the function returns the would-be payload in
//     the response body and logs it; tests can verify the
//     evaluation without needing real Firebase. When set, it
//     POSTs to https://fcm.googleapis.com/fcm/send per token.
//   * No retry / backoff / token-invalidation pruning. A later
//     slice can add those once production behaviour is observable.
//
// The trigger logic is a TypeScript port of evaluateNotifications.
// It deliberately mirrors the Dart contract one-to-one so the
// two sides stay in sync — same dedup key namespacing, same $1
// noise floor on budget-over, same 24-hour created_at gate on
// large transactions, same transfer-leg exclusion.

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import {
  createClient,
  SupabaseClient,
} from "https://esm.sh/@supabase/supabase-js@2";

// ─── Engine constants ──────────────────────────────────────────
// These MUST match notification_engine.dart so both engines fire
// identically. Drift here would mean a user sees a push that the
// in-app surface doesn't (or vice versa) — confusing and worth
// avoiding.

const BUDGET_OVER_FLOOR_CENTS = 100;
const RECENT_TRANSACTION_WINDOW_MS = 24 * 60 * 60 * 1000;
const DEFAULT_LARGE_TX_THRESHOLD_CENTS = 20000;

interface PendingNotification {
  key: string;
  title: string;
  body: string;
}

interface RequestBody {
  household_id: string;
}

serve(async (req) => {
  if (req.method !== "POST") return jsonError(405, "method not allowed");

  let body: RequestBody;
  try {
    body = (await req.json()) as RequestBody;
  } catch {
    return jsonError(400, "invalid JSON body");
  }
  if (!body.household_id) return jsonError(400, "household_id is required");

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    // Service role bypasses RLS — the per-user RLS on
    // device_push_tokens hides other members' tokens from one
    // another, but a server-side dispatcher legitimately needs to
    // see all of them.
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    const evaluated = await evaluateForHousehold(supabase, body.household_id);
    // Atomic dedup against the shared notification_log. Whichever
    // pass — server here, in-app engine on the client — inserts
    // first wins; the loser sees its INSERT skipped by ON CONFLICT
    // and doesn't fire. See migration 039.
    const claimed = await claimUnfired(supabase, body.household_id, evaluated);
    const delivery = await deliverViaFcm(supabase, body.household_id, claimed);
    return Response.json({
      household_id: body.household_id,
      evaluated: evaluated.length,
      pending: claimed.length,
      sent: delivery.sent,
      // Tokens FCM said were dead and that we removed from
      // device_push_tokens. Surfaced so a scheduler can flag noisy
      // households (lots of stale tokens) for follow-up.
      invalidated: delivery.invalidated,
      // When FIREBASE_SERVER_KEY is unset we surface the payload
      // so callers can verify the evaluation without real FCM.
      preview: delivery.sent === 0 && claimed.length > 0
        ? claimed
        : undefined,
    }, { status: 200 });
  } catch (err) {
    return jsonError(500, String(err));
  }
});

/// Tries to claim each pending key in notification_log via
/// INSERT ... ON CONFLICT DO NOTHING RETURNING. The keys that come
/// back are the ones we successfully wrote (i.e., no other pass
/// fired them). The keys that DON'T come back are already in the
/// log — we drop them so the user doesn't see the same alert via
/// two paths.
async function claimUnfired(
  supabase: SupabaseClient,
  householdId: string,
  pending: PendingNotification[],
): Promise<PendingNotification[]> {
  if (pending.length === 0) return [];
  const rows = pending.map((n) => ({
    household_id: householdId,
    dedup_key: n.key,
    source: "server",
  }));
  // ignoreDuplicates: true → DO NOTHING on PK conflict (the PK is
  // (household_id, dedup_key)). Returned rows are only the new
  // ones; existing rows are skipped silently.
  const { data: claimedRows, error } = await supabase
    .from("notification_log")
    .upsert(rows, { onConflict: "household_id,dedup_key", ignoreDuplicates: true })
    .select("dedup_key");
  if (error) throw error;
  const claimedKeys = new Set(
    (claimedRows as Array<{ dedup_key: string }> | null)
      ?.map((r) => r.dedup_key) ?? [],
  );
  return pending.filter((n) => claimedKeys.has(n.key));
}

// ─── Engine port ───────────────────────────────────────────────
//
// Mirrors evaluateNotifications in
// notification_engine.dart. Reads the same rows the Flutter side
// would read for the same household, applies the same dedup map
// (stored client-side per device in slice 1 — server-side dedup
// is its own follow-up so the same notification doesn't fire
// twice when the user is online + a push lands).

async function evaluateForHousehold(
  supabase: SupabaseClient,
  householdId: string,
): Promise<PendingNotification[]> {
  // The household's notification settings live in shared_preferences
  // on the client; the server doesn't see them today. Slice 2-A
  // would move the master toggle into a notification_settings DB
  // table. For now this function assumes the user has consented
  // to budget-over + large-tx alerts.

  const out: PendingNotification[] = [];

  // Pre-fetch the household's display currency + FX rates so the
  // budget-over branch can convert caps and the spending RPC can
  // convert per-row totals. Mirrors budgetDataProvider on the Dart
  // side. A USD-only household ends up with an empty rate map and
  // every conversion short-circuits to the legacy single-currency
  // behaviour.
  const [{ data: household }, { data: fxRows }, { data: categoryRows }] =
    await Promise.all([
      supabase
        .from("households")
        .select("display_currency")
        .eq("id", householdId)
        .single(),
      // newest-first ordering means the first row we see for a
      // (from, to) pair wins the latest-rate slot
      supabase
        .from("fx_rates")
        .select("from_currency, to_currency, as_of_date, rate")
        .eq("household_id", householdId)
        .order("as_of_date", { ascending: false }),
      supabase
        .from("categories")
        .select("id, name")
        .eq("household_id", householdId),
    ]);
  const displayCurrency: string = household?.display_currency ?? "USD";
  const ratesToDisplay = new Map<string, number>();
  for (const r of (fxRows as Array<{
    from_currency: string;
    to_currency: string;
    rate: number | string;
  }> | null) ?? []) {
    if (r.to_currency !== displayCurrency) continue;
    if (ratesToDisplay.has(r.from_currency)) continue;
    ratesToDisplay.set(r.from_currency, Number(r.rate));
  }
  const categoryNames = new Map<string, string>(
    (categoryRows as Array<{ id: string; name: string }> | null)
      ?.map((c) => [c.id, c.name]) ?? [],
  );
  // The RPC accepts a JSONB rate map; null preserves migration 029
  // single-currency behaviour. We pass null when the household has
  // no rates configured so a USD-only household pays nothing for
  // the FX-aware path.
  const rpcRates: Record<string, number> | null = ratesToDisplay.size === 0
    ? null
    : Object.fromEntries(ratesToDisplay);

  // Budget-over: read each budget + its current-period spending,
  // surface those exceeding cap + the $1 floor.
  const { data: budgets } = await supabase
    .from("budgets")
    .select("id, category_id, amount, currency, period, start_date")
    .eq("household_id", householdId);
  if (budgets) {
    for (const b of budgets) {
      const { from, to } = currentPeriodRange(b.period);

      // Convert the budget cap to the household's display currency.
      // exclude-not-lie: a foreign-currency budget with no rate
      // gets dropped from evaluation rather than compared at rate=1.
      let capCents: number;
      if (b.currency === displayCurrency) {
        capCents = b.amount;
      } else {
        const rate = ratesToDisplay.get(b.currency);
        if (rate === undefined) continue;
        capCents = Math.round(b.amount * rate);
      }

      const { data: rpc } = await supabase.rpc("get_category_spending", {
        p_household_id: householdId,
        p_from: from,
        p_to: to,
        p_rates: rpcRates,
      });
      const row = (rpc as Array<{ category_id: string; net_cents: number }> | null)
        ?.find((r) => r.category_id === b.category_id);
      const spent = Math.max(0, row?.net_cents ?? 0);
      if (spent <= capCents) continue;
      const overBy = spent - capCents;
      if (overBy < BUDGET_OVER_FLOOR_CENTS) continue;
      const categoryName = categoryNames.get(b.category_id) ?? "Unknown";
      out.push({
        key: `budget_over:${b.id}:${from}`,
        title: `Over budget: ${categoryName}`,
        body: `$${(overBy / 100).toFixed(2)} over the $${(capCents / 100).toFixed(2)} ${periodLabel(b.period)} cap.`,
      });
    }
  }

  // Large transactions in the last 24 hours. The threshold check
  // is in display currency — a transaction in a foreign currency
  // converts via ratesToDisplay before the comparison. exclude-not-
  // lie: a tx whose currency is missing from the rate map is
  // dropped, not compared at rate=1.
  const cutoff = new Date(Date.now() - RECENT_TRANSACTION_WINDOW_MS).toISOString();
  const { data: recentTx } = await supabase
    .from("transactions")
    .select("id, amount, currency, merchant, description, transfer_id, created_at")
    .eq("household_id", householdId)
    .gte("created_at", cutoff)
    .is("transfer_id", null);
  if (recentTx) {
    for (const t of recentTx) {
      let amountInDisplay: number;
      if (t.currency === displayCurrency) {
        amountInDisplay = t.amount;
      } else {
        const rate = ratesToDisplay.get(t.currency);
        if (rate === undefined) continue;
        amountInDisplay = Math.round(t.amount * rate);
      }
      if (Math.abs(amountInDisplay) < DEFAULT_LARGE_TX_THRESHOLD_CENTS) continue;
      const sign = amountInDisplay < 0 ? "-" : "+";
      out.push({
        key: `large_tx:${t.id}`,
        title: `Large transaction`,
        body: `${sign}$${(Math.abs(amountInDisplay) / 100).toFixed(2)} — ${t.merchant ?? t.description}`,
      });
    }
  }

  return out;
}

/// Mirrors `BudgetPeriod.label.toLowerCase()` on the Dart side so the
/// notification body reads identically across the two engines.
function periodLabel(period: string): string {
  switch (period) {
    case "weekly":
      return "1 week";
    case "biweekly":
      return "2 weeks";
    case "monthly":
      return "monthly";
    case "semiannual":
      return "6 months";
    case "annual":
      return "annual";
    default:
      return period;
  }
}

/// Returns YYYY-MM-DD `from` / `to` strings for the current
/// period of a budget cadence. Mirrors BudgetPeriod.currentRange
/// in budget.dart. Weekly/biweekly use Monday-anchored ISO weeks.
function currentPeriodRange(period: string): { from: string; to: string } {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const iso = (d: Date) => d.toISOString().slice(0, 10);

  switch (period) {
    case "monthly": {
      const from = new Date(today.getFullYear(), today.getMonth(), 1);
      const to = new Date(today.getFullYear(), today.getMonth() + 1, 0);
      return { from: iso(from), to: iso(to) };
    }
    case "weekly": {
      // Monday-anchored week. JS getDay() is 0=Sun..6=Sat; shift
      // so Mon=0.
      const dayFromMon = (today.getDay() + 6) % 7;
      const monday = new Date(today);
      monday.setDate(today.getDate() - dayFromMon);
      const sunday = new Date(monday);
      sunday.setDate(monday.getDate() + 6);
      return { from: iso(monday), to: iso(sunday) };
    }
    case "annual": {
      const from = new Date(today.getFullYear(), 0, 1);
      const to = new Date(today.getFullYear(), 11, 31);
      return { from: iso(from), to: iso(to) };
    }
    default: {
      // biweekly / semiannual not yet ported — fall back to monthly
      // so a misconfigured budget at least gets ITS rough range
      // rather than crashing the dispatcher.
      const from = new Date(today.getFullYear(), today.getMonth(), 1);
      const to = new Date(today.getFullYear(), today.getMonth() + 1, 0);
      return { from: iso(from), to: iso(to) };
    }
  }
}

// ─── FCM delivery ──────────────────────────────────────────────

interface DeliveryReport {
  sent: number;
  invalidated: number;
}

async function deliverViaFcm(
  supabase: SupabaseClient,
  householdId: string,
  pending: PendingNotification[],
): Promise<DeliveryReport> {
  if (pending.length === 0) return { sent: 0, invalidated: 0 };
  const serverKey = Deno.env.get("FIREBASE_SERVER_KEY");
  if (!serverKey) {
    // No Firebase yet — log + return zeros, the caller sees
    // `preview` in the response so tests can assert on what would
    // have been sent. Treats this path as "stubbed" rather than
    // "failed."
    console.log(
      `[send-notification] FIREBASE_SERVER_KEY unset; would send ${pending.length} notifications`,
    );
    return { sent: 0, invalidated: 0 };
  }

  const { data: tokens } = await supabase
    .from("device_push_tokens")
    .select("token")
    .eq("household_id", householdId);
  if (!tokens || tokens.length === 0) return { sent: 0, invalidated: 0 };

  let sent = 0;
  // Tokens FCM tells us are dead — collected here so we can do one
  // batch DELETE at the end rather than one per failure.
  const invalidTokens = new Set<string>();
  for (const t of tokens) {
    if (invalidTokens.has(t.token)) continue;
    for (const n of pending) {
      // Legacy FCM HTTP API — Firebase has a v1 OAuth-scoped API
      // we'd ideally use, but the legacy server-key form is the
      // simplest credential to handle from an Edge Function. A
      // follow-up can swap when we're ready to take the OAuth dep.
      const res = await fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Authorization": `key=${serverKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          to: t.token,
          notification: { title: n.title, body: n.body },
          // tag matches the local-engine's hashCode-keyed update-
          // in-place so two devices in the same household don't
          // stack the same alert.
          data: { tag: n.key },
        }),
      });
      if (!res.ok) continue;
      // FCM returns 200 even for known-bad tokens; the real verdict
      // is in the body's `results[].error`. Pull it out and decide.
      const body = await res.json().catch(() => null);
      if (isFcmTokenInvalid(body)) {
        invalidTokens.add(t.token);
        // Don't waste the remaining notifications on this token.
        break;
      }
      sent += 1;
    }
  }

  // Prune any tokens FCM flagged as dead so we stop pushing to
  // uninstalled / unregistered devices. Scoped to this household:
  // device_push_tokens has UNIQUE(user_id, token), so the same
  // token CAN coexist on two households when a user is a member
  // of both. Without the household_id filter, the service-role
  // DELETE would wipe the token from the other household too —
  // an attacker who can craft an invalid token (via a compromised
  // device or by registering a known-dead token) could weaponise
  // this to purge legitimate tokens globally.
  if (invalidTokens.size > 0) {
    await supabase
      .from("device_push_tokens")
      .delete()
      .eq("household_id", householdId)
      .in("token", [...invalidTokens]);
  }

  return { sent, invalidated: invalidTokens.size };
}

/// True when the FCM response body indicates the token is dead.
/// Legacy FCM HTTP returns 200 with one of these error codes:
///   * NotRegistered — token was unregistered (user uninstalled,
///     cleared data, etc.)
///   * InvalidRegistration — token is malformed
///
/// Both mean the row should leave device_push_tokens. Other errors
/// (RateLimit, InternalServerError, MismatchSenderId, ...) are
/// transient or our problem, not the token's; leave the row alone.
function isFcmTokenInvalid(body: unknown): boolean {
  if (!body || typeof body !== "object") return false;
  const results = (body as { results?: Array<{ error?: string }> }).results;
  const err = results?.[0]?.error;
  return err === "NotRegistered" || err === "InvalidRegistration";
}

function jsonError(status: number, message: string): Response {
  return Response.json({ error: message }, { status });
}
