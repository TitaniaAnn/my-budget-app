# send-notification

Server-side notification dispatcher. Evaluates the same triggers the
Flutter client evaluates locally ([notification_engine.dart](../../../mobile/lib/features/notifications/services/notification_engine.dart))
and POSTs to FCM for any pending notifications keyed off the
`device_push_tokens` table (migration 033).

The point of this function is the "app is closed" path: when the
client isn't running, a scheduler invokes this once per household and
the user still gets the alert.

## Invocation

```bash
curl -i -X POST http://localhost:54421/functions/v1/send-notification \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -d '{"household_id": "00000000-0000-0000-0000-000000000000"}'
```

Response shape:

```json
{
  "household_id": "...",
  "pending": 2,
  "sent": 0,
  "preview": [{ "key": "...", "title": "...", "body": "..." }]
}
```

`preview` is only present when `FIREBASE_SERVER_KEY` is unset — useful
for verifying the engine without provisioned Firebase.

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
2. **Set the secret on the deployed function**:
   ```bash
   supabase secrets set FIREBASE_SERVER_KEY=<key>
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
5. **Schedule it**. Easiest path is pg_cron in a migration:
   ```sql
   select cron.schedule(
     'send-notifications-daily',
     '0 18 * * *',
     $$
       select net.http_post(
         url := 'https://<project>.functions.supabase.co/send-notification',
         headers := jsonb_build_object(
           'Authorization', 'Bearer ' || current_setting('app.service_role_key'),
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

- **No server-side dedup.** The client's `lastFiredByKey` map lives in
  SharedPreferences; the function doesn't read it. A user who's online
  could see the same alert twice (in-app + push). A later slice can
  add a `notification_log` table keyed by `(household_id, key)`.
- **No token-invalidation pruning.** If FCM returns an error indicating
  a token is stale, this function ignores it. A retry/cleanup pass is
  a follow-up.
- **No multi-currency cap conversion server-side.** The function reads
  `budgets.amount` directly as if denominated in the display currency.
  The Dart engine compares against `capCents` (= FX-converted). For
  the budget-over alert to be correct under multi-currency, this
  function needs the same household-info + fx_rates fetch the Dart
  side does (slice 3 of the multi-currency arc).
