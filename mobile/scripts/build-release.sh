#!/usr/bin/env bash
# Release build wrapper for the mobile app.
#
# Refuses to start a release build until .env.json points at the
# PRODUCTION Supabase project (https://<ref>.supabase.co). Without
# this guard a dev who had .env.json pointing at the local stack
# (127.0.0.1:54421) and then ran `flutter build appbundle` would
# ship an .aab that tries to talk to localhost — silently broken on
# every device that isn't the dev's laptop.
#
# Usage (from anywhere; resolves paths relative to its own dir):
#   ./scripts/build-release.sh android    # bundleRelease -> .aab
#   ./scripts/build-release.sh windows    # windows --release
#   ./scripts/build-release.sh all        # both
#
# Validation is intentionally strict: SUPABASE_URL must be
# https://<something>.supabase.co (not http, not an IP, not a
# localhost variant). The anon key must be non-empty.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$MOBILE_DIR/.env.json"

target="${1:-}"
if [[ -z "$target" || ! "$target" =~ ^(android|windows|all)$ ]]; then
  echo "usage: $0 {android|windows|all}" >&2
  exit 64
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: $ENV_FILE not found." >&2
  echo "       Copy .env.json.example (if present) and fill it in," >&2
  echo "       or set SUPABASE_URL + SUPABASE_ANON_KEY for the" >&2
  echo "       production project before running this script." >&2
  exit 1
fi

# Pull the two values out of .env.json with minimal regex parsing
# so we don't need jq as a dependency. Tolerates whitespace + the
# usual JSON formatting variations the user's editor will produce.
extract() {
  local key="$1"
  python -c "
import json, sys
with open(sys.argv[1]) as f:
    print(json.load(f).get(sys.argv[2], ''))
" "$ENV_FILE" "$key"
}

SUPABASE_URL="$(extract SUPABASE_URL)"
SUPABASE_ANON_KEY="$(extract SUPABASE_ANON_KEY)"

# Production guard — the whole point of this script.
if [[ ! "$SUPABASE_URL" =~ ^https://[a-z0-9-]+\.supabase\.co/?$ ]]; then
  echo "error: SUPABASE_URL does not look like a production Supabase URL." >&2
  echo "       Got:      $SUPABASE_URL" >&2
  echo "       Expected: https://<project-ref>.supabase.co" >&2
  echo >&2
  echo "       Release builds must point at the production project on" >&2
  echo "       supabase.com — never localhost or the local CLI stack." >&2
  exit 2
fi
if [[ -z "$SUPABASE_ANON_KEY" ]]; then
  echo "error: SUPABASE_ANON_KEY is empty in $ENV_FILE." >&2
  exit 2
fi

echo "Building against: $SUPABASE_URL"

build_android() {
  echo
  echo "==> flutter build appbundle --release"
  (cd "$MOBILE_DIR" && flutter build appbundle --release \
    --dart-define-from-file=.env.json)
  local out="$MOBILE_DIR/build/app/outputs/bundle/release/app-release.aab"
  if [[ -f "$out" ]]; then
    echo "    -> $out"
  fi
}

build_windows() {
  echo
  echo "==> flutter build windows --release"
  (cd "$MOBILE_DIR" && flutter build windows --release \
    --dart-define-from-file=.env.json)
  local out="$MOBILE_DIR/build/windows/x64/runner/Release/mybudget.exe"
  if [[ -f "$out" ]]; then
    echo "    -> $out (+ runtime DLLs + data/ in the same folder)"
  fi
}

case "$target" in
  android) build_android ;;
  windows) build_windows ;;
  all)
    build_android
    build_windows
    ;;
esac

echo
echo "Done."
