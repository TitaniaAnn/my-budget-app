// Entry point for MyBudget. Initializes Supabase, then hands routing
// and theming to MaterialApp.router via Riverpod providers.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// These constants are injected at build time via --dart-define-from-file=.env.json.
// They compile to empty strings if the flag is omitted, which the assert below catches.
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fail fast in debug mode if the env file wasn't passed to the build.
  assert(
    _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty,
    'Missing Supabase credentials. Run with --dart-define-from-file=.env.json',
  );

  // Audit C4: pre-fix `Supabase.initialize` was un-wrapped. On
  // captive-portal Wi-Fi, airplane mode, or DNS hijack at launch
  // it threw before runApp and the user saw a blank window — no
  // error message, no retry, no offline indicator. Wrap and
  // surface a retry screen.
  //
  // Supabase.initialize is idempotent (the SDK short-circuits on
  // _isInitialized), so the retry simply calls main() again. On
  // success the second pass takes the fast path through init and
  // proceeds to runApp normally.
  try {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  } catch (e) {
    runApp(_InitErrorApp(error: e, onRetry: main));
    return;
  }

  // ONNX Runtime is a singleton — must be initialised before any
  // OrtSession is constructed. Safe to call even when the ML model
  // assets are absent; MlCategoryClassifier.load() handles that.
  OrtEnv.instance.init();

  // ProviderScope is required at the root so all Riverpod providers are
  // accessible anywhere in the widget tree.
  runApp(const ProviderScope(child: MyBudgetApp()));
}

/// Standalone MaterialApp shown when Supabase init throws at launch.
/// Themed minimally so it works without any providers (we haven't
/// mounted ProviderScope yet on the failing path).
class _InitErrorApp extends StatelessWidget {
  const _InitErrorApp({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyBudget',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    "Couldn't connect to the backend",
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check your network connection and try again. If you '
                    'just launched the app on captive-portal Wi-Fi, sign '
                    'into the portal first.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Root widget. Watches [appRouterProvider] so the router is rebuilt
/// whenever auth state changes (login/logout triggers a redirect).
class MyBudgetApp extends ConsumerWidget {
  const MyBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

    return MaterialApp.router(
      title: 'MyBudget',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
