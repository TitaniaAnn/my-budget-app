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

**Atomicity via RPC, not Dart loops.** Whenever a write would otherwise be "read X → mutate → write back" or "delete then insert," factor it into a SQL function and call it via `supabase.rpc(...)`. Migrations [`015`](supabase/migrations/015_recalculate_balance_function.sql) (account balance recalc), [`028`](supabase/migrations/028_save_receipt_line_items_preserve_ids.sql) (atomic replace of receipt line items — preserves IDs of rows that survive the edit so FKs from `receipt_line_item_tag_assignments` aren't cascade-deleted; supersedes the destroy-and-reinsert pattern from migration 018), and [`029`](supabase/migrations/029_category_spending_dedupe_line_items.sql) (Option B spending aggregation, dedupe-safe across multi-paired receipts; supersedes 021 and 026) all follow this pattern. Run them as the caller (no `SECURITY DEFINER`) so RLS still applies.

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

- [`ci.yaml`](.github/workflows/ci.yaml) — runs `dart format --set-exit-if-changed`, `flutter analyze`, and `flutter test` on every push/PR. Format failures are exit-code failures, not warnings — run `dart format lib test` locally before pushing.
- [`categorizer.yaml`](.github/workflows/categorizer.yaml) — triggers on `tools/categorizer/**`, `mobile/assets/ml/**`, or the classifier Dart file. Runs `pytest` (the pure-logic Python tests in `test_train.py`), bootstraps a seed, retrains the model, gates on `eval.py --min-accuracy 0.70`, then runs the Dart parity test against the fresh fixture. Splits this from the main `ci.yaml` so a Dart-only PR doesn't pay the Python install cost.

**Caveat:** the workflows watch `main` but the active branch is `master`, so CI may not actually run on commits here. Verify locally before assuming the gates are enforced.

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
