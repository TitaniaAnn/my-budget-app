"""
Train the on-device transaction classifier and export the artefacts the
Flutter app consumes from `mobile/assets/ml/`.

Inputs (CSV with columns id, description, merchant, amount, account_type,
category_name):
  - real labels from dump_labels.py
  - synthetic seeds from bootstrap_seed.py (cold-start only)

Outputs (in --out-dir):
  category_model.onnx   — TfidfVectorizer + LogisticRegression
  vocab.json            — { ngram: index, idf: [..], analyzer params }
  labels.json           — [ category_name, ... ] indexed by output column
  thresholds.json       — { default, target_recall, per_class: {name: thr} }
                          per-class auto-apply thresholds learned on the
                          holdout (precision-maximising at recall ≥ target).
                          Dart side falls back to default when a class is
                          missing or the file is absent.
  test_vectors.json     — golden fixture for the Dart parity test
  metrics.json          — holdout accuracy + per-class precision/recall

Pipeline:
  TfidfVectorizer(analyzer='char_wb', ngram_range=(3,5),
                  lowercase=True, sublinear_tf=False)
  → CalibratedClassifierCV(
        LogisticRegression(C=4.0, max_iter=1000,
                           class_weight='balanced',
                           solver='liblinear', multi_class='ovr'),
        method='sigmoid', cv=min(5, smallest_class_count),
        ensemble=False,
    )
  Calibration falls back to uncalibrated LogReg when the smallest
  training class has <2 examples (k-fold calibration needs ≥k per
  class). Calibrated probabilities matter because both the per-class
  thresholds and the active-learning uncertain band treat confidence
  as a true probability.

The text fed to the vectoriser is
  `<description>|<merchant>|<sign>|<amt_bucket>|<account_type>`
where:
  • sign is '+' for credits, '-' for debits;
  • amt_bucket is one of xs|s|m|l|xl (see AMOUNT_BUCKETS), bucketed by
    absolute value of cents;
  • account_type is the snake_case Postgres enum (checking, savings,
    credit_card, cash, mortgage, …) or '' if unknown at training time.
The Dart `_renderInput` MUST stay byte-identical to `render()` below —
the parity test in ml_category_classifier_test.dart pins it.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    precision_recall_curve,
)
from sklearn.model_selection import train_test_split
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import FloatTensorType


# ── Feature shaping ─────────────────────────────────────────────────────────

# Cents thresholds (absolute) → bucket label. Boundaries are inclusive on
# the LOW side: $10.00 → 's', $50.00 → 'm', $200.00 → 'l', $1000.00 → 'xl'.
# The Dart side mirrors these in `_amountBucket` — change in lockstep.
AMOUNT_BUCKETS = (
    (1000,    "xs"),   # < $10
    (5000,    "s"),    # < $50
    (20000,   "m"),    # < $200
    (100000,  "l"),    # < $1000
    (10**12,  "xl"),   # ≥ $1000 (any larger value)
)


def _amount_bucket(amount_cents: int) -> str:
    a = abs(int(amount_cents))
    for cutoff, label in AMOUNT_BUCKETS:
        if a < cutoff:
            return label
    return "xl"


def render(
    description: str,
    merchant: str,
    amount: int,
    account_type: str = "",
) -> str:
    """Same string format used at inference time on the device.

    Order: description|merchant|sign|amt_bucket|account_type. Empty
    `account_type` is rendered as the empty string (model sees an
    unknown-account placeholder, same as merchant).
    """
    sign = "+" if amount > 0 else "-"
    bucket = _amount_bucket(amount)
    return (
        f"{description or ''}|{merchant or ''}|"
        f"{sign}|{bucket}|{account_type or ''}"
    )


# Vocab cap. Char-n-gram dictionaries fan out fast; this keeps the asset
# small enough to ship and the per-inference dense vector affordable
# (10_000 floats ≈ 40 KB per call, fine even on bulk-import paths).
MAX_FEATURES = 10_000


# ── Vectoriser + classifier (NOT a Pipeline) ────────────────────────────────
# We deliberately do NOT export the TfidfVectorizer to ONNX. Reasons:
#   • char_wb tokenisation is a known-fragile area of skl2onnx — converters
#     vary by version and platform.
#   • The Dart side already has to load vocab.json to be able to reason
#     about predictions; once it has that, doing the tokenisation locally
#     is a small extra step with strict, testable semantics.
# So the ONNX model is the LogisticRegression alone, taking a dense
# Float32 vector of length len(vocab) as input.

def build_vectoriser() -> TfidfVectorizer:
    return TfidfVectorizer(
        analyzer="char_wb",
        ngram_range=(3, 5),
        lowercase=True,
        sublinear_tf=False,
        max_features=MAX_FEATURES,
        min_df=1,
    )


def _build_base_logreg() -> LogisticRegression:
    return LogisticRegression(
        C=4.0,
        max_iter=1000,
        class_weight="balanced",
        solver="liblinear",
        # Pinned explicitly: liblinear's implicit default. sklearn ≥ 1.5
        # warns when this is omitted, and skl2onnx's converter cares
        # which strategy was used. Don't change without re-exporting the
        # ONNX model AND re-checking the Dart parity fixture.
        multi_class="ovr",
    )


def build_classifier(
    *,
    smallest_class_count: int,
    calibrate: bool = True,
):
    """Returns the classifier to fit.

    By default wraps the LogReg in a CalibratedClassifierCV (Platt scaling)
    so the probabilities Categorizer treats as confidence are actually
    calibrated. The active-learning band cut-offs (Tier 1 #3) and per-class
    thresholds (Tier 2 #1) both rely on confidences meaning what they say
    — uncalibrated LR overstates extreme probabilities, which makes the
    "uncertain" band (typically [0.30, 0.55)) catch fewer rows than it
    should.

    `ensemble=False` (sklearn ≥ 1.4) keeps the exported model size flat:
    one calibrated classifier instead of an ensemble of `cv` of them.

    Falls back to uncalibrated LR when `smallest_class_count` is too low
    for k-fold calibration to be meaningful (each fold needs ≥1 example
    per class). Caller passes `calibrate=False` to force uncalibrated for
    debugging.
    """
    base = _build_base_logreg()
    if not calibrate:
        return base
    # CalibratedClassifierCV with cv=k requires every class to have at
    # least k examples (each fold gets one). With small synthetic seed
    # data, smaller cv keeps the calibration step from failing.
    cv = max(2, min(5, smallest_class_count))
    if smallest_class_count < 2:
        # Can't calibrate at all — at least one class has only 1 example.
        return base
    return CalibratedClassifierCV(
        base,
        method="sigmoid",  # Platt scaling
        cv=cv,
        ensemble=False,
    )


# ── Artefact writers ────────────────────────────────────────────────────────

def write_vocab_json(vec: TfidfVectorizer, path: Path) -> None:
    """Dart needs vocab + IDF weights + analyser knobs to reproduce vectors."""
    vocab = {term: int(idx) for term, idx in vec.vocabulary_.items()}
    payload = {
        "analyzer": "char_wb",
        "ngram_min": int(vec.ngram_range[0]),
        "ngram_max": int(vec.ngram_range[1]),
        "lowercase": bool(vec.lowercase),
        "sublinear_tf": bool(vec.sublinear_tf),
        "vocabulary": vocab,
        "idf": [float(x) for x in vec.idf_.tolist()],
    }
    path.write_text(json.dumps(payload), encoding="utf-8")


def write_labels_json(classes: np.ndarray, path: Path) -> None:
    path.write_text(json.dumps([str(c) for c in classes.tolist()]),
                    encoding="utf-8")


def compute_per_class_thresholds(
    y_true: list[str],
    y_proba: np.ndarray,
    classes: np.ndarray,
    target_recall: float = 0.7,
    default: float = 0.55,
) -> dict[str, float]:
    """Per-class auto-apply thresholds learned from the holdout.

    For each class C:
      - Treat as binary: y_bin = (y_true == C); scores = y_proba[:, idx_C].
      - Run sklearn's precision_recall_curve, which returns precision,
        recall, threshold arrays. recall is monotonically non-increasing
        as threshold rises (a stricter threshold predicts fewer positives,
        so misses more — recall drops).
      - Pick the HIGHEST threshold where recall(thr) >= target_recall.
        Among thresholds that maintain target recall, the highest one
        gives the best precision (the P-R curve's other axis).
      - Fall back to `default` when the class is absent from the holdout
        (rare class, train_test_split moved all examples one way) or when
        no threshold maintains target recall (model genuinely can't hit
        the bar — keep the conservative global threshold).

    The Dart side reads the resulting map and uses thresholds[predicted_name]
    when the predicted class is present, otherwise the same `default`.
    """
    thresholds: dict[str, float] = {}
    y_arr = np.asarray(y_true)
    for i, cls in enumerate(classes):
        cls_name = str(cls)
        y_bin = (y_arr == cls_name).astype(int)
        if y_bin.sum() == 0:
            thresholds[cls_name] = float(default)
            continue
        precision, recall, threshs = precision_recall_curve(y_bin, y_proba[:, i])
        # recall and precision have one more element than threshs; the
        # final entry corresponds to "predict everything positive" (the
        # zero-threshold limit) and has no associated threshold to store.
        # recall[:-1] is the recall AT each threshold in threshs.
        valid = recall[:-1] >= target_recall
        if not valid.any():
            thresholds[cls_name] = float(default)
            continue
        last_valid_idx = int(np.where(valid)[0].max())
        thresholds[cls_name] = float(threshs[last_valid_idx])
    return thresholds


def write_thresholds_json(
    per_class: dict[str, float],
    target_recall: float,
    default: float,
    path: Path,
) -> None:
    payload = {
        "default": float(default),
        "target_recall": float(target_recall),
        "per_class": {k: round(float(v), 4) for k, v in per_class.items()},
    }
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def write_test_vectors_json(
    vec: TfidfVectorizer, samples: list[str], path: Path
) -> None:
    """Sparse TF-IDF outputs for ~20 hand-picked inputs.

    Dart-side test asserts byte-identical output. If this file changes,
    the Dart tokeniser is broken or sklearn changed.
    """
    matrix = vec.transform(samples)
    out = []
    for i, s in enumerate(samples):
        row = matrix[i]
        # Sparse → list of (idx, weight) tuples sorted by index for stability.
        triples = sorted(
            zip(row.indices.tolist(), row.data.tolist()),
            key=lambda t: t[0],
        )
        out.append({
            "input": s,
            "indices": [int(i) for i, _ in triples],
            # Round to 6dp to make the parity test tolerant to harmless
            # float-formatting differences across runtimes.
            "weights": [round(float(w), 6) for _, w in triples],
        })
    path.write_text(json.dumps(out, indent=2), encoding="utf-8")


def write_onnx(clf, n_features: int, path: Path) -> None:
    """Serialise the fitted classifier (LogReg, or CalibratedClassifierCV
    wrapping a LogReg) to ONNX. skl2onnx supports both shapes; the latter
    adds a sigmoid scaling layer to the exported graph."""
    initial_types = [("input", FloatTensorType([None, n_features]))]
    onx = convert_sklearn(clf, initial_types=initial_types,
                          target_opset=15)
    path.write_bytes(onx.SerializeToString())


# ── Main ────────────────────────────────────────────────────────────────────

GOLDEN_INPUTS = [
    # Stable handful that exercises sign + merchant + special chars + casing,
    # plus the amount-bucket and account-type fields. Format mirrors
    # render(): description|merchant|sign|amt_bucket|account_type.
    "STARBUCKS STORE 1234|Starbucks|-|xs|credit_card",
    "AMAZON.COM*MK1AB2CD|Amazon|-|s|credit_card",
    "AMAZON REFUND ORDER|Amazon|+|s|credit_card",
    "ZELLE PAYMENT TO JOHN|Zelle|-|m|checking",
    "PAYROLL DEPOSIT - ADP|ADP|+|xl|checking",
    "shell gas #4421|Shell|-|s|credit_card",
    "VENMO TRANSFER||+|s|checking",
    "CHIPOTLE 0987||-|xs|credit_card",
    "Netflix.com|Netflix|-|xs|credit_card",
    "TRADER JOE'S #102|Trader Joe's|-|s|credit_card",
    # Edge cases:
    "||-|xs|",                       # empty desc + empty merchant + empty account
    "X|Y|+|xs|cash",                 # very short
    "a b c d e|f g h|-|m|savings",   # multi-token
    "ÜBER eats|Über|-|xs|credit_card",  # non-ASCII
    "  CAPS WITH  SPACES  ||-|l|checking",  # whitespace + larger amount bucket
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--in", dest="csv", default="labels.csv", type=Path)
    parser.add_argument("--out-dir", default=Path("build"), type=Path)
    parser.add_argument("--test-size", type=float, default=0.15)
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()

    if not args.csv.exists():
        print(f"ERROR: input CSV not found at {args.csv}", file=sys.stderr)
        return 1

    df = pd.read_csv(args.csv)
    if df.empty:
        print("ERROR: input CSV is empty", file=sys.stderr)
        return 1
    df = df.dropna(subset=["category_name"])
    # Backwards-compat: older dump CSVs may not have an account_type column.
    # Treat missing as empty string (matches the inference-time fallback).
    if "account_type" not in df.columns:
        df["account_type"] = ""
    df["text"] = df.apply(
        lambda r: render(
            r.get("description"),
            r.get("merchant"),
            int(r["amount"]),
            str(r.get("account_type") or ""),
        ),
        axis=1,
    )

    # Hold out a stratified slice for evaluation. Drop classes with <2
    # examples — stratify can't handle them.
    counts = df["category_name"].value_counts()
    keep = counts[counts >= 2].index
    df = df[df["category_name"].isin(keep)]
    if df.empty:
        print("ERROR: after dropping rare classes nothing is left to train on",
              file=sys.stderr)
        return 1

    X = df["text"].tolist()
    y = df["category_name"].tolist()
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=args.test_size, random_state=args.seed, stratify=y,
    )

    # CalibratedClassifierCV's k-fold calibration needs ≥k examples per
    # class within `y_train`. Compute the smallest class size so
    # build_classifier picks a feasible cv (or falls back uncalibrated).
    smallest_class = min(pd.Series(y_train).value_counts())
    if smallest_class < 2:
        print("WARN: smallest training class has <2 examples — Platt "
              "calibration disabled, shipping uncalibrated LR.",
              file=sys.stderr)

    vec = build_vectoriser()
    clf = build_classifier(smallest_class_count=int(smallest_class))
    X_train_tfidf = vec.fit_transform(X_train).toarray().astype(np.float32)
    X_test_tfidf = vec.transform(X_test).toarray().astype(np.float32)
    clf.fit(X_train_tfidf, y_train)

    y_pred = clf.predict(X_test_tfidf)
    y_proba = clf.predict_proba(X_test_tfidf)
    acc = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred, output_dict=True,
                                   zero_division=0)
    print(f"Holdout accuracy: {acc:.3f}  ({len(X_test)} rows, "
          f"{X_train_tfidf.shape[1]} features)")

    # Per-class thresholds — see compute_per_class_thresholds for rationale.
    # Default (0.55) matches the Dart Categorizer's `_minMlConfidence` so
    # behaviour without a thresholds.json (or for unknown classes within
    # one) matches the pre-Tier-2 baseline exactly.
    thresholds = compute_per_class_thresholds(
        y_test, y_proba, clf.classes_,
        target_recall=0.7, default=0.55,
    )
    print("Per-class auto-apply thresholds:")
    for name, thr in sorted(thresholds.items()):
        marker = " (default)" if abs(thr - 0.55) < 1e-6 else ""
        print(f"  {name:<30s}  {thr:.3f}{marker}")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_onnx(clf, X_train_tfidf.shape[1],
               args.out_dir / "category_model.onnx")
    write_vocab_json(vec, args.out_dir / "vocab.json")
    # Pickled vectoriser is for eval.py only (lets it apply the same
    # transform to a labelled CSV without rewriting char_wb in two
    # languages). Not shipped in the app.
    joblib.dump(vec, args.out_dir / "vectoriser.pkl")
    write_labels_json(clf.classes_, args.out_dir / "labels.json")
    write_thresholds_json(
        thresholds,
        target_recall=0.7,
        default=0.55,
        path=args.out_dir / "thresholds.json",
    )
    write_test_vectors_json(vec, GOLDEN_INPUTS,
                            args.out_dir / "test_vectors.json")
    (args.out_dir / "metrics.json").write_text(json.dumps({
        "holdout_accuracy": acc,
        "n_train": len(X_train),
        "n_test": len(X_test),
        "n_features": int(X_train_tfidf.shape[1]),
        "n_classes": int(len(set(y_train))),
        "per_class": report,
    }, indent=2), encoding="utf-8")

    print(f"Wrote artefacts to {args.out_dir}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
