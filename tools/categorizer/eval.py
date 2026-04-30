"""
Evaluate a trained ONNX category model against a labelled CSV.

Loads the pickled TfidfVectorizer alongside the ONNX classifier, applies
the same transform train.py used, then runs ONNX inference. Exits
non-zero when accuracy falls below --min-accuracy. Use as a CI gate
before promoting a model into mobile/assets/ml/.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import joblib
import numpy as np
import onnxruntime as ort
import pandas as pd
from sklearn.metrics import accuracy_score, classification_report

from train import render  # same string format as training


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--in", dest="csv", required=True, type=Path)
    parser.add_argument("--model", default=Path("build/category_model.onnx"),
                        type=Path)
    parser.add_argument("--vectoriser",
                        default=Path("build/vectoriser.pkl"),
                        type=Path)
    parser.add_argument("--min-accuracy", type=float, default=0.70)
    args = parser.parse_args()

    df = pd.read_csv(args.csv)
    df = df.dropna(subset=["category_name"])
    df["text"] = df.apply(
        lambda r: render(r.get("description"), r.get("merchant"),
                         int(r["amount"])),
        axis=1,
    )

    vec = joblib.load(args.vectoriser)
    X = vec.transform(df["text"].tolist()).toarray().astype(np.float32)

    sess = ort.InferenceSession(str(args.model),
                                providers=["CPUExecutionProvider"])
    input_name = sess.get_inputs()[0].name
    raw = sess.run(None, {input_name: X})
    # skl2onnx convention: outputs[0] = predicted label, outputs[1] = proba.
    y_pred = [str(p) for p in raw[0]]
    y_true = df["category_name"].tolist()

    acc = accuracy_score(y_true, y_pred)
    print(f"Accuracy: {acc:.3f}  ({len(df)} rows)")
    print(classification_report(y_true, y_pred, zero_division=0))

    if acc < args.min_accuracy:
        print(f"FAIL: accuracy {acc:.3f} < min {args.min_accuracy:.3f}",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
