// Pure-function tests for the category-icon name → IconData mapping.
//
// Contracts pinned:
//   * a null icon name returns the default fallback rather than
//     crashing — categories without an icon column happen and
//     callers can't be expected to null-check before rendering;
//   * an unknown icon name (e.g. a future icon added in another
//     branch) also returns the fallback rather than crashing;
//   * every icon name in categoryIconOptions maps to a real
//     IconData entry — the picker UI surfaces these to users, so
//     a typo here would render a generic label everywhere the
//     user selected it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/utils/category_icon.dart';

void main() {
  group('categoryIconData', () {
    test('null returns the fallback (Icons.label_outline)', () {
      expect(categoryIconData(null), Icons.label_outline);
    });

    test('unknown name returns the fallback', () {
      // A category created in a future branch with an icon name
      // we haven't mapped yet must not crash — fallback is fine.
      expect(categoryIconData('not-a-real-icon'), Icons.label_outline);
    });

    test('a known name returns its specific icon', () {
      // Spot-check a few of the well-known mappings.
      expect(categoryIconData('home'), Icons.home_outlined);
      expect(categoryIconData('shopping-cart'), Icons.shopping_cart_outlined);
      expect(categoryIconData('credit-card'), Icons.credit_card_outlined);
    });

    test('empty string returns the fallback', () {
      // The DB allows NULL but not empty strings for the icon
      // column in practice. Still — defending against empty is
      // cheaper than debugging it.
      expect(categoryIconData(''), Icons.label_outline);
    });
  });

  group('categoryIconOptions', () {
    test('every name in the picker list resolves to a real icon', () {
      // Picker UI surfaces these. A typo here means a user can
      // tap "trending-up" and end up with the generic
      // label_outline icon on every screen — silent regression
      // that's painful to track down.
      for (final name in categoryIconOptions) {
        expect(
          categoryIconData(name),
          isNot(Icons.label_outline),
          reason:
              "icon name '$name' surfaced by the picker must be in "
              "the categoryIconData map; otherwise the user picks an "
              "icon that silently renders as the fallback.",
        );
      }
    });

    test('contains no duplicate entries', () {
      // Duplicates in the picker UI would render the same icon
      // tile twice for the same name — confusing without being
      // a hard bug.
      final seen = <String>{};
      for (final name in categoryIconOptions) {
        expect(
          seen.add(name),
          isTrue,
          reason: "duplicate '$name' in categoryIconOptions.",
        );
      }
    });
  });
}
