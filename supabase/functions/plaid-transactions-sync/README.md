# `plaid-transactions-sync`

Pulls `/transactions/sync` deltas from Plaid for one `plaid_items` row
and hands them to the `upsert_plaid_transactions` RPC (one call per
Plaid account in the delta).

## Invocation

```dart
final response = await Supabase.instance.client.functions.invoke(
  'plaid-transactions-sync',
  body: { 'plaid_item_id': internalPlaidItemUuid },
);
// response.data = {
//   added: number,
//   modified: number,
//   removed: number,
//   merged: number,             // dedup merges (migration 057)
//   accounts_synced: ['<uuid>', ...],
//   requires_reauth: bool,
//   error_code: 'ITEM_LOGIN_REQUIRED' | ... (only set on failure)
// }
```

`plaid_item_id` is the internal UUID (from `plaid_items.id`), NOT Plaid's
opaque `item_id` string. Pre-fix making this distinction would mean every
caller needed to remember the difference; the function rejects the body
shape if the wrong one is passed.

## What it does

1. Validates the user JWT.
2. Loads the `plaid_items` row via the service role (needed to read
   `access_token`, which the column-grant from migration 054 hides from
   client SELECT).
3. Verifies the caller's household matches the item's household via an
   RLS-scoped `household_members` query. A foreign item's
   `plaid_item_id` returns 403.
4. Loops `/transactions/sync` with the stored cursor until
   `has_more = false`. Hard upper bound of 50 pages × ~500 rows = 25k
   transactions per sync, which exceeds any realistic family-scale
   Item's full backfill.
5. Groups deltas by Plaid `account_id`, looks up the matching internal
   `accounts.id`, transforms (sign-flip + cents conversion via
   `plaidAmountToCents`, ISO currency map), and calls
   `upsert_plaid_transactions` ONCE per account with the user's JWT.
6. Persists the new cursor + `last_sync_at` back to `plaid_items`.

## Re-auth surfacing

When Plaid returns `ITEM_LOGIN_REQUIRED`, `PENDING_EXPIRATION`, or
`PENDING_DISCONNECT` (set unioned in `REAUTH_ERROR_CODES`), the function
writes `last_sync_error` and returns `requires_reauth: true`. The Phase 3
mobile orchestrator branches on this and pushes the user through Plaid
Link in update mode, which refreshes the `access_token` in place
(no new public_token exchange needed).

## What this is NOT

- It doesn't call `mapPlaidAccountType` — that's only for the public-
  token-exchange path (Item creation). Once accounts exist, sync just
  routes by `plaid_account_id`.
- It doesn't emit notifications — the existing `send-notification` flow
  evaluates the dashboard's rule set against whatever the ledger looks
  like, and that already includes anything sync just landed.

## Unofficial currency codes (crypto, etc.)

A Plaid transaction with `unofficial_currency_code` set and
`iso_currency_code` NULL is dropped + logged rather than coerced. The
multi-currency rollups (`get_category_spending` with `p_rates`) only
understand ISO 4217; silently mapping NXT → USD would wreck the
exclude-not-lie contract.
