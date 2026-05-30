// User-facing locale tag. Audit 2026-05-26 I2.
//
// Single source of truth for "what locale should we format
// money / dates in?" The v1 surface persists the picked locale to
// SharedPreferences so the choice survives app restarts. Today
// the AppLocalizations layer only ships English, so the picker
// limits options to en_US / en_GB / en_CA — same language, same
// .arb file, only differs in number/date formatting. Adding a
// new language = adding a new .arb file and widening the picker.
//
// Wire-up:
//   * MaterialApp.locale reads from userLocaleProvider (parses
//     the "xx_YY" tag into Locale(xx, YY)).
//   * formatCurrency / DateFormat call sites pass
//     `ref.watch(userLocaleProvider)` as the locale argument.

import 'package:flutter/widgets.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_locale_provider.g.dart';

/// SharedPreferences key for the persisted locale tag.
const _userLocaleKey = 'user_locale_v1';

/// Default when nothing's been picked (or the prefs read fails).
const _defaultLocale = 'en_US';

@Riverpod(keepAlive: true)
class UserLocale extends _$UserLocale {
  @override
  String build() {
    // Synchronous build for ergonomic ref.watch — callers don't
    // want to AsyncValue.when() a locale string at every format
    // site. The initial value is the default; the async load
    // (kicked off below) updates state once the prefs read
    // settles. First-frame formatting uses the default; second
    // frame onward uses the picked locale. The brief flash is
    // acceptable for a setting the user changes once a year.
    _load();
    return _defaultLocale;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_userLocaleKey);
      if (stored != null && stored.isNotEmpty) state = stored;
    } catch (_) {
      // Prefs unavailable (test env, locked profile): keep default.
    }
  }

  /// Persist [tag] and update state. Tag shape is "xx_YY"
  /// (language_country); the picker validates against the
  /// supported set before calling.
  Future<void> set(String tag) async {
    state = tag;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userLocaleKey, tag);
    } catch (_) {/**/}
  }
}

/// Parse the "xx_YY" tag the picker writes into a Flutter [Locale]
/// for MaterialApp.locale. Returns null when the tag doesn't fit
/// the shape — caller falls back to the system locale in that case.
Locale? parseLocaleTag(String tag) {
  final parts = tag.split('_');
  if (parts.isEmpty || parts[0].isEmpty) return null;
  if (parts.length == 1) return Locale(parts[0]);
  return Locale(parts[0], parts[1]);
}

/// Picker options shipped in v1. Same language across all three —
/// only the formatting differs (e.g. en_GB uses "12/05/2026" date
/// shape vs en_US's "05/12/2026"). Adding a new entry should also
/// add the matching .arb file when the language differs.
const supportedLocales = <({String tag, String label})>[
  (tag: 'en_US', label: 'English (United States)'),
  (tag: 'en_GB', label: 'English (United Kingdom)'),
  (tag: 'en_CA', label: 'English (Canada)'),
];
