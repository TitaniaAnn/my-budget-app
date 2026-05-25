// Unit tests for the SharedPreferences-backed column mapping store.
//
// The CSV import flow saves per-bank column mappings keyed by a
// header-row fingerprint so a re-import of the same statement
// auto-applies without prompting. Contracts pinned:
//
//   * save then load round-trips signed (single-amount) and split
//     (debit / credit) mappings — both shapes must survive the
//     encode/decode pair;
//   * multiple fingerprints coexist (saving one doesn't touch
//     another bank's preset);
//   * re-saving the same fingerprint overwrites the old mapping
//     rather than appending;
//   * delete removes only the target fingerprint and leaves
//     siblings intact;
//   * load returns null when no row exists for the fingerprint;
//   * corruption recovery: a malformed prefs blob returns null
//     from load (and is silently ignored by save / delete) so a
//     bad write doesn't wedge the whole import surface.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/services/column_mapping_presets.dart';
import 'package:mybudget/features/transactions/services/statement_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('signed-shape round trip', () {
    test('save then load returns the same ColumnMapping.signed', () async {
      const fingerprint = 'chase-cc-headers-v1';
      const mapping = ColumnMapping.signed(
        dateIdx: 0,
        descIdx: 2,
        amountIdx: 4,
      );

      await saveColumnMappingPreset(fingerprint: fingerprint, mapping: mapping);

      final loaded = await loadColumnMappingPreset(fingerprint);
      expect(loaded, isNotNull);
      expect(loaded!.dateIdx, 0);
      expect(loaded.descIdx, 2);
      expect(loaded.amountIdx, 4);
      // Sentinel values for the unused split-shape fields. The decoder
      // picks the signed constructor whenever amountIdx != -1.
      expect(loaded.debitIdx, -1);
      expect(loaded.creditIdx, -1);
    });
  });

  group('split-shape round trip', () {
    test('save then load returns the same ColumnMapping.split', () async {
      const fingerprint = 'amex-export-v2';
      const mapping = ColumnMapping.split(
        dateIdx: 1,
        descIdx: 3,
        debitIdx: 5,
        creditIdx: 6,
      );

      await saveColumnMappingPreset(fingerprint: fingerprint, mapping: mapping);

      final loaded = await loadColumnMappingPreset(fingerprint);
      expect(loaded, isNotNull);
      expect(loaded!.dateIdx, 1);
      expect(loaded.descIdx, 3);
      expect(loaded.debitIdx, 5);
      expect(loaded.creditIdx, 6);
      // amountIdx == -1 is what the decoder uses to pick the split
      // constructor; pin it explicitly so a future shape change
      // doesn't silently flip the branch.
      expect(loaded.amountIdx, -1);
    });
  });

  group('multi-fingerprint coexistence', () {
    test('saving two distinct fingerprints leaves both retrievable', () async {
      await saveColumnMappingPreset(
        fingerprint: 'bank-a',
        mapping: const ColumnMapping.signed(
          dateIdx: 0,
          descIdx: 1,
          amountIdx: 2,
        ),
      );
      await saveColumnMappingPreset(
        fingerprint: 'bank-b',
        mapping: const ColumnMapping.split(
          dateIdx: 0,
          descIdx: 1,
          debitIdx: 2,
          creditIdx: 3,
        ),
      );

      final a = await loadColumnMappingPreset('bank-a');
      final b = await loadColumnMappingPreset('bank-b');
      expect(a?.amountIdx, 2);
      expect(b?.debitIdx, 2);
      expect(b?.creditIdx, 3);
    });

    test(
      're-saving the same fingerprint overwrites rather than merges',
      () async {
        const fingerprint = 'overwrite-target';
        // First save: signed.
        await saveColumnMappingPreset(
          fingerprint: fingerprint,
          mapping: const ColumnMapping.signed(
            dateIdx: 0,
            descIdx: 1,
            amountIdx: 2,
          ),
        );
        // Re-save: split (different shape entirely). The new shape
        // must completely replace the old — otherwise stale fields
        // from the prior shape could leak through.
        await saveColumnMappingPreset(
          fingerprint: fingerprint,
          mapping: const ColumnMapping.split(
            dateIdx: 9,
            descIdx: 8,
            debitIdx: 7,
            creditIdx: 6,
          ),
        );

        final loaded = await loadColumnMappingPreset(fingerprint);
        expect(loaded!.dateIdx, 9);
        expect(loaded.descIdx, 8);
        expect(loaded.debitIdx, 7);
        expect(loaded.creditIdx, 6);
        expect(
          loaded.amountIdx,
          -1,
          reason:
              're-save must overwrite the prior shape; amountIdx '
              'should be the sentinel for the new split shape, not '
              'carried over from the prior signed save.',
        );
      },
    );
  });

  group('load returns null when nothing is stored', () {
    test('missing prefs key returns null', () async {
      expect(await loadColumnMappingPreset('never-saved'), isNull);
    });

    test('empty prefs blob returns null', () async {
      // Edge: save was called with an empty blob via some other
      // path, or the blob was wiped. Same behaviour as missing.
      SharedPreferences.setMockInitialValues({'csv_import.column_presets': ''});
      expect(await loadColumnMappingPreset('anything'), isNull);
    });

    test('saved-fingerprints-but-not-this-one returns null', () async {
      await saveColumnMappingPreset(
        fingerprint: 'a-different-bank',
        mapping: const ColumnMapping.signed(
          dateIdx: 0,
          descIdx: 1,
          amountIdx: 2,
        ),
      );
      expect(await loadColumnMappingPreset('our-bank'), isNull);
    });
  });

  group('deleteColumnMappingPreset', () {
    test('removes only the targeted fingerprint', () async {
      await saveColumnMappingPreset(
        fingerprint: 'keep-me',
        mapping: const ColumnMapping.signed(
          dateIdx: 0,
          descIdx: 1,
          amountIdx: 2,
        ),
      );
      await saveColumnMappingPreset(
        fingerprint: 'delete-me',
        mapping: const ColumnMapping.signed(
          dateIdx: 0,
          descIdx: 1,
          amountIdx: 3,
        ),
      );

      await deleteColumnMappingPreset('delete-me');

      expect(await loadColumnMappingPreset('delete-me'), isNull);
      expect(await loadColumnMappingPreset('keep-me'), isNotNull);
    });

    test('delete with no prior store is a no-op (does not throw)', () async {
      // Edge: the "forget this bank" affordance could fire on a
      // never-saved fingerprint. Must not throw or wedge.
      await deleteColumnMappingPreset('whatever');
    });
  });

  group('corruption recovery', () {
    test('malformed JSON returns null from load (does not throw)', () async {
      SharedPreferences.setMockInitialValues({
        'csv_import.column_presets': '{not valid json',
      });
      expect(await loadColumnMappingPreset('any'), isNull);
    });

    test(
      'save over a corrupt blob silently resets and writes the new value',
      () async {
        // A bad write upstream shouldn't permanently wedge subsequent
        // saves. The save path's try/catch around jsonDecode treats
        // a corrupt blob as "start fresh" and writes a clean single-
        // entry blob.
        SharedPreferences.setMockInitialValues({
          'csv_import.column_presets': 'garbage',
        });

        await saveColumnMappingPreset(
          fingerprint: 'recovered',
          mapping: const ColumnMapping.signed(
            dateIdx: 0,
            descIdx: 1,
            amountIdx: 2,
          ),
        );

        final loaded = await loadColumnMappingPreset('recovered');
        expect(loaded, isNotNull);
        expect(loaded!.amountIdx, 2);
      },
    );

    test(
      'entry with wrong-typed fields returns null (decode-level guard)',
      () async {
        // Even if the outer JSON parses, an entry with the wrong
        // field types should fail closed (null) rather than throw
        // up the call stack.
        SharedPreferences.setMockInitialValues({
          'csv_import.column_presets':
              '{"bad-entry": {"dateIdx": "zero", "descIdx": 1, "amountIdx": 2, "debitIdx": -1, "creditIdx": -1}}',
        });
        expect(await loadColumnMappingPreset('bad-entry'), isNull);
      },
    );
  });
}
