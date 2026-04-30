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

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  // ONNX Runtime is a singleton — must be initialised before any
  // OrtSession is constructed. Safe to call even when the ML model
  // assets are absent; MlCategoryClassifier.load() handles that.
  OrtEnv.instance.init();

  // ProviderScope is required at the root so all Riverpod providers are
  // accessible anywhere in the widget tree.
  runApp(const ProviderScope(child: MyBudgetApp()));
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
