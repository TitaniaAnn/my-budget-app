// Tests the Categorizer façade's routing logic. Doesn't load any ONNX
// model — uses a fake MlCategoryClassifier-shaped helper that the
// production class accepts via its constructor (the façade only ever
// calls `predict` on it).
//
// What this nails down:
//   • when ML is absent, every result is keyword-sourced (or null)
//   • when ML hits with confidence >= threshold, result is ml-sourced
//   • when ML hits with confidence < threshold, façade falls through
//     to the keyword matcher
//   • when ML hits a category the household doesn't have, façade falls
//     through to the keyword matcher

import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/features/transactions/models/category.dart';
import 'package:mybudget/features/transactions/services/categorizer.dart';
import 'package:mybudget/features/transactions/services/category_matcher.dart';
import 'package:mybudget/features/transactions/services/ml_category_classifier.dart';

List<Category> _categories() => [
  Category(
    id: 'id-Coffee & Drinks',
    name: 'Coffee & Drinks',
    isIncome: false,
    sortOrder: 0,
  ),
  Category(
    id: 'id-Groceries',
    name: 'Groceries',
    isIncome: false,
    sortOrder: 0,
  ),
  Category(id: 'id-Transfer', name: 'Transfer', isIncome: false, sortOrder: 0),
];

void main() {
  group('without an ML model', () {
    final cats = _categories();
    final c = Categorizer(
      categories: cats,
      keywordMatcher: CategoryMatcher(cats),
    );

    test('routes to the keyword matcher', () {
      final r = c.categorize(
        description: 'STARBUCKS STORE 1234',
        amountCents: -485,
      );
      expect(r, isNotNull);
      expect(r!.categoryId, 'id-Coffee & Drinks');
      expect(r.source, CategorizerSource.keywordMatcher);
      expect(r.confidence, isNull);
    });

    test('returns null when neither engine matches', () {
      final r = c.categorize(
        description: 'GENERIC UNRECOGNISED MERCHANT',
        amountCents: -1234,
      );
      expect(r, isNull);
    });

    test('reports mlAvailable=false', () {
      expect(c.mlAvailable, isFalse);
    });
  });

  group('with a stub ML classifier', () {
    final cats = _categories();

    test('uses ML when confidence >= threshold', () {
      final c = Categorizer(
        categories: cats,
        keywordMatcher: CategoryMatcher(cats),
        mlClassifier: _StubMl(
          predictions: {
            'STARBUCKS STORE 1234||-': const MlPrediction(
              categoryName: 'Groceries',
              categoryId: 'id-Groceries',
              confidence: 0.9,
            ),
          },
        ),
        minMlConfidence: 0.55,
      );
      final r = c.categorize(
        description: 'STARBUCKS STORE 1234',
        amountCents: -485,
      );
      expect(r, isNotNull);
      expect(r!.categoryId, 'id-Groceries');
      expect(r.source, CategorizerSource.mlModel);
      expect(r.confidence, 0.9);
    });

    test('falls through to keyword matcher when ML returns null', () {
      // Stub returns null for the input → façade should consult keyword.
      final c = Categorizer(
        categories: cats,
        keywordMatcher: CategoryMatcher(cats),
        mlClassifier: _StubMl(predictions: const {}),
      );
      final r = c.categorize(
        description: 'STARBUCKS STORE 1234',
        amountCents: -485,
      );
      expect(r, isNotNull);
      expect(r!.categoryId, 'id-Coffee & Drinks');
      expect(r.source, CategorizerSource.keywordMatcher);
    });

    test('falls through when ML predicts a category the household lacks', () {
      final c = Categorizer(
        categories: cats,
        keywordMatcher: CategoryMatcher(cats),
        mlClassifier: _StubMl(
          predictions: {
            'STARBUCKS STORE 1234||-': const MlPrediction(
              categoryName: 'Subscriptions', // not in cats
              categoryId: null, // resolver couldn't map it
              confidence: 0.99,
            ),
          },
        ),
      );
      final r = c.categorize(
        description: 'STARBUCKS STORE 1234',
        amountCents: -485,
      );
      expect(r, isNotNull);
      expect(r!.source, CategorizerSource.keywordMatcher);
      expect(r.categoryId, 'id-Coffee & Drinks');
    });
  });

  group('confidenceToBasisPoints', () {
    test('rounds ML confidence to the nearest 1% (× 100 bp)', () {
      // 0.557 → 56% → 5600 bp.
      final r1 = const CategorizerResult(
        categoryId: 'x',
        source: CategorizerSource.mlModel,
        confidence: 0.557,
      );
      expect(confidenceToBasisPoints(r1), 5600);

      // 0.555 rounds to 0.56 (round-half-to-even or up depending on
      // platform — 56% × 100 = 5600 either way at this resolution).
      final r2 = const CategorizerResult(
        categoryId: 'x',
        source: CategorizerSource.mlModel,
        confidence: 0.554,
      );
      expect(confidenceToBasisPoints(r2), 5500);
    });

    test('clamps cleanly at 0 and 1.0', () {
      expect(
        confidenceToBasisPoints(
          const CategorizerResult(
            categoryId: 'x',
            source: CategorizerSource.mlModel,
            confidence: 0.0,
          ),
        ),
        0,
      );
      expect(
        confidenceToBasisPoints(
          const CategorizerResult(
            categoryId: 'x',
            source: CategorizerSource.mlModel,
            confidence: 1.0,
          ),
        ),
        10000,
      );
    });

    test('returns null for keyword-source hits', () {
      // The column is reserved for ML provenance only — a keyword match
      // has no probability we'd want to store.
      final r = const CategorizerResult(
        categoryId: 'x',
        source: CategorizerSource.keywordMatcher,
        confidence: null,
      );
      expect(confidenceToBasisPoints(r), isNull);
    });

    test('returns null when an ML hit has no confidence value', () {
      // Defensive: shouldn't happen in practice (the predictor always
      // sets confidence), but the null-check keeps the column truthful.
      final r = const CategorizerResult(
        categoryId: 'x',
        source: CategorizerSource.mlModel,
        confidence: null,
      );
      expect(confidenceToBasisPoints(r), isNull);
    });
  });

  group('categorizeWithUncertain', () {
    final cats = _categories();

    test(
      'high-confidence ML hit lands in `confirmed`, `uncertain` is null',
      () {
        final c = Categorizer(
          categories: cats,
          keywordMatcher: CategoryMatcher(cats),
          mlClassifier: _StubMl(
            predictions: {
              'STARBUCKS STORE 1234||-': const MlPrediction(
                categoryName: 'Groceries',
                categoryId: 'id-Groceries',
                confidence: 0.85,
              ),
            },
          ),
          minMlConfidence: 0.55,
        );
        final r = c.categorizeWithUncertain(
          description: 'STARBUCKS STORE 1234',
          amountCents: -485,
        );
        expect(r.confirmed, isNotNull);
        expect(r.confirmed!.categoryId, 'id-Groceries');
        expect(r.confirmed!.source, CategorizerSource.mlModel);
        expect(r.uncertain, isNull);
      },
    );

    test('mid-confidence ML hit lands in `uncertain`, `confirmed` is null', () {
      // 0.40 is below minMlConfidence (0.55) but above lowerBound (default
      // 0.30), so it should surface as a Review-uncertain candidate.
      final c = Categorizer(
        categories: cats,
        keywordMatcher: CategoryMatcher(cats),
        mlClassifier: _StubMl(
          predictions: {
            'OBSCURE MERCHANT||-': const MlPrediction(
              categoryName: 'Groceries',
              categoryId: 'id-Groceries',
              confidence: 0.40,
            ),
          },
        ),
        minMlConfidence: 0.55,
      );
      final r = c.categorizeWithUncertain(
        description: 'OBSCURE MERCHANT',
        amountCents: -485,
      );
      expect(r.confirmed, isNull);
      expect(r.uncertain, isNotNull);
      expect(r.uncertain!.categoryId, 'id-Groceries');
      expect(r.uncertain!.confidence, closeTo(0.40, 1e-9));
    });

    test('below-lowerBound ML hit is dropped; falls through to keyword', () {
      // 0.20 < lowerBound (0.30), so the stub returns null.
      // Categorizer should consult the keyword matcher and surface that
      // hit as `confirmed` (keyword hits are never "uncertain").
      final c = Categorizer(
        categories: cats,
        keywordMatcher: CategoryMatcher(cats),
        mlClassifier: _StubMl(
          predictions: {
            'STARBUCKS STORE 1234||-': const MlPrediction(
              categoryName: 'Groceries',
              categoryId: 'id-Groceries',
              confidence: 0.20,
            ),
          },
        ),
        minMlConfidence: 0.55,
      );
      final r = c.categorizeWithUncertain(
        description: 'STARBUCKS STORE 1234',
        amountCents: -485,
      );
      expect(r.confirmed, isNotNull);
      expect(r.confirmed!.source, CategorizerSource.keywordMatcher);
      expect(r.confirmed!.categoryId, 'id-Coffee & Drinks');
      expect(r.uncertain, isNull);
    });

    test('no ML, no keyword → both null', () {
      final c = Categorizer(
        categories: cats,
        keywordMatcher: CategoryMatcher(cats),
        mlClassifier: _StubMl(predictions: const {}),
      );
      final r = c.categorizeWithUncertain(
        description: 'TOTALLY UNKNOWN MERCHANT XYZ',
        amountCents: -485,
      );
      expect(r.confirmed, isNull);
      expect(r.uncertain, isNull);
    });
  });

  // ── Per-class auto-apply thresholds ─────────────────────────────────────
  //
  // Verifies that Categorizer consults MlCategoryClassifier.thresholdFor
  // with the predicted class name, falls back to the global threshold for
  // unknown classes, and lets a per-class threshold drop BELOW the global
  // (the whole point — confident classes can auto-apply at lower confidence).

  group('per-class thresholds', () {
    final cats = _categories();

    test(
      'lower per-class threshold lets a previously-uncertain prediction auto-apply',
      () {
        // Without per-class thresholds, 0.45 < 0.55 would be uncertain.
        // With Groceries pinned at 0.40, the same prediction auto-applies.
        final c = Categorizer(
          categories: cats,
          keywordMatcher: CategoryMatcher(cats),
          mlClassifier: _StubMl(
            predictions: {
              'OBSCURE MERCHANT||-': const MlPrediction(
                categoryName: 'Groceries',
                categoryId: 'id-Groceries',
                confidence: 0.45,
              ),
            },
            perClassThresholds: {'Groceries': 0.40},
          ),
          minMlConfidence: 0.55,
        );
        final r = c.categorize(
          description: 'OBSCURE MERCHANT',
          amountCents: -485,
        );
        expect(r, isNotNull);
        expect(r!.source, CategorizerSource.mlModel);
        expect(r.categoryId, 'id-Groceries');
        expect(r.confidence, closeTo(0.45, 1e-9));
      },
    );

    test(
      'higher per-class threshold suppresses an otherwise-acceptable prediction',
      () {
        // 0.60 ≥ global 0.55 would normally auto-apply, but Subscriptions'
        // per-class threshold is 0.80 (model is bad at this class) so the
        // prediction is suppressed and we fall through to keyword.
        final c = Categorizer(
          categories: cats,
          keywordMatcher: CategoryMatcher(cats),
          mlClassifier: _StubMl(
            predictions: {
              'STARBUCKS STORE 1234||-': const MlPrediction(
                categoryName: 'Subscriptions',
                categoryId: 'id-Subscriptions',
                confidence: 0.60,
              ),
            },
            perClassThresholds: {'Subscriptions': 0.80},
          ),
          minMlConfidence: 0.55,
        );
        final r = c.categorize(
          description: 'STARBUCKS STORE 1234',
          amountCents: -485,
        );
        // ML suppressed; keyword fallback wins on "starbucks".
        expect(r, isNotNull);
        expect(r!.source, CategorizerSource.keywordMatcher);
        expect(r.categoryId, 'id-Coffee & Drinks');
      },
    );

    test('class without a learned threshold uses the global default', () {
      // perClassThresholds map present but Groceries not in it — fall
      // back to minMlConfidence (0.55). 0.50 should NOT auto-apply.
      final c = Categorizer(
        categories: cats,
        keywordMatcher: CategoryMatcher(cats),
        mlClassifier: _StubMl(
          predictions: {
            'OBSCURE MERCHANT||-': const MlPrediction(
              categoryName: 'Groceries',
              categoryId: 'id-Groceries',
              confidence: 0.50,
            ),
          },
          perClassThresholds: {'Subscriptions': 0.80},
        ),
        minMlConfidence: 0.55,
      );
      final r = c.categorize(
        description: 'OBSCURE MERCHANT',
        amountCents: -485,
      );
      // No ML auto-apply (0.50 < 0.55), no keyword for "OBSCURE MERCHANT".
      expect(r, isNull);
    });

    test('null perClassThresholds → behaves identically to global gating', () {
      // No thresholds.json loaded — backwards-compatible path. Same
      // setup as the very first categorizeWithUncertain test except no
      // perClassThresholds: behavior should match.
      final c = Categorizer(
        categories: cats,
        keywordMatcher: CategoryMatcher(cats),
        mlClassifier: _StubMl(
          predictions: {
            'STARBUCKS STORE 1234||-': const MlPrediction(
              categoryName: 'Groceries',
              categoryId: 'id-Groceries',
              confidence: 0.85,
            ),
          },
          // perClassThresholds intentionally omitted.
        ),
        minMlConfidence: 0.55,
      );
      final r = c.categorize(
        description: 'STARBUCKS STORE 1234',
        amountCents: -485,
      );
      expect(r, isNotNull);
      expect(r!.source, CategorizerSource.mlModel);
      expect(r.categoryId, 'id-Groceries');
    });

    test(
      'categorizeWithUncertain: per-class threshold determines confirmed vs uncertain',
      () {
        // 0.50 confidence; per-class for Groceries is 0.42 (pinned low).
        // → confirmed. With same prediction but threshold 0.60, → uncertain.
        final cConfirmed = Categorizer(
          categories: cats,
          keywordMatcher: CategoryMatcher(cats),
          mlClassifier: _StubMl(
            predictions: {
              'OBSCURE MERCHANT||-': const MlPrediction(
                categoryName: 'Groceries',
                categoryId: 'id-Groceries',
                confidence: 0.50,
              ),
            },
            perClassThresholds: {'Groceries': 0.42},
          ),
          minMlConfidence: 0.55,
        );
        final r1 = cConfirmed.categorizeWithUncertain(
          description: 'OBSCURE MERCHANT',
          amountCents: -485,
        );
        expect(r1.confirmed, isNotNull);
        expect(r1.uncertain, isNull);

        final cUncertain = Categorizer(
          categories: cats,
          keywordMatcher: CategoryMatcher(cats),
          mlClassifier: _StubMl(
            predictions: {
              'OBSCURE MERCHANT||-': const MlPrediction(
                categoryName: 'Groceries',
                categoryId: 'id-Groceries',
                confidence: 0.50,
              ),
            },
            perClassThresholds: {'Groceries': 0.60},
          ),
          minMlConfidence: 0.55,
        );
        final r2 = cUncertain.categorizeWithUncertain(
          description: 'OBSCURE MERCHANT',
          amountCents: -485,
        );
        expect(r2.confirmed, isNull);
        expect(r2.uncertain, isNotNull);
        expect(r2.uncertain!.categoryId, 'id-Groceries');
      },
    );
  });
}

/// Minimal stand-in for MlCategoryClassifier.
///
/// The real class wraps an OrtSession we can't easily fake in tests.
/// Categorizer only ever calls `predict` and `thresholdFor`, so this
/// stub implements just those.
class _StubMl implements MlCategoryClassifier {
  _StubMl({
    required Map<String, MlPrediction?> predictions,
    Map<String, double>? perClassThresholds,
  }) : _predictions = predictions,
       _perClassThresholds = perClassThresholds;

  final Map<String, MlPrediction?> _predictions;
  final Map<String, double>? _perClassThresholds;

  @override
  MlPrediction? predict({
    required String description,
    String? merchant,
    required int amountCents,
    required Map<String, Category> categoriesByName,
    String? accountType,
    double minConfidence = 0.55,
  }) {
    // Test stub key keeps the original three-field shape so existing
    // test fixtures don't have to know about amount buckets / account
    // types — those features only matter to the real model. New tests
    // that need to assert on the richer key can subclass this.
    final sign = amountCents > 0 ? '+' : '-';
    final key = '$description|${merchant ?? ''}|$sign';
    final p = _predictions[key];
    if (p == null) return null;
    if (p.confidence < minConfidence) return null;
    return p;
  }

  @override
  double thresholdFor(String className, {required double defaultThreshold}) {
    return _perClassThresholds?[className] ?? defaultThreshold;
  }

  @override
  void dispose() {}

  // Unused by Categorizer; kept to satisfy the interface.
  @override
  int get inputSize => 0;
}
