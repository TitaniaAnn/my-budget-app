// SharedPreferences-backed store for CSV column mapping presets.
//
// When the user manually overrides column detection (because the
// heuristic couldn't lock onto the headers), we save the mapping
// keyed by a fingerprint of the header row. A re-import from the
// same bank — which exports the same headers — auto-applies the
// saved mapping without re-prompting.
//
// Header fingerprint comes from [headerFingerprint] in
// statement_parser.dart so the parser and this store agree on
// the key. Storage is one JSON blob under a single prefs key so
// reads/writes are atomic and we don't need to enumerate prefs
// keys to list presets.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'statement_parser.dart';

const _kPresetsKey = 'csv_import.column_presets';

/// Looks up the [ColumnMapping] previously saved for [fingerprint].
/// Returns null when no preset exists for these headers — the UI
/// then shows the manual override sheet.
///
/// Tolerant of a corrupted blob: parse failures return null rather
/// than throw, so a bad write doesn't wedge the import flow.
Future<ColumnMapping?> loadColumnMappingPreset(String fingerprint) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPresetsKey);
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final entry = decoded[fingerprint] as Map<String, dynamic>?;
    if (entry == null) return null;
    return _decode(entry);
  } catch (_) {
    return null;
  }
}

/// Saves [mapping] under [fingerprint]. Existing entries for other
/// fingerprints are preserved. Idempotent — re-saving the same
/// fingerprint overwrites the previous value, which is what we
/// want if the user re-runs the override sheet with different
/// columns.
Future<void> saveColumnMappingPreset({
  required String fingerprint,
  required ColumnMapping mapping,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPresetsKey);
  Map<String, dynamic> all;
  try {
    all = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    all = <String, dynamic>{};
  }
  all[fingerprint] = _encode(mapping);
  await prefs.setString(_kPresetsKey, jsonEncode(all));
}

/// Convenience for the management surface (not exposed in the UI
/// yet — the override sheet implicitly overwrites by re-saving).
/// Exists so a future "forget this bank's preset" affordance has
/// somewhere to call.
Future<void> deleteColumnMappingPreset(String fingerprint) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPresetsKey);
  if (raw == null || raw.isEmpty) return;
  try {
    final all = jsonDecode(raw) as Map<String, dynamic>;
    all.remove(fingerprint);
    await prefs.setString(_kPresetsKey, jsonEncode(all));
  } catch (_) {
    // Corrupt blob — nothing to delete.
  }
}

Map<String, dynamic> _encode(ColumnMapping m) => {
  'dateIdx': m.dateIdx,
  'descIdx': m.descIdx,
  'amountIdx': m.amountIdx,
  'debitIdx': m.debitIdx,
  'creditIdx': m.creditIdx,
};

ColumnMapping? _decode(Map<String, dynamic> j) {
  try {
    final dateIdx = j['dateIdx'] as int;
    final descIdx = j['descIdx'] as int;
    final amountIdx = j['amountIdx'] as int;
    final debitIdx = j['debitIdx'] as int;
    final creditIdx = j['creditIdx'] as int;
    if (amountIdx != -1) {
      return ColumnMapping.signed(
        dateIdx: dateIdx,
        descIdx: descIdx,
        amountIdx: amountIdx,
      );
    }
    return ColumnMapping.split(
      dateIdx: dateIdx,
      descIdx: descIdx,
      debitIdx: debitIdx,
      creditIdx: creditIdx,
    );
  } catch (_) {
    return null;
  }
}
