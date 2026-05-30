// User-facing locale tag. Audit 2026-05-26 I2.
//
// Single source of truth for "what locale should we format
// money / dates in?" Today the answer is hardcoded 'en_US' —
// the AppLocalizations layer only ships English in v1. The
// provider exists so when a non-en locale ships there's already
// a Riverpod-watchable surface every site can hit instead of
// 178 inline `'en_US'` literals.
//
// Wire-up plan when the time comes:
//   * Load the user's preference from SharedPreferences (or the
//     profiles table) in build().
//   * MaterialApp.locale: read from this provider.
//   * formatCurrency / DateFormat call sites: pass
//     `ref.watch(userLocaleProvider)` as the locale argument.

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_locale_provider.g.dart';

@Riverpod(keepAlive: true)
String userLocale(UserLocaleRef ref) {
  // Pinned for v1. Returning a constant rather than reading
  // SharedPreferences keeps the provider free of async setup —
  // callers `ref.watch` synchronously the same way they do
  // today with hardcoded 'en_US'.
  return 'en_US';
}
