# Transaction-categorizer training pipeline

Trains the on-device ML classifier that ships in `mobile/assets/ml/`,
replacing (or augmenting — see `mobile/lib/features/transactions/services/categorizer.dart`)
the legacy hand-maintained keyword matcher.

## What this produces

```
mobile/assets/ml/
  category_model.onnx    — ONNX-exported sklearn pipeline
                           (TfidfVectorizer + LogisticRegression)
  vocab.json             — { ngram: index, ... } — feeds the Dart tokenizer
  labels.json            — [ category_id, ... ] indexed by model output column
  test_vectors.json      — golden-set fixture: input string → expected
                           sparse TF-IDF output. Asserts Dart/Python parity.
```

## One-time setup

```bash
cd tools/categorizer
python -m venv .venv
. .venv/Scripts/activate     # or .venv/bin/activate on Unix
pip install -r requirements.txt
```

## Retrain workflow

1. **Dump current ground-truth labels** from Supabase:
   ```bash
   export SUPABASE_URL=...         # or set in .env
   export SUPABASE_SERVICE_KEY=... # service-role key, NOT anon
   python dump_labels.py --out labels.csv
   ```
   Pulls every `transactions` row where `category_assigned_by = 'user'` and
   `category_id IS NOT NULL`. Service-role key bypasses RLS so you get all
   households at once.

2. **(First run only) Bootstrap-seed**:
   When `labels.csv` has fewer than ~200 rows there isn't enough signal to
   train a real model. `bootstrap_seed.py` parses the keyword rules out of
   `mobile/lib/features/transactions/services/category_matcher.dart` and
   emits one synthetic row per keyword. Concatenate it to the dump:
   ```bash
   python bootstrap_seed.py --out seed.csv
   cat seed.csv >> labels.csv
   ```
   The model starts at roughly keyword-matcher parity and improves as real
   labels accumulate. Drop `seed.csv` from training once you have enough
   real labels.

3. **Train + export**:
   ```bash
   python train.py --in labels.csv --out-dir build/
   ```
   Produces `build/{category_model.onnx, vocab.json, labels.json,
   test_vectors.json}` plus a `metrics.json` with per-class precision/recall.

4. **Evaluate** (printed during training; re-run anytime):
   ```bash
   python eval.py --in labels.csv --model build/category_model.onnx
   ```
   Fails non-zero if holdout accuracy is below `--min-accuracy` (default
   0.70). Useful as a CI gate.

5. **Ship**:
   ```bash
   cp build/*.{onnx,json} ../../mobile/assets/ml/
   ```
   Then build the app as normal — the assets are picked up via `pubspec.yaml`.

## What gets fed to the model

Each transaction is rendered as a single string before tokenisation:

```
"<description>|<merchant or empty>|<sign>"
```

where `<sign>` is `+` for credits (income) or `-` for debits (expenses).
Including the sign means the model can learn merchant names that show up
on both sides ("VENMO" → Transfer either way; "AMAZON +" → refund vs
"AMAZON -" → shopping).

## What does NOT belong here

- No transaction *amount* — money normalisation across households is hard
  and the magnitude rarely disambiguates a category.
- No *account*, *date*, or *user* — would leak household identifiers and
  hurt generalisation.
- No category *names* — only category IDs. Model output is decoded back
  to IDs via `labels.json`, then resolved to a `Category` row in the app.
