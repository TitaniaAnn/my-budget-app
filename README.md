# my-budget-app

A family-budgeting app: Flutter mobile client, Supabase (Postgres + Auth + Storage + Edge Functions) backend.

![CI](https://github.com/TitaniaAnn/my-budget-app/actions/workflows/ci.yml/badge.svg)

> **Status:** Private development. Not currently distributed; this repo exists as a working codebase and a public reference for some of the architectural decisions. See [Highlights](#highlights) for what's worth a closer look.

---

## What it does

Multi-user household budgeting with roles, shared accounts, and the kind of correctness you actually need when real money is involved.

- **Households with roles** — owner, partner, child — and granular per-account visibility grants on top of role defaults.
- **Accounts** across ten types: checking, savings, credit cards, brokerage, IRA (traditional & Roth), 401(k), 403(b), HSA, 529, and cash.
- **Transactions** entered manually, imported from bank CSVs (with header heuristics and dedup), or attached to a receipt.
- **Auto-categorization** of transactions via an on-device ML model (Platt-calibrated LogReg over char-ngram TF-IDF, ONNX) with per-class auto-apply thresholds. Predictions never leave the device. Below-threshold guesses surface in a "Review uncertain" Settings screen so the user's correction becomes ground-truth for the next retrain. The legacy keyword matcher stays as a cold-start / fall-through path.
- **Receipts** uploaded to private Storage, line-itemized via OCR (Supabase Edge Function → Google Cloud Vision). The production Edge Function is deployed externally; this repo ships a stub at [`supabase/functions/process-receipt-ocr/`](supabase/functions/process-receipt-ocr/) that mirrors its output shape so the local stack can exercise the full flow without API keys.
- **Budgets** with weekly / monthly / annual periods and live progress against actual spending.
- **Scenarios & goals** — what-if planning with iCal RRULE recurring events, parent-branching for alternatives, and `is_goal` overlay for target-date savings tracking. Projection runs forward from current net worth; historical net worth is reconstructed by walking transaction deltas backward.

---

## Highlights

The bits that took the most thought, in case you're skimming the repo to see how it's built:

**Row-level security, debugged in production.** Every table is RLS-enforced; access is gated through a `SECURITY DEFINER` `get_household_role()` helper that itself sidesteps recursion. Migration `004_fix_household_members_rls.sql` fixes an infinite-recursion bug in a self-referencing policy. Migration `016_rls_gaps.sql` fills "deny-everything" gaps where RLS was enabled with no policies — silently breaking features. Both migrations name the bug they fix.

**Atomic mutations via PostgREST RPC.** Two places where a multi-step Dart sequence was racy got moved into single SQL functions, both runnable as the caller so RLS still applies:
- [`015_recalculate_balance_function.sql`](supabase/migrations/015_recalculate_balance_function.sql) replaces a three-roundtrip recalc (read starting balance → read transactions → write back) with one `UPDATE … RETURNING`. A concurrent insert can't be lost between read and write.
- [`018_save_receipt_line_items_function.sql`](supabase/migrations/018_save_receipt_line_items_function.sql) wraps the `DELETE old + INSERT new` line-item replace in a single transaction. Previously, an insert failure after the delete left the receipt with zero line items.

**Money is integer cents, end-to-end.** No `double` for currency anywhere. Net worth is the plain signed sum of `current_balance` across all accounts — credit cards and mortgages stored as negative, so debt subtracts naturally. Pinned by regression tests in [`test/features/dashboard/dashboard_data_test.dart`](mobile/test/features/dashboard/dashboard_data_test.dart) after a bug where mortgages were counted as assets.

**CSV statement import** lives as a pure function in [`statement_parser.dart`](mobile/lib/features/transactions/services/statement_parser.dart), called via `compute()` so a multi-MB statement parses on a background isolate. Heuristic column detection covers single signed-amount columns and split debit/credit columns (Wells Fargo–style); two-digit years pivot into the 21st century. Sign inference for unsigned exports prefers credit keywords on overlap — `"PAYMENT REFUND"` is a refund, not a payment. Amounts go through `Decimal` end-to-end (no IEEE-754 round-trip on `0.10 → 9 cents`). Dedup keys are normalised across casing/whitespace so a re-export with cleaned-up descriptions doesn't bypass the server-side `UNIQUE(account_id, external_id)`. Pinned by [`statement_parser_test.dart`](mobile/test/features/transactions/statement_parser_test.dart).

**Scenario engine** with iCal RRULE recurring events, `parent_id` for branching what-ifs, weekly chart sampling for performance, and shared primitives between planning scenarios and savings goals via an `is_goal` flag. Historical net worth is reconstructed by walking transaction deltas backward from the current balance — the math is a pure function ([`reconstructHistoricalNetWorth`](mobile/lib/features/scenarios/repositories/scenarios_repository.dart)) pinned by [`historical_net_worth_test.dart`](mobile/test/features/scenarios/historical_net_worth_test.dart) after an off-by-one where the wrong day's delta was being undone at each step.

**Tags as a second dimension.** Categories answer *what kind of expense* (one per row); [`020_transaction_tags.sql`](supabase/migrations/020_transaction_tags.sql) adds tags for *what context* (many per row, applied to either a transaction or a single receipt line item). The motivating use case is filing a contractor expense without splitting a Costco run into two transactions.

**Storage security via path convention.** Receipt images live in a private bucket at `{household_id}/{uuid}.jpg`; RLS policies parse the household ID out of the path to scope access.

**Integration tests against a local Supabase stack.** Repository methods whose value is "did I write the right SQL / does RLS hold?" can't be tested honestly with mocks — those just verify which builder methods got called. [`mobile/test/integration/`](mobile/test/integration/) hits a real `supabase start` stack via a thin harness ([`_supabase_harness.dart`](mobile/test/integration/_supabase_harness.dart)) that signs up a fresh user per run, leans on the `handle_new_user` trigger to provision the household, and tears everything down at the end. Gated on `--dart-define=SUPABASE_TEST_URL=...` so default `flutter test` runs are unaffected. The suite paid for itself the same hour it was written: it caught an RLS recursion between `accounts` and `account_visibility_grants` (fixed in [`023`](supabase/migrations/023_fix_account_visibility_grants_rls_recursion.sql)) and a timezone-naive timestamp pattern silently shifting every `category_assigned_at` by the host's UTC offset.

**On-device categorizer with honest provenance and a real feedback loop.** The classifier is a `CalibratedClassifierCV(LogisticRegression, method='sigmoid', ensemble=False)` over a `char_wb` TF-IDF (n-grams 3–5, ≤10K features), trained in [`tools/categorizer/`](tools/categorizer/), exported via skl2onnx, and run client-side via [`onnxruntime`](https://pub.dev/packages/onnxruntime) — descriptions never leave the device. The Dart-side TF-IDF transform is a byte-for-byte port of sklearn's `char_wb` analyser, gated by a parity test ([`ml_category_classifier_test.dart`](mobile/test/features/transactions/ml_category_classifier_test.dart)) that asserts identical sparse vectors against a Python-generated fixture; the [`categorizer.yaml`](.github/workflows/categorizer.yaml) workflow rebuilds the fixture from scratch on every push that touches the training pipeline.

What's worth a closer look:

- **Feature shape.** The model sees `<description>|<merchant>|<sign>|<amt_bucket>|<account_type>` — magnitude (xs/s/m/l/xl) and account type (`checking`, `credit_card`, …) carry signal that pure-text models miss. A $5 charge at Walmart is overwhelmingly Groceries; a $700 charge at Walmart is more likely Home Improvement.
- **Calibrated probabilities.** Uncalibrated LogReg overstates extremes — `confidence: 0.7` doesn't always mean "right 70% of the time". Platt scaling makes the confidence number actually mean what it claims, which is what lets the per-class thresholds and the active-learning band cut-offs be principled instead of guess-y.
- **Per-class auto-apply thresholds.** Computed at training time as the highest threshold maintaining recall ≥ 0.7 on a holdout. Confident classes can auto-apply at confidences below the global default; noisy classes hold out above it. Shipped in `assets/ml/thresholds.json` and consulted via `MlCategoryClassifier.thresholdFor`.
- **Active learning loop.** Migration `022_ml_model_confidence.sql` adds a basis-points integer column for the model's probability per row. Predictions in the uncertain band `[0.30, per-class threshold)` surface in a "Review uncertain ML guesses" Settings screen; the user's confirm-or-correct flips `category_assigned_by` to `'user'` and feeds the next training dump. The classic "model overfits to its own past mistakes" failure mode is closed by migration [`017_category_assignment_source.sql`](supabase/migrations/017_category_assignment_source.sql) — only `user`-sourced rows enter training data, never the model's own predictions.
- **Accuracy gate in the retraining script.** `eval.py --min-accuracy 0.70` exits non-zero on regression. The categorizer CI workflow runs this end-to-end (bootstrap seed → train → eval → parity test) so a model regression breaks CI, not production.

---

## Repository layout

```
my-budget-app/
├── .github/workflows/
│   ├── ci.yaml                      — format + analyze + test on push/PR
│   └── categorizer.yaml             — Python tests, train, eval gate, Dart
│                                      parity (only on ML-pipeline changes)
├── mobile/                          — Flutter app
│   ├── lib/
│   │   ├── core/                    — supabase client, theme, router, shared utils
│   │   └── features/                — feature modules (see below)
│   │       ├── auth/
│   │       ├── accounts/
│   │       ├── transactions/
│   │       ├── budget/
│   │       ├── scenarios/
│   │       ├── receipts/
│   │       ├── dashboard/
│   │       └── settings/
│   ├── test/
│   │   ├── ...                      — unit tests, run by default `flutter test`
│   │   └── integration/             — hit a local Supabase stack (env-gated)
│   ├── pubspec.yaml
│   └── CLAUDE.md                    — repo conventions for AI tooling
├── supabase/
│   ├── functions/
│   │   └── process-receipt-ocr/     — local stub mirroring the production
│   │                                  Edge Function's output shape
│   └── migrations/                  — numbered, idempotent, named after the bug they fix
├── tools/
│   └── categorizer/                 — Python pipeline that trains the on-device
│                                      ML categorizer (TF-IDF + Platt-calibrated
│                                      LogReg → ONNX). See its README for the workflow.
└── README.md
```

Each feature folder follows the same shape: `models/` (Freezed immutables), `providers/` (Riverpod, codegen), `repositories/` (data access), `screens/`, `widgets/`.

---

## Tech stack

**Mobile:** Flutter / Dart, Riverpod (codegen), GoRouter, Freezed, json_serializable, fl_chart, decimal, csv, flutter_secure_storage, local_auth, image_picker, onnxruntime.

**Backend:** Supabase — PostgreSQL with RLS, GoTrue auth, Storage with bucket-level policies, Edge Functions (TypeScript) for OCR.

**ML tooling:** scikit-learn + skl2onnx + onnxruntime (Python) for offline training; the resulting model runs on-device via the Dart `onnxruntime` package.

**External services:** Google Cloud Vision (OCR).

> The OCR Edge Function (`receipts.ocr_status: pending → complete`) is **deployed externally** for production — Google Cloud Vision is the upstream. For local development, this repo ships a stub function at [`supabase/functions/process-receipt-ocr/`](supabase/functions/process-receipt-ocr/) that mirrors the production output shape but generates synthetic line items instead of calling Vision. Run `supabase start` (see [CLAUDE.md](CLAUDE.md#local-test-stack)) and the stub deploys automatically.

---

## Getting started

### Prerequisites

- Flutter SDK 3.11+ (`flutter --version`)
- A Supabase project — free tier is fine

### Setup

```bash
# 1. Clone and install
git clone https://github.com/TitaniaAnn/my-budget-app.git
cd my-budget-app/mobile
flutter pub get

# 2. Configure Supabase credentials
#    Create mobile/.env.json (gitignored):
cat > .env.json <<'EOF'
{
  "SUPABASE_URL": "https://yourproject.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
EOF

# 3. Generate freezed / riverpod / json_serializable files
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run --dart-define-from-file=.env.json
```

### Database setup

Apply migrations in numeric order to a fresh Supabase project:

```bash
# Using the Supabase CLI:
supabase db push

# Or paste each file from supabase/migrations/ into the SQL editor in order.
```

Migrations are idempotent — re-running a migration that's already applied is a no-op, not an error.

### Android release build

Release signing requires `mobile/android/app/key.properties` (gitignored). Then:

```bash
flutter build appbundle --release --dart-define-from-file=.env.json
```

---

## Development

### Code generation

After modifying any file with `@freezed`, `@riverpod`, or `@JsonSerializable`, regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
# or, for live regeneration during a session:
dart run build_runner watch
```

### Conventions

- **Money is integer cents.** `$12.34` is `1234`. Never use `double` for money — use the `decimal` package for any conversion math. See `lib/core/utils/money.dart`.
- **Transactions:** negative amount = debit / expense, positive = credit / income.
- **Multi-tenancy:** every query must filter by `household_id`. RLS will catch you if you forget, but filter explicitly anyway.
- **Enum DB values:** use `@JsonValue('snake_case')` to map Dart enum variants to Postgres enum columns.
- **Theme:** Material 3 with a custom `AppColors` extension for semantic colors (`income`, `expense`, `success`, `textMuted`). Access via `Theme.of(context).extension<AppColors>()`.

### Lint, format, test

```bash
flutter format lib/ test/
flutter analyze
flutter test
```

CI runs all three on every push and PR — see [`.github/workflows/ci.yaml`](.github/workflows/ci.yaml). A second workflow, [`categorizer.yaml`](.github/workflows/categorizer.yaml), triggers on `tools/categorizer/**` or `mobile/assets/ml/**` and runs the Python pytest + a full bootstrap → train → eval (`--min-accuracy 0.70`) → Dart parity test pipeline, splitting Python install cost away from Dart-only PRs.

### Retraining the categorizer

The ML model is bundled as plain assets under `mobile/assets/ml/`, regenerated by the Python pipeline in [`tools/categorizer/`](tools/categorizer/). On a fresh clone those assets are empty — `MlCategoryClassifier.load()` returns null and the keyword matcher takes over, so nothing breaks before training has happened.

```bash
cd tools/categorizer
python -m venv .venv && . .venv/Scripts/activate   # or .venv/bin/activate
pip install -r requirements.txt

# Cold start: synthesise training data from the keyword rules.
python bootstrap_seed.py --out seed.csv

# Once you have real user-confirmed labels in Supabase, dump and concat:
python dump_labels.py --out labels.csv          # needs SUPABASE_SERVICE_KEY
cat seed.csv >> labels.csv                       # mix until real labels suffice

# Train + export the artefacts the app loads.
python train.py --in labels.csv --out-dir build/
python eval.py --in labels.csv --model build/category_model.onnx
cp build/*.{onnx,json} ../../mobile/assets/ml/
```

Once the assets land in `mobile/assets/ml/`, `flutter test` runs the parity check that was previously skipped, and the next app build picks up the new model.

---

## Testing

Three layers, each with a different trade-off between speed and what it can catch.

### Dart unit tests — `mobile/test/`

Mirror the feature structure under `lib/`. Cover the parts that are easy to break and expensive to get wrong:

- **`category_matcher_test.dart`** — rule precedence, case insensitivity, income/expense disambiguation, missing-category fallthrough, plus a regression that pins `"renters insurance"` to Home Insurance after a substring overlap with the `rent` keyword used to mis-categorise it as Rent / Mortgage.
- **`ml_category_classifier_test.dart`** — char_wb tokenisation hand-traced against sklearn's documented algorithm, plus a parity test that asserts byte-identical sparse vectors against a Python-generated fixture (auto-skipped on a fresh clone where `assets/ml/` is empty).
- **`categorizer_test.dart`** — façade routing (ML wins above threshold, falls through to keyword on low confidence / missing model / unknown category), per-class threshold behaviour (lower threshold lets a confident class auto-apply below the global default; higher threshold suppresses an otherwise-acceptable hit), the active-learning `categorizeWithUncertain` band, and `confidenceToBasisPoints` rounding.
- **`statement_parser_test.dart`** — CSV import: signed and split debit/credit columns, sign-inference precedence (credit keywords beat debit on overlap), Decimal-based cents conversion, dedup-key normalisation across casing/whitespace, two-digit-year pivot, accounting-paren negatives.
- **`historical_net_worth_test.dart`** — pure-function regression for the end-of-day balance walkback: `B_d = B_{prev} − D_{prev}`, including no-transaction days, future-dated rows, and positive-delta (income) cases.
- **`dashboard_data_test.dart`** — net-worth correctness across account types (regression test for the mortgage-as-asset bug), monthly aggregates, top-N category grouping, 30-day spending bucket placement.

Run them all:

```bash
cd mobile
flutter test
```

### Python pure-logic tests — `tools/categorizer/test_train.py`

Pin three things on the Python side so a future refactor doesn't have to wait for a Dart parity run to surface mistakes: `_amount_bucket` boundary behaviour, `render` field shape, and `compute_per_class_thresholds` (recall-boundary picking + rare-class / can't-reach-target fallbacks).

```bash
cd tools/categorizer
pip install -r requirements-dev.txt    # adds pytest on top of training deps
pytest
```

Wired into the [categorizer CI workflow](.github/workflows/categorizer.yaml) ahead of the heavier train+ONNX export steps so a pure-logic regression fails fast.

### Integration tests — `mobile/test/integration/`

Hit a real `supabase start` stack via [`_supabase_harness.dart`](mobile/test/integration/_supabase_harness.dart). What unit tests can't reach: SQL semantics (does the WHERE clause actually return the right rows?), RLS (does household isolation hold?), schema mismatches that would otherwise drift silently. Skipped by default — gated on env vars so vanilla `flutter test` runs aren't affected.

```bash
supabase start   # if not already running
cd mobile
flutter test \
  --dart-define=SUPABASE_TEST_URL=http://localhost:54421 \
  --dart-define=SUPABASE_TEST_ANON_KEY=<from `supabase status`> \
  test/integration/
```

Current coverage: `TransactionsRepository.setUserCategory`, `fetchUncertain` (filtering, ordering, custom bound, limit), and an explicit RLS-isolation test that pins household separation.

---

## Migration log highlights

The `supabase/migrations/` folder is a small case study in iterating on a live schema. A few worth reading the comments on:

| Migration                                   | Why it exists                                                                       |
| ------------------------------------------- | ----------------------------------------------------------------------------------- |
| `004_fix_household_members_rls.sql`         | RLS policy queried itself recursively (Postgres error 42P17). Fixed via `SECURITY DEFINER` helper. |
| `008_household_invites.sql`                 | Owner-issued 8-char codes, 7-day expiry, email-bound, with auto-cleanup of solo households on accept. |
| `015_recalculate_balance_function.sql`      | Atomicized a racy 3-trip balance recalc into a single RPC.                          |
| `016_rls_gaps.sql`                          | Filled "RLS enabled, no policies" gaps that were silently breaking features. Re-scoped a mis-named storage policy. |
| `017_category_assignment_source.sql`        | Added `category_assigned_by` enum + timestamp so the ML categorizer trains only on user-confirmed labels, never on its own past predictions. |
| `018_save_receipt_line_items_function.sql`  | Atomicized a delete-then-insert line-item replace that could leave a receipt with zero items if the insert half failed — same shape of bug as 015. |
| `019_receipt_match_candidates.sql`          | RPC that ranks plausible transactions for a receipt by combined date+amount proximity, so the pair sheet ships only the top N rows over the wire and excludes already-paired transactions. |
| `020_transaction_tags.sql`                  | Tags as a second dimension orthogonal to categories. Two assignment tables (transactions and receipt line items) so a Costco run can be tagged at whichever granularity reflects the truth. |
| `021_get_category_spending_function.sql`    | Server-side `GROUP BY category_id, SUM(amount)` so the budget screen ships one row per category instead of every transaction in the range. RLS still applies — the RPC runs as the caller. |
| `022_ml_model_confidence.sql`               | Basis-points INTEGER column for the model's top-class probability, plus a partial index on uncertain ML rows. Backs the active-learning Review surface; basis points keep the cents-everywhere INTEGER invariant intact. |
| `023_fix_account_visibility_grants_rls_recursion.sql` | RLS recursion between `accounts` and `account_visibility_grants` (Postgres error 42P17). Same shape of bug as 004; fixed via a new `account_household_id()` `SECURITY DEFINER` helper that resolves the relationship without re-entering the user's RLS path. Surfaced by the integration suite. |

---

## License

MIT — see [LICENSE](LICENSE).

---

## Acknowledgements

Built solo by [Cynthia Brown](https://cynthia-brown.com).
