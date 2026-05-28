# `plaid-public-token-exchange`

Exchanges Plaid Link's short-lived `public_token` for a long-lived
`access_token`, persists the `plaid_items` row + the user-selected
`accounts` rows, and returns the IDs so the mobile app can immediately
trigger the initial transactions sync.

## Invocation

```dart
final response = await Supabase.instance.client.functions.invoke(
  'plaid-public-token-exchange',
  body: {
    'publicToken': successResult.publicToken,
    'institution': {
      'id':   successResult.metadata.institution.id,
      'name': successResult.metadata.institution.name,
    },
    'accounts': successResult.metadata.accounts.map((a) => {
      'id':       a.id,
      'name':     a.name,
      'mask':     a.mask,
      'type':     a.type.name,
      'subtype':  a.subtype?.name,
      'currency': a.balances?.isoCurrencyCode,
    }).toList(),
  },
);
// response.data = {
//   plaid_item_id: '<internal uuid>',
//   institution: { id, name },
//   inserted_accounts: [
//     { account_id, plaid_account_id, account_type, name }, ...
//   ],
//   skipped_accounts: [
//     { plaid_account_id, name, plaid_type, plaid_subtype, reason }, ...
//   ],
// }
```

`skipped_accounts` is populated for any Plaid account whose `(type, subtype)`
doesn't map to one of this app's `account_type` enum values. The mobile UI
should surface these so the user can either map manually (Phase 3
follow-up) or accept the gap.

## What it does

1. Validates the user JWT.
2. Resolves the caller's `household_id` via `household_members`.
3. Calls Plaid `/item/public_token/exchange` → `{ access_token, item_id }`.
4. UPSERTs the `plaid_items` row (idempotent on `(household_id, plaid_item_id)`
   so a re-link refreshes the access_token in place).
5. UPSERTs one `accounts` row per Plaid account (idempotent on
   `(plaid_item_id, plaid_account_id)` per migration 055's partial unique
   index). Maps Plaid's `(type, subtype)` via
   [`mapPlaidAccountType`](../_shared/plaid.ts).
6. Returns the lists.

The `access_token` never enters the response. It lives only in the
`plaid_items` row, hidden from client SELECT by migration 054's
column-level grant.

## Env

Same as [`plaid-link-token-create`](../plaid-link-token-create/README.md).

## Idempotency

Re-running the exchange for the same `(household, plaid_item_id)` and the
same `(plaid_item_id, plaid_account_id)` set is safe — every write uses
UPSERT keyed on the appropriate uniqueness constraint. This means the
mobile app's "Connect bank" flow can retry on transient failure without
risking duplicated rows.

## Plaid → app account_type mapping

See the table in `mapPlaidAccountType` (`_shared/plaid.ts`). Unmapped
types land in `skipped_accounts` rather than being coerced to a default —
silently mapping an investment subtype to `brokerage` would distort the
asset-allocation rollup.
