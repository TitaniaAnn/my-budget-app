# send-notification

Server-side notification dispatcher. Evaluates the same triggers the
Flutter client evaluates locally ([notification_engine.dart](../../../mobile/lib/features/notifications/services/notification_engine.dart))
and POSTs to FCM for any pending notifications keyed off the
`device_push_tokens` table (migration 033).

The point of this function is the "app is closed" path: when the
client isn't running, a scheduler invokes this once per household and
the user still gets the alert.

## Authentication

The function refuses anything without a valid `Authorization: Bearer <token>` header. Two token types are accepted:

1. **`CRON_SECRET`** — a long random string set as a function env var. Used by the scheduled dispatcher (pg_cron, see deployment notes below) that fans the function out per household. The cron path trusts the body's `household_id` verbatim because the scheduler is the source of truth for which households to dispatch.
2. **User JWT** — a Supabase-issued user JWT. The function verifies it against `auth.users` and confirms the caller is a member of the requested `household_id` via the `household_members` table. Used by any client-initiated invocation (today: none, but the door is open for an "evaluate now" UI affordance).

If neither path validates, the function returns `401` (missing/invalid token) or `403` (valid token but not a member of the requested household). Pre-C1 the function had no auth gate at all and trusted any caller with the anon key — exploitable to read budget preview text and pre-claim dedup keys for arbitrary households.

`CRON_SECRET` is optional in local development. When unset, only the user-JWT path is enabled.

## Invocation

User JWT path (e.g. from a signed-in client):

```bash
curl -i -X POST http://localhost:54421/functions/v1/send-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_JWT" \
  -d '{"household_id": "00000000-0000-0000-0000-000000000000"}'
```

Cron path (scheduled job — production):

```bash
curl -i -X POST https://<project>.functions.supabase.co/send-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CRON_SECRET" \
  -d '{"household_id": "<uuid>"}'
```

Response shape:

```json
{
  "household_id": "...",
  "evaluated": 3,
  "pending": 2,
  "sent": 1,
  "invalidated": 1,
  "preview": [{ "key": "...", "title": "...", "body": "..." }]
}
```

- `evaluated` — how many notifications the engine produced before dedup
- `pending` — how many keys we claimed in `notification_log` (and would
  push, if Firebase is configured)
- `sent` — successful FCM POSTs
- `invalidated` — tokens FCM said were dead (`NotRegistered` /
  `InvalidRegistration`) and that this pass removed from
  `device_push_tokens`
- `preview` — only present when `FIREBASE_SERVER_KEY` is unset; useful
  for verifying the engine without provisioned Firebase

## What's stubbed vs. live

The FCM HTTP call is gated on the `FIREBASE_SERVER_KEY` env var.

- **Unset** (default in local stack): the function evaluates triggers,
  logs the payload, returns `sent: 0` plus `preview`. Tests can assert
  on the evaluation without needing a real Firebase project.
- **Set**: POSTs each pending notification to
  `https://fcm.googleapis.com/fcm/send` per registered device token.

## Remaining work to take this to production

1. **Provision a Firebase project** outside this repo. The mobile app
   needs an `android/app/google-services.json` and the Edge Function
   needs the legacy server key.
2. **Set the secrets on the deployed function**:
   ```bash
   supabase secrets set FIREBASE_SERVER_KEY=<key>
   # CRON_SECRET gates the scheduled dispatcher path. Generate
   # something long and random; if unset, the cron path is
   # disabled and only user-JWT callers can dispatch.
   supabase secrets set CRON_SECRET=$(openssl rand -hex 32)
   ```
3. **Populate `device_push_tokens` from the client**. The table and
   repository exist (slice 1) but the registration call needs a real
   FCM token source — i.e., add the `firebase_messaging` package and
   call `FirebaseMessaging.instance.getToken()` to feed
   `DevicePushTokensRepository.upsertToken`.
4. **Deploy the function**:
   ```bash
   supabase functions deploy send-notification
   ```
5. **Schedule it**. Easiest path is pg_cron in a migration. The
   `Authorization` header carries `CRON_SECRET`, not the
   service-role key — the function won't accept the latter on
   this path. Store the secret via a separate `cron` extension
   setting so it isn't logged with the job:
   ```sql
   select cron.schedule(
     'send-notifications-daily',
     '0 18 * * *',
     $$
       select net.http_post(
         url := 'https://<project>.functions.supabase.co/send-notification',
         headers := jsonb_build_object(
           'Authorization', 'Bearer ' || current_setting('app.cron_secret'),
           'Content-Type', 'application/json'
         ),
         body := jsonb_build_object('household_id', h.id)
       )
       from households h;
     $$
   );
   ```

## Keeping the two engines in sync

The trigger logic in `index.ts` is a TypeScript port of
`evaluateNotifications` in
[notification_engine.dart](../../../mobile/lib/features/notifications/services/notification_engine.dart).
They MUST stay aligned — same `$1` budget-over floor, same 24-hour
`created_at` window for large transactions, same transfer-leg
exclusion, same dedup key namespacing. A drift here means a user sees
a push the in-app surface doesn't (or vice versa).

When changing trigger logic, change both files in the same commit.

## What this does NOT do (yet)

- **No transient-error retry.** A `RateLimit` / `InternalServerError`
  / `Unavailable` from FCM is logged-and-dropped, not queued for a
  later retry. The next scheduled invocation will re-evaluate and
  re-claim through `notification_log` — keys already pushed stay
  pushed, anything still pending gets another shot.
