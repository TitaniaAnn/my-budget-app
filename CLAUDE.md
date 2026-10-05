# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Layout

This is a three-component project: a Flutter client, its Supabase backend, and an offline ML training pipeline.

- [mobile/](mobile/) — Flutter app (the only client). Has its own [CLAUDE.md](mobile/CLAUDE.md) covering Flutter commands, Riverpod conventions, and money/enum rules. **Read it before editing any Dart code.**
- [supabase/](supabase/) — Backend definition: `config.toml` for the local stack and `migrations/*.sql` as the source of truth for the schema, RLS policies, and seed data.
- [tools/categorizer/](tools/categorizer/) — Python pipeline that trains the on-device transaction categorizer (sklearn TF-IDF + LogisticRegression → ONNX). Outputs land in `mobile/assets/ml/` and are loaded at runtime by `MlCategoryClassifier`. See its [README](tools/categorizer/README.md) for the retrain workflow.

There is no separate web app, server, or ORM. The Flutter client talks to Supabase directly via `supabase_flutter`; all server-side logic lives in SQL (RLS policies, triggers, functions).

## Backend (Supabase)

The DB schema is defined entirely by the numbered migration files in [supabase/migrations/](supabase/migrations/). To change the schema, **add a new numbered migration**; never edit an existing one. The next number after the current tip wins.

### Local test stack

```bash
supabase start          # spins up DB, auth, storage, studio + serves Edge Functions
supabase status         # shows URLs / keys / ports for the running stack
supabase stop           # tears it all down
supabase db reset       # drops local DB and replays all migrations
supabase migration new <name>   # scaffold the next migration
```

Ports are shifted +100 from CLI defaults (API 54421, DB 54422, Studio 54423, Inbucket 54424) so this stack can coexist with another local Supabase project on the same machine. After `supabase start`, point `mobile/.env.json` at the local stack:

```json
{
  "SUPABASE_URL": "http://localhost:54421",
  "SUPABASE_ANON_KEY": "<anon key from `supabase status`>"
}
```

The OCR Edge Function stub at [`supabase/functions/process-receipt-ocr/`](supabase/functions/process-receipt-ocr/) is auto-served at `http://localhost:54421/functions/v1/process-receipt-ocr`. It mirrors the production function's output shape (advances `ocr_status: pending → complete`, writes line items via the `save_receipt_line_items` RPC, populates `ocr_raw`) but generates synthetic line items instead of calling Cloud Vision. See its [README](supabase/functions/process-receipt-ocr/README.md) for invocation details.

Schema invariants worth knowing before writing migrations or queries:
- All money columns are `INTEGER` cents. Never introduce `numeric`/`float` for money.
- Probability-shaped values (e.g. `ml_model_confidence`) are stored as INTEGER basis points (0–10000) for the same reason — see migration 022.
- Every user-data table is scoped by `household_id` and protected by RLS. New tables must add an RLS policy that joins through `household_members` — otherwise the client will see nothing (or, worse, see other households' rows).
- Enum types in Postgres are `snake_case`. Dart enums map to them via `@JsonValue('snake_case')`; if you add a new enum variant in SQL, add the matching `@JsonValue` in the corresponding Dart model. The `asset_class` enum on [`holdings`](supabase/migrations/027_holdings.sql) (`us_equity`, `intl_equity`, `bond`, `real_estate`, `cash`, `crypto`, `other`) is the most recent example.
- Storage buckets (e.g. receipts) are configured in migrations, not in the Supabase dashboard.
- **TIMESTAMPTZ writes use `.toUtc().toIso8601String()`.** A bare `DateTime.now().toIso8601String()` produces a timezone-naive string that Postgres interprets as UTC, silently shifting the stored time by the host's offset. Repository methods that touch `category_assigned_at`, `created_at`-style columns, etc. must `.toUtc()` first.
- **Budget spending = Option B rollup.** [`get_category_spending`](supabase/migrations/029_category_spending_dedupe_line_items.sql) treats `transactions.category_id` as filing-only when the transaction has a receipt attached: line items dictate which category the spend hits (with `is_discount` flipping the sign). Unpaired transactions still aggregate directly. A paired transaction whose receipt has zero line items contributes nothing to budgets — that's a documented caveat, not a bug. Migration 029 also gates line items through an `EXISTS` subquery so a receipt backing multiple transactions (installments, split bills) only contributes its line-item total once.
- **Transfers are two paired transaction rows, not one.** Migration 030 added a nullable `transfer_id UUID` column on `transactions`; both legs of an account-to-account movement (negative on source, positive on destination) share the same id. The blessed write path is the `create_transfer` RPC — Dart code must never insert the legs separately. Dashboard income/expense math and `SubscriptionDriftRule` skip rows with `transfer_id IS NOT NULL` so transfers don't pollute cash-flow rollups. Deletion is one round-trip too: `TransactionsRepository.deleteTransfer` uses PostgREST's delete-returning form to atomically remove both legs and report the affected account ids.
- **Recurring transactions are rules, not pre-materialised rows.** Migration 031 added `recurring_transactions` (signed `amount_cents`, `cadence` enum [weekly/biweekly/monthly/quarterly/annual], `next_occurrence_date`, `skipped_until_date`, `is_active`, CHECK that rejects amount=0). Migration 032 adds `'recurring'` to the `transaction_source` enum and the `run_recurring_scheduler` RPC, which materialises each due rule into one `transactions` row per missed cycle (multi-cycle catchup is intentional) and advances `next_occurrence_date`. `runRecurringSchedulerProvider` (keepAlive) fires once per app process before `dashboardDataProvider` reads transactions, so the user never sees stale data on the cycle a rule emits. The bulk-import flow runs `matchRecurringDuplicates` against scheduler emissions from the last 14 days (exact amount, ±1 day, claim-once) and batch-deletes matches before the upsert so a Spotify rule + Spotify bank charge doesn't leave two near-duplicates on the ledger.

**Atomicity via RPC, not Dart loops.** Whenever a write would otherwise be "read X → mutate → write back" or "delete then insert," factor it into a SQL function and call it via `supabase.rpc(...)`. Migrations [`015`](supabase/migrations/015_recalculate_balance_function.sql) (account balance recalc), [`028`](supabase/migrations/028_save_receipt_line_items_preserve_ids.sql) (atomic replace of receipt line items — preserves IDs of rows that survive the edit so FKs from `receipt_line_item_tag_assignments` aren't cascade-deleted; supersedes the destroy-and-reinsert pattern from migration 018), [`029`](supabase/migrations/029_category_spending_dedupe_line_items.sql) (Option B spending aggregation, dedupe-safe across multi-paired receipts; supersedes 021 and 026), [`030`](supabase/migrations/030_transfers.sql) (paired-leg transfer insert, raises on same-account / non-positive amounts), and [`032`](supabase/migrations/032_recurring_scheduler.sql) (recurring scheduler — emits per missed cycle, honors `skipped_until_date`) all follow this pattern. Run them as the caller (no `SECURITY DEFINER`) so RLS still applies.

**Recursive RLS — break the loop with `SECURITY DEFINER` helpers.** When two tables' RLS policies reference each other (e.g. `accounts.SELECT` queries `account_visibility_grants`, whose own policy queries `accounts`), Postgres detects the cycle and aborts with error 42P17. Pattern fix: a small `SECURITY DEFINER` SQL function that resolves the relationship without re-entering the user's RLS path. Examples: [`get_household_role`](supabase/migrations/001_initial_schema.sql) (referenced from many policies), [`004`](supabase/migrations/004_fix_household_members_rls.sql) (self-referencing household_members policy), [`023`](supabase/migrations/023_fix_account_visibility_grants_rls_recursion.sql) (`account_household_id` helper for the grants ↔ accounts cycle).

## Cross-cutting changes

A change that touches both layers (new field, new table, new enum variant) almost always needs all of:
1. A new migration in `supabase/migrations/`.
2. The Dart model in `mobile/lib/features/<feature>/models/` updated.
3. `dart run build_runner build --delete-conflicting-outputs` rerun in `mobile/` to regenerate `*.freezed.dart` / `*.g.dart`.
4. The repository class in `mobile/lib/features/<feature>/repositories/` updated to read/write the new column.

Skipping step 3 produces confusing build errors that look like model bugs.

## ML categorizer (cross-component)

Transaction categorization spans all three components. The current model is a `CalibratedClassifierCV(LogisticRegression, method='sigmoid', cv=min(5, smallest_class), ensemble=False)` over a `char_wb` TF-IDF (3–5 ngrams, ≤10K features), exported to ONNX. Calibrated probabilities matter because both the per-class thresholds and the active-learning uncertain band treat confidence as a true probability — uncalibrated LR overstates extremes.

The model sees the input string `<description>|<merchant>|<sign>|<amt_bucket>|<account_type>` (`render()` in [train.py](tools/categorizer/train.py); mirrored byte-for-byte in `_renderInput` on the Dart side). Buckets: `xs <$10 < s < $50 < m < $200 < l < $1000 < xl`. Account type is the snake_case Postgres enum or empty string when unknown.

Per-class auto-apply thresholds are learned at training time and shipped in `assets/ml/thresholds.json`. The Dart `Categorizer.categorize` consults `MlCategoryClassifier.thresholdFor(name, defaultThreshold:)` per prediction; falls back to a global default when the file is absent or the predicted class isn't in the map.

A change to the model's input shape or label space typically needs:
1. The Python training script in [tools/categorizer/](tools/categorizer/) updated and rerun (`python train.py ...`).
2. New `*.onnx` / `*.json` artifacts copied into `mobile/assets/ml/`.
3. The Dart-side TF-IDF transform AND `_renderInput` in [`ml_category_classifier.dart`](mobile/lib/features/transactions/services/ml_category_classifier.dart) kept byte-for-byte compatible with sklearn — the parity test in [`ml_category_classifier_test.dart`](mobile/test/features/transactions/ml_category_classifier_test.dart) will fail otherwise. Note: this test auto-skips when `assets/ml/` is empty, so a green local run on a fresh clone does **not** mean the parity invariant holds. The categorizer GitHub Actions workflow builds the fixture from scratch and runs the parity test on every push that touches `tools/categorizer/**`.
4. Only `category_assigned_by = 'user'` rows are valid training data (see migration `017`). Predictions made by the model itself must never be fed back in. The active-learning Review surface (Settings → "Review uncertain ML guesses") is how user confirmations become training data — confirming a row flips `category_assigned_by` to `'user'` and clears `ml_model_confidence`.

## Auth deep link

Supabase auth callbacks redirect to `mybudget://auth/callback` (see `supabase/config.toml`). The Android intent filter for this scheme lives in `mobile/android/app/src/main/AndroidManifest.xml` — keep them in sync if either changes.

## Local notifications

Budget-over and large-transaction alerts fire client-side from the dashboard load. The server-side dispatcher (Edge Function `send-notification`) exists for the "app is closed" path, but real push delivery is still blocked on out-of-repo Firebase provisioning — see the **Push (FCM/APNS)** section below. The local-notifications engine has three layers, all under [`mobile/lib/features/notifications/`](mobile/lib/features/notifications/):

- **Pure trigger logic.** [`evaluateNotifications`](mobile/lib/features/notifications/services/notification_engine.dart) takes settings + budgets + recent transactions + the last-fired dedup map + `now` and returns a list of `PendingNotification`s. Pure function, unit-testable. Dedup keys are namespaced (`budget_over:<id>:<period_from>`, `large_tx:<tx_id>`) so the same kind of event in a new period or on a new row fires again. The budget trigger has a $1 noise-floor and the large-tx trigger has a 24-hour `created_at` gate so a fresh install doesn't dump months of historical alerts on first dashboard load.
- **State persistence.** [`notification_settings_provider.dart`](mobile/lib/features/notifications/providers/notification_settings_provider.dart) holds toggles + threshold in SharedPreferences and exposes `loadLastFired` / `recordFired` helpers for the dedup map. `recordFired` prunes anything older than 90 days so the JSON blob doesn't grow unbounded.
- **Platform wrapper.** [`NotificationService`](mobile/lib/features/notifications/services/notification_service.dart) is the thin layer over `flutter_local_notifications` — idempotent `ensureInitialized`, explicit `requestPermission` driven by the settings toggle (not by `initialize`, so the OS prompt lands at a moment the user expects). Notification id is `tag.hashCode` so a same-tag re-fire updates in place.

Wiring: `dashboardDataProvider` does `ref.read(runNotificationsProvider.future)` (fire-and-forget) AFTER the recurring scheduler resolves, so today's emissions can be their own trigger. The runner provider is `keepAlive` so subsequent dashboard loads in the same app process don't re-evaluate the engine unless the inputs change.

When adding a new trigger: extend `NotificationSettings` with a toggle, add a branch in `evaluateNotifications` that produces a `PendingNotification` with a fresh key namespace, write unit tests covering enabled / disabled / dedup / freshness. The platform service, settings screen, and dedup map don't need changes — they're already trigger-agnostic.

**Multi-currency.** Migration 036 adds `households.display_currency CHAR(3) DEFAULT 'USD'` and an `fx_rates` table (composite PK on `(household_id, from_currency, to_currency, as_of_date)`, rate as `NUMERIC(18,8)`, CHECK rejects `rate <= 0` and `from == to`). [`FxRatesRepository.latestRate`](mobile/lib/features/currency/repositories/fx_rates_repository.dart) returns the most recent rate at or before a cutoff (or null — no implicit 1/rate inversions; the user enters each direction explicitly). [`multiCurrencyNetWorth`](mobile/lib/features/currency/services/convert.dart) is the pure aggregation function for the net-worth card. Migration 037 redefines [`get_category_spending`](supabase/migrations/037_category_spending_fx_aware.sql) with an optional `p_rates JSONB` parameter — when supplied, each row converts via `amount * COALESCE((p_rates->>currency)::numeric, CASE WHEN p_rates IS NULL THEN 1 ELSE 0 END)`. NULL preserves migration 029's single-currency behaviour for old callers. The contract is **exclude not silently include**: a transaction in a currency missing from the rate map gets rate=0 (drops out) instead of rate=1 (lies). The caller surfaces which currencies were excluded via its own `missingRateCurrencies` set. The dashboard provider, monthly report builder, `DashboardData` aggregations (`monthlyIncome` / `monthlySpending` / `topCategories` / `spendingByDay`), and the converted-net-worth provider all honour this contract. A USD-only household with `display_currency='USD'` resolves the rate map to empty and every path short-circuits to the legacy behaviour. The growth advisor's `SubscriptionDriftRule` and the Dart-side aggregation of `sumPositiveAmountsForAccountsSince` (Roth YTD) also honour the same exclude-not-lie contract. Per-currency budget caps land in migration 038: `budgets.currency` defaults to 'USD'; `BudgetWithSpending.capCents` is `budget.amount` converted to display via the household's FX rate (or 0 + `capIsMissingRate=true` when the rate is missing). Every cap-comparison site reads `capCents` rather than `budget.amount` directly. **Audit M1 caught two sort sites in `budget_alerts.dart` that violated this — multi-currency households got wrong overage ordering. If you add code that compares spending against a budget, use `capCents` (or `isOverBudget` / `progress`, which already do), never `budget.amount`.**

**Push (FCM/APNS).** Migration 033 adds the `device_push_tokens` table (one row per `(user_id, token)`, UNIQUE so a re-register is idempotent and `last_seen_at`-refreshing) — [DevicePushTokensRepository](mobile/lib/features/notifications/repositories/device_push_tokens_repository.dart) is the registration / removal / listMine surface, RLS scopes every read to `user_id = auth.uid()`. The server-side dispatcher lives at [supabase/functions/send-notification/](supabase/functions/send-notification/) — a TypeScript port of `evaluateNotifications` that runs as the service role, honours the same FX contract as the Dart engine (fetches `households.display_currency` + `fx_rates`, threads `p_rates` through `get_category_spending`, converts each budget's cap per its own currency — exclude-not-lie on missing rates), and POSTs to the legacy FCM HTTP API per device token. The FCM call is gated on `FIREBASE_SERVER_KEY`; when unset the function returns a `preview` of what would have been sent so tests can verify the engine without real Firebase. **Atomic dedup** across the two engines is via the `notification_log` table (migration 039) — `(household_id, dedup_key)` PK + `INSERT … ON CONFLICT DO NOTHING RETURNING dedup_key` is the check-and-insert pattern. The Edge Function claims keys before pushing; the in-app runner claims them before showing; whichever wins fires, the loser silently skips. [NotificationLogRepository](mobile/lib/features/notifications/repositories/notification_log_repository.dart) exposes `recentKeys(since:)` (merged into `lastFiredByKey` on the in-app side so the engine respects server fires) + `claimKeys(...)`. What's still NOT in this repo: a Firebase project (`google-services.json` / `GoogleService-Info.plist`), the `firebase_messaging` package wired into the Flutter bootstrap, and a `pg_cron` schedule or `transactions`-table trigger to actually invoke the function — see [supabase/functions/send-notification/README.md](supabase/functions/send-notification/README.md) for the deployment steps.

**Plaid integration.** Migrations 054–064 and 066 + the four edge functions under [`supabase/functions/plaid-*`](supabase/functions/). The mobile feature dir is [`mobile/lib/features/plaid/`](mobile/lib/features/plaid/). Key invariants:
- **`plaid_items.access_token` is encrypted at rest** (migration 066, audit M2). The plaintext column is dropped; the token is stored with pgcrypto `pgp_sym_encrypt` under a key held in `vault.secrets`. Every write and read goes through the `SECURITY DEFINER` accessors `set_plaid_access_token` / `get_plaid_access_token`, with `EXECUTE` revoked from `anon` and `authenticated`, so only the service-role edge functions can call them. The Dart model omits the field, and `plaid_rpc_test.dart` pins both the dropped column and the REVOKE on the accessors. Production must set a real `plaid_access_token_key` (via `vault.update_secret`) before 066 is deployed; the migration seeds a dev placeholder only when no key exists.
- **Webhook signature verification** lives in [`_shared/plaid.ts`](supabase/functions/_shared/plaid.ts) — JWT verified against the raw request body (re-stringification would whitespace-mismatch), JWK cached per-kid for 24h (audit C5 added a typed `PlaidJwkFetchError` so a JWK outage returns 503-retry instead of 200-dead-letter), constant-time body-hash compare, iat window widened to 24h (audit H8: Plaid's exponential-backoff retries legitimately exceed 5min).
- **Webhook replay protection.** Migration 060 added `dedup_hash TEXT` + partial UNIQUE on `(plaid_item_id, dedup_hash)`. The handler computes SHA-256 of the raw body and upserts with `ignoreDuplicates`. Empty RETURNING ⇒ replay ⇒ skip routing, still 200. Audit M5 added an environment cross-check: if the matched plaid_items row's `environment` doesn't match the function's `PLAID_ENV`, skip routing (sandbox webhook → prod function safety).
- **`upsert_plaid_transactions` dedup is greedy with backtracking** (migration 061 — review #3). For each (plaid_row, existing_row) pair ordered by date_distance ASC then external_id ASC, claim each as you go via temp tables. Pure-greedy result isn't strictly optimal but is correct in the "no Plaid row leaves a match on the table" sense.
- **Removed-array preserves user state** (migration 063, audit C4). Rows with no user state hard-delete (Plaid's intent). Rows with `category_assigned_by = 'user'` OR `notes IS NOT NULL` OR `receipt_id IS NOT NULL` OR `transfer_id IS NOT NULL` soft-archive — `external_id` cleared, `source` set to `'import'`. Transfer-leg removals also clear `transfer_id` on the partner leg. Return shape gained an `archived` count alongside the existing `removed`. `IS DISTINCT FROM 'user'` is load-bearing — NULL-vs-`'user'` under 3VL.
- **`unofficial_currency_code` is exclude-not-lie.** Crypto and unofficial currency rows are dropped, not coerced to USD. The added+modified paths both log when they drop.
- **Non-owner household members can sync** (migration 062, audit C3). An additional `accounts` SELECT policy grants every household member read on rows where `plaid_account_id IS NOT NULL`. Manual accounts continue to follow the existing owner/grant/partner-full-access model.
- **Sync vs webhook race.** Migration 057's `lastSyncErrorAtStart` snapshot + `.eq('last_sync_error', captured)` filter covers the during-write race (audit H7 extended it: never downgrade a reauth code to a non-reauth value, in either success or error branch). Webhook-handler's reauth-state UPDATE is wrapped in try/catch so a routing throw still reaches the `processed_at` stamp (audit M7).
- **Cursor advances on full success only.** A partial-account failure holds the cursor (`itemRow.sync_cursor`) so the next sync re-pulls. PARTIAL_FAILURE stamps `last_sync_error` instead.
- **PlaidLink concurrency guard is module-global** (audit M8). Static `PlaidLink.onSuccess`/`onExit` streams mean two launchers in different provider scopes would cross-fire; the in-flight `Future<PlaidLinkOutcome>?` lives at module scope.
- **Webhook event retention.** Migration 064 adds `prune_plaid_webhook_events(retention_days DEFAULT 90)`. No cron job in the repo — schedule via pg_cron or invoke from `plaid-transactions-sync` operationally.

**Offline cache & pending_writes queue.** Drift schema under [`mobile/lib/core/database/`](mobile/lib/core/database/) (`app_database.dart`) mirrors 12 cache tables (one per server-side surface) + a `pending_writes` queue. Currently at schema v7. Key invariants:
- **Reads are cache-through.** Every repository's `fetchX` tries the network with retry, on failure falls back to the cache. Cache-miss + network-fail rethrows. Implemented in `accounts_repository`, `transactions_repository` (+ categories), `budget_repository`, `fx_rates_repository`, `receipts_repository`, `holdings_repository`, `recurring_transactions_repository`, `transaction_tags_repository`. Network-only paths are explicitly documented (typically RPCs with complex joins / storage uploads / FX-aware aggregations).
- **`storeDateTimeAsText: true`** on the drift database (schema v4 migration drops + recreates all cache tables). The default INT-epoch encoding round-trips through the device's local timezone — a UTC midnight written in UTC+0 reads back as the same wall-clock UTC midnight in UTC-5, silently shifting calendar days. Text encoding preserves the instant as ISO 8601 with the `Z` suffix, matching what Postgres returns over the wire.
- **DATE-shaped columns** are stored WITHOUT `.toUtc()` (audit M10). The server returns DATEs as `YYYY-MM-DD` which `DateTime.parse` interprets as LOCAL midnight; calling `.toUtc()` shifts the calendar day by the host's UTC offset. TIMESTAMPTZ columns elsewhere keep their `.toUtc()`. Affected: `transaction_date`, `posted_date`, `start_date`/`end_date` on budgets, `as_of_date` on fx_rates, `receipt_date`, `next_occurrence_date`, `skipped_until_date`.
- **Offline mutations queue via `pending_writes`.** Each row carries (op_type, target_table | rpc_name, row_id, payload JSON, attempt_count, last_error). Drain loop replays in FIFO order on the false→true `isOnlineProvider` edge. Each replay path is documented:
  - `QueuedInsert` requires `rowId` (audit C6) and a runtime assert that `payload['id'] == rowId`. The replay's `.upsert(payload, onConflict: 'id')` is idempotent across retries — a half-completed first attempt no-ops on the second.
  - `QueuedUpdate` carries an optional `expectedUpdatedAt` (audit H5). The replay applies `.eq('updated_at', precondition)` as an optimistic-lock filter; zero rows affected marks the queue row failed with `CONFLICT`. The wrapped payload shape is `{payload, expected_updated_at?}` JSON.
  - The drain caps attempts at 10 (audit H2) so a permanently-stuck row stops thrashing. Beyond that the row stays in `pending_writes` for visibility (Settings → Sync shows the count) but isn't retried.
  - The drain detects auth-expired shapes (PGRST301, `AuthException`, 401, "jwt expired") via `_isAuthExpired` and short-circuits (audit H3). The C1 sign-out listener handles the downstream wipe.
- **Cache + queue write atomicity.** `_atomicCacheAndEnqueue` wraps the optimistic cache write and the queue enqueue in a single drift transaction (audit H4). A disk-full / locked-db error on the queue insert AFTER the cache write would otherwise leave an "optimistic" row that never replays.
- **Sign-out wipes everything.** `clearAllCachesForSignOut` (audit C1) DELETEs every row from every cache table + every pending_writes row in one transaction, fired by `signOutCacheClearProvider` listening to `supabase.auth.onAuthStateChange`. Prevents cross-user data leaks on same-device re-sign-in AND stops queued writes from replaying against the wrong session.
- **Reachability probe.** `isOnlineProvider` (audit H10) layers a 2-min `SELECT id FROM households LIMIT 1` probe on top of `connectivity_plus`. Two consecutive failures flip offline; one success flips back. Catches captive-portal Wi-Fi where the platform reports "I have a Wi-Fi association" but every HTTP call hangs.
- **Phased rollout.** L1 in [`drafts/audit_2026_05_25_todos.md`](drafts/audit_2026_05_25_todos.md) tracks phase status. Phases 1, 2a–2d, 3a, 3b (AccountsRepository template), 4a (FX-aware Dart spending math), 4c (scheduler offline is fire-and-forget), 5a (last-synced banner), 5b (pull-to-refresh through SyncCoordinator), 5c (Settings → Sync surface) — DONE. Phases 3c (mass-migrate remaining write paths through the queue using the AccountsRepository template) and 4b (receipt storage upload queue — image bytes + UI for pending uploads) — deferred.

**Soft-delete vs hard-delete convention** (audit D1):
- **User-creatable parents that the user might want history of** soft-delete: `accounts` (`is_active = false`), `plaid_items` (`is_active = false`). The mobile UI filters on `is_active = true`.
- **Ledger rows and dependent rows** hard-delete: `transactions`, `receipts`, `receipt_line_items`, `budgets`, `tag assignments`, `fx_rates`, `holdings`. Cascades wire the dependents.
- **Recurring rules** flip `is_active = false` instead of deleting so historical scheduler emissions retain a parent pointer. (`recurring_transactions.is_active`.)
- Categories: hard-delete household-scoped rows. System categories (`household_id IS NULL`) aren't user-deletable.

When adding a new user-mutable table, pick the soft-delete pattern if losing the row would orphan data the user expects to keep (cascades being one way that happens). Pick hard-delete for everything else.

## OCR: production lives outside, stub lives here

The `receipts.ocr_status` enum advances `pending → processing → complete | failed`. The Dart upload path inserts rows at `'pending'` and never advances them — that's the OCR Edge Function's job.

- **Production:** the real OCR function calls Google Cloud Vision and is **deployed externally** to this repo. Don't go looking for it in `supabase/functions/` expecting the production source.
- **Local:** the stub at [`supabase/functions/process-receipt-ocr/`](supabase/functions/process-receipt-ocr/) mirrors the production output shape (advances status, writes line items via the atomic RPC, populates `ocr_raw`) but generates synthetic line items. It's not auto-invoked — call it explicitly via `supabase.functions.invoke('process-receipt-ocr', body: {...})` from Dart, or via curl. Auth is forwarded; RLS still gates writes.

## Pure functions for testable logic

When a chunk of logic is worth testing in isolation (math, parsers, transforms), pull it out of the widget/repository as a top-level function. Examples: [`parseStatementCsv`](mobile/lib/features/transactions/services/statement_parser.dart) (CSV import logic, runnable in `compute()`), [`reconstructHistoricalNetWorth`](mobile/lib/features/scenarios/repositories/scenarios_repository.dart) (balance walkback math). The repository's network call stays at the top of the function; everything below it is pure and tested without `flutter_test`'s widget tree.

## Integration tests

Repository methods whose value is "did I write the right SQL / does RLS hold?" can't be tested honestly with mocks — those just verify which builder methods got called. Real integration tests live under [`mobile/test/integration/`](mobile/test/integration/) and hit the local Supabase stack via [`_supabase_harness.dart`](mobile/test/integration/_supabase_harness.dart). The harness signs up a fresh user per run (the `handle_new_user` trigger auto-creates the household), pre-seeds one account, and exposes helpers for inserting transactions and looking up system categories.

Two things to know:
- **Default `flutter test` runs skip them.** Tests are gated on `Harness.envConfigured`, which is false unless `--dart-define=SUPABASE_TEST_URL=...` and `--dart-define=SUPABASE_TEST_ANON_KEY=...` are passed. Both `setUpAll` and individual tests check this.
- **The harness does some Flutter-test gymnastics that production code doesn't need:** clears `HttpOverrides.global` (test binding blocks real HTTP otherwise), passes `EmptyLocalStorage` + an in-memory `pkceAsyncStorage` to `Supabase.initialize` (default storage uses `SharedPreferences`, which isn't registered in the test VM). If you write a new integration test, just `await Harness.bootstrap()` and the gymnastics are hidden.

Run them locally:
```bash
supabase start                                              # if not already running
cd mobile
flutter test \
  --dart-define=SUPABASE_TEST_URL=http://localhost:54421 \
  --dart-define=SUPABASE_TEST_ANON_KEY=<from `supabase status`> \
  test/integration/
```

The integration suite has already paid for itself by catching two bugs that mocks couldn't have flagged: an RLS recursion between `accounts` and `account_visibility_grants` (fixed in 023), and a timezone-naive timestamp pattern that was silently shifting every `category_assigned_at` by the host's UTC offset (fixed in `setUserCategory` and four other write sites; see the TIMESTAMPTZ note above).

## CI

Two workflows under [.github/workflows/](.github/workflows/):

- [`ci.yaml`](.github/workflows/ci.yaml) — runs `dart format --set-exit-if-changed`, `flutter analyze`, and `flutter test` on every push/PR to `main` or `master`. Format failures are exit-code failures, not warnings — run `dart format lib test` locally before pushing.
- [`categorizer.yaml`](.github/workflows/categorizer.yaml) — triggers on `tools/categorizer/**`, `mobile/assets/ml/**`, or the classifier Dart file (same branch list). Runs `pytest` (the pure-logic Python tests in `test_train.py`), bootstraps a seed, retrains the model, gates on `eval.py --min-accuracy 0.70`, then runs the Dart parity test against the fresh fixture. Splits this from the main `ci.yaml` so a Dart-only PR doesn't pay the Python install cost.

## Build & Test Verification

- Always run the full test suite after code changes; never claim completion without passing tests
- On Windows/WSL projects, strip CRLF line endings before diffing test output
- When `make` is unavailable, manually clean build artifacts (object files, executables) rather than skipping cleanup

## Spec-Driven Workflow

- Before approving a plan via ExitPlanMode, verify it against the assignment/requirements PDF directly (read the PDF, don't ask the user)
- For multi-phase implementations, verify each spec section systematically and document gaps before coding

## Commit Hygiene

- Make focused, single-purpose commits; do not auto-commit messy WIP that requires later git reset --soft reorganization
- Run a secret/credential scan before pushing (check for .env leaks, API keys)
- Only modify .gitignore within the explicitly approved scope

## API Usage Discipline

- Before writing code against an unfamiliar package version, inspect the installed package source to confirm the actual API surface
- Do not reference symbols (enum getters, methods) before they are defined in the same change set

## Workflow Templates

### Parallel audit (fresh repo or major checkpoint)

When the user asks for a comprehensive codebase audit and the repo hasn't been audited recently:
- Spawn three parallel subagents via the Agent tool, each on a separate git worktree:
  1. Security Auditor — leaked secrets, CSRF gaps, SQL injection, weak session handling
  2. Refactor Specialist — duplicated widgets/functions with >80% similarity, candidates for shared abstractions
  3. Test Gap Filler — public functions without tests, target >85% coverage on changed code
- Each agent produces focused commits with passing tests and clean static analysis
- After all three complete, merge non-conflicting branches automatically; surface conflicts with a recommended resolution; produce a unified summary report

### TDD with three-strikes recovery

When implementing a feature under strict TDD:
1. Write the complete failing test suite first and commit it
2. Enter an implementation loop — make minimal code changes, run the full test suite, parse failures
3. Classify each failure as: logic-bug, environment-issue, flaky, or wrong-approach
4. If the same error class persists across 3 consecutive iterations, `git reset`, document why the approach failed in `DECISIONS.md`, and try a structurally different solution
5. Continue until all tests pass with clean static analysis
6. Produce a postmortem listing every approach tried, why each failed or succeeded, and lessons learned

Do not ask the user for input unless an actual ambiguity in the spec.

## Reference — Observability Engineering notes

[OBSERVABILITY-NOTES.md](OBSERVABILITY-NOTES.md) — key concepts from *Observability Engineering* 2e (O'Reilly), framed for this repo. Consult when adding instrumentation, telemetry, SLOs, or evaluating observability tooling. This repo currently has no instrumentation layer.
