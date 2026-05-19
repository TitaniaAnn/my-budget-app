// Pure-Dart validation for tag names. Surfaces the UNIQUE
// (household_id, name) constraint from migration 020 as inline
// feedback before the save round-trip, instead of letting the
// user click Save and meet a raw Postgres error string.
//
// Top-level so the manage-tags dialog can call it on every text
// change (cheap, runs against a list of typically dozens of tags)
// and so the unit test can exercise it without a widget tree.

import '../models/transaction_tag.dart';

/// Returns an error message to surface inline under the name
/// field, or null when the input is acceptable.
///
/// Rules:
/// - Empty / whitespace-only input returns null. The Save button
///   is disabled separately by the dialog when the trimmed value
///   is empty; we don't show an angry message at the moment the
///   user starts typing.
/// - A name that collides with another tag in [existing] returns
///   "A tag named ... already exists." Comparison matches the
///   schema-level UNIQUE: case-sensitive, on the trimmed value.
/// - [excludeId] skips a tag by id — used in edit mode so the
///   user can save with the name unchanged.
String? validateTagName(
  String input, {
  required List<TransactionTag> existing,
  String? excludeId,
}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  for (final t in existing) {
    if (t.id == excludeId) continue;
    if (t.name == trimmed) {
      return 'A tag named "$trimmed" already exists.';
    }
  }
  return null;
}
