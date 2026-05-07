// Supabase integration-test harness.
//
// Spins up a fresh test user (and the household auto-created by the
// `handle_new_user` trigger from migration 003), exposes helpers for
// inserting fixture rows, and tears the household down at the end so
// repeated test runs don't pile up data.
//
// Required env (passed via --dart-define):
//   SUPABASE_TEST_URL       — e.g. http://localhost:54421
//   SUPABASE_TEST_ANON_KEY  — from `supabase status` ("Publishable" or
//                             "anon" depending on CLI version)
//
// When either env is missing, [Harness.envConfigured] is false and tests
// using this harness should skip themselves with `skip: ...` or an early
// return — that keeps default `flutter test` runs (which never set these
// envs) green.

import 'dart:io' show HttpOverrides;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Harness {
  Harness._({
    required this.client,
    required this.userId,
    required this.householdId,
    required this.email,
    required this.accountId,
  });

  final SupabaseClient client;
  final String userId;
  final String householdId;
  final String email;

  /// One pre-seeded account inside the test household. Most tests need
  /// at least one account because transactions FK to accounts.
  final String accountId;

  static const _url = String.fromEnvironment('SUPABASE_TEST_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_TEST_ANON_KEY');

  /// True when both env vars are present. Test files should gate their
  /// `setUpAll` and individual tests on this so a vanilla `flutter test`
  /// run skips them cleanly.
  static bool get envConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;

  static bool _initialized = false;

  /// Idempotent global Supabase init. Multiple test files share one
  /// SupabaseClient instance — `Supabase.initialize` throws on a second
  /// call, so we guard.
  ///
  /// `Supabase.initialize` constructs a `SharedPreferencesGotrueAsyncStorage`
  /// for PKCE state by default, which fails in the `flutter test` VM
  /// because the shared_preferences plugin isn't registered. We
  /// explicitly pass an in-memory `pkceAsyncStorage` AND the SDK's
  /// own `EmptyLocalStorage` (for session persistence) so init runs
  /// without touching platform channels. Every test run signs in fresh
  /// anyway, so neither persistence layer matters.
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    // Supabase.initialize uses WidgetsBinding.instance to register a
    // lifecycle observer; the test runner doesn't auto-initialize that.
    TestWidgetsFlutterBinding.ensureInitialized();
    // TestWidgetsFlutterBinding installs an HttpOverrides that blocks
    // real network calls (every request returns 400). For these
    // integration tests we explicitly want real network — clearing
    // the override restores the default HttpClient. Other tests that
    // run later in the same VM aren't affected because they don't
    // make HTTP calls.
    HttpOverrides.global = null;
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _InMemoryPkceStorage(),
      ),
    );
    _initialized = true;
  }

  /// Signs up a fresh test user and resolves the household and account
  /// fixtures the rest of the suite hangs off. Each call gets a unique
  /// email so concurrent runs don't collide.
  static Future<Harness> bootstrap({String? testTag}) async {
    if (!envConfigured) {
      throw StateError(
        'Harness.bootstrap called without SUPABASE_TEST_URL / '
        'SUPABASE_TEST_ANON_KEY. Gate your tests on '
        '`Harness.envConfigured`.',
      );
    }
    await _ensureInitialized();
    final client = Supabase.instance.client;

    // Fresh email per call so reruns don't collide in auth.users.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tag = testTag == null ? '' : '-$testTag';
    final email = 'mybudget-test$tag-$stamp@example.test';
    const password = 'test-password-12345';

    final signUp = await client.auth.signUp(
      email: email,
      password: password,
      data: const {
        'display_name': 'Test User',
        'household_name': 'Test Household',
      },
    );
    final user =
        signUp.user ??
        (await client.auth.signInWithPassword(
          email: email,
          password: password,
        )).user;
    if (user == null) {
      throw StateError('signUp returned no user; auth misconfigured?');
    }

    // The handle_new_user trigger (migration 003) auto-creates a
    // household and adds the user as owner. Look it up.
    final memberRow = await client
        .from('household_members')
        .select('household_id')
        .eq('user_id', user.id)
        .single();
    final householdId = memberRow['household_id'] as String;

    // Pre-seed one checking account so tests can insert transactions
    // without each test repeating the FK setup.
    final account = await client
        .from('accounts')
        .insert({
          'household_id': householdId,
          'owner_user_id': user.id,
          'name': 'Test Checking',
          'account_type': 'checking',
          'currency': 'USD',
          'starting_balance': 0,
          'current_balance': 0,
        })
        .select('id')
        .single();
    final accountId = account['id'] as String;

    return Harness._(
      client: client,
      userId: user.id,
      householdId: householdId,
      email: email,
      accountId: accountId,
    );
  }

  /// Inserts a transaction row inside this harness's household. Returns
  /// the new row's id. Defaults align with the most common test shape:
  /// $10 debit on the seeded account today.
  Future<String> insertTransaction({
    int amountCents = -1000,
    String description = 'TEST TXN',
    String? categoryId,
    String? categoryAssignedBy,
    int? mlModelConfidence,
    DateTime? transactionDate,
  }) async {
    final row = await client
        .from('transactions')
        .insert({
          'household_id': householdId,
          'account_id': accountId,
          'entered_by': userId,
          'amount': amountCents,
          'currency': 'USD',
          'description': description,
          'transaction_date': (transactionDate ?? DateTime.now())
              .toIso8601String()
              .substring(0, 10),
          'pending': false,
          'source': 'manual',
          'category_id': ?categoryId,
          'category_assigned_by': ?categoryAssignedBy,
          'ml_model_confidence': ?mlModelConfidence,
          // Tied to the same nullness as category_assigned_by, not a
          // direct ?-eligible value (the timestamp itself is non-null).
          if (categoryAssignedBy != null)
            'category_assigned_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Returns the id of an arbitrary system category (`household_id IS
  /// NULL`). Tests that just need *a* category id without caring which
  /// one use this; tests that need a specific category by name should
  /// fetch by name directly.
  Future<String> aSystemCategoryId() async {
    final row = await client
        .from('categories')
        .select('id')
        .isFilter('household_id', null)
        .limit(1)
        .single();
    return row['id'] as String;
  }

  /// Returns a system category id by name. Throws if the category
  /// doesn't exist (the seed in migration 002 should cover the common
  /// names — Groceries, Coffee & Drinks, etc.).
  Future<String> systemCategoryIdByName(String name) async {
    final row = await client
        .from('categories')
        .select('id')
        .eq('name', name)
        .isFilter('household_id', null)
        .single();
    return row['id'] as String;
  }

  /// Tears the test household down. Cascades through accounts,
  /// transactions, categories. Best-effort — a failed cleanup logs but
  /// doesn't fail the test (the unique-email guarantee already prevents
  /// data collisions across runs).
  Future<void> dispose() async {
    try {
      await client.from('households').delete().eq('id', householdId);
    } catch (_) {
      // Cleanup failure is acceptable; unique emails per-run mean stale
      // rows don't break the next run.
    }
    try {
      await client.auth.signOut();
    } catch (_) {}
  }
}

/// In-memory replacement for `SharedPreferencesGotrueAsyncStorage`.
/// PKCE state lives only for the duration of the test process — sign-in
/// happens within a single test run, so persistence isn't useful.
class _InMemoryPkceStorage extends GotrueAsyncStorage {
  final _map = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _map[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _map[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _map.remove(key);
  }
}
