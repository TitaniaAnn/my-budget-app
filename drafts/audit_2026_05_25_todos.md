# Audit todos — 2026-05-25

Second-pass deep dive. The 2026-05-24 audit covered security/RLS, money/FX correctness, and basic refactor/test gaps — all 20 items shipped (migrations 044-049). This pass covered three dimensions that audit didn't: **performance + DB hygiene**, **Flutter/Dart quality**, and **resilience + error handling**.

Quick verification pass on 044-049 first: all migrations did what they claimed. Two micro-nits worth fixing while you're in there:

- ~~Migration 045 GRANTs `create_transfer` to both `anon` AND `authenticated`. The `auth.uid()` IS NULL guard catches anon, but cleaner to grant authenticated-only.~~ **CLOSED** — migration 050 revokes from PUBLIC + anon, re-affirms authenticated grant (follows 048 pattern: Supabase auto-grants to anon directly, not via PUBLIC inheritance).
- ~~Migration 046's sentinel UUID default means any future code that forgets to pass `user_id` silently degrades to broadcast dedup. Footgun, not a bug.~~ **CLOSED** — migration 050 drops the default. Both production paths (Dart `claimKeys` + Edge Function `dispatchPerUser`) verified to pass `user_id` explicitly; existing backfilled sentinel rows untouched.

Note: integration test `RLS rejects a write with user_id != auth.uid()` in `notification_log_repository_test.dart` was already failing before 050 (`permission denied for function get_household_role` during Harness bootstrap) — appears to be unintended fallout from migration 048's `get_household_role` lockdown. Separate from this batch; flag for a follow-up.

---

## CRITICAL (real bugs visible to real users today)

### [ ] C1 — `formatCurrency` ignores its own `currency` parameter; every money display says `$` (S)

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

### [ ] C2 — `budgetDataProvider` never invalidated after transaction writes (S)

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

### [ ] C3 — "Delete Account" dialog is a lie (S, plus a real implementation if you want one)

[mobile/lib/features/settings/screens/settings_screen.dart:530-557](../mobile/lib/features/settings/screens/settings_screen.dart). The destructive confirm dialog says "This permanently deletes your account and all household data. This cannot be undone." Then it calls `signOut()` and shows "Contact support to fully delete your account."

The data is NOT deleted. The user believes it was. **Likely GDPR/CCPA exposure** for any EU/CA user.

**Two paths:**
1. **Quick fix (correct the lie):** rewrite the dialog to say "We'll sign you out — email support@yourdomain to request data deletion." Stop promising what you don't deliver.
2. **Real implementation:** Edge Function with service-role auth that cascades through `auth.users` deletion (handle_new_user trigger's inverse). Probably an L-effort separate project.

Do (1) immediately. Do (2) when prioritized.

---

### [ ] C4 — `main()` crashes silently on Supabase init failure → blank screen (S)

[mobile/lib/main.dart:17-36](../mobile/lib/main.dart) — `await Supabase.initialize(...)` is not wrapped. On captive-portal Wi-Fi, airplane mode, or DNS hijack at launch, this throws before `runApp`. User sees a blank window with no error, no retry, no offline indicator.

**Fix:** try/catch around init; on failure, `runApp(MaterialApp(home: InitErrorScreen(onRetry: () => main())))` with a Retry button.

---

### [ ] C5 — All Supabase errors surface as raw `e.toString()` (M)

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

### [ ] C6 — No session-expiry handler anywhere (M)

Grep for `PGRST301`, `JWT expired`, `onTokenRefreshError`: zero hits. The router only redirects when `currentSession` is null; an EXPIRED-but-not-removed session keeps the user on `/dashboard` looking at apparently-empty data (RLS returns empty arrays on 401).

**Fix:** subscribe to `supabase.auth.onAuthStateChange` for `tokenRefreshed` failures or wrap a Postgrest interceptor; force `signOut() → go('/login')` on 401. Pair with C5.

---

### [ ] C7 — Dashboard hard-fails when scheduler RPC errors (XS)

[mobile/lib/features/dashboard/providers/dashboard_provider.dart:263](../mobile/lib/features/dashboard/providers/dashboard_provider.dart) — `await runRecurringSchedulerProvider`. The comment promises "A single failed pass shouldn't bring the whole app down" but the `await` means a scheduler exception (RLS hiccup, transient DB pool exhaustion) puts the dashboard into its error view. The user can't use the app until the RPC succeeds. Notifications runner is correctly fire-and-forget (`:271`); scheduler should be too.

**Fix:** convert to fire-and-forget, log failures. Emitted recurring rows are nice-to-have, not blocking.

---

## HIGH (real but lower-blast-radius)

### [ ] H1 — Six leaked `TextEditingController`s in inline dialogs (S)

- [settings_screen.dart:273, 307, 376, 486](../mobile/lib/features/settings/screens/settings_screen.dart) — Display Name, Household Name, Invite Email, Invite Code dialogs each `final ctrl = TextEditingController(...)` with no `dispose()`.
- [notification_settings_screen.dart:141](../mobile/lib/features/notifications/screens/notification_settings_screen.dart) — threshold-edit dialog.
- [currency_settings_screen.dart:383](../mobile/lib/features/currency/screens/currency_settings_screen.dart) — `_showCurrencyPickerDialog` helper.

The correct pattern exists at [add_transaction_sheet.dart:214](../mobile/lib/features/transactions/widgets/add_transaction_sheet.dart) — `dispose()` after the dialog future resolves. Copy it.

---

### [ ] H2 — Receipt orphans in Storage when DB delete succeeds but Storage delete fails (S)

[mobile/lib/features/receipts/repositories/receipts_repository.dart:246-256](../mobile/lib/features/receipts/repositories/receipts_repository.dart) — `Future.wait([db.delete, storage.remove])` runs both in parallel with no compensation. If DB wins and Storage fails, the row is gone, RLS blocks any path read, and the file is permanently orphaned and uncountable. Header comment acknowledges as "acceptable for personal use" but it accumulates silently.

**Fix:** sequence storage-first, then DB. If storage fails, retry once; on second failure, mark a `pending_delete=true` flag on the receipt row for a retry pass. Or document the orphan rate.

---

### [ ] H3 — OCR `pending` receipts stuck forever with no UI escape (M)

[mobile/lib/features/receipts/repositories/receipts_repository.dart:97](../mobile/lib/features/receipts/repositories/receipts_repository.dart) sets `ocr_status: 'pending'` on upload but nothing in Dart invokes the OCR Edge Function. Production OCR is external (per CLAUDE.md). If that backend is down for any window, every upload in that window stays `'pending'` indefinitely.

[receipt_detail_screen.dart:386-405](../mobile/lib/features/receipts/screens/receipt_detail_screen.dart) `_OcrStatusChip` shows "Queued" / "Failed" but no retry affordance.

**Fix:** add a "Retry OCR" button when status is `pending` (>1h) or `failed`; invoke `process-receipt-ocr` explicitly. After 5min of pending, show "Taking longer than usual" hint.

---

### [ ] H4 — `bulkImport` deletes scheduler rows BEFORE the upsert; abort mid-flight loses recurring history (M)

[mobile/lib/features/transactions/repositories/transactions_repository.dart:593-674](../mobile/lib/features/transactions/repositories/transactions_repository.dart):
1. SELECT recurring rows (`:611-628`)
2. **DELETE matched scheduler rows (`:640-643`)** ← commits
3. UPSERT the import (`:659-666`) ← if this fails, step 2 is already gone

Spotify scheduler row vanishes, bank import never lands, next dashboard load won't re-emit (`next_occurrence_date` is in the future). Silent disappearance.

**Fix:** push the whole sequence into a `bulk_import_with_reconciliation` SQL function so it's atomic. Belt-and-suspenders within current shape: upsert first, rollback the recurring deletes on failure.

---

### [ ] H5 — `_deleteTransferConfirmed` / `_deleteTransaction` swallow errors silently (S)

[transactions_screen.dart:573-593](../mobile/lib/features/transactions/screens/transactions_screen.dart) and `:728-741`. No try/catch around `deleteTransfer` / `recalculateBalance`; network failure → no feedback, confirm dialog already closed. Also no `if (!mounted) return` after `confirmDestructive`.

The single-transaction `_save` and `_bulkDelete` (`:435+`) wrap correctly. These two were missed.

---

### [ ] H6 — Login/register only catch `AuthException`; network failures silently break the button (S)

[login_screen.dart:36-50](../mobile/lib/features/auth/screens/login_screen.dart), [register_screen.dart:42-60](../mobile/lib/features/auth/screens/register_screen.dart) — `SocketException`, `TimeoutException`, `ClientException` bubble through; `_loading` resets via `finally`, but the user sees no error and the button just stops spinning. Form looks broken.

**Fix:** add generic `catch (e)` after the typed catch with "Couldn't reach the server."

---

### [ ] H7 — Concurrent edits across devices: last-write-wins, no version check (M)

There's no optimistic concurrency control anywhere. No `updated_at` precondition, no version column. Two devices in the same household editing the same transaction: spouse A re-categorizes "Whole Foods" → Groceries; spouse B re-categorizes the same row → Restaurants 30 seconds later; A's change vanishes silently.

**Fix (low-effort):** add `.eq('updated_at', knownUpdatedAt)` to UPDATE write paths; if returned row count is 0, surface "this was edited elsewhere — refresh and try again."

---

## PERFORMANCE — DB indexes (one focused migration, immediate wins)

### [ ] P1 — Add missing indexes for hot query paths (M, one migration)

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

### [ ] P2 — `budgetData` fires `get_category_spending` once per budget instead of once per period (S)

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

### [ ] P3 — Dashboard fetches `transactions` three times per refresh (S)

[dashboard_provider.dart](../mobile/lib/features/dashboard/providers/dashboard_provider.dart):
1. `fetchTransactionsForDashboard(90 days)` — `:307`
2. `fetchTransactions(limit: 5)` recent-5 — `:312`
3. `fetchHistoricalNetWorth(180 days)` — `:340`

The 180-day window strictly contains 90 days; recent-5 is the first 5 of either. Fetch 180 days once, slice the others from the in-memory list. Saves 2 wire round-trips per dashboard load.

---

### [ ] P4 — Receipts grid mints N signed URLs in parallel (S)

[receipts_provider.dart:50-59](../mobile/lib/features/receipts/providers/receipts_provider.dart) — per-receipt family provider; opening a household with 50 receipts fires 50 `createSignedUrl` HTTP round-trips on first paint.

**Fix:** hoist a `Future<Map<String, String>> signedUrlsFor(List<String>)` provider that calls `storage.from('receipts').createSignedUrls(paths, 3600)` once; cards resolve from the map. 50 round-trips → 1.

---

### [ ] P5 — No image compression, no thumbnails, no disk cache (M)

[capture_receipt_sheet.dart:33-39](../mobile/lib/features/receipts/widgets/capture_receipt_sheet.dart) uploads at `imageQuality: 85, maxWidth: 2048` — 500KB-1.5MB per receipt. Schema has `thumbnail_path TEXT` (migration 001:107) but nothing populates it. The receipts grid downloads the **full-resolution** image for a 200px thumbnail card.

`Image.network` with no `cached_network_image` means every cold start re-downloads every visible receipt.

**Fix:** add `cached_network_image` to pubspec; client-side compress to 256px thumbnail post-pick (`flutter_image_compress` or `image`); upload thumbnail as sibling; populate `thumbnail_path`. Grid renders thumbnail; detail screen renders full image.

---

## DB CONSTRAINT GAPS (silent breakage today, audit-grade discipline tomorrow)

### [ ] D1 — Missing `ON DELETE` clauses on FKs (S, one migration)

- `transactions.receipt_id` ([001:131](../supabase/migrations/001_initial_schema.sql)) — default `NO ACTION` → `deleteReceipt` crashes if any tx references the receipt. `deleteReceipt` ([receipts_repository.dart:246](../mobile/lib/features/receipts/repositories/receipts_repository.dart)) doesn't unpair first. Fix: `ON DELETE SET NULL`.
- `transactions.category_id` ([001:125](../supabase/migrations/001_initial_schema.sql)) — same. `deleteCategory` ([transactions_repository.dart:124](../mobile/lib/features/transactions/repositories/transactions_repository.dart)) crashes the moment any row references it. Fix: `ON DELETE SET NULL`.
- `budgets.category_id` ([001:180](../supabase/migrations/001_initial_schema.sql)) — `NOT NULL`, so SET NULL won't work. Add a UI check before allowing category delete.
- `accounts.owner_user_id` ([001:62](../supabase/migrations/001_initial_schema.sql)) — blocks `auth.users` cascade.
- `import_batches.account_id` ([001:162](../supabase/migrations/001_initial_schema.sql)) — fix: `ON DELETE SET NULL`.
- `categories.parent_id` ([001:93](../supabase/migrations/001_initial_schema.sql)) — fix: `ON DELETE SET NULL`.

**Verify:** integration test — create receipt with paired tx, delete receipt, assert tx survives with `receipt_id = NULL`.

---

### [ ] D2 — `holdings` quantity unconstrained; `fx_rates.rate` upper-bound missing (XS)

- [027_holdings.sql](../supabase/migrations/027_holdings.sql) — no `CHECK (quantity >= 0)`. Negative-quantity holdings are meaningless.
- [036_multi_currency_foundation.sql](../supabase/migrations/036_multi_currency_foundation.sql) — has `CHECK (rate > 0)` but no upper bound. A typo (1000 when 1.0 intended) silently inflates net worth 1000x.

Add `CHECK (rate < 100000)` as a sanity guardrail.

---

## ACCESSIBILITY

### [ ] A1 — Zero `Semantics` wrappers in the entire codebase (M)

Grep for `Semantics(` across `lib/`: zero hits. All charts (dashboard sparkline, asset allocation pie, budget bars, debt-payoff line) render as `fl_chart` widgets with no semantic label. TalkBack/VoiceOver users hear "graph" with no values.

**Fix:** wrap each chart in `Semantics(label: '<chart name>: <summary>', value: '<key data points>')`.

---

### [ ] A2 — Color-only state signaling on OCR status, budget alerts (S)

- [receipt_detail_screen.dart:391-399](../mobile/lib/features/receipts/screens/receipt_detail_screen.dart) — OCR status uses only color (green/red/secondary). Red-green deficient users can't distinguish processing from failed. Add `✓ / ⚠ / ⏳` icons.
- Budget alert bars on dashboard / budget screen use color alone for over/under.

---

### [ ] A3 — IconButtons without tooltips (S)

- [accounts_screen.dart:28](../mobile/lib/features/accounts/screens/accounts_screen.dart), [dashboard_screen.dart:41](../mobile/lib/features/dashboard/screens/dashboard_screen.dart) — refresh buttons.
- [currency_settings_screen.dart:201](../mobile/lib/features/currency/screens/currency_settings_screen.dart) — delete-rate button.
- [login_screen.dart:103](../mobile/lib/features/auth/screens/login_screen.dart), [register_screen.dart:134](../mobile/lib/features/auth/screens/register_screen.dart) — password visibility toggles.
- [sheet_scaffold.dart:50](../mobile/lib/shared/widgets/sheet_scaffold.dart) — close button used by every sheet.

---

## SMELLS / theme drift

### [ ] T1 — Hardcoded `Colors.green` / `Colors.grey` where `AppColors` token exists (S)

`context.appColors.income` and `context.appColors.textSubtle` exist but are bypassed at:
- [receipt_detail_screen.dart:396, 477](../mobile/lib/features/receipts/screens/receipt_detail_screen.dart) — `Colors.green`
- [scenario_detail_screen.dart:124, 254, 566, 716, 721, 745](../mobile/lib/features/scenarios/screens/scenario_detail_screen.dart) — six sites
- [scenarios_screen.dart:247](../mobile/lib/features/scenarios/screens/scenarios_screen.dart), [scenario_debt_payoff_view.dart:604](../mobile/lib/features/scenarios/widgets/scenario_debt_payoff_view.dart)
- [monthly_report_screen.dart:300, 312, 416](../mobile/lib/features/reports/screens/monthly_report_screen.dart) — `Colors.grey`
- [review_ocr_lines_screen.dart:258](../mobile/lib/features/receipts/screens/review_ocr_lines_screen.dart)
- [transactions_screen.dart:1004, 1046](../mobile/lib/features/transactions/screens/transactions_screen.dart)

Mechanical sed pass.

---

### [ ] T2 — `NotificationSettings` is hand-rolled without `==`/`hashCode` (XS)

[notification_settings.dart:11](../mobile/lib/features/notifications/models/notification_settings.dart) — hand-rolled value class with `copyWith` but no equality. `state = state.copyWith(enabled: true)` produces fresh identity even when value didn't change. No observable bug today (nobody uses `.select`), but the moment someone does, the selector misfires on every prefs save.

**Fix:** convert to `@freezed` per project convention.

---

### [ ] T3 — `add_recurring_sheet` allows `skipped_until < next_occurrence` (XS)

[add_recurring_sheet.dart](../mobile/lib/features/recurring/widgets/add_recurring_sheet.dart) — user can set skip-until BEFORE next-occurrence, which silently does nothing. Either reject in `_submit` or clamp the picker's `firstDate`.

---

## LATER (medium-term, document but defer)

- **No offline behavior at all.** No `connectivity_plus`, no local cache, no SQLite. Empty/error states on every screen when offline. Categorizer works offline (ONNX local); nothing else does.
- **No `AppLifecycleState` observer.** Background app for 3 days, open Monday → Friday's data, no refresh on resume.
- **No retry-on-transient-failure anywhere.** One dropped packet during dashboard load → error view. Add at least one transparent retry with backoff for read-only fetches.
- **Notification deep-links don't exist.** `NotificationService.show` doesn't pass a payload; `initialize` doesn't pass `onDidReceiveNotificationResponse`. Tapping a notification opens the app to wherever it was.
- **Biweekly/weekly date math uses `Duration(days:)` not calendar math.** DST forward → end-of-period is slightly less than 14 days. Cosmetic in practice (date-only comparisons elsewhere), wrong in principle.
- **`fetchTransactions` LIMIT 1000 with no "load more"** — power user at year 3 silently loses transactions off the end.
- **Per-token FCM POST is sequential** in send-notification — switch to legacy FCM's `registration_ids: [...]` multicast (up to 1000 per call).
- **DST/leap-year recurring math** is mostly correct (DATE columns are zone-free), but annual-on-Feb-29 becomes Feb 28 permanently. Document.

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
