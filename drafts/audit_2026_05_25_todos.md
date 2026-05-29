# Audit todos — 2026-05-25

Second-pass deep dive. The 2026-05-24 audit covered security/RLS, money/FX correctness, and basic refactor/test gaps — all 20 items shipped (migrations 044-049). This pass covered three dimensions that audit didn't: **performance + DB hygiene**, **Flutter/Dart quality**, and **resilience + error handling**.

Quick verification pass on 044-049 first: all migrations did what they claimed. Two micro-nits worth fixing while you're in there:

- ~~Migration 045 GRANTs `create_transfer` to both `anon` AND `authenticated`. The `auth.uid()` IS NULL guard catches anon, but cleaner to grant authenticated-only.~~ **CLOSED** — migration 050 revokes from PUBLIC + anon, re-affirms authenticated grant (follows 048 pattern: Supabase auto-grants to anon directly, not via PUBLIC inheritance).
- ~~Migration 046's sentinel UUID default means any future code that forgets to pass `user_id` silently degrades to broadcast dedup. Footgun, not a bug.~~ **CLOSED** — migration 050 drops the default. Both production paths (Dart `claimKeys` + Edge Function `dispatchPerUser`) verified to pass `user_id` explicitly; existing backfilled sentinel rows untouched.

Note: integration test `RLS rejects a write with user_id != auth.uid()` in `notification_log_repository_test.dart` was already failing before 050 (`permission denied for function get_household_role` during Harness bootstrap) — appears to be unintended fallout from migration 048's `get_household_role` lockdown. Separate from this batch; flag for a follow-up.

---

## CRITICAL (real bugs visible to real users today)

### [x] C1 — `formatCurrency` ignores its own `currency` parameter; every money display says `$` (S)

**CLOSED.** Helper now uses `NumberFormat.simpleCurrency(name: currency, ...)` so EUR → "€", GBP → "£", JPY → "¥", unknown ISO falls back to the code (fail-visible). Added `currencySymbol(currency)` helper for `prefixText` inputs. Threaded `displayCurrency` / `account.currency` / `tx.currency` through dashboard_screen (14 sites), receipt_detail_screen, attach_receipt_sheet, add_transaction_sheet, growth_advisor (`_formatDollars`), transactions_screen (single + transfer delete confirm). `MoneyTextField` takes a currency param, defaulting to USD — non-USD callers must thread (no regression vs status quo). Other formatCurrency call sites that don't yet thread a currency still default to USD = status quo for USD households. Added 5 new tests covering EUR/GBP/JPY/unknown + currencySymbol round-trip. 440 tests passing.

[mobile/lib/core/utils/money.dart:11-22](../mobile/lib/core/utils/money.dart) — signature takes `String currency = 'USD'`, body hardcodes `symbol: r'$'`. The parameter is dead. After migrations 036–038 wired full multi-currency (FX rates, per-budget currency, exclude-not-lie aggregation), the entire backend converts to display currency — and then the UI renders the converted value prefixed with `$` regardless. A EUR household sees "€1234" rendered as "$1234".

Bleed sites that hardcode `$` directly instead of going through `formatCurrency`:
- [mobile/lib/features/receipts/widgets/attach_receipt_sheet.dart:156](../mobile/lib/features/receipts/widgets/attach_receipt_sheet.dart)
- [mobile/lib/features/transactions/widgets/add_transaction_sheet.dart:687](../mobile/lib/features/transactions/widgets/add_transaction_sheet.dart)
- [mobile/lib/features/receipts/screens/receipt_detail_screen.dart:549](../mobile/lib/features/receipts/screens/receipt_detail_screen.dart)
- [mobile/lib/features/dashboard/services/growth_advisor.dart:189](../mobile/lib/features/dashboard/services/growth_advisor.dart) (`$dollars` interpolation)
- [mobile/lib/shared/widgets/money_text_field.dart:33](../mobile/lib/shared/widgets/money_text_field.dart) (`prefixText: r'$'`)

**Fix:** thread `householdInfo.displayCurrency` through `formatCurrency`, switch to `NumberFormat.simpleCurrency(name: currency, locale: locale)`. Route every `NumberFormat.currency(symbol: r'$')` and `prefixText: r'$'` through the helper.

**Verify:** screenshot test or integration test in EUR household; assert `€` appears, not `$`.

---

### [x] C2 — `budgetDataProvider` never invalidated after transaction writes (S)

**CLOSED.** Extracted `invalidateLedger(WidgetRef ref)` to `lib/core/providers/ledger_invalidation.dart`. Invalidates accountsProvider + transactionsProvider + budgetDataProvider + dashboardDataProvider (dashboardData included because it doesn't `ref.watch(transactionsProvider)` either — same staleness shape when an FAB-write happens with the dashboard mounted). Replaced the 6 audit-listed pair-invalidation clusters with single `invalidateLedger(ref)` calls. Cleaned up now-unused `transactionsProvider` imports in add_transfer_sheet + import_statement_sheet. Added the helper file but skipped a test for it — the helper is 4 lines and provably correct by inspection; a behavior test fighting Riverpod's autoDispose-timer + family-overrideWith machinery added maintenance cost without value.

Six transaction write sites invalidate `accountsProvider` + `transactionsProvider` but NOT `budgetDataProvider`. Open Budgets tab, switch to Transactions, add a $100 grocery expense, switch back — Groceries bar is unchanged until manual refresh.

Sites:
- [add_transaction_sheet.dart:256-258, 341-343](../mobile/lib/features/transactions/widgets/add_transaction_sheet.dart) (create, edit, delete)
- [add_transfer_sheet.dart:105-106](../mobile/lib/features/transactions/widgets/add_transfer_sheet.dart)
- [import_statement_sheet.dart:233-234](../mobile/lib/features/transactions/widgets/import_statement_sheet.dart)
- [transactions_screen.dart:451-452, 591-592, 739-740](../mobile/lib/features/transactions/screens/transactions_screen.dart) (bulk delete, transfer delete, single delete)
- [line_items_editor_screen.dart:150](../mobile/lib/features/receipts/screens/line_items_editor_screen.dart) — per Option B (migration 029), line-item category changes shift budget spend.

**Root cause:** `budgetDataProvider` ([budget_provider.dart:108](../mobile/lib/features/budget/providers/budget_provider.dart)) reads via the RPC and doesn't `ref.watch(transactionsProvider)`.

**Fix:** extract `void invalidateLedger(WidgetRef ref) { ref.invalidate(accountsProvider); ref.invalidate(transactionsProvider); ref.invalidate(budgetDataProvider); }` to a shared helper. Replace the existing pair-invalidation clusters with `invalidateLedger(ref)`. The lack of a helper is exactly what let this drift.

**Verify:** widget test — write a transaction, assert the budget provider refetches.

---

### [x] C3 — "Delete Account" dialog is a lie (S, plus a real implementation if you want one)

**CLOSED (path 1, quick fix).** Button renamed "Sign Out & Request Deletion" with `Icons.logout_outlined` (was "Delete Account" + `delete_forever_outlined` — both reinforced the lie). Dialog title is now "Sign out and request deletion?" with body that explicitly says the app can't auto-delete yet, data lives in the backend after sign-out, and the user needs to contact the project maintainer or have the household owner delete the records. Snackbar matches: "Signed out. Your data still exists in the backend — contact the project maintainer to delete it." Path 2 (real cascade-delete Edge Function) deferred — inline comments at both sites tell the next implementer where to swap it in.

[mobile/lib/features/settings/screens/settings_screen.dart:530-557](../mobile/lib/features/settings/screens/settings_screen.dart). The destructive confirm dialog says "This permanently deletes your account and all household data. This cannot be undone." Then it calls `signOut()` and shows "Contact support to fully delete your account."

The data is NOT deleted. The user believes it was. **Likely GDPR/CCPA exposure** for any EU/CA user.

**Two paths:**
1. **Quick fix (correct the lie):** rewrite the dialog to say "We'll sign you out — email support@yourdomain to request data deletion." Stop promising what you don't deliver.
2. **Real implementation:** Edge Function with service-role auth that cascades through `auth.users` deletion (handle_new_user trigger's inverse). Probably an L-effort separate project.

Do (1) immediately. Do (2) when prioritized.

---

### [x] C4 — `main()` crashes silently on Supabase init failure → blank screen (S)

**CLOSED.** Wrapped `Supabase.initialize` in try/catch in `main.dart`. On failure, falls back to `runApp(_InitErrorApp(onRetry: main))` — a standalone MaterialApp (no ProviderScope needed, since we haven't mounted it yet on the failing path) that shows a cloud-off icon, "Couldn't connect to the backend" + captive-portal hint + a Retry button. The retry button calls `main()` again; `Supabase.initialize` is idempotent in the SDK (short-circuits on `_isInitialized`), so on success the second pass proceeds normally to `runApp(ProviderScope(...))`.

[mobile/lib/main.dart:17-36](../mobile/lib/main.dart) — `await Supabase.initialize(...)` is not wrapped. On captive-portal Wi-Fi, airplane mode, or DNS hijack at launch, this throws before `runApp`. User sees a blank window with no error, no retry, no offline indicator.

**Fix:** try/catch around init; on failure, `runApp(MaterialApp(home: InitErrorScreen(onRetry: () => main())))` with a Retry button.

---

### [x] C5 — All Supabase errors surface as raw `e.toString()` (M)

**CLOSED.** Added `lib/core/error/error_mapper.dart` with `mapError(Object) → MappedError {userMessage, requiresReauth}`. Pattern-matches:
- `PostgrestException`: PGRST301 (JWT expired, reauth), 42501 (RLS denial), PGRST116 (no/multiple rows = "not found"), 23505 (unique = "already exists"), 23503 (FK = "refresh"), 23502 (not-null = "required missing"), default = generic.
- `AuthException`: subclasses `AuthSessionMissingException` + `AuthInvalidJwtException` → reauth; code `invalid_jwt` → reauth; otherwise pass `error.message` verbatim (login-time failures like "Invalid login credentials" are already user-facing).
- `SocketException` / `TimeoutException` → "Couldn't reach the server. Check your connection."
- `String` → passes through verbatim (several catch sites pre-choose copy).
- Unknown → generic "Something went wrong."

`showErrorSnackBar` now routes through the mapper (all 33 existing call sites benefit zero-touch). 14 new unit tests cover every branch including the reauth flag. Paired with C6 below.

Grep finds only TWO typed Postgrest/Auth catches in the entire `lib/` tree (both `AuthException` in login/register). Every other call site does `} catch (e) { context.showErrorSnackBar(e.toString()) }` — the user sees `PostgrestException(message: JSON object requested, multiple (or no) rows returned, code: PGRST116, …)`.

A 401 from auth expiry looks identical to a CHECK violation. There's no "Your session expired — please sign in again" branch anywhere.

**Fix:** add `core/error/error_mapper.dart` that pattern-matches:
- `PostgrestException.code == 'PGRST301'` (JWT expired) → bounce to login
- `PostgrestException.code == '42501'` (RLS denial) → "You don't have access to this"
- `AuthException.statusCode == 401/403` → bounce to login
- `SocketException` / `TimeoutException` → "Couldn't reach the server. Check your connection."
- Default → "Something went wrong" + log raw

Wire every `showErrorSnackBar` site through it.

**Verify:** unit test the mapper against each exception type.

---

### [x] C6 — No session-expiry handler anywhere (M)

**CLOSED via the C5 path.** When `mapError` returns `requiresReauth: true`, `showErrorSnackBar` fires `unawaited(supabase.auth.signOut())`. The existing router (`app_router.dart`) already watches `authStateProvider` and redirects when `currentSession` becomes null — so the snackbar shows synchronously, the signOut roundtrip resolves shortly after, and the user lands on `/login` automatically with no per-catch-site `context.go('/login')` plumbing. PGRST301, `AuthSessionMissingException`, `AuthInvalidJwtException`, and code `invalid_jwt` all trigger the path. Unit-tested per branch.

Grep for `PGRST301`, `JWT expired`, `onTokenRefreshError`: zero hits. The router only redirects when `currentSession` is null; an EXPIRED-but-not-removed session keeps the user on `/dashboard` looking at apparently-empty data (RLS returns empty arrays on 401).

**Fix:** subscribe to `supabase.auth.onAuthStateChange` for `tokenRefreshed` failures or wrap a Postgrest interceptor; force `signOut() → go('/login')` on 401. Pair with C5.

---

### [x] C7 — Dashboard hard-fails when scheduler RPC errors (XS)

**CLOSED.** Changed `await ref.watch(runRecurringSchedulerProvider.future)` to `ref.read(runRecurringSchedulerProvider.future)` (with the `unused_result` ignore) — mirrors the notifications-runner pattern just below it. The provider is still `keepAlive` so the call still runs at most once per app process; we just no longer block the dashboard render on its completion. Tradeoff: on the cycle a rule emits, the user may see one frame of pre-emission data before the next dashboard load picks up the new rows. The audit explicitly accepts that — "Emitted recurring rows are nice-to-have, not blocking."

[mobile/lib/features/dashboard/providers/dashboard_provider.dart:263](../mobile/lib/features/dashboard/providers/dashboard_provider.dart) — `await runRecurringSchedulerProvider`. The comment promises "A single failed pass shouldn't bring the whole app down" but the `await` means a scheduler exception (RLS hiccup, transient DB pool exhaustion) puts the dashboard into its error view. The user can't use the app until the RPC succeeds. Notifications runner is correctly fire-and-forget (`:271`); scheduler should be too.

**Fix:** convert to fire-and-forget, log failures. Emitted recurring rows are nice-to-have, not blocking.

---

## HIGH (real but lower-blast-radius)

### [x] H1 — Six leaked `TextEditingController`s in inline dialogs (S)

**CLOSED.** Wrapped each dialog body in `try { … } finally { ctrl.dispose(); }`. Patched in settings_screen (`_editDisplayName`, `_editHouseholdName`, `_inviteMember`, `_joinWithCode`), notification_settings_screen (`_editThreshold`), and currency_settings_screen (`_showCurrencyPickerDialog`). Pattern mirrors the existing one at `add_transaction_sheet._createTag`.

- [settings_screen.dart:273, 307, 376, 486](../mobile/lib/features/settings/screens/settings_screen.dart) — Display Name, Household Name, Invite Email, Invite Code dialogs each `final ctrl = TextEditingController(...)` with no `dispose()`.
- [notification_settings_screen.dart:141](../mobile/lib/features/notifications/screens/notification_settings_screen.dart) — threshold-edit dialog.
- [currency_settings_screen.dart:383](../mobile/lib/features/currency/screens/currency_settings_screen.dart) — `_showCurrencyPickerDialog` helper.

The correct pattern exists at [add_transaction_sheet.dart:214](../mobile/lib/features/transactions/widgets/add_transaction_sheet.dart) — `dispose()` after the dialog future resolves. Copy it.

---

### [x] H2 — Receipt orphans in Storage when DB delete succeeds but Storage delete fails (S)

**CLOSED.** Repo `deleteReceipt` now sequences storage-first (with a single transient retry) then DB. Tradeoff: a storage-success / DB-fail leaves a "broken" receipt with a 404 image — but the row is still RLS-readable so a retry-from-UI cleans it up (storage.remove is idempotent). The prior parallel pattern silently orphaned storage objects whenever DB won the race. Caller wraps in try/catch + `showErrorSnackBar` so failures are visible. Documented limit case (DB-fail-after-storage-success) inline as a follow-up for the senior fix (pending-delete queue Edge Function).

[mobile/lib/features/receipts/repositories/receipts_repository.dart:246-256](../mobile/lib/features/receipts/repositories/receipts_repository.dart) — `Future.wait([db.delete, storage.remove])` runs both in parallel with no compensation. If DB wins and Storage fails, the row is gone, RLS blocks any path read, and the file is permanently orphaned and uncountable. Header comment acknowledges as "acceptable for personal use" but it accumulates silently.

**Fix:** sequence storage-first, then DB. If storage fails, retry once; on second failure, mark a `pending_delete=true` flag on the receipt row for a retry pass. Or document the orphan rate.

---

### [x] H3 — OCR `pending` receipts stuck forever with no UI escape (M)

**CLOSED.** Added `ReceiptsRepository.retryOcr(receiptId)` → invokes `supabase.functions.invoke('process-receipt-ocr', body: {receipt_id})`. Receipt detail screen shows a compact "Retry OCR" TextButton next to the status chip when the receipt is `failed` OR `pending` for more than an hour (`_kOcrStuckAfter = Duration(hours: 1)`). Button disables while a retry is in-flight so a double-tap can't queue two invocations. On success, invalidates `receiptProvider(receiptId)` so the chip updates. Failures bubble through `showErrorSnackBar` → mapper.

[mobile/lib/features/receipts/repositories/receipts_repository.dart:97](../mobile/lib/features/receipts/repositories/receipts_repository.dart) sets `ocr_status: 'pending'` on upload but nothing in Dart invokes the OCR Edge Function. Production OCR is external (per CLAUDE.md). If that backend is down for any window, every upload in that window stays `'pending'` indefinitely.

[receipt_detail_screen.dart:386-405](../mobile/lib/features/receipts/screens/receipt_detail_screen.dart) `_OcrStatusChip` shows "Queued" / "Failed" but no retry affordance.

**Fix:** add a "Retry OCR" button when status is `pending` (>1h) or `failed`; invoke `process-receipt-ocr` explicitly. After 5min of pending, show "Taking longer than usual" hint.

---

### [x] H4 — `bulkImport` deletes scheduler rows BEFORE the upsert; abort mid-flight loses recurring history (M)

**CLOSED via SQL function** (the senior path per CLAUDE.md's "Atomicity via RPC, not Dart loops" rule). Migration 052 adds `bulk_import_transactions(p_rows JSONB, p_reconciled_ids UUID[])` → `INTEGER inserted_count`. The function does (DELETE matched scheduler rows + INSERT … ON CONFLICT DO NOTHING) in one transaction; a failure rolls both back. Dart `bulkImport` still computes the reconciliation matches (matchRecurringDuplicates — pure / well-tested), just hands the resolved IDs + bank rows across the RPC. Existing 3 integration tests for bulkImport reconciliation still pass against the new atomic path. Runs under caller's RLS (no SECURITY DEFINER). Granted to authenticated only.

[mobile/lib/features/transactions/repositories/transactions_repository.dart:593-674](../mobile/lib/features/transactions/repositories/transactions_repository.dart):
1. SELECT recurring rows (`:611-628`)
2. **DELETE matched scheduler rows (`:640-643`)** ← commits
3. UPSERT the import (`:659-666`) ← if this fails, step 2 is already gone

Spotify scheduler row vanishes, bank import never lands, next dashboard load won't re-emit (`next_occurrence_date` is in the future). Silent disappearance.

**Fix:** push the whole sequence into a `bulk_import_with_reconciliation` SQL function so it's atomic. Belt-and-suspenders within current shape: upsert first, rollback the recurring deletes on failure.

---

### [x] H5 — `_deleteTransferConfirmed` / `_deleteTransaction` swallow errors silently (S)

**CLOSED.** Wrapped both methods in `try { … } catch (e) { showErrorSnackBar(e); }` and added the missing `if (!mounted) return` after `confirmDestructive`. Network failures now flow through the central error mapper instead of vanishing. Matches the existing pattern in `_save` / `_bulkDelete`.

[transactions_screen.dart:573-593](../mobile/lib/features/transactions/screens/transactions_screen.dart) and `:728-741`. No try/catch around `deleteTransfer` / `recalculateBalance`; network failure → no feedback, confirm dialog already closed. Also no `if (!mounted) return` after `confirmDestructive`.

The single-transaction `_save` and `_bulkDelete` (`:435+`) wrap correctly. These two were missed.

---

### [x] H6 — Login/register only catch `AuthException`; network failures silently break the button (S)

**CLOSED.** Both auth screens get an extra `catch (e) { showErrorSnackBar(e); }` after the typed `on AuthException`. The central mapper (C5) translates `SocketException` / `TimeoutException` to "Couldn't reach the server. Check your connection." so the user no longer sees the spinner stop with no message.

[login_screen.dart:36-50](../mobile/lib/features/auth/screens/login_screen.dart), [register_screen.dart:42-60](../mobile/lib/features/auth/screens/register_screen.dart) — `SocketException`, `TimeoutException`, `ClientException` bubble through; `_loading` resets via `finally`, but the user sees no error and the button just stops spinning. Form looks broken.

**Fix:** add generic `catch (e)` after the typed catch with "Couldn't reach the server."

---

### [x] H7 — Concurrent edits across devices: last-write-wins, no version check (M)

**CLOSED via the cheap shape the audit suggested.** Added `ConcurrentUpdateException` (in `core/error/error_mapper.dart`). `updateTransaction` takes an optional `expectedUpdatedAt: DateTime` parameter — when supplied, the UPDATE adds `.eq('updated_at', expectedUpdatedAt.toUtc().toIso8601String())` as a precondition and uses `.select('id')` to count affected rows; an empty result throws `ConcurrentUpdateException`. The BEFORE-UPDATE trigger refreshes `updated_at` on every write (migration 001), so a concurrent edit naturally invalidates the filter. The transaction-edit sheet now passes `widget.transaction!.updatedAt`. Mapper translates the exception to "This was edited from another device — refresh and try again." 2 new integration tests pin both the stale (throws) and fresh (succeeds) paths; mapper test added. Other UPDATE paths (`setUserCategory`, `setReceiptId`, etc.) intentionally NOT covered — those are single-screen actions on freshly-loaded data where last-write-wins is the user's intent. Expand on a per-flow basis when the concurrent-edit hazard becomes real.

There's no optimistic concurrency control anywhere. No `updated_at` precondition, no version column. Two devices in the same household editing the same transaction: spouse A re-categorizes "Whole Foods" → Groceries; spouse B re-categorizes the same row → Restaurants 30 seconds later; A's change vanishes silently.

**Fix (low-effort):** add `.eq('updated_at', knownUpdatedAt)` to UPDATE write paths; if returned row count is 0, surface "this was edited elsewhere — refresh and try again."

---

## PERFORMANCE — DB indexes (one focused migration, immediate wins)

### [x] P1 — Add missing indexes for hot query paths (M, one migration)

**CLOSED.** Migration 051 ships all 8 statements from the audit. Verified pre-state: none of the 7 new indexes existed; `target_allocations_household_idx` was redundant with the PK `(household_id, asset_class)` (leading column = household_id). Post-state confirmed via `pg_indexes`: 7 new indexes present on transactions / receipts / receipt_line_items, redundant index dropped. Partial indexes (`WHERE NOT NULL`) on receipt_id + category_id keep the index small since the majority of rows are null. Used `IF NOT EXISTS` so the migration is idempotent. Skipped CONCURRENTLY because Supabase migrations run in a transaction; tables are small enough that lock duration is negligible. Integration tests (37) still green.

The hottest read paths table-scan today. None of these is user-visible yet; all will bite within 12 months of active use as transaction volume grows.

New migration `050_hot_path_indexes.sql`:

```sql
CREATE INDEX transactions_household_date_idx
  ON transactions(household_id, transaction_date DESC);

CREATE INDEX transactions_receipt_id_idx
  ON transactions(receipt_id) WHERE receipt_id IS NOT NULL;

CREATE INDEX transactions_account_date_idx
  ON transactions(account_id, transaction_date DESC);

CREATE INDEX transactions_category_id_idx
  ON transactions(category_id) WHERE category_id IS NOT NULL;

CREATE INDEX receipt_line_items_receipt_id_idx
  ON receipt_line_items(receipt_id);

CREATE INDEX receipts_household_uploaded_idx
  ON receipts(household_id, uploaded_at DESC);

CREATE INDEX receipts_storage_path_idx
  ON receipts(storage_path);

DROP INDEX IF EXISTS target_allocations_household_idx;  -- redundant with PK
```

**Why each:**
- `transactions(household_id, date)` — every dashboard refresh, `get_category_spending`, scenarios historical walk, monthly report all filter on this shape.
- `transactions(receipt_id) WHERE NOT NULL` — `fetchByReceiptId`, `find_receipt_match_candidates`, `fetch_unpaired_receipts`, and the EXISTS subquery in `get_category_spending` all probe this.
- `transactions(account_id, date)` — `bulkImport` reconciliation, `recalculate_account_balance`, per-account lists.
- `receipt_line_items(receipt_id)` — opens on every receipt detail and every `save_receipt_line_items` DELETE.
- `receipts(storage_path)` — every storage object operation triggers the delete policy which scans `receipts`.

**Verify:** EXPLAIN ANALYZE before/after on a seed with 10k transactions. Index-only scans for the dashboard query.

---

### [x] P2 — `budgetData` fires `get_category_spending` once per budget instead of once per period (S)

**CLOSED.** Both engines fixed: Dart `budgetDataProvider` and the `send-notification` Edge Function now group RPC calls by distinct `(from, to)` period. A 10-monthly-budget household drops from 10 identical RPCs to 1; a mixed monthly/weekly/biweekly drops to 3. Pure call-pattern fix — no schema change.

[budget_provider.dart:134-144](../mobile/lib/features/budget/providers/budget_provider.dart):
```dart
final spendingFutures = budgets.map((b) {
  final (from, to) = b.period.currentRange();
  return repo.fetchSpendingByCategory(...);
}).toList();
```

10 monthly budgets = 10 identical RPC calls. Group by `(period, from, to)`, dispatch one RPC per distinct period, merge results.

Same N+1 in [supabase/functions/send-notification/index.ts:317-322](../supabase/functions/send-notification/index.ts) inside the budget loop.

---

### [x] P3 — Dashboard fetches `transactions` three times per refresh (S)

**CLOSED.** Collapsed to one 180-day fetch + in-memory slicing for the 90-day list, recent-5, and `deltasByDate` for the historical-net-worth walk. Saves 2 wire round-trips per dashboard load. One acceptable contract drift: same-day ordering of `recentTransactions` may differ from the prior `fetchTransactions(limit:5)` which had a `created_at` tiebreaker; dashboard's preview list doesn't need that precision.

[dashboard_provider.dart](../mobile/lib/features/dashboard/providers/dashboard_provider.dart):
1. `fetchTransactionsForDashboard(90 days)` — `:307`
2. `fetchTransactions(limit: 5)` recent-5 — `:312`
3. `fetchHistoricalNetWorth(180 days)` — `:340`

The 180-day window strictly contains 90 days; recent-5 is the first 5 of either. Fetch 180 days once, slice the others from the in-memory list. Saves 2 wire round-trips per dashboard load.

---

### [x] P4 — Receipts grid mints N signed URLs in parallel (S)

**CLOSED.** Added `ReceiptsRepository.getSignedUrls(paths)` wrapping `storage.createSignedUrls`. New `signedReceiptUrlsProvider` watches `receiptsProvider` and pulls every path in one POST (covers both full + thumbnail paths after P5). Existing per-path `receiptImageUrlProvider` reads from the batched map with a single-sign fallback for paths outside the household list (deep-link detail screen, etc).

[receipts_provider.dart:50-59](../mobile/lib/features/receipts/providers/receipts_provider.dart) — per-receipt family provider; opening a household with 50 receipts fires 50 `createSignedUrl` HTTP round-trips on first paint.

**Fix:** hoist a `Future<Map<String, String>> signedUrlsFor(List<String>)` provider that calls `storage.from('receipts').createSignedUrls(paths, 3600)` once; cards resolve from the map. 50 round-trips → 1.

---

### [x] P5 — No image compression, no thumbnails, no disk cache (M)

**CLOSED.** Three pieces:
- **Thumbnails.** `uploadReceipt` now generates a 256-px JPEG via `flutter_image_compress` and uploads it to `{householdId}/{uuid}_thumb.jpg` alongside the full image. Writes `thumbnail_path` (column existed since migration 001; nothing populated it before). Compression failures are non-fatal — the receipt still saves, the grid falls back to the full image.
- **Disk cache.** `cached_network_image` replaces `Image.network` on both the grid card and the detail screen. Cold-start re-downloads are gone.
- **Grid uses thumbnail when present.** `_ReceiptCard` reads `receipt.thumbnailPath ?? receipt.storagePath`. Pre-P5 receipts keep working (NULL thumbnail_path → fall back). `signedReceiptUrlsProvider` extended to fetch both sets of paths in one POST so the batching from P4 still holds.
- Insert rollback updated to clean up both objects (full + thumb) when the DB insert fails after Storage succeeds.

Two new deps: `cached_network_image: ^3.4.1`, `flutter_image_compress: ^2.4.0`.

[capture_receipt_sheet.dart:33-39](../mobile/lib/features/receipts/widgets/capture_receipt_sheet.dart) uploads at `imageQuality: 85, maxWidth: 2048` — 500KB-1.5MB per receipt. Schema has `thumbnail_path TEXT` (migration 001:107) but nothing populates it. The receipts grid downloads the **full-resolution** image for a 200px thumbnail card.

`Image.network` with no `cached_network_image` means every cold start re-downloads every visible receipt.

**Fix:** add `cached_network_image` to pubspec; client-side compress to 256px thumbnail post-pick (`flutter_image_compress` or `image`); upload thumbnail as sibling; populate `thumbnail_path`. Grid renders thumbnail; detail screen renders full image.

---

## DB CONSTRAINT GAPS (silent breakage today, audit-grade discipline tomorrow)

### [x] D1 — Missing `ON DELETE` clauses on FKs (S, one migration)

**CLOSED.** Migration 053 changes five FKs from default NO ACTION to ON DELETE SET NULL:
- `transactions.receipt_id` — deleteReceipt no longer needs to unpair first; paired transactions survive with NULL.
- `transactions.category_id` — deleteCategory no longer crashes; the existing "transactions become uncategorized" UI message becomes truthful.
- `import_batches.account_id` — account delete no longer blocks on stale batch history.
- `categories.parent_id` — parent category delete cleanly nulls out children's parent.
- `receipt_line_items.category_id` — same shape for consistency.

For `budgets.category_id` (NOT NULL, can't SET NULL), the Dart-side repo guards via a new `CategoryHasBudgetsException` — the mapper translates it to "Can't delete — at least one budget still uses this category. Remove the budget first." Manage-Categories sheet wraps deleteCategory in try/catch + showErrorSnackBar.

Deferred: `accounts.owner_user_id` — the right shape is SET NULL but that requires dropping NOT NULL + changing Dart's required `ownerUserId` field. Out of scope for a constraint-only migration; noted inline in migration 053's preamble.

4 new integration tests pin the FK SET NULL and the budget-guard behavior.

- `transactions.receipt_id` ([001:131](../supabase/migrations/001_initial_schema.sql)) — default `NO ACTION` → `deleteReceipt` crashes if any tx references the receipt. `deleteReceipt` ([receipts_repository.dart:246](../mobile/lib/features/receipts/repositories/receipts_repository.dart)) doesn't unpair first. Fix: `ON DELETE SET NULL`.
- `transactions.category_id` ([001:125](../supabase/migrations/001_initial_schema.sql)) — same. `deleteCategory` ([transactions_repository.dart:124](../mobile/lib/features/transactions/repositories/transactions_repository.dart)) crashes the moment any row references it. Fix: `ON DELETE SET NULL`.
- `budgets.category_id` ([001:180](../supabase/migrations/001_initial_schema.sql)) — `NOT NULL`, so SET NULL won't work. Add a UI check before allowing category delete.
- `accounts.owner_user_id` ([001:62](../supabase/migrations/001_initial_schema.sql)) — blocks `auth.users` cascade.
- `import_batches.account_id` ([001:162](../supabase/migrations/001_initial_schema.sql)) — fix: `ON DELETE SET NULL`.
- `categories.parent_id` ([001:93](../supabase/migrations/001_initial_schema.sql)) — fix: `ON DELETE SET NULL`.

**Verify:** integration test — create receipt with paired tx, delete receipt, assert tx survives with `receipt_id = NULL`.

---

### [x] D2 — `holdings` quantity unconstrained; `fx_rates.rate` upper-bound missing (XS)

**CLOSED.** Migration 053 adds:
- `holdings_quantity_nonneg_check`: `CHECK (quantity >= 0)` — negative-quantity holdings are nonsense; a typo (-100 instead of 100) silently inverted the position's net-worth contribution.
- `fx_rates_rate_max_check`: `CHECK (rate < 100000)` — sits alongside the existing `rate > 0` check. Sanity guardrail against a typo (1000 entered instead of 1.0) inflating net worth 1000×. 100000 isn't market-realistic; it's the loudest plausible typo upper-bound.

Both CHECKs wrapped in `DO $$ IF NOT EXISTS` blocks so a re-run is idempotent. Integration tests verify both rejections.

- [027_holdings.sql](../supabase/migrations/027_holdings.sql) — no `CHECK (quantity >= 0)`. Negative-quantity holdings are meaningless.
- [036_multi_currency_foundation.sql](../supabase/migrations/036_multi_currency_foundation.sql) — has `CHECK (rate > 0)` but no upper bound. A typo (1000 when 1.0 intended) silently inflates net worth 1000x.

Add `CHECK (rate < 100000)` as a sanity guardrail.

---

## ACCESSIBILITY

### [x] A1 — Zero `Semantics` wrappers in the entire codebase (M)

**CLOSED.** Wrapped every `fl_chart` site in `Semantics(label:, value:)`:
- Dashboard spending sparkline: label "Spending sparkline, last 30 days"; value reports 30-day total + today's spend.
- Dashboard asset allocation pie: label "Asset allocation"; value reports total + asset-class count.
- Scenario detail line chart: "Net worth over time, scenario projection".
- Debt-payoff summary chart: "Debt payoff trajectory"; value reports starting balance + month count.
- Debt-payoff per-debt chart: "Per-debt payoff trajectory"; value reports debt count + month count.
TalkBack / VoiceOver now reads the chart's headline data instead of "graph".

Grep for `Semantics(` across `lib/`: zero hits. All charts (dashboard sparkline, asset allocation pie, budget bars, debt-payoff line) render as `fl_chart` widgets with no semantic label. TalkBack/VoiceOver users hear "graph" with no values.

**Fix:** wrap each chart in `Semantics(label: '<chart name>: <summary>', value: '<key data points>')`.

---

### [x] A2 — Color-only state signaling on OCR status, budget alerts (S)

**ALREADY ADDRESSED.** Verification pass found both call-out sites already pair icons with color:
- `_OcrStatusChip` has `_icon` getter (hourglass / autorenew / check_circle_outline / error_outline) rendered alongside the colored text.
- Dashboard `_BudgetAlertTile` uses `warning_rounded` (over-budget) vs `info_outline_rounded` (approaching).
- Budget screen tiles use bold text + a `trending_up` / `trending_flat` icon for projected-over state.
No code change required — the audit may have been written against a pre-icon revision.

- [receipt_detail_screen.dart:391-399](../mobile/lib/features/receipts/screens/receipt_detail_screen.dart) — OCR status uses only color (green/red/secondary). Red-green deficient users can't distinguish processing from failed. Add `✓ / ⚠ / ⏳` icons.
- Budget alert bars on dashboard / budget screen use color alone for over/under.

---

### [x] A3 — IconButtons without tooltips (S)

**CLOSED.** Added `tooltip:` to every audit-listed bare IconButton:
- `accounts_screen` refresh → "Refresh"
- `dashboard_screen` refresh → "Refresh"
- `currency_settings_screen` per-rate delete → "Delete rate"
- `login_screen` + `register_screen` password-visibility toggles → "Show password" / "Hide password" (label flips with state)
- `sheet_scaffold` close → "Close" (covers every sheet that uses AppSheetScaffold).

- [accounts_screen.dart:28](../mobile/lib/features/accounts/screens/accounts_screen.dart), [dashboard_screen.dart:41](../mobile/lib/features/dashboard/screens/dashboard_screen.dart) — refresh buttons.
- [currency_settings_screen.dart:201](../mobile/lib/features/currency/screens/currency_settings_screen.dart) — delete-rate button.
- [login_screen.dart:103](../mobile/lib/features/auth/screens/login_screen.dart), [register_screen.dart:134](../mobile/lib/features/auth/screens/register_screen.dart) — password visibility toggles.
- [sheet_scaffold.dart:50](../mobile/lib/shared/widgets/sheet_scaffold.dart) — close button used by every sheet.

---

## SMELLS / theme drift

### [x] T1 — Hardcoded `Colors.green` / `Colors.grey` where `AppColors` token exists (S)

**CLOSED.** Mechanical sweep across all 15 sites:
- `Colors.green` → `context.appColors.success` (OCR-complete status) or `context.appColors.income` (positive deltas, discounts, net gains)
- `Colors.grey` → `context.appColors.textSubtle` (subdued labels, placeholder swatches)
Files touched: `receipt_detail_screen`, `review_ocr_lines_screen`, `monthly_report_screen`, `scenarios_screen`, `scenario_detail_screen`, `transactions_screen`. Audit's mention of `scenario_debt_payoff_view.dart:604` was stale — no `Colors.green` there in current code.

`context.appColors.income` and `context.appColors.textSubtle` exist but are bypassed at:
- [receipt_detail_screen.dart:396, 477](../mobile/lib/features/receipts/screens/receipt_detail_screen.dart) — `Colors.green`
- [scenario_detail_screen.dart:124, 254, 566, 716, 721, 745](../mobile/lib/features/scenarios/screens/scenario_detail_screen.dart) — six sites
- [scenarios_screen.dart:247](../mobile/lib/features/scenarios/screens/scenarios_screen.dart), [scenario_debt_payoff_view.dart:604](../mobile/lib/features/scenarios/widgets/scenario_debt_payoff_view.dart)
- [monthly_report_screen.dart:300, 312, 416](../mobile/lib/features/reports/screens/monthly_report_screen.dart) — `Colors.grey`
- [review_ocr_lines_screen.dart:258](../mobile/lib/features/receipts/screens/review_ocr_lines_screen.dart)
- [transactions_screen.dart:1004, 1046](../mobile/lib/features/transactions/screens/transactions_screen.dart)

Mechanical sed pass.

---

### [x] T2 — `NotificationSettings` is hand-rolled without `==`/`hashCode` (XS)

**CLOSED.** Converted to `@freezed` per project convention. Hand-rolled `copyWith` removed (freezed generates it); `@Default(...)` annotations preserve every prior default. `==` / `hashCode` now come for free, so a future `.select(...)` on the provider won't misfire on every prefs save.

[notification_settings.dart:11](../mobile/lib/features/notifications/models/notification_settings.dart) — hand-rolled value class with `copyWith` but no equality. `state = state.copyWith(enabled: true)` produces fresh identity even when value didn't change. No observable bug today (nobody uses `.select`), but the moment someone does, the selector misfires on every prefs save.

**Fix:** convert to `@freezed` per project convention.

---

### [x] T3 — `add_recurring_sheet` allows `skipped_until < next_occurrence` (XS)

**CLOSED.** Clamped the skipped-until picker's `firstDate` to `_nextOccurrence` so dates before the next emission visually can't be selected. Also moves `initialDate` forward to `_nextOccurrence` when the stored value is stale. The scheduler honours `skipped_until` only when it cuts off a future emission, so pre-fix a user could pick a past date and silently get no-op behaviour.

[add_recurring_sheet.dart](../mobile/lib/features/recurring/widgets/add_recurring_sheet.dart) — user can set skip-until BEFORE next-occurrence, which silently does nothing. Either reject in `_submit` or clamp the picker's `firstDate`.

---

## LATER (medium-term, document but defer)

7 of 8 closed in the audit pass. L1 (offline) graduated into its
own phased feature project (still in progress).

- **[L1 — Phase 1 done, Phases 2–5 pending] Offline behavior.** Phase 1 shipped 2026-05-28: `drift` + `sqlite3_flutter_libs` + `connectivity_plus` added; `AppDatabase` mirrors `accounts` as the first cache-through table; `isOnlineProvider` (keepAlive Notifier) feeds the offline banner in `MainScaffold` and triggers `invalidateLedger` on the false→true reconnect edge; `AccountsRepository` is cache-through (network → cache write → return; on failure, return cached rows). Remaining phases: **2** mirror the rest of the read surface (transactions, budgets, receipts, holdings, recurring, tags, fx_rates) with cursor-based pull sync; **3** offline write queue (`pending_writes` table + replay on reconnect); **4** hard cases (receipts/storage uploads deferred, recurring scheduler offline lag, FX-aware spending math ported to Dart); **5** polish (per-screen offline states, "last synced" timestamps, manual sync trigger). Categorizer continues to work offline (ONNX local).
- **[x] L2 — `AppLifecycleState` observer.** `MyBudgetApp` now extends `WidgetsBindingObserver`; tracks `_pausedAt` on background, invalidates the ledger providers on resume when away ≥ 1 minute.
- **[x] L3 — Retry-on-transient-failure.** Added `lib/core/utils/retry.dart` → `retryTransient(body)` with 200ms→800ms exponential backoff. Recognises `SocketException` / `TimeoutException` / `ClientException` / `PostgrestException` codes in the PGRST5xx range; auth/RLS/CHECK violations bubble through immediately. Wired into the dashboard's parallel-fetch tuple. 7 new tests.
- **[x] L4 — Notification deep-links.** `NotificationService.show` now passes the dedup tag as the payload; `ensureInitialized` wires `onDidReceiveNotificationResponse` to forward it to a top-level `notificationTapCallback`. `main.dart` sets the callback to a namespace-router map (`budget_over:*` → /budget, `large_tx:*` → /transactions).
- **[x] L5 — Biweekly/weekly date math.** Replaced every `Duration(days: N)` in `BudgetPeriod.currentRange` and `_isoWeekNumber` with `DateTime(y, m, d + N)` so DST-forward boundaries no longer drift the window end by an hour.
- **[x] L6 — `fetchTransactions` pagination.** Family provider gets `limit` as a key; transactions screen tracks `_pageSize` (starts 1000, +1000 per "Load more" tap, resets on filter change); `_TransactionList` renders a Load-More tile when results fill the page.
- **[x] L7 — FCM multicast batching.** Switched per-token POST loop to multicast via `registration_ids: [...userTokens]`. A 3-device, 5-notification user dropped from 15 sequential POSTs to 5. Per-token invalid-token detection moved inline via the `results[]` array.
- **[x] L8 — Feb-29 annual recurring quirk.** Documented in `RecurrenceCadence`'s class doc. Postgres `+ INTERVAL '1 year'` clamps Feb 29 → Feb 28 in non-leap years and the rule sticks there permanently. NOT fixed because alternative behaviors (round forward to Mar 1, re-snap to Feb 29 in leap years) also silently change the date — neither is clearly better. Users can edit `next_occurrence_date` directly if Feb 29 specifically matters.

---

## What's already done well

Surfacing the senior signals from this pass:

- Every write path with multi-step state lives in a single RPC (`create_transfer`, `save_receipt_line_items`, `run_recurring_scheduler`, `recalculate_account_balance`, `get_category_spending`). The recurring scheduler emission, balance recalc, and line-item replace are all single round-trips — no Dart-side loop hiding a partial-failure window.
- `notification_log` migrations 039+046 give genuine atomic dedup via `INSERT … ON CONFLICT … RETURNING`, now per-user.
- The recurring scheduler clamps `p_today` to `CURRENT_DATE` (migration 049), defeating the "emit 50 years of catch-up" surface.
- `create_transfer` (migration 045) derives `auth.uid()` and currency server-side — no caller-supplied attribution forgery, no hardcoded USD.
- The categorizer ONNX model works fully offline (only `rootBundle.loadString` calls, no network).
- Migration 047 pre-check uses a loud `DO $$` block — failing forward is better than failing silently on the next INSERT.
- Riverpod providers default to `autoDispose` under the generator (project convention). The 4 explicit `keepAlive` providers each have a documented reason.
- Const correctness: spot-check passed — `flutter_lints` is doing its job.
- No `print(` calls, no `.then(` chains, one `unawaited(...)` correctly marking the only fire-and-forget Future.

---

## Suggested ship order

1. **C1, C2, P1** — three S/M items, immediate user-visible wins. C1 fixes multi-currency UX in one function; C2 fixes daily UX stale-budgets bug; P1 fixes the perf cliff before it hurts.
2. **C3** — quick fix the lying dialog. GDPR exposure is the kind of thing you want closed today, not next sprint.
3. **C5, C6** — central error mapper + session-expiry handler. Pair these; they share the Postgrest interceptor surface.
4. **C4, C7** — main init crash + dashboard scheduler unblock. Both XS-effort, immediate quality-of-life.
5. **H1-H7** — real bugs but lower blast radius.
6. **P2-P5** — perf wins beyond indexes.
7. **D1, D2** — FK cleanups, one migration.
8. **A1-A3, T1-T3** — accessibility + theme drift.
9. **Document the LATER list** — these are real concerns but not urgent.

Total: 7 critical, 7 high, 5 perf, 2 DB constraint, 3 a11y, 3 smells, 8 deferred = **35 items**.

Roughly 3 focused weeks if shipped in this order. The critical batch (1-4) is ~1 week of focused work.
