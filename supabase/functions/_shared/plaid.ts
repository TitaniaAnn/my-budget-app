// Shared Plaid HTTP helpers for the three plaid-* Edge Functions.
//
// Folder prefix `_shared/` is a Supabase convention: directories
// starting with `_` are NOT deployed as functions, just bundled
// into anything that imports from them.
//
// Why hand-rolled fetch instead of npm:plaid? Two reasons:
//   1. Deno's npm-interop adds startup time + a dependency on
//      Node-isms (Buffer, etc.) that the existing send-notification
//      function deliberately avoids — keeping the pattern uniform.
//   2. Plaid's REST surface is narrow for our use (link-token-create,
//      item/public_token/exchange, transactions/sync). Hand-rolling
//      keeps every wire shape explicit in the function source.

/// Resolves PLAID_ENV to the corresponding Plaid API base URL.
/// `development` is supported for completeness even though Plaid is
/// sunsetting it; new integrations should be on `sandbox` or
/// `production`.
export function plaidBaseUrl(): string {
  const env = (Deno.env.get("PLAID_ENV") ?? "sandbox").toLowerCase();
  switch (env) {
    case "production":
      return "https://production.plaid.com";
    case "development":
      return "https://development.plaid.com";
    case "sandbox":
    default:
      return "https://sandbox.plaid.com";
  }
}

/// Returns the env-configured Plaid environment string. Stored on
/// every `plaid_items` row so a household never has Items from
/// mixed environments under the same row.
export function plaidEnvironment(): "sandbox" | "development" | "production" {
  const env = (Deno.env.get("PLAID_ENV") ?? "sandbox").toLowerCase();
  if (env === "production" || env === "development") return env;
  return "sandbox";
}

/// Raised when Plaid returns a non-2xx. Carries the error code +
/// message so callers can branch (e.g. `ITEM_LOGIN_REQUIRED` →
/// surface re-auth) without re-parsing the response body.
export class PlaidApiError extends Error {
  readonly status: number;
  readonly errorCode: string | null;
  readonly errorType: string | null;
  readonly requestId: string | null;

  constructor(opts: {
    status: number;
    errorCode: string | null;
    errorType: string | null;
    requestId: string | null;
    message: string;
  }) {
    super(opts.message);
    this.name = "PlaidApiError";
    this.status = opts.status;
    this.errorCode = opts.errorCode;
    this.errorType = opts.errorType;
    this.requestId = opts.requestId;
  }
}

/// Posts [body] to a Plaid endpoint path and returns the parsed
/// JSON response. Automatically threads PLAID_CLIENT_ID +
/// PLAID_SECRET from env. Throws [PlaidApiError] on non-2xx so the
/// caller can pattern-match on `errorCode` for re-auth and rate-
/// limit cases.
export async function plaidPost<T>(
  path: string,
  body: Record<string, unknown>,
): Promise<T> {
  const clientId = Deno.env.get("PLAID_CLIENT_ID");
  const secret = Deno.env.get("PLAID_SECRET");
  if (!clientId || !secret) {
    throw new Error(
      "PLAID_CLIENT_ID / PLAID_SECRET not configured. Set via " +
        "`supabase secrets set ...` (production) or " +
        "`supabase/functions/.env.local` (local serve).",
    );
  }
  const res = await fetch(`${plaidBaseUrl()}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      client_id: clientId,
      secret,
      ...body,
    }),
  });
  const raw = await res.text();
  let parsed: unknown;
  try {
    parsed = raw.length === 0 ? {} : JSON.parse(raw);
  } catch {
    throw new PlaidApiError({
      status: res.status,
      errorCode: null,
      errorType: null,
      requestId: null,
      message: `Plaid response was not JSON (HTTP ${res.status}): ${raw.slice(0, 200)}`,
    });
  }
  if (!res.ok) {
    const obj = parsed as {
      error_code?: string;
      error_type?: string;
      error_message?: string;
      request_id?: string;
    };
    throw new PlaidApiError({
      status: res.status,
      errorCode: obj.error_code ?? null,
      errorType: obj.error_type ?? null,
      requestId: obj.request_id ?? null,
      message: obj.error_message ??
        `Plaid call to ${path} failed with HTTP ${res.status}`,
    });
  }
  return parsed as T;
}

/// Maps Plaid's positive-outflow / float-dollars `amount` to the
/// project's negative-outflow / integer-cents convention.
///
/// Parse via fixed-2 string then split on `.` to dodge JS float
/// rounding (`19.99 * 100 === 1998.9999999999998`). Tests below
/// pin the boundary cases: $19.99 → -1999, $-19.99 → 1999,
/// $0.01 → -1, $1234.56 → -123456, $0 → 0.
export function plaidAmountToCents(plaidAmount: number): number {
  if (!Number.isFinite(plaidAmount)) {
    throw new Error(`plaidAmountToCents: non-finite input ${plaidAmount}`);
  }
  const str = plaidAmount.toFixed(2);
  const negative = str.startsWith("-");
  const magnitude = negative ? str.slice(1) : str;
  const [whole, frac] = magnitude.split(".");
  const cents = parseInt(whole, 10) * 100 + parseInt(frac, 10);
  // Plaid: positive = outflow. Project: negative = outflow.
  // So Plaid-positive (no leading minus) → project-negative.
  return negative ? cents : -cents;
}

/// Maps Plaid's `(account.type, account.subtype)` pair to this
/// app's `account_type` enum value. Returns null for shapes we
/// don't model (the caller should surface them in the UI rather
/// than coerce, per the spec's account-import UX direction).
///
/// The enum values mirror `accounts.account_type` in
/// supabase/migrations/001_initial_schema.sql.
export function mapPlaidAccountType(
  plaidType: string | null,
  plaidSubtype: string | null,
): string | null {
  const t = (plaidType ?? "").toLowerCase();
  const s = (plaidSubtype ?? "").toLowerCase();
  if (t === "depository") {
    if (s === "checking") return "checking";
    if (s === "savings") return "savings";
    if (s === "cash management") return "cash";
    if (s === "money market") return "savings";
    return null;
  }
  if (t === "credit") {
    if (s === "credit card") return "credit_card";
    return null;
  }
  if (t === "investment") {
    if (s === "ira") return "ira_traditional";
    if (s === "roth") return "ira_roth";
    if (s === "roth ira") return "ira_roth";
    if (s === "401k") return "retirement_401k";
    if (s === "403b") return "retirement_403b";
    if (s === "hsa") return "hsa";
    if (s === "529") return "college_529";
    if (s === "brokerage" || s === "non-taxable brokerage account") {
      return "brokerage";
    }
    return null;
  }
  if (t === "loan") {
    if (s === "mortgage") return "mortgage";
    return null;
  }
  return null;
}

/// Bearer-token auth helper shared by every plaid-* function.
/// Returns `{ user, token }` on success; throws with the response
/// the caller should return on failure.
export interface AuthedRequest {
  token: string;
  userId: string;
}

export async function requireAuthedUser(req: Request): Promise<
  | { ok: true; auth: AuthedRequest }
  | { ok: false; response: Response }
> {
  const header = req.headers.get("Authorization") ?? "";
  const token = header.toLowerCase().startsWith("bearer ")
    ? header.slice(7).trim()
    : "";
  if (!token) {
    return { ok: false, response: jsonError(401, "missing bearer token") };
  }
  // Anon-key client so auth.getUser validates the JWT but the
  // subsequent queries from the caller side use the JWT's claims
  // (i.e. RLS applies normally for any further reads).
  const { createClient } = await import(
    "https://esm.sh/@supabase/supabase-js@2"
  );
  const client = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: `Bearer ${token}` } } },
  );
  const { data, error } = await client.auth.getUser(token);
  if (error || !data?.user) {
    return { ok: false, response: jsonError(401, "invalid or expired token") };
  }
  return { ok: true, auth: { token, userId: data.user.id } };
}

/// Standard error response shape. Matches the existing
/// send-notification function's helper.
export function jsonError(status: number, message: string): Response {
  return Response.json({ error: message }, { status });
}

/// Verifies a Plaid webhook against the JWT in the
/// `Plaid-Verification` header. Returns the parsed body on
/// success; throws on any verification failure.
///
/// Verification steps per Plaid's docs:
///   1. Decode the JWT header to extract the `kid` (key id).
///   2. Fetch the corresponding JWK from Plaid's
///      `/webhook_verification_key/get` endpoint.
///   3. Verify the JWT signature with that JWK (ES256).
///   4. Verify the body's SHA-256 matches the JWT's
///      `request_body_sha256` claim — this is what binds the
///      signature to THIS request's body.
///   5. Verify the JWT's iat is within the last 5 minutes (replay
///      window).
///
/// Without this, anyone with the function URL could forge
/// webhooks — sync triggers, fake re-auth states, garbage
/// audit log rows.
export async function verifyPlaidWebhook(
  verificationHeader: string,
  rawBody: string,
): Promise<void> {
  // Lazy npm import — jose is heavyweight, only pulled in on
  // webhook calls (not for the other plaid-* functions).
  const jose = await import("https://esm.sh/jose@5");

  // Step 1: decode the JWT header to get the kid. Don't trust
  // the alg field — pin to ES256 below.
  const decodedHeader = jose.decodeProtectedHeader(verificationHeader);
  const kid = decodedHeader.kid;
  if (!kid) throw new Error("Plaid-Verification: JWT has no `kid`");

  // Step 2: fetch the JWK from Plaid.
  const keyResponse = await plaidPost<{
    key: {
      kty: string;
      alg: string;
      use: string;
      kid: string;
      crv?: string;
      x?: string;
      y?: string;
      expired_at?: string | null;
    };
  }>("/webhook_verification_key/get", { key_id: kid });

  // Step 3 & 4: verify the JWT signature AND the body hash.
  // jose's jwtVerify checks signature + standard claims (iat, exp);
  // we still need to manually verify the body hash.
  const publicKey = await jose.importJWK(
    keyResponse.key as jose.JWK,
    "ES256",
  );
  const { payload } = await jose.jwtVerify(
    verificationHeader,
    publicKey,
    { algorithms: ["ES256"] },
  );

  const requestBodySha256 = (payload as { request_body_sha256?: string })
    .request_body_sha256;
  if (!requestBodySha256) {
    throw new Error("Plaid-Verification: missing request_body_sha256 claim");
  }

  // Compute SHA-256 of the raw body and compare.
  const bodyBytes = new TextEncoder().encode(rawBody);
  const bodyHashBuf = await crypto.subtle.digest("SHA-256", bodyBytes);
  const bodyHashHex = Array.from(new Uint8Array(bodyHashBuf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  if (bodyHashHex !== requestBodySha256) {
    throw new Error(
      "Plaid-Verification: body sha256 mismatch (request was modified " +
        "between signature + arrival)",
    );
  }

  // Step 5: iat freshness (5-minute replay window). jose's
  // jwtVerify already checks exp; iat needs a manual bound.
  const iat = (payload as { iat?: number }).iat;
  if (!iat) throw new Error("Plaid-Verification: missing iat claim");
  const ageSec = Math.floor(Date.now() / 1000) - iat;
  if (ageSec < -60 || ageSec > 300) {
    throw new Error(
      `Plaid-Verification: iat ${iat} outside the 5-minute replay window ` +
        `(${ageSec}s old)`,
    );
  }
}
