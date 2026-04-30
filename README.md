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
└── README.md
```

Each feature folder follows the same shape: `models/` (Freezed immutables), `providers/` (Riverpod, codegen), `repositories/` (data access), `screens/`, `widgets/`.

---

## Tech stack

**Mobile:** Flutter / Dart, Riverpod (codegen), GoRouter, Freezed, json_serializable, fl_chart, decimal, csv, flutter_secure_storage, local_auth, image_picker.

**Backend:** Supabase — PostgreSQL with RLS, GoTrue auth, Storage with bucket-level policies, Edge Functions (TypeScript) for OCR.

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

---

## Testing

Unit tests live in `mobile/test/`, mirroring the feature structure under `lib/`. Coverage focuses on the parts that are easy to break and expensive to get wrong:

- **`category_matcher_test.dart`** — rule precedence, case insensitivity, income/expense disambiguation, missing-category fallthrough.
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

---

## License

MIT — see [LICENSE](LICENSE).

---

## Acknowledgements

Built solo by [Cynthia Brown](https://cynthia-brown.com).
