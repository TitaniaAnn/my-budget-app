# mobile/

Flutter client for MyBudget. Connects directly to Supabase via
`supabase_flutter`; no separate server/ORM layer. Architecture,
schema, RLS rules, OCR pipeline, recurring scheduler, FX/multi-
currency, notifications, transfers, offline cache, and the L1
phased rollout are all documented in the [root CLAUDE.md](../CLAUDE.md)
and [mobile/CLAUDE.md](CLAUDE.md). Start there.

## Run

`.env.json` (not committed) at the project root:

```json
{
  "SUPABASE_URL": "http://localhost:54421",
  "SUPABASE_ANON_KEY": "<anon key from `supabase status`>"
}
```

Then:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=.env.json
```

The build_runner step is required after any change to a freezed
model, riverpod_annotation provider, or json_serializable class.
CI does not regenerate the `.g.dart` / `.freezed.dart` files —
they're committed.

## Test

```bash
# Unit + widget tests (the harness skips integration tests when
# SUPABASE_TEST_* env vars are unset)
flutter test

# Integration tests against a running local Supabase stack
flutter test \
  --dart-define=SUPABASE_TEST_URL=http://localhost:54421 \
  --dart-define=SUPABASE_TEST_ANON_KEY=<from `supabase status`> \
  test/integration/
```

## Release

Wrapper scripts refuse to build unless `.env.json` points at the
production Supabase project (prevents a stray localhost URL
shipping in an .aab):

```bash
./scripts/build-release.sh android   # or windows / all
.\scripts\build-release.ps1 android  # PowerShell sibling
```

Android signing requires `android/app/key.properties` (not
committed); the script stashes a placeholder when missing so
debug builds still work.
