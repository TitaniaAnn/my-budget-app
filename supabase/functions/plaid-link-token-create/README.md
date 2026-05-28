# `plaid-link-token-create`

Mints a short-lived [Plaid Link
token](https://plaid.com/docs/api/link/#linktokencreate) the mobile SDK uses
to open the Link UI.

## Invocation

```dart
final response = await Supabase.instance.client.functions.invoke(
  'plaid-link-token-create',
  body: const <String, dynamic>{},
);
// response.data = {
//   link_token: 'link-sandbox-...',
//   expiration: '2026-06-01T12:34:56Z',
//   environment: 'sandbox' | 'production',
// }
```

The user JWT in `Supabase.instance.client`'s default `Authorization`
header is what the function validates. Anonymous calls 401.

## What it does

1. Validates the user JWT (`requireAuthedUser` in
   [`_shared/plaid.ts`](../_shared/plaid.ts)).
2. POSTs to Plaid's `/link/token/create` with:
   - `client_user_id = auth.uid()` (Plaid's per-user identifier — keeping
     this stable across links lets a re-link of an existing item update the
     same Plaid User rather than creating a new one)
   - `products = ['transactions']`
   - `country_codes = ['US']`
   - `language = 'en'`
   - `webhook = PLAID_WEBHOOK_URL` (only when set — Phase 4)
3. Returns `link_token`, `expiration`, and the configured `environment` so
   the client can show "Sandbox" / "Production" in dev menus.

## Env

```
PLAID_CLIENT_ID=<from Plaid dashboard>
PLAID_SECRET=<sandbox or production secret matching PLAID_ENV>
PLAID_ENV=sandbox | production
PLAID_WEBHOOK_URL=<optional, Phase 4 only>
```

## What this is NOT

- It does not write to the database. Nothing about a Link session is
  persisted until the user completes Link and the public_token comes back
  to [`plaid-public-token-exchange`](../plaid-public-token-exchange/).
- It does not handle Link errors — those happen client-side and surface
  through the Plaid Flutter SDK's `onExit` callback.
