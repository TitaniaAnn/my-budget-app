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

/// Converts a categorizer hit's float confidence into the basis-points
/// integer the database stores in `transactions.ml_model_confidence`.
///
/// Returns null for non-ML hits (keyword matcher) and for ML hits without
/// a confidence value — the column is nullable for both reasons.
///
/// Confidence is rounded to the nearest percentage point (1% == 100 bp)
/// so the bulk-recategorize grouping doesn't degenerate to one-bucket-
/// per-row when every prediction has a slightly different float. The
/// active-learning UX thinks in "high / mid / low" bands, not exact
/// values, so the precision loss is invisible there.
int? confidenceToBasisPoints(CategorizerResult result) {
  if (result.source != CategorizerSource.mlModel) return null;
  final c = result.confidence;
  if (c == null) return null;
  return (c * 100).round() * 100;
}

class Categorizer {
  Categorizer({
    required this.categories,
    required CategoryMatcher keywordMatcher,
    MlCategoryClassifier? mlClassifier,
    double minMlConfidence = 0.55,
  }) : _keyword = keywordMatcher,
       _ml = mlClassifier,
       _minMlConfidence = minMlConfidence,
       // Built once at construction so bulk-import paths don't pay an
       // O(N) linear scan over `categories` per ML prediction. The
       // Riverpod provider rebuilds the Categorizer when the household's
       // category list changes, so this map is effectively immutable.
       _categoriesByName = {for (final c in categories) c.name: c};

  /// The category list the ML model resolves predictions against.
  /// Held here so callers don't have to thread it through every call.
  final List<Category> categories;

  final CategoryMatcher _keyword;
  final MlCategoryClassifier? _ml;
  final double _minMlConfidence;
  final Map<String, Category> _categoriesByName;

  /// True when an ML model is loaded and will be tried first. False
  /// during cold-start (model assets missing) — the façade silently
  /// becomes a thin wrapper around the keyword matcher.
  bool get mlAvailable => _ml != null;

  /// Lowest plausible auto-apply threshold across all classes. Below this,
  /// even a per-class learned threshold wouldn't auto-apply — the model
  /// is too uncertain to be useful. Used as the floor passed to
  /// [MlCategoryClassifier.predict] in [categorize] AND as the default
  /// `lowerBound` of the uncertain band in [categorizeWithUncertain] so
  /// the two paths can't drift.
  static const double defaultAutoApplyFloor = 0.30;

  /// Categorises a single transaction. Tries the ML classifier first
  /// (when available) and falls back to the keyword matcher when the
  /// model is unavailable, returns no prediction, returns one below the
  /// per-class auto-apply threshold (or [_minMlConfidence] for classes
  /// without a learned threshold), or names a category the household
  /// doesn't have.
  ///
  /// [accountType] is the snake_case Postgres enum for the account the
  /// transaction belongs to (`checking`, `credit_card`, …). Pass null
  /// when the caller can't easily determine it; the model handles the
  /// unknown-account case as a placeholder.
  ///
  /// Returns null when neither engine produces a hit.
  CategorizerResult? categorize({
    required String description,
    String? merchant,
    required int amountCents,
    String? accountType,
  }) {
    // Predict at the floor; per-class threshold enforced below. With no
    // per-class map loaded, every class falls back to _minMlConfidence —
    // matches the pre-Tier-2 behaviour exactly.
    final ml = _ml?.predict(
      description: description,
      merchant: merchant,
      amountCents: amountCents,
      categoriesByName: _categoriesByName,
      accountType: accountType,
      minConfidence: defaultAutoApplyFloor,
    );
    if (ml != null && ml.categoryId != null) {
      final threshold = _ml!.thresholdFor(
        ml.categoryName,
        defaultThreshold: _minMlConfidence,
      );
      if (ml.confidence >= threshold) {
        return CategorizerResult(
          categoryId: ml.categoryId!,
          source: CategorizerSource.mlModel,
          confidence: ml.confidence,
        );
      }
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

  /// Same as [categorize] but also returns the ML's top guess when its
  /// confidence falls in the uncertain band — at or above [lowerBound]
  /// but below the predicted class's auto-apply threshold (per-class via
  /// [MlCategoryClassifier.thresholdFor], or [_minMlConfidence] when no
  /// per-class map is loaded).
  ///
  /// `confirmed` mirrors what [categorize] would have returned (auto-apply
  /// only when confidence ≥ class threshold). `uncertain` is non-null
  /// when the ML had a guess in the band but it was suppressed for
  /// auto-apply — feed those to the Review surface. Both can be null (no
  /// guess at all).
  ({CategorizerResult? confirmed, CategorizerResult? uncertain})
  categorizeWithUncertain({
    required String description,
    String? merchant,
    required int amountCents,
    String? accountType,
    double lowerBound = defaultAutoApplyFloor,
  }) {
    // Run the ML once at the lower threshold so we always get its top
    // class when it has anything to say.
    final ml = _ml?.predict(
      description: description,
      merchant: merchant,
      amountCents: amountCents,
      categoriesByName: _categoriesByName,
      accountType: accountType,
      minConfidence: lowerBound,
    );

    if (ml != null && ml.categoryId != null) {
      final result = CategorizerResult(
        categoryId: ml.categoryId!,
        source: CategorizerSource.mlModel,
        confidence: ml.confidence,
      );
      final threshold = _ml!.thresholdFor(
        ml.categoryName,
        defaultThreshold: _minMlConfidence,
      );
      if (ml.confidence >= threshold) {
        return (confirmed: result, uncertain: null);
      }
      return (confirmed: null, uncertain: result);
    }

    // No ML hit — same fallback path as `categorize`. Keyword hits are
    // never "uncertain" — the matcher either fires or it doesn't.
    final kwId = _keyword.match(description, isIncome: amountCents > 0);
    if (kwId != null) {
      return (
        confirmed: CategorizerResult(
          categoryId: kwId,
          source: CategorizerSource.keywordMatcher,
        ),
        uncertain: null,
      );
    }
    return (confirmed: null, uncertain: null);
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
