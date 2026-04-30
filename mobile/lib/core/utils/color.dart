// Helpers for converting between the hex strings stored in the DB
// (e.g. category.color = "#3B82F6") and Flutter [Color] values.
//
// The DB stores 6-digit hex with a leading '#'. We always render at full
// opacity, so the 0xFF alpha byte is added here in one place rather than
// scattered across widgets.

import 'package:flutter/material.dart';

/// Parses a "#RRGGBB" or "RRGGBB" hex string into a fully-opaque [Color].
///
/// Returns [fallback] (or transparent) if the string is null or unparseable,
/// so callers can use this directly in build methods without try/catch.
Color colorFromHex(String? hex, {Color fallback = const Color(0x00000000)}) {
  if (hex == null) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
}

/// Encodes a [Color] as a "#RRGGBB" hex string (alpha is dropped).
///
/// On Flutter 3.27+, [Color.r], [Color.g], [Color.b] are normalized doubles
/// in 0.0–1.0, so multiplying by 255 before rounding is required to recover
/// the original 8-bit channel values.
String colorToHex(Color color) {
  String byte(double channel) =>
      (channel * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${byte(color.r)}${byte(color.g)}${byte(color.b)}';
}
