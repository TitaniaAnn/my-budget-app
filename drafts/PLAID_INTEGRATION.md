# Plaid Integration — Implementation Spec

Target audience: Claude Code working in this repo. Read [CLAUDE.md](../CLAUDE.md) and [mobile/CLAUDE.md](../mobile/CLAUDE.md) before starting any phase below.

## Scope

Wire Plaid into the existing client-direct-to-Supabase architecture so a household can connect bank accounts, ingest transactions via `/transactions/sync`, and keep balances current. Sized for family-scale use (≤10 Items, Plaid Trial plan) — not multi-tenant SaaS.

The `'plaid'` value already exists on the `transaction_source` enum (see [001_initial_schema.sql](../supabase/migrations/001_initial_schema.sql)). Everything else is unwired.

In scope: Link, item lifecycle, `/transactions/sync`, balance refresh, re-auth (update mode), basic webhook handling.

Out of scope (call out if a user asks): Investments product, Liabilities product, Income, Identity, Auth (numbers for ACH), Signal, asset reports, statement-style historical pulls, any payment initiation. Pottery Studio domain is irrelevant here.

## Non-negotiable constraints inherited from the existing codebase

These are repeated from the root CLAUDE.md because spec drift here will cause real bugs. Re-verify before writing code:

- **Money is `INTEGER` cents.** Plaid returns floats in major units (USD as dollars). The conversion `(amount * 100).round()` is wrong in edge cases (floating-point: `19.99 * 100 = 1998.9999999999998`). Parse as string and split on `.`, or use `Decimal` server-side and `Decimal` → int conversion. Test with $19.99, $0.01, $1234.56.
- **Sign convention: negative = debit/outflow.** Confirmed at [`transactions.amount`](../supabase/migrations/001_initial_schema.sql) (`-- cents; negative = debit`) and at the `create_transfer` RPC (negative on source, positive on destination). Plaid's convention is the opposite: Plaid returns positive for outflows. **Flip the sign on import.**
- **`transactions.external_id` already exists with `UNIQUE (account_id, external_id)`.** Use it to store `plaid_transaction_id`. Do not introduce a parallel `plaid_transaction_id` column.
- **`transactions.currency CHAR(3)` already exists.** Map Plaid's `iso_currency_code` directly; for `unofficial_currency_code` (crypto, etc.) decide explicitly — recommended default is to drop the row and log, not to coerce.
- **Numbered migrations only.** Next number is **050** (current tip is 049). Never edit an existing migration. If you need to fix a prior migration's intent, add a new one named after the bug.
- **RLS via `household_members` join.** Every new user-data table needs an RLS policy that joins through `household_members`. Reference [`004_fix_household_members_rls.sql`](../supabase/migrations/004_fix_household_members_rls.sql) and [`023_fix_account_visibility_grants_rls_recursion.sql`](../supabase/migrations/023_fix_account_visibility_grants_rls_recursion.sql) if you hit recursion (error 42P17) — use `SECURITY DEFINER` helpers to break cycles.
- **Atomicity via SQL RPCs, not Dart loops.** The Plaid sync upsert is a multi-row mutation — it must be an RPC, not a per-row loop from the client. Follow the pattern in [`028_save_receipt_line_items_preserve_ids.sql`](../supabase/migrations/028_save_receipt_line_items_preserve_ids.sql) and [`030_transfers.sql`](../supabase/migrations/030_transfers.sql).
- **TIMESTAMPTZ writes use `.toUtc().toIso8601String()`.** Bare `.toIso8601String()` silently shifts by the host's offset (the bug fixed in `setUserCategory`). Applies to any timestamp the Edge Function writes from Dart-side input too — but Edge Functions in Deno use proper ISO-8601 by default; the trap is on the Dart client side.
- **Mobile app never touches Plaid secrets.** `PLAID_CLIENT_ID` and `PLAID_SECRET` live in Supabase Edge Function env vars only. The mobile client gets a short-lived `link_token` from an Edge Function and hands the `public_token` straight back to another Edge Function. The mobile app never sees an `access_token`. Ever.
- **Match the existing Dart enum convention.** New SQL enums are `snake_case`; their Dart counterparts use `@JsonValue('snake_case')`. Run `dart run build_runner build --delete-conflicting-outputs` in `mobile/` after any model change.

## Architectural decisions (with reasoning, so future-you can revisit)

### D1: Server-mediated, not client-direct

The mobile app talks to four Edge Functions (`plaid-link-token-create`, `plaid-public-token-exchange`, `plaid-transactions-sync`, `plaid-webhook`). The Plaid SDK runs in-app for the Link UI only — everything that requires the client secret happens server-side.

Why: Plaid `access_token`s are long-lived credentials to a user's bank. Embedding the Plaid client secret in the mobile binary, or letting the client call Plaid directly with an access_token, would mean every reverse-engineered build is a credential leak. The Edge Function tier is the natural trust boundary.

### D2: `/transactions/sync` (cursor-based), not `/transactions/get`

Plaid recommends `/transactions/sync` for new integrations. It returns `added`/`modified`/`removed` arrays plus a cursor, handles pending→posted transitions natively, and removes the need for date-window bookkeeping.

Why not `/transactions/get`: window math, dedup-by-date-range, and explicit pending tracking are all things `/transactions/sync` solves. No reason to inherit them.

### D3: Reuse `accounts` and `transactions`; add a thin `plaid_items` table

A `plaid_items` row carries `access_token`, `item_id`, institution metadata, and the per-item sync cursor. `accounts` gets a nullable `plaid_account_id TEXT` and a nullable `plaid_item_id UUID` pointing into `plaid_items`. `transactions` already has `external_id` for the Plaid transaction ID.

Why not a parallel `plaid_transactions` table: the rest of the app (dashboard, budgets, categorizer, recurring matcher) operates on `transactions`. A shadow table would require teaching every downstream surface a second source of truth. Reuse keeps the blast radius small.

Why nullable rather than a separate `linked_accounts` join table: an account is either manual or Plaid-backed. The 1:0..1 relationship doesn't justify a join table at this scale.

### D4: Plaid categories are a hint, not authoritative

Import with `category_id = NULL` and let the existing ML categorizer run on the next dashboard load (per the existing flow). Optionally store Plaid's category in `notes` or a new nullable `plaid_category TEXT` column on `transactions` (Phase 2 decision — recommend skipping unless you want the ML training pipeline to consider it as a feature).

Why: the project's categorizer + active-learning Review surface is the canonical category source. Letting Plaid pre-fill would dilute training signal (only `category_assigned_by = 'user'` rows are training-valid per migration 017) and create UI ambiguity about which category is authoritative.

### D5: Transfer pairing stays manual for now

Plaid will independently report both legs of an account-to-account move as separate transactions. The existing `transfer_id` column ([`030_transfers.sql`](../supabase/migrations/030_transfers.sql)) pairs them only via the `create_transfer` RPC. Plaid sync does **not** auto-pair.

Why: auto-pairing requires a heuristic (same household, opposite signs, near-equal amounts, ±2 day window, both Plaid-source) and false positives corrupt cash-flow rollups (which skip `transfer_id IS NOT NULL` rows). A "suggested pairing" UI is a follow-up; the spec defers it.

### D6: Webhooks are Phase 4 and optional

For family-scale use, sync-on-app-open is enough. Webhooks add real-time freshness but require a publicly reachable Edge Function URL and Plaid JWK signature verification. Phase 1–3 must not depend on webhooks existing.

## Phase 1 — Schema (Migrations 050–052)

Each migration ships in its own focused commit. Run `supabase db reset` after the full set and confirm the schema replays clean.

### Migration 050: `plaid_items` table + RLS

```sql
-- 050_plaid_items.sql

CREATE TYPE plaid_environment AS ENUM ('sandbox', 'development', 'production');

CREATE TABLE plaid_items (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id        UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  created_by          UUID NOT NULL REFERENCES auth.users(id),
  plaid_item_id       TEXT NOT NULL,
  plaid_institution_id TEXT,
  institution_name    TEXT,
  access_token        TEXT NOT NULL,             -- encrypted at rest via pgcrypto if available; otherwise plain (document trade-off)
  environment         plaid_environment NOT NULL,
  sync_cursor         TEXT,                       -- /transactions/sync cursor; NULL = initial pull pending
  last_sync_at        TIMESTAMPTZ,
  last_sync_error     TEXT,                       -- last error code if a sync failed; NULL on success
  consent_expires_at  TIMESTAMPTZ,                -- if Plaid surfaces a consent expiry, store it
  is_active           BOOLEAN NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (household_id, plaid_item_id)
);

ALTER TABLE plaid_items ENABLE ROW LEVEL SECURITY;

-- SELECT: any household member can see that an item exists, but the access_token
-- column should be redacted from client reads. The simplest enforcement is a view
-- that omits access_token; alternatively grant SELECT only on (id, household_id,
-- plaid_institution_id, institution_name, last_sync_at, last_sync_error, is_active).
CREATE POLICY plaid_items_select ON plaid_items FOR SELECT
  USING (household_id IN (
    SELECT hm.household_id FROM household_members hm WHERE hm.user_id = auth.uid()
  ));

-- INSERT/UPDATE/DELETE: restrict to the Edge Function service role only.
-- Clients must go through Edge Functions for all mutations.
-- (No client-facing INSERT/UPDATE/DELETE policy = denied by default.)
```

Trade-off to surface in the commit message: `access_token` stored as plain text relies on Postgres at-rest encryption and RLS. If you want belt-and-suspenders, wrap with `pgcrypto` + a secret stored in Supabase Vault; that's a follow-up migration. Don't gate Phase 1 on it.

### Migration 051: link `accounts` to Plaid

```sql
-- 051_accounts_plaid_link.sql

ALTER TABLE accounts
  ADD COLUMN plaid_item_id    UUID REFERENCES plaid_items(id) ON DELETE SET NULL,
  ADD COLUMN plaid_account_id TEXT;

CREATE UNIQUE INDEX accounts_plaid_account_id_unique
  ON accounts (plaid_item_id, plaid_account_id)
  WHERE plaid_account_id IS NOT NULL;
```

Why partial unique index: manual accounts have `plaid_account_id IS NULL`, and you don't want NULL-NULL collisions blocking inserts.

### Migration 052: atomic upsert RPC for Plaid sync

```sql
-- 052_upsert_plaid_transactions.sql

CREATE OR REPLACE FUNCTION upsert_plaid_transactions(
  p_account_id         UUID,
  p_added              JSONB,   -- [{plaid_transaction_id, amount_cents, currency, description, merchant, date, pending}, ...]
  p_modified           JSONB,   -- same shape as p_added
  p_removed_external_ids TEXT[] -- plaid_transaction_ids to delete
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_household_id UUID;
  v_added_count INT := 0;
  v_modified_count INT := 0;
  v_removed_count INT := 0;
BEGIN
  -- Authorize: caller must own a household_member row for this account's household.
  SELECT a.household_id INTO v_household_id
  FROM accounts a
  WHERE a.id = p_account_id
    AND a.household_id IN (
      SELECT hm.household_id FROM household_members hm WHERE hm.user_id = auth.uid()
    );
  IF v_household_id IS NULL THEN
    RAISE EXCEPTION 'account not found or not authorized' USING ERRCODE = '42501';
  END IF;

  -- Added: insert; on conflict by (account_id, external_id) skip (already there).
  WITH new_rows AS (
    SELECT
      p_account_id AS account_id,
      v_household_id AS household_id,
      (elem->>'amount_cents')::INT AS amount,
      COALESCE(elem->>'currency', 'USD') AS currency,
      elem->>'description' AS description,
      elem->>'merchant' AS merchant,
      (elem->>'date')::DATE AS transaction_date,
      COALESCE((elem->>'pending')::BOOLEAN, false) AS pending,
      elem->>'plaid_transaction_id' AS external_id
    FROM jsonb_array_elements(COALESCE(p_added, '[]'::jsonb)) AS elem
  )
  INSERT INTO transactions (
    household_id, account_id, amount, currency, description, merchant,
    transaction_date, pending, source, external_id
  )
  SELECT
    household_id, account_id, amount, currency, description, merchant,
    transaction_date, pending, 'plaid'::transaction_source, external_id
  FROM new_rows
  ON CONFLICT (account_id, external_id) DO NOTHING;
  GET DIAGNOSTICS v_added_count = ROW_COUNT;

  -- Modified: update in place by (account_id, external_id).
  -- Preserve user-set category_id, notes, receipt_id, transfer_id — these are user intent, not Plaid state.
  WITH mod_rows AS (
    SELECT
      elem->>'plaid_transaction_id' AS external_id,
      (elem->>'amount_cents')::INT AS amount,
      COALESCE(elem->>'currency', 'USD') AS currency,
      elem->>'description' AS description,
      elem->>'merchant' AS merchant,
      (elem->>'date')::DATE AS transaction_date,
      COALESCE((elem->>'pending')::BOOLEAN, false) AS pending
    FROM jsonb_array_elements(COALESCE(p_modified, '[]'::jsonb)) AS elem
  )
  UPDATE transactions t SET
    amount = m.amount,
    currency = m.currency,
    description = m.description,
    merchant = m.merchant,
    transaction_date = m.transaction_date,
    pending = m.pending,
    updated_at = now()
  FROM mod_rows m
  WHERE t.account_id = p_account_id
    AND t.external_id = m.external_id;
  GET DIAGNOSTICS v_modified_count = ROW_COUNT;

  -- Removed: only delete rows the user hasn't materially edited.
  -- Heuristic: receipt_id IS NULL AND notes IS NULL AND transfer_id IS NULL AND category_assigned_by IS NULL (or = 'ml').
  -- A row the user touched is preserved; surface via UI as "Plaid says this no longer exists, keep or delete?".
  -- For Phase 1, just delete unconditionally and document the caveat.
  DELETE FROM transactions
  WHERE account_id = p_account_id
    AND external_id = ANY(p_removed_external_ids);
  GET DIAGNOSTICS v_removed_count = ROW_COUNT;

  -- Recalculate account balance via the existing function from migration 015.
  PERFORM recalculate_account_balance(p_account_id);

  RETURN jsonb_build_object(
    'added', v_added_count,
    'modified', v_modified_count,
    'removed', v_removed_count
  );
END;
$$;

-- Caller-as-user grant (no SECURITY DEFINER) so RLS applies to all writes.
GRANT EXECUTE ON FUNCTION upsert_plaid_transactions(UUID, JSONB, JSONB, TEXT[]) TO authenticated;
```

The Edge Function will invoke this with the user's JWT, so RLS still applies. Verify by reading the pattern in [`029_category_spending_dedupe_line_items.sql`](../supabase/migrations/029_category_spending_dedupe_line_items.sql) and [`030_transfers.sql`](../supabase/migrations/030_transfers.sql).

### Phase 1 test gate

Add an integration test under [`mobile/test/integration/`](../mobile/test/integration/) that:

1. Creates an account with the harness.
2. Calls `upsert_plaid_transactions` directly via `supabase.rpc(...)` with synthetic added/modified/removed payloads.
3. Asserts the row counts and that `recalculate_account_balance` updated `accounts.current_balance`.
4. Confirms a foreign household_member cannot invoke the RPC against another household's account (RLS check).

## Phase 2 — Edge Functions

Three functions under `supabase/functions/`. Each is a focused commit. Pattern to follow: [`supabase/functions/send-notification/`](../supabase/functions/send-notification/) (service-role auth, `Deno.env.get`, JSON in/out).

### Required env vars (set via `supabase secrets set ...`)

```
PLAID_CLIENT_ID=<from Plaid dashboard>
PLAID_SECRET=<from Plaid dashboard — separate per environment>
PLAID_ENV=sandbox | development | production
PLAID_WEBHOOK_URL=<your-project-ref>.supabase.co/functions/v1/plaid-webhook   # Phase 4 only
```

Use [`plaid-node`](https://github.com/plaid/plaid-node) via Deno's npm interop (`import { PlaidApi } from 'npm:plaid@latest'`), or hand-roll HTTPS calls — either is fine, npm interop is fewer lines.

### `plaid-link-token-create`

POST body: `{ accountFilters?: { ... } }` (passthrough to Plaid).
Server-side: looks up the caller's `user_id` and `household_id` from the JWT, calls `/link/token/create` with `client_user_id = user_id`, `products: ['transactions']`, `country_codes: ['US']`, `language: 'en'`, `webhook: PLAID_WEBHOOK_URL` (if set).
Returns: `{ link_token, expiration }`.

### `plaid-public-token-exchange`

POST body: `{ public_token, institution: { id, name }, accounts: [{ id, name, mask, type, subtype }] }` (whatever the Link `onSuccess` callback returned).
Server-side:
1. POST `/item/public_token/exchange` with `public_token` → `{ access_token, item_id }`.
2. Insert into `plaid_items` (one row per item) using service-role client (bypasses the no-INSERT-from-client policy).
3. For each account in the payload, create a corresponding `accounts` row in the user's household with `plaid_item_id`, `plaid_account_id`, `account_type` mapped from Plaid's `(type, subtype)` to your `account_type` enum (see mapping table below), `name` from Plaid, `last_four` from `mask`, `currency` from the account's `balances.iso_currency_code`. Alternatively, return the account list to the client and let the user choose which to import and which to map to an existing manual account — recommended for family use where some accounts may already exist as manual.
4. Kick off an initial `/transactions/sync` (cursor=null) — either inline or by enqueuing.

Plaid → my-budget account_type mapping:

| Plaid type/subtype                | my-budget `account_type`     |
|-----------------------------------|------------------------------|
| `depository/checking`             | `checking`                   |
| `depository/savings`              | `savings`                    |
| `depository/cash management`      | `cash`                       |
| `credit/credit card`              | `credit_card`                |
| `investment/ira`                  | `ira_traditional`            |
| `investment/roth`                 | `ira_roth`                   |
| `investment/401k`                 | `retirement_401k`            |
| `investment/403b`                 | `retirement_403b`            |
| `investment/hsa`                  | `hsa`                        |
| `investment/529`                  | `college_529`                |
| `investment/brokerage` (+ others) | `brokerage`                  |
| anything else                     | reject — surface in UI for manual choice |

### `plaid-transactions-sync`

POST body: `{ plaid_item_id: UUID }` (the internal id, not Plaid's).
Server-side:
1. Load the `plaid_items` row using service-role client. Confirm `household_id` matches the caller's household (auth check using the JWT — do NOT trust the body's item id alone).
2. Loop calling `/transactions/sync` with `{ access_token, cursor }` until `has_more: false`. Aggregate `added`, `modified`, `removed`.
3. For each Plaid account_id present in the deltas, look up the corresponding internal `accounts.id`, transform the Plaid transaction shape into the RPC's JSONB shape (sign flip, cents conversion, currency map), and call `upsert_plaid_transactions` once per account.
4. Update `plaid_items.sync_cursor = new_cursor`, `last_sync_at = now()`, clear `last_sync_error`.
5. On Plaid error: store `last_sync_error = error.error_code`. If `ITEM_LOGIN_REQUIRED`, the response should signal the client to launch Link in update mode.

Return: `{ added: N, modified: N, removed: N, accounts_synced: [...], requires_reauth: bool }`.

### Cents conversion gotcha (write this as a pure function and unit-test it)

```typescript
// Convert Plaid's "amount" (positive=outflow, float dollars) to my-budget convention (negative=outflow, int cents).
function plaidAmountToCents(plaidAmount: number): number {
  // Parse via string to avoid floating-point drift.
  const str = plaidAmount.toFixed(2);
  const [whole, frac] = str.split('.');
  const cents = parseInt(whole, 10) * 100 + parseInt(frac, 10) * (whole.startsWith('-') ? -1 : 1);
  return -cents; // sign flip
}
```

Tests: `19.99 → -1999`, `-19.99 → 1999`, `0.01 → -1`, `1234.56 → -123456`, `0 → 0`.

## Phase 3 — Flutter integration

### Package

Add [`plaid_flutter`](https://pub.dev/packages/plaid_flutter) to `mobile/pubspec.yaml`. Verify the version's API surface before referencing symbols — per CLAUDE.md, "inspect the installed package source to confirm the actual API surface."

iOS needs the `LSApplicationQueriesSchemes` plist entry per Plaid docs; Android needs an intent filter. Do those at the same time you add the package.

### Feature directory layout

```
mobile/lib/features/plaid/
  models/
    plaid_item.dart            # freezed model mirroring plaid_items row (client-visible columns only)
    plaid_link_session.dart    # ephemeral state during a Link flow
  repositories/
    plaid_repository.dart      # calls the three Edge Functions; never sees access_token
  services/
    plaid_link_launcher.dart   # wraps plaid_flutter, owns onSuccess/onExit
    plaid_sync_orchestrator.dart # triggers sync, then triggers categorizer over new rows
  providers/
    plaid_items_provider.dart  # Riverpod stream over plaid_items rows for this household
  ui/
    connect_bank_screen.dart
    plaid_items_list.dart
    reauth_prompt.dart
```

### Repository surface

```dart
abstract class PlaidRepository {
  Future<String> createLinkToken();                  // -> link_token
  Future<List<PlaidItem>> exchangePublicToken({
    required String publicToken,
    required PlaidInstitution institution,
    required List<PlaidLinkAccount> accounts,
  });
  Future<PlaidSyncResult> sync(String plaidItemId);  // -> {added, modified, removed, requiresReauth}
  Future<String> createUpdateLinkToken(String plaidItemId); // for re-auth
}
```

All methods call Edge Functions via `Supabase.instance.client.functions.invoke(...)`. None of them call Plaid directly. None of them touch `access_token`.

### Sync orchestration

`PlaidSyncOrchestrator.syncAll()`:

1. Read active `plaid_items` rows for the household.
2. For each, call `plaid-transactions-sync`.
3. After sync completes, trigger the ML categorizer over any rows where `category_id IS NULL AND source = 'plaid' AND created_at >= sync_start`. The categorizer's existing flow handles this; just make sure it's wired into the post-sync callback.
4. Surface re-auth prompts for any item returning `requires_reauth: true`.

When to fire: on dashboard load (similar to `runRecurringSchedulerProvider`), gated by "not run in the last N minutes" — `keepAlive` provider so an app session doesn't hammer Plaid. Pull-to-refresh on the dashboard forces a sync regardless.

### Re-auth flow

When `requires_reauth: true` (Plaid `ITEM_LOGIN_REQUIRED` or `PENDING_EXPIRATION`):

1. `ReauthPrompt` widget surfaces in the dashboard with item + institution name.
2. User taps "Reconnect" → `PlaidRepository.createUpdateLinkToken(plaidItemId)` → launches `plaid_flutter` Link in update mode with the returned token.
3. On `onSuccess`, no public_token exchange is needed (update mode reuses the existing access_token); just call sync again.

### Dashboard wiring

The dashboard already reads `transactions` and `accounts` directly. Once Phase 1 + 2 are working, Plaid-sourced rows show up automatically with no dashboard changes. The only dashboard-side work is adding the sync-on-load trigger (above) and the re-auth banner.

## Phase 4 — Webhooks (optional, can ship later)

### Migration 053: `plaid_webhook_events`

```sql
-- 053_plaid_webhook_events.sql

CREATE TABLE plaid_webhook_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plaid_item_id UUID REFERENCES plaid_items(id) ON DELETE CASCADE,
  webhook_type  TEXT NOT NULL,
  webhook_code  TEXT NOT NULL,
  payload       JSONB NOT NULL,
  processed_at  TIMESTAMPTZ,
  received_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- No client-facing RLS policy needed; this is service-role only.
ALTER TABLE plaid_webhook_events ENABLE ROW LEVEL SECURITY;
```

### `plaid-webhook` Edge Function

1. Verify the JWT in the `Plaid-Verification` header against Plaid's JWKs (`/webhook_verification_key/get`). This is the security boundary — without verification anyone can forge a sync trigger.
2. Decode payload. Insert into `plaid_webhook_events`.
3. Route on `(webhook_type, webhook_code)`:
   - `TRANSACTIONS / SYNC_UPDATES_AVAILABLE` → invoke `plaid-transactions-sync` for the item.
   - `ITEM / ERROR` with `ITEM_LOGIN_REQUIRED` → set `plaid_items.last_sync_error`, surface re-auth state.
   - `ITEM / PENDING_EXPIRATION` → same.
   - everything else → log + ignore for v1.
4. Mark `processed_at`.

### `pg_cron` fallback

Plaid's webhook reliability is good but not guaranteed. Add a cron job (or Supabase scheduled function) that fires `plaid-transactions-sync` for every active item once a day as a safety net. Same pattern as the recurring scheduler in [`032_recurring_scheduler.sql`](../supabase/migrations/032_recurring_scheduler.sql).

## Configuration

### Plaid dashboard setup (out of repo)

1. Create a Plaid account; pick the **Trial** plan (free, 10-item cap, real production data — available for accounts created on or after April 15, 2026).
2. Enable products: **Transactions**. Skip Auth, Identity, Liabilities, Investments unless you decide to add them later.
3. Note your `client_id`, `sandbox_secret`, and (when you move beyond sandbox) `production_secret`.
4. Add your webhook URL once Phase 4 ships.

### Local dev

Add to `mobile/.env.json`:

```json
{
  "PLAID_ENV": "sandbox"
}
```

`PLAID_CLIENT_ID` and `PLAID_SECRET` go in Supabase Edge Function env, never in the mobile binary. For local Edge Function dev:

```bash
supabase secrets set PLAID_CLIENT_ID=... PLAID_SECRET=... PLAID_ENV=sandbox --env-file <path>
```

Or use `.env.local` per the Supabase docs and `supabase functions serve --env-file .env.local`.

### Sandbox test credentials

Plaid sandbox: username `user_good`, password `pass_good`, any MFA code `1234`. Returns a deterministic synthetic dataset suitable for the integration test below.

## Testing

### Unit tests (Edge Function)

Pure-function tests for `plaidAmountToCents` (cases above) and the Plaid-account-type → my-budget-account_type mapper. Deno test runner; live alongside each function.

### Integration tests (Dart)

Under `mobile/test/integration/`, harness already exists per [`_supabase_harness.dart`](../mobile/test/integration/_supabase_harness.dart). Two new files:

1. `plaid_rpc_test.dart` — tests `upsert_plaid_transactions` directly (Phase 1 gate above).
2. `plaid_sync_e2e_test.dart` — gated on `PLAID_SANDBOX_AVAILABLE=1`. Spins up a sandbox Item, runs the full Link → exchange → sync flow against deployed local Edge Functions, asserts transactions land in the DB with correct sign and cents.

The sandbox e2e test will not run in CI without Plaid sandbox creds. Mark it `@Tags(['plaid-sandbox'])` and document the opt-in in the existing CI workflow comment block (don't add it to `flutter test` default invocations).

### Parity check with the categorizer

After Phase 3 ships, run the existing categorizer test suite ([`mobile/test/features/transactions/ml_category_classifier_test.dart`](../mobile/test/features/transactions/ml_category_classifier_test.dart)). Plaid-imported descriptions should categorize at the same accuracy as manually entered ones — the model's input shape (`<description>|<merchant>|<sign>|<amt_bucket>|<account_type>`) is source-agnostic, but worth confirming the merchant field comes through cleanly from Plaid's `merchant_name` (and not the raw `name` which is often noisier).

## Known caveats — surface in PRs, not as bugs

1. **First-Item access_token leak surface.** If anyone gets read access to `plaid_items` they get the user's bank credentials in effect. RLS prevents client SELECT of `access_token`, but a leaked service-role key = total compromise. Document in the Phase 1 PR; consider Vault-wrapping in a follow-up.
2. **Removed-transaction policy is destructive in Phase 1.** A user-edited transaction that Plaid later removes will be deleted along with the user's edits. The mitigation (preserve rows with user state, surface a reconciliation UI) is deferred. Note this in the user-facing release notes.
3. **No auto-pairing of Plaid-imported transfers.** Cash-flow rollups will count both legs as income/expense until the user manually pairs them via the existing transfer creation UI. Acceptable for v1; the suggested-pairing feature is a separate spec.
4. **Multi-currency assumption.** The Edge Function maps `iso_currency_code` directly. If a Plaid account returns `unofficial_currency_code` (rare; some crypto), the row should be dropped with a logged warning, not coerced to `USD`. Confirm the Edge Function takes this branch explicitly.
5. **Pending → posted as separate rows.** `/transactions/sync` will deliver the pending row as `added`, then later deliver the posted row as `added` with a new `transaction_id` and the pending row as `removed`. The cents and date may differ slightly (final settled amount, posting date). The upsert handles this via add/remove sequencing, but a budget alert that fires off the pending amount will not re-fire off the corrected posted amount — verify the notification engine's dedup key behavior here.
6. **Webhook signature verification (Phase 4) is not optional.** Without JWK verification, anyone with the function URL can trigger syncs and inject `plaid_webhook_events` rows. Don't ship `plaid-webhook` without it.

## Suggested commit sequence

```
chore(plaid): add 050_plaid_items migration + RLS
chore(plaid): add 051_accounts_plaid_link migration
chore(plaid): add 052_upsert_plaid_transactions RPC + integration test
chore(plaid): scaffold plaid-link-token-create edge function
chore(plaid): scaffold plaid-public-token-exchange edge function + account mapping
chore(plaid): scaffold plaid-transactions-sync edge function + cents conversion tests
feat(plaid): add PlaidRepository + Edge Function client calls
feat(plaid): add PlaidLinkLauncher + connect-bank UI
feat(plaid): wire sync orchestrator into dashboard load + re-auth prompt
docs(plaid): add user-facing how-to for connecting a bank
# Phase 4 (later, separate PR):
chore(plaid): add 053_plaid_webhook_events migration
feat(plaid): add plaid-webhook edge function with JWK verification
chore(plaid): add daily pg_cron fallback sync
```

Each commit lands with passing tests and clean `dart format` / `flutter analyze`. Per CLAUDE.md: focused single-purpose commits, no WIP needing `git reset --soft` reorganization, secret scan before push.

## When you get stuck

- **RLS recursion error 42P17:** see [023_fix_account_visibility_grants_rls_recursion.sql](../supabase/migrations/023_fix_account_visibility_grants_rls_recursion.sql). The Plaid path most likely to hit this is if you teach `accounts.SELECT` to consult `plaid_items` — avoid that, the FK direction is already accounts → plaid_items so the policy can stay account-scoped.
- **TIMESTAMPTZ drift:** the Edge Function side doesn't have the Dart bug because Deno's `Date.toISOString()` emits Z-suffixed UTC. But if you ever take a timestamp from the mobile client and write it through, `.toUtc().toIso8601String()` on the Dart side first.
- **`build_runner` not regenerating freezed/json files:** `dart run build_runner build --delete-conflicting-outputs` in `mobile/`. Skipping this after model changes produces "missing concrete implementation" errors that look like real bugs but aren't.
- **Sandbox returns transactions but `upsert_plaid_transactions` returns 0/0/0:** check sign convention and JSONB shape first. The RPC expects `amount_cents` already in int cents with sign already flipped — if you pass raw Plaid amounts the conflict-on-external_id may silently no-op the second sync.

## What I'm asking Claude Code to do, ordered

1. Phase 1 (migrations 050, 051, 052) + the Phase 1 integration test. Stop. Confirm with user.
2. Phase 2 (three Edge Functions) + Edge-Function-level unit tests for the pure transforms. Stop. Confirm with user.
3. Phase 3 (Flutter feature dir) + the end-to-end sandbox test gated on env. Stop. Confirm with user.
4. Phase 4 (webhooks) only after user explicitly asks for it.

Do not collapse phases. Do not ship Phase 2 without Phase 1 merged. Do not begin Phase 3 without sandbox-tested Phase 2.
