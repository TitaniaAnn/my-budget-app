import 'package:flutter/material.dart';

/// Semantic brand colors that don't change between light and dark themes.
///
/// These are intentionally `static const` so they can be used inside
/// `const TextStyle(...)` and `const BoxDecoration(...)` without forcing
/// callers to remove the `const` keyword. Surface/border/text colors live
/// in [AppColors] (theme extension) or the Material [ColorScheme] instead.
class BrandColors {
  BrandColors._();

  // Semantic palette — same in both themes.
  static const primary = Color(0xFF3B82F6); // blue-500
  static const expense = Color(0xFFEF4444); // red-500
  static const income = Color(0xFF22C55E); // green-500
  static const warning = Color(0xFFF59E0B); // amber-500
  static const accent = Color(0xFF6366F1); // indigo-500
}

/// Theme-aware tokens that aren't covered by Material's [ColorScheme].
///
/// Access via `Theme.of(context).extension<AppColors>()!` or, more
/// concisely, `context.appColors` (see [AppColorsContext] below).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.income,
    required this.expense,
    required this.textMuted,
    required this.textSubtle,
    required this.surfaceDeep,
    required this.surfaceRaised,
    required this.gradientStart,
    required this.gradientEnd,
  });

  /// Used for "you saved", "on track", confirmation banners.
  final Color success;

  /// Used for "approaching limit", warning banners.
  final Color warning;

  /// Used for income amounts, deposits, positive deltas.
  final Color income;

  /// Used for expense amounts, debt totals, over-budget badges.
  final Color expense;

  /// Lower-emphasis labels (e.g. "of $500" under a budget bar).
  final Color textMuted;

  /// Even lower emphasis (timestamps in lists, empty-state hints).
  final Color textSubtle;

  /// Page-level background that sits behind raised surfaces. In dark mode
  /// this is the slate-900 scaffold; in light mode it's a pale grey.
  final Color surfaceDeep;

  /// Cards and bottom sheets rest on top of [surfaceDeep].
  final Color surfaceRaised;

  /// Gradient endpoints used by the Net Worth hero card on the dashboard.
  final Color gradientStart;
  final Color gradientEnd;

  static const _dark = AppColors(
    success: BrandColors.income,
    warning: BrandColors.warning,
    income: BrandColors.income,
    expense: BrandColors.expense,
    textMuted: Color(0xFF94A3B8), // slate-400
    textSubtle: Color(0xFF64748B), // slate-500
    surfaceDeep: Color(0xFF0F172A), // slate-900
    surfaceRaised: Color(0xFF1E293B), // slate-800
    gradientStart: Color(0xFF1E3A5F),
    gradientEnd: Color(0xFF1E293B),
  );

  static const _light = AppColors(
    success: BrandColors.income,
    warning: BrandColors.warning,
    income: BrandColors.income,
    expense: BrandColors.expense,
    textMuted: Color(0xFF64748B), // slate-500
    textSubtle: Color(0xFF94A3B8), // slate-400
    surfaceDeep: Color(0xFFF1F5F9), // slate-100
    surfaceRaised: Colors.white,
    gradientStart: Color(0xFFDBEAFE), // blue-100
    gradientEnd: Color(0xFFEFF6FF), // blue-50
  );

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? income,
    Color? expense,
    Color? textMuted,
    Color? textSubtle,
    Color? surfaceDeep,
    Color? surfaceRaised,
    Color? gradientStart,
    Color? gradientEnd,
  }) =>
      AppColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        income: income ?? this.income,
        expense: expense ?? this.expense,
        textMuted: textMuted ?? this.textMuted,
        textSubtle: textSubtle ?? this.textSubtle,
        surfaceDeep: surfaceDeep ?? this.surfaceDeep,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        gradientStart: gradientStart ?? this.gradientStart,
        gradientEnd: gradientEnd ?? this.gradientEnd,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      surfaceDeep: Color.lerp(surfaceDeep, other.surfaceDeep, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
    );
  }
}

/// `context.appColors` and `context.cs` for terser theme lookups.
extension AppColorsContext on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get cs => Theme.of(this).colorScheme;
}

class AppTheme {
  static const _primary = BrandColors.primary;
  static const _error = BrandColors.expense;

  // Dark theme tokens — kept private so only this file knows the literal values.
  static const _darkSurface = Color(0xFF1E293B); // slate-800
  static const _darkBackground = Color(0xFF0F172A); // slate-900
  static const _darkBorder = Color(0xFF334155); // slate-700
  static const _darkOnSurface = Color(0xFFF8FAFC); // slate-50
  static const _darkMuted = Color(0xFF94A3B8); // slate-400

  // Light theme tokens.
  static const _lightSurface = Colors.white;
  static const _lightBackground = Color(0xFFF1F5F9); // slate-100
  static const _lightBorder = Color(0xFFE2E8F0); // slate-200
  static const _lightOnSurface = Color(0xFF0F172A); // slate-900
  static const _lightMuted = Color(0xFF64748B); // slate-500

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: _primary,
          surface: _darkSurface,
          error: _error,
          onPrimary: Colors.white,
          onSurface: _darkOnSurface,
          outline: _darkMuted,
          outlineVariant: _darkBorder,
        ),
        scaffoldBackgroundColor: _darkBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBackground,
          foregroundColor: _darkOnSurface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _darkOnSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkBackground,
          selectedItemColor: _primary,
          unselectedItemColor: _darkMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: _darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _darkBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkSurface,
          hintStyle: const TextStyle(color: _darkMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _error),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primary),
        ),
        dividerTheme: const DividerThemeData(color: _darkBorder, space: 1),
        extensions: const [AppColors._dark],
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: _primary,
          surface: _lightSurface,
          error: _error,
          onPrimary: Colors.white,
          onSurface: _lightOnSurface,
          outline: _lightMuted,
          outlineVariant: _lightBorder,
        ),
        scaffoldBackgroundColor: _lightBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: _lightBackground,
          foregroundColor: _lightOnSurface,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: _lightOnSurface,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _lightSurface,
          selectedItemColor: _primary,
          unselectedItemColor: _lightMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: _lightSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _lightBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lightSurface,
          hintStyle: const TextStyle(color: _lightMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _error),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _primary),
        ),
        dividerTheme: const DividerThemeData(color: _lightBorder, space: 1),
        extensions: const [AppColors._light],
      );
}
