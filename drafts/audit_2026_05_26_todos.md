# Audit todos — 2026-05-26

Third-pass deep dive. Prior audits (2026-05-24 closed, 2026-05-25 in flight) covered security/RLS, money/FX correctness, performance/indexes, Flutter quality, and resilience/error handling on the pre-Plaid + pre-offline codebase. This pass covers the surfaces that didn't exist when those audits ran:

- **Plaid integration** (9 Dart files + 4 edge functions + migrations 054-061)
- **Offline architecture** (drift cache + pending_writes queue + cache-through repos)
- **Cross-cutting hygiene** (i18n, build/release, PII, supply chain, docs drift)

35 items total. The architecture work is genuinely sound — the bugs cluster in the integration points (sign-out doesn't clear cache, RLS denies non-owners from a new RPC, etc.) rather than the core designs.

---

## SHIP-BLOCKER (App Store will reject; do this week)

### [ ] S1 — iOS Info.plist missing every required permission string (XS)

[mobile/ios/Runner/Info.plist](../mobile/ios/Runner/Info.plist) — receipt capture goes through `ImagePicker(source: ImageSource.camera | gallery)` at [capture_receipt_sheet.dart:33-45](../mobile/lib/features/receipts/widgets/capture_receipt_sheet.dart). iOS hard-crashes the process the instant `pickImage` is called without `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` declared. App Store review flags missing usage strings as a 5.1.1 rejection.

`local_auth` is in pubspec — if you wire it in later it also needs `NSFaceIDUsageDescription`.

**Fix:** add the three strings before any TestFlight build. 10-minute fix.

---

## CRITICAL (real bugs visible today)

### [ ] C1 — Sign-out leaves drift cache + pending_writes intact (M; data leak + GDPR exposure)

Multiple files: [settings_screen.dart:241-244, 577-594](../mobile/lib/features/settings/screens/settings_screen.dart), [app_sheet.dart:59](../mobile/lib/shared/widgets/app_sheet.dart) — all call `supabase.auth.signOut()` then navigate. Nothing wipes drift. [app_database.dart:1263-1268](../mobile/lib/core/database/app_database.dart) opens `<app docs>/mybudget_cache.sqlite` unconditionally, same file across users, no encryption.

Concrete consequences:
- **Cross-user leak.** User A signs out → User B signs in. B opens app offline, sees A's category names in the picker until B's first online `fetchCategories` lands. Same for tag assignments. The `transaction_tag_assignments` table is purged whole-table only.
- **Pending writes replay against the wrong user.** A queued writes while offline → signed out without coming back online. Those writes will replay against B's session, hitting Supabase as B with A's payloads. RLS rejects them (B doesn't own A's `household_id`), they mark-failed-forever and sit in the queue — but only after attempting.
- **Disk forensics.** The sqlite file is plaintext. Rooted device, ADB pull, iCloud backup, or another OS user on a desktop Flutter build sees every transaction, account name, last-four, balance, and merchant.
- **GDPR/CCPA.** Compounds the audit_2026_05_25 C3 fix (which renamed the button to "Sign Out & Request Deletion") — the local copy isn't cleared either.

**Fix:** on `auth.onAuthStateChange` `signedOut`, delete every row in every cache table + delete every row in `pending_writes` (or delete the sqlite file and reopen). For multi-user-on-same-device, partition the cache by `auth.currentUser.id` (folder per user, or a user_id column + session-scoped filter). For disk forensics, encrypt via sqlcipher with an Android Keystore / iOS Keychain key.

---

### [ ] C2 — `.env.local` with Plaid sandbox secrets sits on dev disk; no pre-commit secret scanner (S)

[supabase/functions/.env.local:1-3](../supabase/functions/.env.local) — real Plaid sandbox `PLAID_CLIENT_ID` + `PLAID_SECRET`. `.gitignore:16` (`.env.local`) excludes it from git AND `git ls-files` confirms it's untracked. But:
- The exact filename match means a typo (`env.local`, missing dot; `secrets.json`; any non-ignored name) leaks silently.
- These are sandbox today; same file will hold prod secrets at deploy. Rotate before going prod.

**Fix:** add a pre-commit gitleaks rule with the Plaid client_id format (`/^[0-9a-f]{24}$/`). Per your CLAUDE.md "Run a secret/credential scan before pushing" — this is exactly that.

---

### [ ] C3 — Non-owner household members can never sync Plaid items (M)

[supabase/migrations/056_upsert_plaid_transactions.sql:77-90](../supabase/migrations/056_upsert_plaid_transactions.sql) (also 057, 061 — same auth guard).

The RPC's `SELECT a.household_id FROM accounts a WHERE a.id = p_account_id AND a.household_id IN (...)` runs under RLS as the caller. The `accounts` SELECT policy ([001:291](../supabase/migrations/001_initial_schema.sql)) requires owner / household owner / explicit visibility grant / partner-with-full-access. The exchange function ([plaid-public-token-exchange:297](../supabase/functions/plaid-public-token-exchange/index.ts)) writes `owner_user_id: auth.auth.userId`.

So if user A links a bank, user B (non-owner, no visibility grant) can SELECT the `plaid_items` row (household-scoped RLS at 054:92-99), but cannot see the underlying `accounts` row → `v_household_id IS NULL` → RPC raises 42501. The orchestrator ([plaid_sync_orchestrator.dart:103](../mobile/lib/features/plaid/services/plaid_sync_orchestrator.dart)) catches the throw and stuffs the item into `failedItems`. The partner sees "couldn't sync $institution, will retry" forever even though it's an auth error, not transient. They never get fresh transactions.

**Fix options:**
1. Extend `accounts` SELECT policy to grant all household members read on Plaid-backed accounts (bank data is already shared with the bank, lower trust bar than hidden accounts).
2. Auto-write `account_visibility_grants` rows for every household member on Plaid link.
3. Gate `syncAll` to skip items whose accounts aren't visible; have the household owner be the sole syncer.

Pick (1) or (2). (3) is the smallest patch but loses freshness for non-owner-driven sessions.

---

### [ ] C4 — Plaid removed-array DELETE drops user-edited rows and breaks transfer pairings (M)

[supabase/migrations/056_upsert_plaid_transactions.sql:156-172](../supabase/migrations/056_upsert_plaid_transactions.sql) (also 057, 061). The comment at line 158 acknowledges this is "the known-acceptable-for-v1 caveat."

A user manually categorizes a Plaid transaction, adds a note, attaches a receipt, or pairs it to a transfer. Plaid removes it (which Plaid does often when a bank flips a pending row to a different transaction_id on posting). The user's work is gone.

**Worst case:** transactions in a paired transfer (migration 030). `transactions.transfer_id` is not FK-enforced. Plaid deletes one leg. The surviving leg holds a dangling `transfer_id`. Dashboard cash-flow math that excludes `transfer_id IS NOT NULL` rows silently excludes the surviving leg too — drops a legit income/expense row from the report.

**Fix:** change to soft-archive (`source = 'plaid_removed'` or `removed_at` column), OR refuse to delete rows where any user-state column is set (`category_assigned_by = 'user'`, `notes IS NOT NULL`, `receipt_id IS NOT NULL`, `transfer_id IS NOT NULL`), OR at minimum unset `transfer_id` on the surviving paired leg when one leg is removed.

---

### [ ] C5 — JWK fetch failure fails-closed silently → Plaid retries forever, then stops (M)

[supabase/functions/_shared/plaid.ts:310-321](../supabase/functions/_shared/plaid.ts), [plaid-webhook/index.ts:81-89](../supabase/functions/plaid-webhook/index.ts).

If Plaid's JWK endpoint 5xxes or times out, `plaidPost` throws → `verifyPlaidWebhook` throws → webhook returns 200 with `{received: false, reason: "invalid signature"}`. Safe default for forgery.

But the 24h JWK cache is per Deno worker instance. Edge Functions cold-start frequently; a JWK outage during a cold start means webhooks in that window are 404'd to the audit log invisibly. Worse: a misconfig (sandbox/prod swap of PLAID_CLIENT_ID) makes every legitimate webhook return `received: false`. The README explicitly tells Plaid not to retry on 5xx — so Plaid stops retrying. You miss every webhook for hours, no signal anywhere.

**Fix:** differentiate "signature is bad" (200 + dead-letter) from "we couldn't reach Plaid" (500 + let Plaid retry). `verifyPlaidWebhook` should throw distinct error classes; the handler branches on them.

---

### [ ] C6 — Pending writes that succeed server-side but never ACK will duplicate inserts that lack a client-generated id (S, latent today)

[pending_writes_queue.dart:213-224](../mobile/lib/core/sync/pending_writes_queue.dart) — `upsert(payload, ignoreDuplicates: false)`. Idempotent **only when the payload contains the row's PK**.

`AccountsRepository.createAccount` does pass `'id': clientId` ([accounts_repository.dart:104-106](../mobile/lib/features/accounts/repositories/accounts_repository.dart)) — good. But `QueuedInsert.rowId` is documented as optional ([pending_writes_queue.dart:67-68](../mobile/lib/core/sync/pending_writes_queue.dart)). The moment Phase 3c wires a repo that lets Postgres mint the id via `DEFAULT uuid_generate_v4()`:
- First attempt: TCP completes server-side, response packet drops. Server has row X1.
- Drift's replay catches SocketException, marks transient, keeps the row.
- Reconnect → drain → upsert with no id → server mints X2. **Duplicate.**

**Fix:** make `QueuedInsert.rowId` required, OR error in `enqueue` when an insert payload doesn't contain a PK. Set `onConflict: 'id'` explicitly on the replay upsert.

---

## HIGH (real bugs, smaller blast radius)

### [ ] H1 — No FK-aware ordering on replay (M, latent until Phase 3c)

[pending_writes_queue.dart:179-208](../mobile/lib/core/sync/pending_writes_queue.dart) drains in `created_at ASC` (per-row FIFO, not dependency-aware). Scenario: create Account A offline (queued), create 3 transactions on A (queued). Reconnect. If the account insert fails permanently (RLS, etc.), all three transactions fail with FK violation forever — and the user has no signal about which is the root cause.

**Fix:** add `depends_on TEXT` to `pending_writes`; drain skips dependent rows when their parent has failed. OR group cross-table operations into one queued RPC (e.g. `create_account_with_initial_transactions`).

---

### [ ] H2 — Permanent failures sit in the queue forever, no dead-letter, no Settings UI (S)

[pending_writes_queue.dart:191-198](../mobile/lib/core/sync/pending_writes_queue.dart): "For now treat the same as transient — the row stays in the queue. Surfaces in the Settings sync status."

There is no Settings UI consumer of `pendingWritesCount()`. Grep confirms. So a permanent failure:
1. Never shown to the user.
2. Re-attempted on every connectivity flip false→true.
3. `attemptCount` unbounded. A row stuck on RLS denial after 6 months has `attempt_count = 4127`.

No backoff, no max-retries, no jitter, no per-error policy.

**Fix:** cap `attemptCount` (e.g. 10), move to `pending_writes_dead_letter`. Add jittered exponential backoff — skip rows whose `last_attempted_at + backoff(attempt_count)` is in the future. Build the Settings indicator.

---

### [ ] H3 — Auth-expired token during drain not handled (S)

[transient_error.dart:19-31](../mobile/lib/core/sync/transient_error.dart) — PGRST301 (JWT expired) doesn't match `PGRST5*` pattern → classified permanent → loops via H2.

If user comes back online after 30-day refresh-token expiry: 401, marked failed-permanent, sits forever. The user is signed out server-side but cache still shows their data and queue accumulates writes that will never replay. No signal anywhere.

**Fix:** before `drain()`, check `supabase.auth.currentSession?.isExpired`, call `refreshSession()`. On auth-shape errors during replay, trigger sign-out + cache-clear (compose with C1's fix).

---

### [ ] H4 — Cache write + queue enqueue are not transactional (S)

[accounts_repository.dart:154-158, 213-216, 245-253, 294-302](../mobile/lib/features/accounts/repositories/accounts_repository.dart):

```dart
await _writeCacheRow(optimistic);
await _queue?.enqueue(QueuedInsert(...));
```

`_writeCacheRow` swallows errors. The queue enqueue does NOT. If drift fails to insert into `pending_writes` (disk full, locked db), the optimistic Account is in the UI but will never replay. User sees it, it survives relaunch (cache is persistent), they assume it's saved. Next online fetch reconciles → row vanishes silently.

**Fix:** wrap both writes in `db.transaction(...)`. Same drift database — straightforward.

---

### [ ] H5 — Replay strips `expected_updated_at`; cross-device concurrent edits clobber silently (M)

[pending_writes_queue.dart:225-229](../mobile/lib/core/sync/pending_writes_queue.dart) — replay update is `.update(payload).eq('id', rowId)` with no precondition. The repo-level update path ([transactions_repository.dart:431-469](../mobile/lib/features/transactions/repositories/transactions_repository.dart)) has an `expectedUpdatedAt` optimistic-lock check — only on the live network path. The queue's replay strips it.

Scenario: Phone A goes offline at 9am, queues "Coffee → Espresso" on tx-1. Phone B updates tx-1 at 10am: "Coffee → Latte". Phone A reconnects at 11am. Queue replays, clobbering B's Latte → Espresso. No signal.

The doc comment at queue.dart:17-22 acknowledges "last-write-wins" — but the linked H7 from audit_2026_05_25 was about the *online* repo path having the lock. The queue does not.

**Fix:** persist `expected_updated_at` alongside the queued payload. On replay, include `.eq('updated_at', expectedUpdatedAt)` and on zero-rows-affected, write to `pending_writes_conflicts` for UI surfacing.

---

### [ ] H6 — `fetchSpendingByCategory` offline fallback returns `const {}` silently (S; actively misleading)

[budget_repository.dart:105-117](../mobile/lib/features/budget/repositories/budget_repository.dart). On RPC failure AND cache fallback returning null, returns `const {}` — "no spending data."

A user offline AND has never previously loaded that date range sees every budget reading $0 spent — green across the board. The dashboard's budget alerts engine reads this map; user gets a false "you're under budget" signal.

Compare to read paths (`fetchAccounts`, `fetchBudgets`) which `rethrow` on cache-miss. That's correct.

**Fix:** `rethrow` (or throw a typed `OfflineSpendingUnavailableException`) so the budget screen renders "spending unavailable while offline."

---

### [ ] H7 — Sync-vs-webhook race guard has logic gap (M)

[plaid-transactions-sync/index.ts:396-410](../supabase/functions/plaid-transactions-sync/index.ts).

Captures `lastSyncErrorAtStart` at line 128; uses it as conditional `eq` filter at line 408. Window where webhook fires BEFORE line 125 read: the read returns the webhook's value as `lastSyncErrorAtStart`. Sync proceeds, calls Plaid (which 200s because user hasn't actually re-authed yet), succeeds, and CLEARS `last_sync_error` with the filter `eq('last_sync_error', '<webhook code>')`. UPDATE succeeds because the row hasn't changed since.

The reauth state gets cleared until the next sync re-fetches the error from Plaid.

**Fix:** clear `last_sync_error` only if the previous value was a transient sync error, never if it was a reauth code. Current code conflates "we got the error before" with "we should be allowed to clear it."

---

### [ ] H8 — Replay window of 5 min via `iat` rejects legit Plaid retries (XS)

[supabase/functions/_shared/plaid.ts:354-362](../supabase/functions/_shared/plaid.ts) — `iat` must be within ±60s forward and within 300s past.

Plaid retries with exponential backoff over minutes. The dedup_hash UNIQUE (migration 060) already prevents double-processing. The `iat` check has no security value — JWT signature is what authenticates; body-hash binding stops replay against new requests; dedup-hash row stops double-processing.

**Fix:** bump iat window to 24h or remove entirely. Rely on dedup hash.

---

### [ ] H9 — `transactions_repository` bulk updates skip cache writes entirely (S)

[transactions_repository.dart:493-507 (bulkRecategorize), :561-574 (setReceiptId), :597-605 (setUserCategoryForMany), :611-680 (setUserCategory, deleteMany)](../mobile/lib/features/transactions/repositories/transactions_repository.dart).

After successful server-side bulk update, cached rows still have the old `category_id`/`receipt_id`. Until the next `fetchTransactions`, the UI shows stale data.

`setReceiptId` is the most painful: pair receipt to transaction in receipt detail, navigate back to transactions list, row still shows "no receipt" because cache wasn't touched.

**Fix:** every server-side update path should delete the cached row at minimum, ideally upsert with new values. Same for `deleteTransfer` ([:540-547](../mobile/lib/features/transactions/repositories/transactions_repository.dart)) — both legs vanish from server but linger in cache.

---

### [ ] H10 — `connectivity_plus` is not reachability; captive-portal Wi-Fi breaks auto-drain (S)

[connectivity_provider.dart:18-25](../mobile/lib/core/connectivity/connectivity_provider.dart) — `connectivity_plus` reports "I have a Wi-Fi association," not "I can reach the internet." User on captive-portal at hotel: `isOnline == true`, auto-drain never fires when they sign in to portal (no false→true edge).

Queued writes still happen (via the transient-error catch). But no "writes pending" indicator (H2), no auto-drain.

**Fix:** periodic reachability probe (every N min, `supabase.from('households').select('id').limit(1)`) updates `isOnline` based on result. Or timer-based drain not just edge-triggered.

---

## MEDIUM (defense-in-depth)

### [ ] M1 — Dead deps: `local_auth` + `flutter_secure_storage` declared, never imported (XS)

[mobile/pubspec.yaml:24-25](../mobile/pubspec.yaml). `grep -r "LocalAuthentication\|FlutterSecureStorage" mobile/lib` → zero hits. Ships ~2-3MB of native code per ABI and pulls OS framework deps.

Either remove or wire them in. `flutter_secure_storage` is conspicuous given the Plaid access_token plaintext issue (next item).

---

### [ ] M2 — Plaid `access_token` stored plaintext (M, follow-up promised in migration comment)

[supabase/migrations/054_plaid_items.sql:46-49](../supabase/migrations/054_plaid_items.sql) — comment admits "Stored plaintext for Phase 1; pgcrypto + Vault wrap is a documented follow-up."

Column-level `REVOKE SELECT FROM authenticated` (line 116) protects client read — correct. Doesn't address service-role compromise, accidental dump exposure, or insider access via Supabase Studio.

**Fix:** wrap with `pgsodium` / Supabase Vault, or AES-GCM in pgcrypto with key in Vault and a `SECURITY DEFINER` accessor. Promote from comment to real ticket.

---

### [ ] M3 — No GDPR data export flow (M)

For EU/CA users, both Right to Access (Art. 15) and Right to Erasure (Art. 17) are unmet. The "Sign Out & Request Deletion" fix from audit_2026_05_25 C3 was honest about not auto-deleting; M3 is the actual implementation.

**Fix:** RPC `export_my_data()` dumps every household-scoped row to JSON. RPC `delete_my_household()` does a real `DELETE FROM households WHERE id = X` (cascades wire most of it). Both belong on the same Settings page.

---

### [ ] M4 — `plaid_webhook_events.payload` has no retention policy (S)

[supabase/migrations/058_plaid_webhook_events.sql:60](../supabase/migrations/058_plaid_webhook_events.sql). Plaid sends webhooks per item per sync. `notification_log` got `prune_notification_log` (040); this table got nothing. Heavy household with many institutions grows unbounded.

**Fix:** add `prune_plaid_webhook_events(p_retention_days INTEGER DEFAULT 90)` mirroring 040. Schedule via pg_cron or invoke from `plaid-transactions-sync` once per sync.

---

### [ ] M5 — Webhook URL not gated per-environment (XS)

[plaid-link-token-create/index.ts:129](../supabase/functions/plaid-link-token-create/index.ts) — single `PLAID_WEBHOOK_URL` env var across sandbox+prod. `plaid-webhook` accepts any signed body regardless of environment. Cross-env routing risk during cutover.

**Fix:** log `body.environment` if present; reject if it doesn't match the function's `PLAID_ENV`.

---

### [ ] M6 — Skipped Plaid accounts (unmapped subtypes) never surfaced in UI (XS)

[plaid-public-token-exchange/index.ts:270-278](../supabase/functions/plaid-public-token-exchange/index.ts) returns `skipped_accounts`. [connect_bank_screen.dart:50-82](../mobile/lib/features/plaid/ui/connect_bank_screen.dart) reads `insertedAccounts.length` for the success message — never displays `skippedAccounts`. User linking a brokerage with an annuity subtype sees "Linked 3 accounts" when their bank has 4 visible. Same for crypto (mapped to USD with all transactions dropped).

**Fix:** render `skippedAccounts` with a "Map account type manually" CTA. `PlaidSkippedAccount` already carries the reason.

---

### [ ] M7 — Webhook `processed_at` UPDATE has no replay script promised in migration 058 comment (S)

[plaid-webhook/index.ts:209-212](../supabase/functions/plaid-webhook/index.ts) and [migration 058:24](../supabase/migrations/058_plaid_webhook_events.sql) — "a follow-up script can re-process." No such script exists. If routing throws between insert and UPDATE, the row stays with `processed_at IS NULL` forever.

**Fix:** write the replay script OR catch routing errors and stamp `processed_at` regardless.

---

### [ ] M8 — Plaid concurrency guard is per-instance, not module-global (XS)

[plaid_link_launcher.dart:78](../mobile/lib/features/plaid/services/plaid_link_launcher.dart) — `_pending` lives on the instance. Cross-instance concurrent launches (user taps Connect Bank, screen opens Link, backs out, taps ReauthBanner before first onSuccess fires) re-subscribe to PlaidLink's static streams.

**Fix:** singleton (Riverpod-provided) or module-level Completer.

---

### [ ] M9 — `updated_at` triggers inconsistent across tables (S)

Have trigger: `households`, `accounts`, `transactions`, `scenarios`, `holdings`, `plaid_items`. Missing: `budgets`, `categories`, `receipts`, `receipt_line_items`, `recurring_transactions`, `notification_settings`, `target_allocations`, `fx_rates`. Some don't have the column either.

**Fix:** decide explicitly which tables track `updated_at`. Add column + trigger or document why not.

---

### [ ] M10 — Drift cache `transaction_date` round-trip risk in non-UTC timezones (S)

[app_database.dart:144-147](../mobile/lib/core/database/app_database.dart) stores `transactionDate` as DateTime (TEXT ISO). Server returns it as a date string like `"2026-05-28"` which `DateTime.parse` interprets as local midnight. The repo's `_transactionToCompanion` does `.toUtc()` ([transactions_repository.dart:898](../mobile/lib/features/transactions/repositories/transactions_repository.dart)) — for a parsed local-midnight value in UTC+10, the stored value is `2026-05-27T14:00:00Z` (day 27, not 28). A May 28 transaction misses the May window for UTC+10 users.

**Fix:** store transaction_date as a DATE-only string, not TIMESTAMPTZ. Add integration test in a non-UTC timezone.

---

## CONSTRAINT GAPS

### [ ] D1 — Soft-delete vs hard-delete is inconsistent and undocumented (S)

- `accounts` soft-deletes via `is_active = false`.
- `transactions` hard-deletes.
- `plaid_items` cascades on parent + has its own `is_active` for soft state.
- No pattern documented.

**Fix:** pick one rule ("user-creatable entities soft-delete; ledger rows hard-delete") and write it into CLAUDE.md.

---

## CI / BUILD HYGIENE

### [ ] C7 — Pin Android `minSdk`/`targetSdk`/`compileSdk` literally (XS)

[mobile/android/app/build.gradle.kts:46-48](../mobile/android/app/build.gradle.kts) — inherits `flutter.minSdkVersion` etc. A future Flutter SDK bump silently changes targetSdk and behaviour for permissions/background services. Pin literally; bump deliberately. Play Store requires targetSdk=34 as of Aug 2024, 35 as of Aug 2025.

---

### [ ] C8 — Add build flavors (dev/prod) with distinct `applicationId` (S)

Same package name `com.mybudgetapp.mobile` for both. Debug build with dev Supabase URL installs over a production build. Add `applicationIdSuffix = ".dev"` for dev flavor, per-flavor `.env.json`.

---

### [ ] C9 — Tighten `analysis_options.yaml` lint rules (XS)

Currently default `flutter_lints` with no additions. For a money app you want:
- `unawaited_futures: error` — catches dropped Supabase futures
- `use_build_context_synchronously: error` (currently warning)
- `avoid_dynamic_calls: error` — Supabase RPC returns are dynamic
- `require_trailing_commas` — small diffs
- `avoid_print: error` — already passes, lock it in

Or swap `flutter_lints` for `very_good_analysis` (~150 rules).

---

### [ ] C10 — Add `dependabot.yml` and CI coverage step (XS)

No Dependabot or Renovate. Plaid SDK and Supabase SDK ship monthly. Drop a `.github/dependabot.yml` with weekly pub + github-actions checks. Add `flutter test --coverage` + Codecov to the existing CI workflow.

---

## DOCS DRIFT

### [ ] D2 — Root `CLAUDE.md` missing Plaid + offline coverage (S)

`grep -c plaid CLAUDE.md` → 1 (the deprecated guardrail). `grep -c offline CLAUDE.md` → 0. Migrations 050-061 absent. 11 most recent migrations covering the largest shipped surface (Plaid + offline + indexes + bulk_import_atomic + constraint gaps) are invisible.

**Fix:** add sections "Plaid integration" (mention plaintext access_token, the 4 edge functions, webhook dedup hash invariant, the `unofficial_currency_code` exclude-not-lie contract) and "Offline cache & pending_writes queue" (drift schema, auto-drain provider, L1 phase notes already in code comments).

Also: the project_instructions guardrail "No Plaid integration exists" is now stale — Plaid is built. Remove or rewrite.

---

### [ ] D3 — `mobile/README.md` is still `flutter create` boilerplate (XS)

Replace with a 30-line pointer to the root README + the dart-define recipe.

---

### [ ] D4 — Root `README.md` tech stack + features + migration highlights are pre-Plaid (S)

- "Tech stack" doesn't list `plaid_flutter`, `drift`, `connectivity_plus`, `cached_network_image`, `pdf`, `printing`, `flutter_local_notifications`.
- "What it does" doesn't mention automatic bank sync.
- "Repository layout" missing `lib/shared/widgets/`, `lib/core/database/`, `lib/core/sync/`, the four Plaid edge functions.
- Migration-highlights table stops at 023.

---

## INTERNATIONALIZATION (mostly absent; high-leverage to set up now)

### [ ] I1 — `flutter_localizations` not configured at all (M to set up; XL to actually translate)

- `pubspec.yaml` has no `flutter_localizations: sdk: flutter`.
- No `l10n.yaml`, no `.arb` files.
- `MaterialApp.router(...)` at [main.dart:219](../mobile/lib/main.dart) declares no `localizationsDelegates`, no `supportedLocales`.
- 178 inline `Text('...')` calls across 42 files. Zero `Intl.message`, zero `AppLocalizations`.

Even if you decide not to ship localized strings, **wrap the formatters now** with an explicit `locale:` argument threaded from a `userLocaleProvider` (today returns `'en_US'`). Refactoring 178 sites later is much worse than threading a parameter now.

---

### [ ] I2 — Date/number formats hardcoded `en_US` (S to fix forward)

- [money.dart:19](../mobile/lib/core/utils/money.dart) — `formatCurrency` defaults `locale: 'en_US'`.
- [dates.dart:20-32](../mobile/lib/core/utils/dates.dart) — `DateFormat` constants use no locale parameter, falling back to system default — which **races** because `intl` requires `initializeDateFormatting` for non-en locales and that call doesn't exist.
- [import_statement_sheet.dart:369](../mobile/lib/features/transactions/widgets/import_statement_sheet.dart) — hardcoded `'MM/dd'` confuses DD/MM users.

---

### [ ] I3 — Hand-rolled pluralization sprinkled (XS)

[import_statement_sheet.dart:317,415](../mobile/lib/features/transactions/widgets/import_statement_sheet.dart), [transactions_screen.dart:764](../mobile/lib/features/transactions/screens/transactions_screen.dart), [dashboard_screen.dart:1070](../mobile/lib/features/dashboard/screens/dashboard_screen.dart) — all do `'${n} transactions'` directly. Never call `Intl.plural`.

---

## TEST QUALITY

### [ ] T1 — No factories/builders; every test inlines seed data (S; pays back over time)

59 test files. A `test/_factories/` with `aTransaction(...)`, `anAccount(...)`, `aReceipt(...)` cuts hundreds of lines and standardizes "what does a valid X look like" so schema changes touch one file.

---

### [ ] T2 — No golden / snapshot tests (M)

For a budget app where dashboard, charts, and currency formatting are the product, visual regression coverage is high-leverage. fl_chart renders deterministically — a 5-test golden set (dashboard cards, net-worth chart, budget progress bars, monthly-report PDF) catches ~80% of UI regressions.

---

### [ ] T3 — No tests for `_replayOne`'s dispatcher branches (S)

[pending_writes_queue_test.dart](../mobile/test/core/sync/pending_writes_queue_test.dart) covers the persistence layer but NOT the actual replay logic. The `switch (row.opType)` is unreachable from any test. Grep of `mobile/test/integration/` for `pending_writes`/`drain` returns zero hits. Integration coverage of the replay path is nonexistent.

Every offline fix above (C1, C6, H1-H5, H10) needs replay integration tests. Build the harness once.

---

## CACHE WRITE GAPS (cleanup pass)

### [ ] X1 — `ConfirmLineItem` write not cache-mirrored — stale "needs review" badge (XS)

[receipts_repository.dart:299-319](../mobile/lib/features/receipts/repositories/receipts_repository.dart). Server clears `ocr_confidence_bp`, cache write skipped. UI shows the OCR-warning chip on confirmed line items until next visit.

**Fix:** re-fetch via `fetchLineItems(receiptId)` after update, or patch cached row in place.

---

### [ ] X2 — `recalculateBalance` is network-only with no offline handling (S, defer to Phase 4)

[accounts_repository.dart:268-273](../mobile/lib/features/accounts/repositories/accounts_repository.dart). Server-side compute that can't meaningfully be deferred. Known Phase 4 hard case per inline comments. Flag, defer.

---

## What's genuinely well-built (third audit, same pattern)

- **Plaid `access_token` hardening at the column level.** Migration 054:116-132 REVOKE + GRANT excludes `access_token`; 059 reaffirms. Integration test [plaid_rpc_test.dart:623-655](../mobile/test/integration/plaid_rpc_test.dart) verifies `SELECT access_token` is rejected. Model omits the field. (Plaintext-at-rest issue is M2, but defense-in-depth is real.)
- **Service-role used only for crown-jewel reads** in Plaid sync; user-JWT client for the RPC dispatch. Auth boundary maintained.
- **JWT verification against raw body** in plaid-webhook — `req.text()` first, then verify the same byte sequence. Whitespace-preserving.
- **JWK cache TTL 24h with per-kid keyspace.** Rotation handles itself because Plaid hands out new kids.
- **Multi-household ambiguity in token exchange** (commit 33002b2) correctly requires explicit `householdId` and verifies membership.
- **Cursor advancement on partial-success** — holds the cursor when any per-account RPC fails.
- **Sign convention transform** (`plaidAmountToCents`) has thorough test coverage including float-drift and NaN/Inf rejection.
- **Backtracking dedup correctness** (migration 061) tested via [plaid_rpc_test.dart:459-539](../mobile/test/integration/plaid_rpc_test.dart) with two manual entries.
- **dedup_hash UNIQUE replay protection** + `upsert + ignoreDuplicates + select.length === 0` pattern correctly skips routing on replay.
- **Webhook table service-role-only** — RLS enabled with zero policies = default deny.
- **camelize bug fix** (ed8be2c) — repository hands raw data to `fromJson` with `field_rename: snake` in build.yaml. Regression tests in `plaid_models_fromjson_test.dart` lock the snake_case contract.
- **PlaidLinkLauncher timeout** — 5-min fallback, synthetic TIMEOUT exit, best-effort `PlaidLink.close()`.
- **Drift schema discipline** — every cache table mirrors a server table 1:1. The `storeDateTimeAsText: true` decision and the v3→v4 migration enforce it. Schema at v7 with proper additive `onUpgrade` branches.
- **Atomic transaction wrappers** on every `replace*ForHousehold` and `replaceLineItemsForReceipt` — mid-write crash never leaves cache half-populated.
- **Cache-write try/catch wrappers** uniformly opportunistic — cache failure never breaks network-success path. Verified across all 9 cache-through repos.
- **Concurrency guard on drain** — `_draining` flag with try/finally prevents connectivity-flip / lifecycle-resume / manual-trigger double-fire.
- **FIFO ordering of pending writes** verified at app_database.dart:1214-1218 and unit test :117-140.
- **Zero `Future.delayed` waits in test/**, zero unseeded RNG, zero `print`/`debugPrint` in lib/. Money utility uses `Decimal` end-to-end. No bare `DateTime.now().toIso8601String()` in lib/ — the TIMESTAMPTZ rule is followed.
- **ProGuard rules** cover Flutter embedding, OkHttp/Supabase, Freezed annotations. `isMinifyEnabled = true` + `isShrinkResources = true` for release.

---

## Suggested ship order

1. **S1** (iOS Info.plist) — 10 minutes, unblocks TestFlight.
2. **C1** (sign-out cache clear) — GDPR + cross-user leak; one focused PR.
3. **C2 + C7-C10** (secret scanner + Android SDK pin + build flavors + lint tightening + dependabot) — single half-day "hardening" PR.
4. **C3** (non-owner Plaid sync auth) — pick option (1) or (2); one migration.
5. **C4** (Plaid removed-array soft-archive) — one migration + one code change.
6. **C5** (JWK fail-closed vs open) — one edge function refactor.
7. **C6 + H1-H4** (queue correctness) — one focused PR, fixes the latent bugs before Phase 3c wires more repos.
8. **H5 + H6** (replay version check + spending offline error) — paired with offline integration tests (T3).
9. **H7 + H8** (Plaid sync race + iat window) — one edge function PR.
10. **H9, H10** (cache write gaps + reachability probe) — cleanup pass.
11. **M1-M10** (defense in depth, retention policies, UI polish) — as time allows.
12. **D2-D4, I1-I3, T1-T3** (docs + i18n setup + test quality) — strategic, lower urgency, do in the gaps.

Total: 1 ship-blocker, 6 critical, 10 high, 10 medium, 1 constraint gap, 4 CI/build, 3 docs, 3 i18n, 3 test quality, 2 cache cleanup = **43 items**.

Critical + ship-blocker is ~1 week of focused work. Everything else is opportunistic.
