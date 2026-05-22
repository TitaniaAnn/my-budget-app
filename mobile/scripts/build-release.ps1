# Release build wrapper for the mobile app (PowerShell variant —
# see build-release.sh for the bash version with the same logic).
#
# Refuses to start a release build until .env.json points at the
# PRODUCTION Supabase project (https://<ref>.supabase.co). Without
# this guard a dev who had .env.json pointing at the local stack
# (127.0.0.1:54421) and then ran `flutter build appbundle` would
# ship an .aab that tries to talk to localhost — silently broken on
# every device that isn't the dev's laptop.
#
# Usage (from anywhere):
#   .\scripts\build-release.ps1 android    # bundleRelease -> .aab
#   .\scripts\build-release.ps1 windows    # windows --release
#   .\scripts\build-release.ps1 all        # both

param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('android', 'windows', 'all')]
    [string]$Target
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MobileDir = Resolve-Path (Join-Path $ScriptDir '..')
$EnvFile = Join-Path $MobileDir '.env.json'

if (-not (Test-Path $EnvFile)) {
    Write-Error @"
$EnvFile not found.
Copy .env.json.example (if present) and fill it in, or set
SUPABASE_URL + SUPABASE_ANON_KEY for the production project
before running this script.
"@
    exit 1
}

$env = Get-Content $EnvFile -Raw | ConvertFrom-Json
$SupabaseUrl = $env.SUPABASE_URL
$SupabaseAnonKey = $env.SUPABASE_ANON_KEY

# Production guard — the whole point of this script.
if (-not ($SupabaseUrl -match '^https://[a-z0-9-]+\.supabase\.co/?$')) {
    Write-Error @"
SUPABASE_URL does not look like a production Supabase URL.
Got:      $SupabaseUrl
Expected: https://<project-ref>.supabase.co

Release builds must point at the production project on
supabase.com — never localhost or the local CLI stack.
"@
    exit 2
}
if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
    Write-Error "SUPABASE_ANON_KEY is empty in $EnvFile."
    exit 2
}

Write-Host "Building against: $SupabaseUrl"

function Build-Android {
    Write-Host ""
    Write-Host "==> flutter build appbundle --release"
    Push-Location $MobileDir
    try {
        flutter build appbundle --release --dart-define-from-file=.env.json
        if ($LASTEXITCODE -ne 0) { throw "flutter build appbundle failed" }
    } finally {
        Pop-Location
    }
    $out = Join-Path $MobileDir 'build\app\outputs\bundle\release\app-release.aab'
    if (Test-Path $out) {
        Write-Host "    -> $out"
    }
}

function Build-Windows {
    Write-Host ""
    Write-Host "==> flutter build windows --release"
    Push-Location $MobileDir
    try {
        flutter build windows --release --dart-define-from-file=.env.json
        if ($LASTEXITCODE -ne 0) { throw "flutter build windows failed" }
    } finally {
        Pop-Location
    }
    $out = Join-Path $MobileDir 'build\windows\x64\runner\Release\mybudget.exe'
    if (Test-Path $out) {
        Write-Host "    -> $out (+ runtime DLLs + data/ in the same folder)"
    }
}

switch ($Target) {
    'android' { Build-Android }
    'windows' { Build-Windows }
    'all'     { Build-Android; Build-Windows }
}

Write-Host ""
Write-Host "Done."
