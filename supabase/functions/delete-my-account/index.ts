// GDPR Right to Erasure (Art. 17). Audit 2026-05-26 M3.
//
// Wraps the two-step deletion the mobile UI needs as a single
// signed call:
//   1. As the calling user, invoke public.delete_my_household
//      (migration 067). The RPC requires the caller to be the
//      owner; cascades wire the rest of the data graph.
//   2. As the service role, call auth.admin.deleteUser(uid) to
//      remove the auth.users row itself. Without this step the
//      user could sign back in to a fresh household via the
//      handle_new_user trigger.
//
// The user receives 200 once both steps succeed. The mobile UI
// signs the user out locally after, but the session is already
// invalidated by step 2.
//
// Errors:
//   * 401 — caller isn't authenticated.
//   * 400 — request body missing householdId.
//   * 403 — caller isn't the owner of the named household
//          (surfaces the RPC's 42501).
//   * 5xx — anything else; the RPC or admin call threw.
//
// Body:
//   { "householdId": "<uuid>" }

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface RequestBody {
  householdId: string;
}

function jsonError(status: number, message: string): Response {
  return Response.json({ error: message }, { status });
}

serve(async (req) => {
  if (req.method !== "POST") return jsonError(405, "method not allowed");

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonError(401, "missing Authorization header");

  let body: RequestBody;
  try {
    body = (await req.json()) as RequestBody;
  } catch {
    return jsonError(400, "invalid JSON body");
  }
  if (!body.householdId || typeof body.householdId !== "string") {
    return jsonError(400, "householdId is required");
  }

  // Step 1: invoke delete_my_household as the calling user. RLS
  // and the function's get_household_role check enforce that
  // the caller is actually the owner — we don't re-check here.
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  // Resolve the caller's uid from their JWT for step 2.
  const {
    data: { user },
    error: userErr,
  } = await userClient.auth.getUser();
  if (userErr || !user) {
    return jsonError(401, "invalid session");
  }

  const { error: deleteErr } = await userClient.rpc("delete_my_household", {
    p_household_id: body.householdId,
  });
  if (deleteErr) {
    // PostgREST surfaces our 42501 EXCEPTION with code PGRST or
    // similar; pass the message through so the UI sees "not the
    // owner" specifically.
    console.error(
      "[delete-my-account] delete_my_household failed",
      deleteErr,
    );
    return jsonError(
      deleteErr.code === "42501" || deleteErr.message.includes("not the owner")
        ? 403
        : 500,
      deleteErr.message,
    );
  }

  // Step 2: delete the auth.users row via the admin API. Uses
  // the service role; not exposed to the user JWT.
  const adminClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error: authDeleteErr } = await adminClient.auth.admin.deleteUser(
    user.id,
  );
  if (authDeleteErr) {
    // The household is already gone at this point. Surface the
    // error so the user can retry the auth-row deletion via
    // support, but acknowledge the data is gone.
    console.error(
      "[delete-my-account] auth.admin.deleteUser failed AFTER " +
        "household delete succeeded",
      authDeleteErr,
    );
    return Response.json(
      {
        partial: true,
        household_deleted: true,
        auth_user_deleted: false,
        error: authDeleteErr.message,
      },
      { status: 500 },
    );
  }

  return Response.json({
    household_deleted: true,
    auth_user_deleted: true,
  });
});
