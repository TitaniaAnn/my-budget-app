# CLAUDE.md (mobile)

Mobile-specific guidance for working in the Flutter app. **The root
[`CLAUDE.md`](../CLAUDE.md) is the authoritative source for
cross-cutting context** — multi-currency / FX, notifications,
transfers, OCR, RLS conventions, the recurring scheduler, the
integration-test harness, and the migration log all live there.
This file covers only what's specific to the `mobile/` directory.

## Commands

```bash
# Install dependencies
flutter pub get

# Run app (requires .env.json with Supabase credentials)
flutter run --dart-define-from-file=.env.json

# Code generation (freezed, riverpod, json_serializable) — run after model changes
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch

# Lint and format
flutter analyze
dart format lib/ test/

# Run tests (unit + widget). Integration tests are gated on env;
# see root CLAUDE.md for the local-Supabase test recipe.
flutter test

# Build release — wrapper that refuses to run unless .env.json
# points at the production Supabase project on supabase.com.
# Prevents a stray localhost URL from shipping in an .aab. The
# bash + PowerShell variants do the same thing; pick by host.
./scripts/build-release.sh android   # or windows / all
.\scripts\build-release.ps1 android  # PowerShell sibling
```

## Architecture

Feature-based modular structure. Each feature lives in `lib/features/<name>/` with consistent subdirectories: `models/`, `providers/`, `repositories/`, `screens/`, `widgets/`. Shared app-wide code lives in `lib/core/`.

**State management**: Riverpod with code generation (`@riverpod` annotations). Providers are defined per-feature; repositories are singletons injected via Riverpod. Use `ConsumerWidget` for read-only, `ConsumerStatefulWidget` when local state + Riverpod are both needed.

**Backend access**: Supabase via `lib/core/supabase/supabase_client.dart`. All data is scoped to `household_id`; every query must include this filter, and RLS does the real gating server-side.

**Routing**: GoRouter with auth-aware redirects in `lib/core/router/app_router.dart`. Authenticated screens are wrapped in a `ShellRoute` with `MainScaffold` (bottom nav). Navigate with `context.go()` / `context.push()`.

**Models**: Freezed + json_serializable. All models are immutable with `copyWith`. Enum values use `@JsonValue` to map to DB snake_case strings. Generated files are `*.freezed.dart` and `*.g.dart` — do not edit these manually.

## Key conventions

These are the ones a code change in `mobile/` is likely to trip over. The root CLAUDE.md goes deeper on each.

- **Money is always integer cents**. Use `lib/core/utils/money.dart` for formatting/parsing. Never use `double` for monetary values — use the `decimal` package for conversions.
- **Transactions**: negative amount = debit/expense, positive = credit/income.
- **Theme**: Material3 with a custom `AppColors` extension for semantic colors (`income`, `expense`, `success`, `textMuted`). Access via `Theme.of(context).extension<AppColors>()`.
- **Enums with DB values**: `@JsonValue('snake_case')` on every variant to match Supabase column values. If you add an enum variant in SQL, mirror it here.
- **TIMESTAMPTZ writes use `.toUtc().toIso8601String()`**. A bare `.toIso8601String()` on a local-zone `DateTime` produces a timezone-naive string Postgres interprets as UTC, silently shifting the stored time by the host's offset. Repository methods that touch `category_assigned_at` / `created_at`-style columns must `.toUtc()` first. The same applies to any `DateTime` serialized to a string for SharedPreferences/cross-device sync (audit M4 caught one such site in the notifications dedup map).
- **Budget comparison uses `BudgetWithSpending.capCents`, not `budget.amount`**. In a multi-currency household, two budgets with the same `amount` value can have wildly different `capCents` after FX conversion. Sorting / threshold comparisons on raw `amount` give wrong results. Audit M1 caught two violations.

## Environment

The app requires a `.env.json` file at the project root (not committed):

```json
{
  "SUPABASE_URL": "https://yourproject.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

Android release signing requires `android/app/key.properties` (not committed). The build script stashes a placeholder version of this file when present so unsigned debug builds still work.

## Code generation

After modifying any file with `@freezed`, `@riverpod`, or `@JsonSerializable` annotations, re-run `build_runner` to regenerate the associated `.freezed.dart` / `.g.dart` files. The generated files ARE committed to the repo — CI doesn't regenerate them, so a missed run will surface as a "redirected constructor has incompatible parameters" error or missing-symbol failures rather than a clean regeneration on the next build.
