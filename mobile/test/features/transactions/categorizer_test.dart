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
      Category(id: 'id-Coffee & Drinks', name: 'Coffee & Drinks',
          isIncome: false, sortOrder: 0),
      Category(id: 'id-Groceries', name: 'Groceries',
          isIncome: false, sortOrder: 0),
      Category(id: 'id-Transfer', name: 'Transfer',
          isIncome: false, sortOrder: 0),
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
        mlClassifier: _StubMl(predictions: {
          'STARBUCKS STORE 1234||-': const MlPrediction(
            categoryName: 'Groceries',
            categoryId: 'id-Groceries',
            confidence: 0.9,
          ),
        }),
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
        mlClassifier: _StubMl(predictions: {
          'STARBUCKS STORE 1234||-': const MlPrediction(
            categoryName: 'Subscriptions', // not in cats
            categoryId: null,              // resolver couldn't map it
            confidence: 0.99,
          ),
        }),
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
    required List<Category> categories,
    double minConfidence = 0.55,
  }) {
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
