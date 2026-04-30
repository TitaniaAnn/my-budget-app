// Façade combining the ML classifier with the legacy keyword matcher.
//
// Callers ask `categorize(...)` and get back a single result tagged with
// the engine that produced it (`source`). They never see the underlying
// engines — that decouples the call sites from how categorisation
// actually happens, lets us swap in different models later, and lets the
// repository record an honest provenance for every category write.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/category.dart';
import '../providers/transactions_provider.dart';
import 'category_matcher.dart';
import 'ml_category_classifier.dart';

part 'categorizer.g.dart';

/// Which engine produced a categorisation. Mirrors the
/// `category_assignment_source` Postgres enum so it can be written
/// directly to `transactions.category_assigned_by`.
enum CategorizerSource {
  keywordMatcher('keyword_matcher'),
  mlModel('ml_model');

  const CategorizerSource(this.dbValue);
  final String dbValue;
}

class CategorizerResult {
  const CategorizerResult({
    required this.categoryId,
    required this.source,
    this.confidence,
  });

  final String categoryId;
  final CategorizerSource source;
  final double? confidence;
}

class Categorizer {
  Categorizer({
    required this.categories,
    required CategoryMatcher keywordMatcher,
    MlCategoryClassifier? mlClassifier,
    double minMlConfidence = 0.55,
  })  : _keyword = keywordMatcher,
        _ml = mlClassifier,
        _minMlConfidence = minMlConfidence;

  /// The category list the ML model resolves predictions against.
  /// Held here so callers don't have to thread it through every call.
  final List<Category> categories;

  final CategoryMatcher _keyword;
  final MlCategoryClassifier? _ml;
  final double _minMlConfidence;

  /// True when an ML model is loaded and will be tried first. False
  /// during cold-start (model assets missing) — the façade silently
  /// becomes a thin wrapper around the keyword matcher.
  bool get mlAvailable => _ml != null;

  /// Categorises a single transaction. Tries the ML classifier first
  /// (when available) and falls back to the keyword matcher when the
  /// model is unavailable, returns no prediction, returns one below
  /// [minMlConfidence], or names a category the household doesn't have.
  ///
  /// Returns null when neither engine produces a hit.
  CategorizerResult? categorize({
    required String description,
    String? merchant,
    required int amountCents,
  }) {
    final ml = _ml?.predict(
      description: description,
      merchant: merchant,
      amountCents: amountCents,
      categories: categories,
      minConfidence: _minMlConfidence,
    );
    if (ml != null && ml.categoryId != null) {
      return CategorizerResult(
        categoryId: ml.categoryId!,
        source: CategorizerSource.mlModel,
        confidence: ml.confidence,
      );
    }

    final kwId = _keyword.match(description, isIncome: amountCents > 0);
    if (kwId != null) {
      return CategorizerResult(
        categoryId: kwId,
        source: CategorizerSource.keywordMatcher,
      );
    }
    return null;
  }
}

/// Riverpod provider for the singleton [Categorizer].
///
/// The ML classifier loads asynchronously the first time the provider
/// is read; until then `mlAvailable` is false and the façade is a pure
/// keyword matcher. The first read must therefore be `await` (the
/// provider returns a Future). All call sites already do this.
@Riverpod(keepAlive: true)
Future<Categorizer> categorizer(CategorizerRef ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  final ml = await MlCategoryClassifier.load();
  ref.onDispose(() => ml?.dispose());
  return Categorizer(
    categories: categories,
    keywordMatcher: CategoryMatcher(categories),
    mlClassifier: ml,
  );
}
