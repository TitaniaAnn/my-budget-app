# Audit todos — 2026-05-24

Findings from the three-agent parallel audit (security/RLS, correctness, refactor/test-gap). Each item is sized for a single focused Claude Code session.

Format: `[ ] PRIORITY — task (effort)`. File:line citations in brackets are clickable from VS Code / IntelliJ.

---

## Status — 2026-05-25

**All 20 audit items closed.** 3 CRITICAL + 5 HIGH + 5 MEDIUM shipped with migrations 044-049 and the corresponding Dart / Edge Function changes. 5 test-gap items shipped. 5 refactors shipped (R2 widget shipped with 3 example migrations; ~45 remaining call sites are mechanical follow-up as code is touched). 3 docs shipped. R3 turned out to be an audit error — the two `_SummaryTile` classes have different APIs and aren't a dedup target.

Items now have `[x]` markers; the original prose stays intact as a record of what was found and how it was fixed.

---

## CRITICAL (exploitable today, ship this week)

### [x] C1 — Gate `send-notification` Edge Function on caller identity (L)

[supabase/functions/send-notification/index.ts:58-104](../supabase/functions/send-notification/index.ts)

The function trusts `household_id` from the request body and runs as service role. Anyone with the anon key (which ships in every release) can POST any UUID and read budget/transaction text from the `preview` field, pre-claim every `notification_log` key to silence alerts, or DoS the function.

**Fix:** verify the JWT on every call, derive `household_id` from `auth.uid()` via `household_members`, return 403 if the caller isn't a member. Alternative: lock down to service-role-only invocation with an internal cron secret in `Authorization`.

**Verify:** add a test that calls the function as user A passing user B's household_id and asserts 403. Update [supabase/functions/send-notification/README.md](../supabase/functions/send-notification/README.md) deployment notes.

---

### [x] C2 — Scope token-prune DELETE to household (XS)

[supabase/functions/send-notification/index.ts:418-423](../supabase/functions/send-notification/index.ts)

```ts
await supabase.from("device_push_tokens").delete().in("token", [...invalidTokens]);
```

Service role + no household filter = wipes the token globally. Combined with C1, an attacker who crafts an invalid token can purge it everywhere.

**Fix:** add `.eq("household_id", householdId)` to the chain.

**Verify:** unit test the dispatcher's token-cleanup branch with two households sharing a token; assert only the calling household's row is deleted.

---

### [x] C3 — Constrain `account_id` in transactions INSERT policy (M)

[supabase/migrations/001_initial_schema.sql:330-343](../supabase/migrations/001_initial_schema.sql)

The `members can insert transactions` policy only verifies `household_id`. A partner-role user can insert rows referencing account UUIDs from another household; `recalculate_account_balance` (SECURITY INVOKER) then silently includes the rogue row on the victim's next dashboard refresh, overwriting `accounts.current_balance` to a tampered value.

Same shape repeats in:
- `create_transfer` (see H1)
- `recurring_transactions` policy ([supabase/migrations/031_recurring_transactions.sql:90-96](../supabase/migrations/031_recurring_transactions.sql))
- `holdings` policy ([supabase/migrations/027_holdings.sql:100-106](../supabase/migrations/027_holdings.sql))
- ~~`target_allocations` policy~~ — **CORRECTION:** that table has no `account_id` column (PK is `(household_id, asset_class)`), so there's nothing to constrain. Audit was wrong on this one. ([supabase/migrations/035_target_allocations.sql:25-34](../supabase/migrations/035_target_allocations.sql))

**Fix:** new migration `044_constrain_account_id_to_household.sql`. Add to each WITH CHECK:
```sql
AND account_id IN (SELECT id FROM accounts WHERE household_id = <table>.household_id)
```

Drop and recreate each policy; document why in a top-of-file comment per project convention (idempotent + named for the bug it fixes).

**Verify:** integration test using the existing harness — set up two households, attempt cross-household transaction insert, assert it's rejected.

---

## HIGH (real bugs, fix next)

### [x] H1 — `create_transfer` should derive `entered_by` and `household_id` from auth.uid() (M)

[supabase/migrations/030_transfers.sql:68-116](../supabase/migrations/030_transfers.sql)

The RPC trusts caller-supplied `p_household_id`, `p_entered_by`, and both account IDs. Any owner/partner can call it with their own household + a victim's account, inserting -$X on the victim's account and +$X on theirs.

The comment at lines 33–38 also claims the function enforces `category_id IS NULL` as belt-and-suspenders — body doesn't. Dead docs.

**Fix:** new migration overriding `create_transfer`:
- Derive `v_entered_by := auth.uid()`
- Derive `v_household_id` from `accounts.household_id` of `p_from_account_id`
- Assert `p_to_account_id` belongs to the same household
- Remove `p_household_id` / `p_entered_by` from the signature (breaking change for the Dart wrapper at [mobile/lib/features/transactions/repositories/transactions_repository.dart:204-228](../mobile/lib/features/transactions/repositories/transactions_repository.dart))

**Verify:** integration test — attempt cross-household transfer, assert it raises.

---

### [x] H2 — Exclude transfers from `sumPositiveAmountsForAccountsSince` (XS)

[mobile/lib/features/transactions/repositories/transactions_repository.dart:269-306](../mobile/lib/features/transactions/repositories/transactions_repository.dart) (line 281 is the fix site)

The Roth YTD tally filters by account, sign, and date — but not `transfer_id IS NULL`. A checking→Roth recurring transfer inflates Roth YTD by the transfer amount, silencing `RothIraUnderusedRule` prematurely.

CLAUDE.md explicitly names this function as one that honors the exclude-not-lie contract; it doesn't.

**Fix:** add `.isFilter('transfer_id', null)` after the existing filters.

**Verify:** new test case in `growth_advisor_test.dart` (or wherever Roth tally is exercised) — seed a checking→Roth transfer, assert it does NOT count toward the limit.

---

### [x] H3 — `create_transfer` should not hardcode 'USD' currency (M)

[supabase/migrations/030_transfers.sql:98,109](../supabase/migrations/030_transfers.sql)
[mobile/lib/features/transactions/repositories/transactions_repository.dart:204-228](../mobile/lib/features/transactions/repositories/transactions_repository.dart) (wrapper has no currency param)

In a non-USD household, both transfer legs are tagged 'USD'. Cash-flow rollups survive (transfer_id filter), but per-account history shows wrong currency, and any FX-aware view either triggers a spurious "missing USD→EUR rate" banner or silently converts the amount.

**Decision needed:** are cross-currency transfers allowed? If yes, the RPC needs an explicit FX rate parameter; if no, it should reject when source/destination currencies differ.

**Fix (minimum):** read each account's `currency` from the `accounts` table inside the RPC, use the source's currency on the negative leg and the destination's on the positive leg. Reject cross-currency by default.

**Verify:** integration test with EUR household and two EUR accounts; assert both legs land with `currency='EUR'`.

---

### [x] H4 — Restrict `notification_log` writes to prevent intra-household silencing (M)

[supabase/migrations/039_notification_log.sql:70-86](../supabase/migrations/039_notification_log.sql)

Cross-household writes are blocked, but within a household any member can pre-claim any guessable dedup key (`budget_over:<budget_id>:<period_start>`, `large_tx:<tx_id>`) — keys are derivable from RLS-visible data. A child-role member can silence a parent's "Over budget: Dining" alert.

**Fix options:**
1. **Per-user dedup** — add `user_id` to the PK. Lowest-effort, sensible default for personal alerts. Migration to backfill `user_id` from `created_by` or set `NULL` for server-side claims.
2. **SECURITY DEFINER RPC** that derives keys server-side and refuses arbitrary keys from clients.

Pick (1) unless there's a use case for shared per-household dedup.

**Verify:** integration test — user A pre-claims user B's key; assert user B's engine still fires (because the dedup is now per-user).

---

### [x] H5 — Restrict storage delete to receipts in caller's household path (S)

[supabase/migrations/016_rls_gaps.sql:79-92](../supabase/migrations/016_rls_gaps.sql)

The delete policy looks up a `receipts` row by `storage_path = storage.objects.name`. The receipts INSERT policy doesn't constrain `storage_path`, so a user can insert a receipt row in their household pointing at another household's storage path, then delete it. Requires knowing the path (former member, leak).

**Fix:** add a CHECK constraint on `receipts.storage_path` requiring `storage_path LIKE household_id::text || '/%'`. Backfill validation in the migration.

**Verify:** integration test attempts insert with mismatched household/path; assert rejected.

---

## MEDIUM (should fix)

### [x] M1 — Fix `budget_alerts.dart` sort to use `capCents` not raw amount (XS)

[mobile/lib/features/dashboard/services/budget_alerts.dart:80,85](../mobile/lib/features/dashboard/services/budget_alerts.dart)

Both sort sites use `a.budget.budget.amount` (native currency) instead of `a.budget.capCents` (display currency). The doc-comment on `BudgetWithSpending.capCents` at [mobile/lib/features/budget/providers/budget_provider.dart:52](../mobile/lib/features/budget/providers/budget_provider.dart) explicitly says comparisons must use the converted value. Single-currency households unaffected.

**Fix:** one-line per site.

**Verify:** add a multi-currency case to `budget_alerts_test.dart` (currently single-currency, which is why this slipped). Seed a EUR budget and a USD budget with an FX rate; assert sort order is correct in display currency.

---

### [x] M2 — Revoke PUBLIC EXECUTE on `get_household_role`, `create_invite`, `accept_invite` (S)

[supabase/migrations/001_initial_schema.sql:240-245](../supabase/migrations/001_initial_schema.sql), [supabase/migrations/008_household_invites.sql:30-126](../supabase/migrations/008_household_invites.sql)

Migration 024 explicitly deferred these revokes. 19 migrations later, still deferred. Apply the same `REVOKE EXECUTE ... FROM PUBLIC` posture; grant to `authenticated` only.

**Bonus:** add a per-user rate limit on `accept_invite` — the 8-char hex invite code is brute-forceable at Supabase default rate limits, and the 7-day expiry is the only bound.

**Verify:** confirm anon role gets `permission denied for function` when calling each.

---

### [x] M3 — Clamp `p_today` in `run_recurring_scheduler` (XS)

[supabase/migrations/032_recurring_scheduler.sql:74-119](../supabase/migrations/032_recurring_scheduler.sql)

A member can pass `p_today := '2099-12-31'` and emit thousands of catch-up rows in one call, polluting reports for everyone.

**Fix:** either ignore the param entirely (use `CURRENT_DATE` internally) or clamp `LEAST(p_today, CURRENT_DATE)`.

**Verify:** integration test passes a future date; assert no rows emitted past today.

---

### [x] M4 — `.toUtc()` the notification dedup map serialization (XS)

[mobile/lib/features/notifications/providers/notification_settings_provider.dart:136](../mobile/lib/features/notifications/providers/notification_settings_provider.dart)

Bare `.toIso8601String()` on the SharedPreferences write. Symmetric local read/write makes it harmless today, but the pattern matches the CLAUDE.md-documented bug class. If the dedup map ever syncs across devices, this becomes real.

**Fix:** add `.toUtc()` before the call.

---

### [x] M5 — Document `mybudget://` hijack risk + PKCE mitigation (XS)

[mobile/android/app/src/main/AndroidManifest.xml:30-35](../mobile/android/app/src/main/AndroidManifest.xml)

Custom URL scheme is hijackable by any other Android app declaring the same filter. PKCE (Supabase Flutter default) mitigates code interception. Add a comment in the manifest and a note in [README.md](../README.md) so a future change to `AuthFlowType.implicit` doesn't silently regress this.

**Action:** doc-only change. If you ever want defense in depth, switch to App Links with `autoVerify="true"` and a hosted `assetlinks.json`.

---

## TEST GAPS (cheap to add, currently untested)

### [x] T1 — Unit test `column_mapping_presets.dart` load/save (S)

SharedPreferences blob with a "corrupted store returns null" branch. No tests.

### [x] T2 — Integration test `AccountsRepository.recalculateBalance` (S)

Harness exists. The RPC 015 atomicity claim is exactly what the integration suite was built for.

### [x] T3 — Integration test `SettingsRepository.acceptInvite` (S)

RLS-sensitive path, untested. Cover: accept own invite, attempt to accept another user's invite, expired invite, used invite.

### [x] T4 — Integration test `ScenariosRepository.fetchHistoricalNetWorth` (S)

Only the pure-fn `reconstructHistoricalNetWorth` is pinned; the server walk isn't.

### [x] T5 — Unit test `recordFired` 90-day prune (XS)

Currently tested transitively via the runner only. Pure-function-style test would pin the contract.

---

## REFACTOR (preference, not bugs — do when convenient)

### [x] R1 — Centralize `DateFormat` constants (S)

~30 sites instantiate `DateFormat.yMMMd()` / `DateFormat('MMM d, yyyy')` / `DateFormat('yyyy-MM-dd')` / `DateFormat('MMM yyyy')` independently. Extract `core/utils/dates.dart` with `kShortDate`, `kLongDate`, `kIsoDate`, `kMonthYear`. Mechanical.

### [x] R2 — Extract `AppCard` wrapper (M)

~49 sites across 18 files repeat `Container(decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: dividerColor)))`. Extract to `shared/widgets/app_card.dart` with optional `padding` and `accent` props.

### [x] R3 — De-duplicate `_SummaryTile` (S)

Defined twice with identical shape: [mobile/lib/features/dashboard/screens/dashboard_screen.dart:487](../mobile/lib/features/dashboard/screens/dashboard_screen.dart), [mobile/lib/features/scenarios/screens/scenario_detail_screen.dart:177](../mobile/lib/features/scenarios/screens/scenario_detail_screen.dart). Extract to `shared/widgets/summary_tile.dart`.

### [x] R4 — Split `scenario_detail_screen.dart` (1857 LOC) (M)

Extract the debt-payoff sub-tree (`:793-1549`, ~750 lines) to `scenario_debt_payoff_view.dart`. Move `_BudgetEditDialog` and `_OneOffDialog` (not scenarios-specific) to `shared/widgets/`.

### [x] R5 — Extract filter bars from `transactions_screen.dart` (1353 LOC) (S)

`_AccountFilterBar`, `_CategoryFilterBar`, `_TagFilterBar`, `_DateFilterBar` → `transactions_filter_bars.dart`.

---

## DOCS

### [x] D1 — Update README integration coverage claim (XS)

[README.md:271](../README.md) lists `TransactionsRepository.setUserCategory, fetchUncertain` as the coverage. There are now 11 integration files (~5,300 LOC) covering 10 repos. Replace with current list or remove the line.

### [x] D2 — Refresh or delete mobile/CLAUDE.md (S)

[mobile/CLAUDE.md](../mobile/CLAUDE.md) is stuck at an earlier feature set — no mention of multi-currency, recurring scheduler, notifications, transfers. Root CLAUDE.md is authoritative. Either bring this one current or delete it.

### [x] D3 — Note `capCents` invariant in CLAUDE.md (XS)

Add a sentence to the multi-currency section: "Budget comparison sites must use `BudgetWithSpending.capCents`, not `budget.amount`." Would have caught M1 in review.

---

## Suggested ship order

1. C1, C2, C3 — one PR each, security-critical
2. H2, M1 — one-line correctness fixes with new tests
3. H1, H3 — coordinated migration + Dart wrapper change
4. H4 — design call on per-user vs per-household dedup, then migration
5. H5, M2, M3, M4 — schema/hardening migration batch
6. T1-T5 — test gaps as background work
7. R1-R5, D1-D3 — refactor and docs as time allows

Total: 12 bugs, 5 test gaps, 5 refactors, 3 doc updates. Roughly 2 focused weeks if shipped in this order.
