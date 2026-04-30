# ML category model assets

These files are produced by `tools/categorizer/train.py` and are NOT
committed to the repo (they're regenerated whenever the model is
retrained — see `tools/categorizer/README.md`).

Expected files after running training:

```
category_model.onnx    — sklearn pipeline exported via skl2onnx
vocab.json             — { ngram: index, ... } + idf weights
labels.json            — [ category_name, ... ]
test_vectors.json      — golden fixture for the Dart parity test
```

When this directory is empty (which is the default in a freshly cloned
repo), `MlCategoryClassifier.load()` returns `null`, the `Categorizer`
façade falls through to the legacy keyword matcher, and the app behaves
exactly as it did before the ML work.

To regenerate:

```bash
cd ../../tools/categorizer
python bootstrap_seed.py --out seed.csv
python train.py --in seed.csv --out-dir build/
cp build/* ../../mobile/assets/ml/
```
