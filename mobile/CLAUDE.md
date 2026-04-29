# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
flutter format lib/ test/

# Run tests
flutter test

# Build release
flutter build appbundle --release --dart-define-from-file=.env.json
```

## Architecture

Feature-based modular architecture. Each feature lives in `lib/features/<name>/` with consistent subdirectories: `models/`, `providers/`, `repositories/`, `screens/`, `widgets/`. Shared app-wide code lives in `lib/core/`.

**State management**: Riverpod with code generation (`@riverpod` annotations). Providers are defined per-feature; repositories are singletons injected via Riverpod. Use `ConsumerWidget` for read-only, `ConsumerStatefulWidget` when local state + Riverpod are both needed.

**Backend**: Supabase (auth, database, storage). The singleton client is accessed via `lib/core/supabase/supabase_client.dart`. All data is scoped to `household_id` for multi-family isolation — every query must include this filter.

**Routing**: GoRouter with auth-aware redirects in `lib/core/router/app_router.dart`. Authenticated screens are wrapped in a `ShellRoute` with `MainScaffold` (bottom nav). Navigate with `context.go()` / `context.push()`.

**Models**: Freezed + json_serializable. All models are immutable with `copyWith`. Enum values use `@JsonValue` to map to DB snake_case strings. Generated files are `*.freezed.dart` and `*.g.dart` — do not edit these manually.

## Key Conventions

- **Money is always integer cents** (e.g., $12.34 = 1234). Use `lib/core/utils/money.dart` for formatting/parsing. Never use `double` for monetary values — use the `decimal` package for conversions.
- **Transactions**: negative amount = debit/expense, positive = credit/income.
- **Theme**: Material3 with custom `AppColors` extension for semantic colors (`income`, `expense`, `success`, `textMuted`). Access via `Theme.of(context).extension<AppColors>()`.
- **Enums with DB values**: Use `@JsonValue('snake_case')` on enum variants to match Supabase column values.

## Environment

The app requires a `.env.json` file at the project root (not committed):
```json
{
  "SUPABASE_URL": "https://yourproject.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key-here"
}
```

Android release signing requires `android/app/key.properties` (not committed).

## Code Generation Note

After modifying any file with `@freezed`, `@riverpod`, or `@JsonSerializable` annotations, you must re-run `build_runner` to regenerate the associated `.freezed.dart` or `.g.dart` files. The generated files are committed to the repo.
