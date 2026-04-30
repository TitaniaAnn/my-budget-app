"""
Evaluate a trained ONNX category model against a labelled CSV.

Exits non-zero when holdout accuracy falls below --min-accuracy. Use as a
CI gate before promoting a model into mobile/assets/ml/.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

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
    parser.add_argument("--labels", default=Path("build/labels.json"),
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

    sess = ort.InferenceSession(str(args.model),
                                providers=["CPUExecutionProvider"])
    input_name = sess.get_inputs()[0].name

    inputs = np.array(df["text"].tolist(), dtype=object).reshape(-1, 1)
    raw = sess.run(None, {input_name: inputs})
    # skl2onnx convention: outputs[0] = predicted label, outputs[1] = proba dict
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
