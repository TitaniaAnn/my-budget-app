"""
Train the on-device transaction classifier and export the artefacts the
Flutter app consumes from `mobile/assets/ml/`.

Inputs (CSV with columns id, description, merchant, amount, category_name):
  - real labels from dump_labels.py
  - synthetic seeds from bootstrap_seed.py (cold-start only)

Outputs (in --out-dir):
  category_model.onnx   — TfidfVectorizer + LogisticRegression
  vocab.json            — { ngram: index, idf: [..], analyzer params }
  labels.json           — [ category_name, ... ] indexed by output column
  test_vectors.json     — golden fixture for the Dart parity test
  metrics.json          — holdout accuracy + per-class precision/recall

Pipeline:
  TfidfVectorizer(analyzer='char_wb', ngram_range=(3,5),
                  lowercase=True, sublinear_tf=False)
  → LogisticRegression(C=4.0, max_iter=1000, class_weight='balanced',
                       solver='liblinear', multi_class='ovr')

The text fed to the vectoriser is `<description>|<merchant>|<sign>` where
sign is '+' for credits or '-' for debits — same shape used at inference.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from skl2onnx import convert_sklearn
from skl2onnx.common.data_types import StringTensorType


# ── Feature shaping ─────────────────────────────────────────────────────────

def render(description: str, merchant: str, amount: int) -> str:
    """Same string format used at inference time on the device."""
    sign = "+" if amount > 0 else "-"
    return f"{description or ''}|{merchant or ''}|{sign}"


# ── Pipeline factory ────────────────────────────────────────────────────────

def build_pipeline() -> Pipeline:
    return Pipeline([
        ("tfidf", TfidfVectorizer(
            analyzer="char_wb",
            ngram_range=(3, 5),
            lowercase=True,
            sublinear_tf=False,
            # Hard cap so the vocab JSON doesn't bloat the app asset.
            max_features=40_000,
            min_df=1,
        )),
        ("clf", LogisticRegression(
            C=4.0,
            max_iter=1000,
            class_weight="balanced",
            solver="liblinear",
        )),
    ])


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


def write_onnx(pipeline: Pipeline, path: Path) -> None:
    initial_types = [("input", StringTensorType([None, 1]))]
    onx = convert_sklearn(pipeline, initial_types=initial_types,
                          target_opset=15)
    path.write_bytes(onx.SerializeToString())


# ── Main ────────────────────────────────────────────────────────────────────

GOLDEN_INPUTS = [
    # Stable handful that exercises sign + merchant + special chars + casing.
    "STARBUCKS STORE 1234|Starbucks|-",
    "AMAZON.COM*MK1AB2CD|Amazon|-",
    "AMAZON REFUND ORDER|Amazon|+",
    "ZELLE PAYMENT TO JOHN|Zelle|-",
    "PAYROLL DEPOSIT - ADP|ADP|+",
    "shell gas #4421|Shell|-",
    "VENMO TRANSFER||+",
    "CHIPOTLE 0987||-",
    "Netflix.com|Netflix|-",
    "TRADER JOE'S #102|Trader Joe's|-",
    # Edge cases:
    "||-",                        # empty desc + empty merchant
    "X|Y|+",                      # very short
    "a b c d e|f g h|-",          # multi-token
    "ÜBER eats|Über|-",          # non-ASCII
    "  CAPS WITH  SPACES  ||-",  # leading/trailing/internal whitespace
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
    df["text"] = df.apply(
        lambda r: render(r.get("description"), r.get("merchant"), int(r["amount"])),
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

    pipeline = build_pipeline()
    pipeline.fit(X_train, y_train)

    y_pred = pipeline.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred, output_dict=True,
                                   zero_division=0)
    print(f"Holdout accuracy: {acc:.3f}  ({len(X_test)} rows)")

    args.out_dir.mkdir(parents=True, exist_ok=True)
    write_onnx(pipeline, args.out_dir / "category_model.onnx")
    write_vocab_json(pipeline.named_steps["tfidf"],
                     args.out_dir / "vocab.json")
    write_labels_json(pipeline.named_steps["clf"].classes_,
                      args.out_dir / "labels.json")
    write_test_vectors_json(pipeline.named_steps["tfidf"], GOLDEN_INPUTS,
                            args.out_dir / "test_vectors.json")
    (args.out_dir / "metrics.json").write_text(json.dumps({
        "holdout_accuracy": acc,
        "n_train": len(X_train),
        "n_test": len(X_test),
        "n_classes": int(len(set(y_train))),
        "per_class": report,
    }, indent=2), encoding="utf-8")

    print(f"Wrote artefacts to {args.out_dir}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
