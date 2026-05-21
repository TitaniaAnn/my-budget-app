// Pure-function tests for the hex ↔ Color helpers.
//
// Contracts pinned:
//   * colorFromHex parses "#RRGGBB" and "RRGGBB" (with or without
//     the leading hash);
//   * the returned Color is always fully opaque (0xFF alpha)
//     regardless of input — categories don't carry alpha;
//   * malformed input falls back to [fallback] (default
//     transparent) without throwing — callers use this in build
//     methods where exceptions would crash the widget tree;
//   * colorToHex round-trips channels even on Flutter 3.27+ where
//     Color.r/g/b are normalised doubles in [0, 1];
//   * the alpha byte is dropped on the way back to hex (categories
//     don't store alpha).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/utils/color.dart';

void main() {
  group('colorFromHex', () {
    test('parses "#RRGGBB" at full opacity', () {
      // Indigo-500: #6366F1 → ARGB 0xFF6366F1.
      final c = colorFromHex('#6366F1');
      expect(c.toARGB32(), 0xFF6366F1);
    });

    test('parses bare "RRGGBB" without the leading hash', () {
      final c = colorFromHex('6366F1');
      expect(c.toARGB32(), 0xFF6366F1);
    });

    test('is case-insensitive', () {
      // Lowercase vs uppercase must produce identical ARGB.
      expect(
        colorFromHex('#aabbcc').toARGB32(),
        colorFromHex('#AABBCC').toARGB32(),
      );
    });

    test('null input returns the fallback', () {
      // Default fallback is fully-transparent black.
      expect(colorFromHex(null).toARGB32(), 0x00000000);
    });

    test('returns explicit [fallback] on null', () {
      const fallback = Color(0xFFDEADBE);
      expect(colorFromHex(null, fallback: fallback), fallback);
    });

    test('unparseable string returns the fallback', () {
      // "GG" isn't a hex byte. Callers use this in build methods so
      // throwing would crash the widget tree.
      const fallback = Color(0xFFCAFEBE);
      expect(colorFromHex('#GGGGGG', fallback: fallback), fallback);
    });

    test('empty string is unparseable but does not throw', () {
      expect(colorFromHex(''), const Color(0x00000000));
    });
  });

  group('colorToHex', () {
    test('encodes a Color as #RRGGBB with lowercase channels', () {
      // Color from full ARGB; the alpha byte must be dropped on
      // the way out.
      expect(colorToHex(const Color(0xFF6366F1)), '#6366f1');
    });

    test('round-trips colorFromHex output back to the same string', () {
      // The most important invariant for the category-picker UX:
      // a value the user picked, stored as a hex string, and read
      // back into a Color must encode to the same hex.
      const original = '#3b82f6';
      final color = colorFromHex(original);
      expect(colorToHex(color), original);
    });

    test('handles the pure-black and pure-white extremes', () {
      expect(colorToHex(const Color(0xFF000000)), '#000000');
      expect(colorToHex(const Color(0xFFFFFFFF)), '#ffffff');
    });

    test('pads single-digit channel values to two hex digits', () {
      // 0x010203 — each channel needs zero-padding. Without it
      // the string would be "#123", a length-mismatched parse
      // target.
      expect(colorToHex(const Color(0xFF010203)), '#010203');
    });
  });
}
