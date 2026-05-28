// Mints a short-lived Plaid Link token the mobile SDK uses to
// open the Link flow. First of three Plaid Edge Functions (the
// others handle public→access token exchange and /transactions/
// sync).
//
// Flow:
//   1. Mobile calls supabase.functions.invoke('plaid-link-token-create')
//   2. This function calls Plaid's POST /link/token/create with
//      the user's id as client_user_id (Plaid uses this to dedup
//      multiple Link sessions from the same user).
//   3. Returns { link_token, expiration } to the mobile app.
//   4. Mobile passes link_token to the Plaid Flutter SDK and
//      opens the Link UI; user picks bank + logs in.
//   5. SDK's onSuccess callback hands back a `public_token` →
//      mobile calls plaid-public-token-exchange (next function).
//
// The link_token itself is non-sensitive (short-lived, scoped
// to one Link session); only the access_token returned by
// /item/public_token/exchange is the long-lived credential, and
// that one never leaves the Edge Function tier.
//
// Invocation:
//   POST /functions/v1/plaid-link-token-create
//   Headers: Authorization: Bearer <user JWT>
//   Body: {}  (or optionally { accountFilters: {...} } — passthrough)

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import {
  jsonError,
  plaidEnvironment,
  plaidPost,
  PlaidApiError,
  requireAuthedUser,
} from "../_shared/plaid.ts";

interface RequestBody {
  // Optional Plaid Link account-filter passthrough. Most apps
  // don't need this; included for forward-compat with niche cases
  // like "only show deposit-style accounts."
  accountFilters?: Record<string, unknown>;
}

interface PlaidLinkTokenResponse {
  link_token: string;
  expiration: string;
  request_id: string;
}

serve(async (req) => {
  if (req.method !== "POST") return jsonError(405, "method not allowed");

  const auth = await requireAuthedUser(req);
  if (!auth.ok) return auth.response;

  let body: RequestBody = {};
  if (req.headers.get("content-length") !== "0") {
    try {
      body = (await req.json()) as RequestBody;
    } catch {
      // An empty body POST is fine; only reject malformed JSON.
      return jsonError(400, "invalid JSON body");
    }
  }

  try {
    // Plaid Link token request. `client_user_id` is the Plaid-
    // side identifier for this end user — using auth.uid keeps
    // a 1:1 mapping so a re-link from the same user updates the
    // same Plaid User on their side.
    //
    // products=['transactions'] is the only product we use. Adding
    // more (auth, identity, etc.) here would inflate the
    // permission prompt the user sees and trigger additional
    // billing on Plaid's side.
    const webhook = Deno.env.get("PLAID_WEBHOOK_URL") ?? undefined;
    const response = await plaidPost<PlaidLinkTokenResponse>(
      "/link/token/create",
      {
        client_name: "MyBudget",
        language: "en",
        country_codes: ["US"],
        products: ["transactions"],
        user: { client_user_id: auth.auth.userId },
        ...(webhook ? { webhook } : {}),
        ...(body.accountFilters
          ? { account_filters: body.accountFilters }
          : {}),
      },
    );

    return Response.json({
      link_token: response.link_token,
      expiration: response.expiration,
      environment: plaidEnvironment(),
    });
  } catch (err) {
    if (err instanceof PlaidApiError) {
      // Don't echo Plaid's full error body to the client — it
      // can include internal request IDs. Log here, return a
      // friendly shape.
      console.error("[plaid-link-token-create] Plaid error", {
        status: err.status,
        errorCode: err.errorCode,
        errorType: err.errorType,
        requestId: err.requestId,
      });
      return jsonError(
        err.status >= 500 ? 502 : 400,
        `Plaid Link setup failed (${err.errorCode ?? "unknown"})`,
      );
    }
    console.error("[plaid-link-token-create] unexpected error", err);
    return jsonError(500, "internal error");
  }
});
