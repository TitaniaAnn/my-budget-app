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
- **Auto-categorization** of transactions via an on-device ML model (TF-IDF + LogisticRegression, ONNX), with the legacy keyword matcher kept as a cold-start fallback. Predictions never leave the device.
- **Receipts** uploaded to private Storage, line-itemized via OCR (Supabase Edge Function → Google Cloud Vision).
- **Budgets** with weekly / monthly / annual periods and live progress against actual spending.
- **Scenarios & goals** — what-if planning with iCal RRULE recurring events, parent-branching for alternatives, and `is_goal` overlay for target-date savings tracking. Projection runs forward from current net worth; historical net worth is reconstructed by walking transaction deltas backward.

---

## Highlights

The bits that took the most thought, in case you're skimming the repo to see how it's built:

**Row-level security, debugged in production.** Every table is RLS-enforced; access is gated through a `SECURITY DEFINER` `get_household_role()` helper that itself sidesteps recursion. Migration `004_fix_household_members_rls.sql` fixes an infinite-recursion bug in a self-referencing policy. Migration `016_rls_gaps.sql` fills "deny-everything" gaps where RLS was enabled with no policies — silently breaking features. Both migrations name the bug they fix.

**Atomic balance recalculation.** [`015_recalculate_balance_function.sql`](supabase/migrations/015_recalculate_balance_function.sql) replaces a racy three-roundtrip Dart recalc (read starting balance → read transactions → write back) with a single SQL `UPDATE … RETURNING` callable via PostgREST RPC. The migration comment names the race condition.

**Money is integer cents, end-to-end.** No `double` for currency anywhere. Net worth is the plain signed sum of `current_balance` across all accounts — credit cards and mortgages stored as negative, so debt subtracts naturally. Pinned by regression tests in [`test/features/dashboard/dashboard_data_test.dart`](mobile/test/features/dashboard/dashboard_data_test.dart) after a bug where mortgages were counted as assets.

**CSV statement import** with `UNIQUE(account_id, external_id)` server-side dedup, heuristic column detection across bank export formats, async file I/O so a multi-MB statement doesn't freeze the UI thread, and sign inference from descriptions for banks that export all amounts as positive.

**Scenario engine** with iCal RRULE recurring events, `parent_id` for branching what-ifs, weekly chart sampling for performance, and shared primitives between planning scenarios and savings goals via an `is_goal` flag.

**Storage security via path convention.** Receipt images live in a private bucket at `{household_id}/{uuid}.jpg`; RLS policies parse the household ID out of the path to scope access.

**On-device categorizer with honest provenance.** Transaction categorization is a sklearn TF-IDF (`char_wb`, n-grams 3–5) + LogisticRegression model trained in [`tools/categorizer/`](tools/categorizer/), exported via skl2onnx, and run client-side via [`onnxruntime`](https://pub.dev/packages/onnxruntime) — descriptions never leave the device. The Dart-side TF-IDF transform is a byte-for-byte port of sklearn's `char_wb` analyser, gated by a parity test ([`ml_category_classifier_test.dart`](mobile/test/features/transactions/ml_category_classifier_test.dart)) that asserts identical sparse vectors against a Python-generated fixture. A [`Categorizer` façade](mobile/lib/features/transactions/services/categorizer.dart) tries the model first, falls through to the keyword matcher when confidence < 0.55 or the predicted category isn't in the household's list — so cold-start households (no model assets, no labels yet) keep working unchanged. Migration [`017_category_assignment_source.sql`](supabase/migrations/017_category_assignment_source.sql) adds a `category_assigned_by` enum (`user` / `keyword_matcher` / `ml_model`) so the model is only ever retrained on user-confirmed labels — preventing the classic "model overfits to its own past mistakes" failure mode.

---

## Repository layout

```
my-budget-app/
├── .github/workflows/
│   └── ci.yml                       — analyze + test on push/PR
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
│   ├── test/                        — unit tests for matchers, derived data, money math
│   ├── pubspec.yaml
│   └── CLAUDE.md                    — repo conventions for AI tooling
├── supabase/
│   └── migrations/                  — numbered, idempotent, named after the bug they fix
├── tools/
│   └── categorizer/                 — Python pipeline that trains the on-device
│                                      ML categorizer (TF-IDF + LogisticRegression
│                                      → ONNX). See its README for the workflow.
└── README.md
```

Each feature folder follows the same shape: `models/` (Freezed immutables), `providers/` (Riverpod, codegen), `repositories/` (data access), `screens/`, `widgets/`.

---

## Tech stack

**Mobile:** Flutter / Dart, Riverpod (codegen), GoRouter, Freezed, json_serializable, fl_chart, decimal, csv, flutter_secure_storage, local_auth, image_picker, onnxruntime.

**Backend:** Supabase — PostgreSQL with RLS, GoTrue auth, Storage with bucket-level policies, Edge Functions (TypeScript) for OCR.

**ML tooling:** scikit-learn + skl2onnx + onnxruntime (Python) for offline training; the resulting model runs on-device via the Dart `onnxruntime` package.

**External services:** Google Cloud Vision (OCR).

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

CI runs all three on every push and PR — see [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

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

Unit tests live in `mobile/test/`, mirroring the feature structure under `lib/`. Coverage focuses on the parts that are easy to break and expensive to get wrong:

- **`category_matcher_test.dart`** — rule precedence, case insensitivity, income/expense disambiguation, missing-category fallthrough (still load-bearing as the keyword fallback for the categorizer).
- **`ml_category_classifier_test.dart`** — char_wb tokenisation hand-traced against sklearn's documented algorithm, plus a parity test that asserts byte-identical sparse vectors against a Python-generated fixture (auto-skipped on a fresh clone where `assets/ml/` is empty).
- **`categorizer_test.dart`** — façade routing: ML hits above threshold win, fall through to the keyword matcher otherwise (low confidence, no model loaded, predicted category absent from the household's list).
- **`dashboard_data_test.dart`** — net-worth correctness across account types (regression test for the mortgage-as-asset bug), monthly aggregates, top-N category grouping, 30-day spending bucket placement.

Run them all:

```bash
cd mobile
flutter test
```

---

## Migration log highlights

The `supabase/migrations/` folder is a small case study in iterating on a live schema. A few worth reading the comments on:

| Migration                              | Why it exists                                                                       |
| -------------------------------------- | ----------------------------------------------------------------------------------- |
| `004_fix_household_members_rls.sql`    | RLS policy queried itself recursively (Postgres error 42P17). Fixed via `SECURITY DEFINER` helper. |
| `008_household_invites.sql`            | Owner-issued 8-char codes, 7-day expiry, email-bound, with auto-cleanup of solo households on accept. |
| `015_recalculate_balance_function.sql` | Atomicized a racy 3-trip balance recalc into a single RPC.                          |
| `016_rls_gaps.sql`                     | Filled "RLS enabled, no policies" gaps that were silently breaking features. Re-scoped a mis-named storage policy. |
| `017_category_assignment_source.sql`   | Added `category_assigned_by` enum + timestamp so the ML categorizer trains only on user-confirmed labels, never on its own past predictions. |

---

## License

MIT — see [LICENSE](LICENSE).

---

## Acknowledgements

Built solo by [Cynthia Brown](https://cynthia-brown.com).
