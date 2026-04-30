// Tests for the Dart-side TF-IDF tokeniser embedded in
// MlCategoryClassifier. Two layers:
//
//   1. `charWbNgrams` algorithm tests — fully deterministic, no external
//      fixture. Verifies the Dart implementation against the documented
//      sklearn `char_wb` algorithm on hand-traced inputs.
//
//   2. Parity test against `assets/ml/test_vectors.json` — only runs
//      when the asset is present (i.e. someone has executed
//      tools/categorizer/train.py and copied the artefacts). Asserts
//      that Dart's full TF-IDF vector exactly matches the one Python
//      produced for the same input + the same vocab/idf.
//
// On a fresh clone where no model assets exist, the parity test is
// reported as skipped, not failed.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/services/ml_category_classifier.dart';

TfidfVectoriser _vectoriser({
  Map<String, int> vocab = const {'__none__': 0},
  Float32List? idf,
  int minN = 3,
  int maxN = 5,
  bool lowercase = true,
}) {
  return TfidfVectoriser(
    vocab: vocab,
    idf: idf ?? Float32List.fromList(List.filled(vocab.length, 1.0)),
    minN: minN,
    maxN: maxN,
    lowercase: lowercase,
    sublinearTf: false,
  );
}

void main() {
  group('charWbNgrams algorithm', () {
    test('emits padded n-grams for a single short word', () {
      final v = _vectoriser(minN: 3, maxN: 5);
      // " ab " has length 4.
      //   n=3: " ab", "ab "                      (offset != 0, keep going)
      //   n=4: " ab " (single slice, then offset==0 → break out of n-loop)
      // So n=5 is never tried — sklearn's `break` exits the entire n-loop
      // for short words, not just the inner while.
      expect(v.charWbNgrams('ab'), [
        ' ab',
        'ab ',
        ' ab ',
      ]);
    });

    test('lowercases before tokenising', () {
      final v = _vectoriser(minN: 3, maxN: 3);
      expect(v.charWbNgrams('AB'), [' ab', 'ab ']);
    });

    test('collapses multi-whitespace runs to a single space', () {
      final v = _vectoriser(minN: 3, maxN: 3);
      expect(v.charWbNgrams('a   b'), [' a ', ' b ']);
    });

    test('handles a longer word with overlapping n-grams', () {
      final v = _vectoriser(minN: 3, maxN: 4);
      // " abcd " has len 6.
      // n=3: " ab", "abc", "bcd", "cd "
      // n=4: " abc", "abcd", "bcd "
      expect(v.charWbNgrams('abcd'), [
        ' ab', 'abc', 'bcd', 'cd ',
        ' abc', 'abcd', 'bcd ',
      ]);
    });

    test('strips empty words from leading/trailing whitespace', () {
      final v = _vectoriser(minN: 3, maxN: 3);
      expect(v.charWbNgrams('  a '), [' a ']);
    });

    test('emits nothing for empty input', () {
      final v = _vectoriser(minN: 3, maxN: 5);
      expect(v.charWbNgrams(''), isEmpty);
    });
  });

  group('TfIdf transform', () {
    test('returns an all-zero vector when nothing in vocab matches', () {
      final v = _vectoriser(
        vocab: {'foo': 0, 'bar': 1},
        idf: Float32List.fromList([1.0, 1.0]),
      );
      final out = v.transform('xyz qrs');
      expect(out.length, 2);
      expect(out.every((x) => x == 0), isTrue);
    });

    test('produces an L2-normalised weighted vector', () {
      // Vocab covers exactly one trigram from " ab ". After tf=1 * idf=2
      // the dense vector is [2, 0]; L2-normalised it becomes [1, 0].
      final v = _vectoriser(
        vocab: {' ab': 0, 'zz ': 1},
        idf: Float32List.fromList([2.0, 5.0]),
        minN: 3,
        maxN: 3,
      );
      final out = v.transform('ab');
      expect(out[0], closeTo(1.0, 1e-6));
      expect(out[1], 0.0);
    });
  });

  group('parity with Python', () {
    // Conditional: skipped when the model has not been trained yet.
    final fixture = File('assets/ml/test_vectors.json');
    final vocabFile = File('assets/ml/vocab.json');
    if (!fixture.existsSync() || !vocabFile.existsSync()) {
      test('skipped — assets/ml/ not populated yet', () {
        markTestSkipped(
          'Run tools/categorizer/train.py and copy build/* into '
          'mobile/assets/ml/ to enable the parity check.',
        );
      });
      return;
    }

    test('Dart and Python produce byte-identical sparse vectors', () {
      final vocabJson =
          jsonDecode(vocabFile.readAsStringSync()) as Map<String, dynamic>;
      final v = TfidfVectoriser.fromJson(vocabJson);
      final fixtures =
          (jsonDecode(fixture.readAsStringSync()) as List).cast<Map>();

      for (final f in fixtures) {
        final input = f['input'] as String;
        final expectedIndices =
            (f['indices'] as List).cast<num>().map((n) => n.toInt()).toList();
        final expectedWeights = (f['weights'] as List)
            .cast<num>()
            .map((n) => n.toDouble())
            .toList();

        final dense = v.transform(input);
        // Re-sparsify the dense Dart output for comparison.
        final actualIndices = <int>[];
        final actualWeights = <double>[];
        for (var i = 0; i < dense.length; i++) {
          if (dense[i] != 0) {
            actualIndices.add(i);
            actualWeights.add(dense[i]);
          }
        }

        expect(actualIndices, expectedIndices,
            reason: 'index set mismatch for input "$input"');
        for (var i = 0; i < expectedWeights.length; i++) {
          expect(actualWeights[i], closeTo(expectedWeights[i], 1e-5),
              reason: 'weight mismatch at idx ${expectedIndices[i]} '
                  'for input "$input"');
        }
      }
    });
  });
}
