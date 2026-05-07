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
}

/// Minimal stand-in for MlCategoryClassifier.
///
/// The real class wraps an OrtSession we can't easily fake in tests.
/// Categorizer only ever calls `predict`, so we subclass and override
/// just that method.
class _StubMl implements MlCategoryClassifier {
  _StubMl({required Map<String, MlPrediction?> predictions})
    : _predictions = predictions;

  final Map<String, MlPrediction?> _predictions;

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
  void dispose() {}

  // Unused by Categorizer; kept to satisfy the interface.
  @override
  int get inputSize => 0;
}
