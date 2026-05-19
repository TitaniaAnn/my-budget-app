// Unit tests for [validateTagName] — pure-Dart, no widget tree.
//
// What's pinned:
//   * empty input returns null (Save button gating handles "empty"
//     separately; an inline message on the first keystroke would
//     read as a scolding error)
//   * exact duplicate against another tag returns a message
//   * editing the same tag with its existing name returns null
//     when excludeId matches — the user kept the name unchanged
//   * comparison matches the schema-level UNIQUE: case-sensitive
//     on the trimmed value

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/models/transaction_tag.dart';
import 'package:mybudget/features/transactions/services/tag_name_validator.dart';

TransactionTag _tag(String id, String name) => TransactionTag(
  id: id,
  householdId: 'h',
  name: name,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  group('validateTagName', () {
    test('returns null for empty / whitespace input', () {
      // Save-button gating handles "empty" — the validator stays
      // quiet so the dialog doesn't show an angry message at the
      // moment the user starts typing.
      expect(validateTagName('', existing: const []), isNull);
      expect(validateTagName('   ', existing: const []), isNull);
    });

    test('returns null when no other tag has the same name', () {
      final existing = [_tag('a', 'contractor'), _tag('b', 'pottery_studio')];
      expect(validateTagName('tax_deductible', existing: existing), isNull);
    });

    test('flags an exact duplicate against another tag', () {
      final existing = [_tag('a', 'contractor')];
      final err = validateTagName('contractor', existing: existing);
      expect(err, isNotNull);
      expect(err, contains('contractor'));
    });

    test('trims input before comparing', () {
      // The repo trims on write — the validator must agree, so a
      // user typing "contractor  " sees the collision warning
      // instead of getting a "phantom dup" past the inline check.
      final existing = [_tag('a', 'contractor')];
      expect(validateTagName('  contractor  ', existing: existing), isNotNull);
    });

    test('excludeId lets a tag keep its own name unchanged', () {
      // Edit mode: the user opens the dialog for tag "a" and clicks
      // Save without renaming. The dialog passes excludeId="a", so
      // the validator must NOT flag it against itself.
      final existing = [_tag('a', 'contractor')];
      expect(
        validateTagName('contractor', existing: existing, excludeId: 'a'),
        isNull,
      );
    });

    test('case-sensitive — matches the schema UNIQUE constraint', () {
      // Migration 020's UNIQUE (household_id, name) is case-
      // sensitive at the DB level. The validator must mirror that
      // or the user would type "Contractor", see "all clear", and
      // hit a DB error on save.
      final existing = [_tag('a', 'contractor')];
      expect(
        validateTagName('Contractor', existing: existing),
        isNull,
        reason:
            'differing case must pass the validator since Postgres '
            'allows the row. If/when the schema moves to a case-'
            'insensitive index, the validator should follow.',
      );
    });
  });
}
