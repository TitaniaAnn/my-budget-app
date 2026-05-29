# `plaid-webhook`

Receives Plaid webhooks. Verifies the JWT signature in the
`Plaid-Verification` header, logs every event to
`plaid_webhook_events`, and routes on `(webhook_type, webhook_code)`
for any reactive work.

## Configuration

This function's URL is what Plaid POSTs to. Configure it in:

1. The Plaid dashboard → **Team Settings** → **API** → **Webhooks**
   → set the URL to:
   ```
   https://<your-project-ref>.supabase.co/functions/v1/plaid-webhook
   ```
2. The `PLAID_WEBHOOK_URL` env var on the same project so newly
   minted Link tokens auto-register this URL:
   ```bash
   supabase secrets set PLAID_WEBHOOK_URL=https://<ref>.supabase.co/functions/v1/plaid-webhook
   ```

For local dev: webhooks won't fire against `localhost`. Test the
verification path with [Plaid's webhook simulator](https://dashboard.plaid.com/team/webhooks)
once the function is deployed to a hosted Supabase project.

## What it does

1. Reads the raw POST body (signature verifies against bytes, not
   re-stringified JSON).
2. Verifies the `Plaid-Verification` JWT via
   [`verifyPlaidWebhook`](../_shared/plaid.ts):
   - decodes the JWT header to extract `kid`
   - fetches the corresponding public key from Plaid's
     `/webhook_verification_key/get`
   - verifies the JWT signature (ES256)
   - verifies the body's SHA-256 matches the JWT's
     `request_body_sha256` claim
   - verifies `iat` is within the last 5 minutes (replay window)
3. Resolves Plaid's `item_id` → internal `plaid_items.id` (NULL if
   we don't have it — webhook still logged for audit).
4. Inserts a row into `plaid_webhook_events`.
5. Routes:
   - `ITEM/ERROR` with re-auth-style error codes
     (`ITEM_LOGIN_REQUIRED`, `PENDING_EXPIRATION`,
     `PENDING_DISCONNECT`) → update `plaid_items.last_sync_error`
     so the dashboard's `ReauthBanner` lights up before the next
     failed sync.
   - `TRANSACTIONS/SYNC_UPDATES_AVAILABLE` → log only. Real-time
     sync triggering needs FCM (blocked on out-of-repo
     provisioning); the existing "sync on dashboard load" trigger
     covers active-user freshness.
   - Other codes → log only. Replay-friendly: a follow-up script
     can re-process `WHERE processed_at IS NULL`.
6. Stamps `processed_at` so the unprocessed-events index doesn't
   accumulate.

## Failure modes

- **Missing / invalid JWT** → returns 200 with `{received: false,
  reason}`. Plaid retries on 5xx but we explicitly DON'T want
  retries here — a forged request shouldn't be re-tried, and a
  signature failure caused by misconfigured `PLAID_CLIENT_ID` /
  `PLAID_SECRET` would loop indefinitely on retry.
- **DB write fails** → returns 500. Plaid retries with backoff,
  which is the right behaviour for transient infra.
- **Unknown `webhook_type` / `webhook_code`** → still logged,
  routing no-ops, `processed_at` set. The log surfaces the
  unknown shape for handler updates without a panic deploy.

## What's NOT here (deferred)

- **Real-time sync trigger.** Would require either FCM to wake a
  backgrounded app, or a service-role variant of
  `plaid-transactions-sync` (which currently requires
  `auth.uid()` via the RPC). Both are larger projects than
  Phase 4's scope.
- **`pg_cron` daily fallback sync.** Same reason — needs the
  service-role sync path. Deferred until either FCM lands or we
  add a `bulk_sync_items_for_cron` SECURITY DEFINER variant of
  the RPC.
