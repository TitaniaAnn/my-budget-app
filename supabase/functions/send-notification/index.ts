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
    const pending = await evaluateForHousehold(supabase, body.household_id);
    const sent = await deliverViaFcm(supabase, body.household_id, pending);
    return Response.json({
      household_id: body.household_id,
      pending: pending.length,
      sent,
      // When FIREBASE_SERVER_KEY is unset we surface the payload
      // so callers can verify the evaluation without real FCM.
      preview: sent === 0 && pending.length > 0 ? pending : undefined,
    }, { status: 200 });
  } catch (err) {
    return jsonError(500, String(err));
  }
});

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

  // Budget-over: read each budget + its current-period spending,
  // surface those exceeding cap + the $1 floor.
  const { data: budgets } = await supabase
    .from("budgets")
    .select("id, category_id, amount, currency, period, start_date")
    .eq("household_id", householdId);
  if (budgets) {
    for (const b of budgets) {
      const { from, to } = currentPeriodRange(b.period);
      const { data: rpc } = await supabase.rpc("get_category_spending", {
        p_household_id: householdId,
        p_from: from,
        p_to: to,
      });
      const row = (rpc as Array<{ category_id: string; net_cents: number }> | null)
        ?.find((r) => r.category_id === b.category_id);
      const spent = Math.max(0, row?.net_cents ?? 0);
      if (spent <= b.amount) continue;
      const overBy = spent - b.amount;
      if (overBy < BUDGET_OVER_FLOOR_CENTS) continue;
      out.push({
        key: `budget_over:${b.id}:${from}`,
        title: `Over budget`,
        body: `$${(overBy / 100).toFixed(2)} over the $${(b.amount / 100).toFixed(2)} ${b.period} cap.`,
      });
    }
  }

  // Large transactions in the last 24 hours.
  const cutoff = new Date(Date.now() - RECENT_TRANSACTION_WINDOW_MS).toISOString();
  const { data: recentTx } = await supabase
    .from("transactions")
    .select("id, amount, merchant, description, transfer_id, created_at")
    .eq("household_id", householdId)
    .gte("created_at", cutoff)
    .is("transfer_id", null);
  if (recentTx) {
    for (const t of recentTx) {
      if (Math.abs(t.amount) < DEFAULT_LARGE_TX_THRESHOLD_CENTS) continue;
      const sign = t.amount < 0 ? "-" : "+";
      out.push({
        key: `large_tx:${t.id}`,
        title: `Large transaction`,
        body: `${sign}$${(Math.abs(t.amount) / 100).toFixed(2)} — ${t.merchant ?? t.description}`,
      });
    }
  }

  return out;
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

async function deliverViaFcm(
  supabase: SupabaseClient,
  householdId: string,
  pending: PendingNotification[],
): Promise<number> {
  if (pending.length === 0) return 0;
  const serverKey = Deno.env.get("FIREBASE_SERVER_KEY");
  if (!serverKey) {
    // No Firebase yet — log + return 0, the caller sees `preview`
    // in the response so tests can assert on what would have been
    // sent. Treats this path as "stubbed" rather than "failed."
    console.log(
      `[send-notification] FIREBASE_SERVER_KEY unset; would send ${pending.length} notifications`,
    );
    return 0;
  }

  const { data: tokens } = await supabase
    .from("device_push_tokens")
    .select("token")
    .eq("household_id", householdId);
  if (!tokens || tokens.length === 0) return 0;

  let sent = 0;
  for (const t of tokens) {
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
      if (res.ok) sent += 1;
    }
  }
  return sent;
}

function jsonError(status: number, message: string): Response {
  return Response.json({ error: message }, { status });
}
