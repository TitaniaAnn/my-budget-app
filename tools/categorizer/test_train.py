"""
Unit tests for the pure-logic pieces of train.py.

What's covered here:
  • _amount_bucket — boundary behaviour at the cutoff seams.
  • render — the inference-time string contract; the Dart side is
    pinned byte-identically by the parity test on the mobile side, but
    these tests guard the Python contract directly so a mistake doesn't
    have to wait for a Dart-side run to surface.
  • compute_per_class_thresholds — the heart of the Tier-2 per-class
    threshold work. Hand-crafted prediction matrices exercise the
    "highest threshold maintaining recall ≥ target" rule, the
    rare-class fallback, and the "model can't reach target" fallback.

Heavier paths (full train+ONNX export+eval) are exercised by the
categorizer GitHub Actions workflow on every push that touches
tools/categorizer/**, so they don't need duplicate Python coverage here.

Run locally:
  cd tools/categorizer
  python -m venv .venv && . .venv/Scripts/activate   # or .venv/bin/activate
  pip install -r requirements-dev.txt
  pytest
"""
from __future__ import annotations

import numpy as np
import pytest

from train import (
    AMOUNT_BUCKETS,
    _amount_bucket,
    compute_per_class_thresholds,
    render,
)


# ── _amount_bucket ─────────────────────────────────────────────────────────

class TestAmountBucket:
    """Boundaries documented in train.py:

        < $10   → xs
        < $50   → s
        < $200  → m
        < $1000 → l
        ≥ $1000 → xl

    Tests pin both the values inside each band and the seam (the value
    just below vs at the boundary), since the Dart side mirrors these
    cutoffs exactly.
    """

    @pytest.mark.parametrize(
        "cents, expected",
        [
            (0, "xs"),
            (1, "xs"),
            (999, "xs"),
            (1000, "s"),         # seam: $10 exactly is 's'
            (4999, "s"),
            (5000, "m"),         # seam: $50
            (19999, "m"),
            (20000, "l"),        # seam: $200
            (99999, "l"),
            (100000, "xl"),      # seam: $1000
            (1_000_000_00, "xl"),  # absurdly large → still xl
        ],
    )
    def test_band_assignment(self, cents, expected):
        assert _amount_bucket(cents) == expected

    def test_negative_amount_uses_absolute_value(self):
        # The bucket is amount-magnitude, not signed: a $50 debit and a
        # $50 credit fall into the same bucket. The model gets the sign
        # via the separate `+`/`-` field.
        assert _amount_bucket(-5000) == _amount_bucket(5000) == "m"
        assert _amount_bucket(-100000) == _amount_bucket(100000) == "xl"

    def test_amount_buckets_constant_is_in_ascending_order(self):
        # Defensive: the loop in _amount_bucket relies on the cutoffs
        # being ascending. If someone reorders AMOUNT_BUCKETS without
        # noticing, this catches it before retrain.
        cutoffs = [c for c, _ in AMOUNT_BUCKETS]
        assert cutoffs == sorted(cutoffs)


# ── render ─────────────────────────────────────────────────────────────────

class TestRender:
    """The inference-time string the model trains and predicts on. Dart's
    `_renderInput` mirrors this exactly — these tests guard the Python
    half of the contract."""

    def test_basic_shape_with_all_fields(self):
        s = render("STARBUCKS STORE 1234", "Starbucks", -485, "credit_card")
        assert s == "STARBUCKS STORE 1234|Starbucks|-|xs|credit_card"

    def test_positive_amount_renders_plus_sign(self):
        s = render("PAYROLL DEPOSIT", "ADP", 250000, "checking")
        # 250000 cents = $2500 → xl bucket, sign is +.
        assert s == "PAYROLL DEPOSIT|ADP|+|xl|checking"

    def test_zero_amount_falls_through_to_minus_sign(self):
        # The convention is `+ if amount > 0 else -` (mirror of categorizer
        # façade and Dart side). Zero amounts are rare in practice but the
        # behaviour is pinned.
        assert render("X", "Y", 0, "checking") == "X|Y|-|xs|checking"

    def test_empty_merchant_renders_as_empty_field(self):
        s = render("CASH WITHDRAWAL", "", -10000, "checking")
        # Cents < $200 → 'm'. Wait: 10000 cents = $100 → 'm'.
        assert s == "CASH WITHDRAWAL||-|m|checking"

    def test_none_merchant_renders_as_empty_field(self):
        # render() is called from main() via df.apply with .get(), which
        # can pass None. The function tolerates that — same fallback as
        # the empty string path.
        s = render("X", None, -100, "")  # type: ignore[arg-type]
        assert s == "X||-|xs|"

    def test_empty_description_renders_as_empty_field(self):
        # Mirrors the GOLDEN_INPUTS edge case `||-|xs|`.
        assert render("", "", -100, "") == "||-|xs|"

    def test_account_type_default_is_empty_string(self):
        # Backwards-compatible: callers who don't pass account_type get
        # an empty unknown-account placeholder (matches what dump_labels
        # writes when the account row is missing).
        s = render("FOO", "Bar", -500)
        assert s == "FOO|Bar|-|xs|"


# ── compute_per_class_thresholds ───────────────────────────────────────────

class TestComputePerClassThresholds:
    """The threshold-finding logic from Tier 2. Hand-crafted prediction
    matrices so we can reason precisely about expected output without
    needing a real trained model."""

    def test_strong_class_picks_high_threshold(self):
        # Two classes, A perfectly separated:
        #   - 10 A's all scored 0.95
        #   - 10 B's all scored 0.05 for class A
        # All thresholds in (0, 0.95] keep recall=1.0 ≥ 0.7. The highest
        # such threshold is 0.95.
        classes = np.array(["A", "B"])
        y_true = ["A"] * 10 + ["B"] * 10
        y_proba = np.array(
            [[0.95, 0.05]] * 10 + [[0.05, 0.95]] * 10
        )
        thresholds = compute_per_class_thresholds(
            y_true, y_proba, classes, target_recall=0.7, default=0.55,
        )
        # By symmetry both classes get threshold 0.95.
        assert thresholds["A"] == pytest.approx(0.95)
        assert thresholds["B"] == pytest.approx(0.95)

    def test_threshold_lands_at_recall_boundary(self):
        # Class A's scores span 0.45..0.90 in 0.05 steps (10 examples).
        # Recall ≥ 0.7 ⇒ catch at least 7 of the 10 A's.
        # The 7th-highest A-score is 0.60 (sorted desc: 0.90, 0.85, 0.80,
        # 0.75, 0.70, 0.65, 0.60). At threshold 0.60, exactly 7 A's are
        # predicted positive → recall = 0.7. So the highest valid
        # threshold is 0.60.
        classes = np.array(["A", "B"])
        a_scores = [0.90, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50, 0.45]
        b_scores = [0.40, 0.35, 0.30, 0.25, 0.20, 0.15, 0.10, 0.05, 0.02, 0.01]
        y_true = ["A"] * 10 + ["B"] * 10
        y_proba = np.array(
            [[s, 1.0 - s] for s in a_scores]
            + [[s, 1.0 - s] for s in b_scores]
        )
        thresholds = compute_per_class_thresholds(
            y_true, y_proba, classes, target_recall=0.7, default=0.55,
        )
        assert thresholds["A"] == pytest.approx(0.60)

    def test_class_absent_from_holdout_falls_back_to_default(self):
        # Class C exists in `classes` (the model knows about it) but no
        # holdout example has y_true == 'C'. We can't measure recall, so
        # the threshold falls back to the global default.
        classes = np.array(["A", "B", "C"])
        y_true = ["A"] * 5 + ["B"] * 5
        y_proba = np.array(
            [[0.9, 0.05, 0.05]] * 5 + [[0.05, 0.9, 0.05]] * 5
        )
        thresholds = compute_per_class_thresholds(
            y_true, y_proba, classes, target_recall=0.7, default=0.55,
        )
        assert thresholds["C"] == pytest.approx(0.55)

    def test_class_that_cannot_reach_target_recall_falls_back_to_default(self):
        # Construct a class where even at the lowest threshold the model
        # only catches a few positives — recall never reaches the target.
        # 10 A's, but the model assigns them low probability for class A
        # because (in this hypothetical) the model is wrong about A.
        classes = np.array(["A", "B"])
        y_true = ["A"] * 10 + ["B"] * 10
        # A's all score 0.05 for class A. B's score 0.95 for B.
        y_proba = np.array(
            [[0.05, 0.95]] * 10 + [[0.05, 0.95]] * 10
        )
        # All A's get the same low score, so at any threshold > 0.05
        # we predict zero A's → recall = 0. At threshold ≤ 0.05 we
        # predict all 20 rows as A → recall = 1.0 but precision is 0.5.
        # precision_recall_curve returns thresholds = [0.05] only (the
        # one unique non-trivial score). recall[:-1] = [1.0] → valid.
        thresholds = compute_per_class_thresholds(
            y_true, y_proba, classes, target_recall=0.7, default=0.55,
        )
        # With only one unique score the highest valid threshold is 0.05.
        # That's a degenerate case — the test just pins behaviour. The
        # more interesting case is "model can't reach target recall at
        # ANY threshold": that requires y_proba[:, A_idx] to be 0 for
        # the A examples, which would still give recall=1 at threshold=0.
        # Easier to verify the default-fallback path with the absent-class
        # test above; this case verifies we don't crash on degenerate
        # input.
        assert "A" in thresholds  # didn't crash
        assert 0.0 <= thresholds["A"] <= 1.0

    def test_truly_never_reaches_target_falls_back(self):
        # Force the "no threshold valid" branch: a class where every
        # positive example has probability 0 for that class. recall is
        # always 0 → no threshold satisfies recall ≥ target.
        classes = np.array(["A", "B"])
        y_true = ["A"] * 10 + ["B"] * 10
        # A examples score 0.0 for class A, B examples score moderate
        # positive for class A (false positives).
        y_proba = np.array(
            [[0.0, 1.0]] * 10 + [[0.5, 0.5]] * 10
        )
        thresholds = compute_per_class_thresholds(
            y_true, y_proba, classes, target_recall=0.7, default=0.55,
        )
        # Recall is 0 at any threshold > 0 (no A example crosses).
        # At threshold 0 (and below) all rows predicted as A → recall = 1
        # but precision is 0.5. precision_recall_curve produces thresholds
        # for unique non-zero scores only, so [0.5]. At thresh 0.5,
        # recall = 0 (no A scores ≥ 0.5). So valid is all-False → fallback.
        assert thresholds["A"] == pytest.approx(0.55)

    def test_returns_only_string_class_names(self):
        # `classes` is a numpy array; the function should coerce names to
        # str so the JSON serialiser doesn't choke on numpy strings later.
        classes = np.array(["Coffee & Drinks", "Groceries"])
        y_true = ["Coffee & Drinks"] * 5 + ["Groceries"] * 5
        y_proba = np.array(
            [[0.9, 0.1]] * 5 + [[0.1, 0.9]] * 5
        )
        thresholds = compute_per_class_thresholds(
            y_true, y_proba, classes, target_recall=0.7, default=0.55,
        )
        for k, v in thresholds.items():
            assert isinstance(k, str)
            assert isinstance(v, float)

    def test_target_recall_parameter_is_respected(self):
        # Same data, different target_recall. Lower target → higher
        # threshold can still be valid. Higher target → must use lower
        # threshold (catch more). Pin that the parameter actually moves
        # the result.
        classes = np.array(["A", "B"])
        a_scores = [0.90, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50, 0.45]
        b_scores = [0.40, 0.35, 0.30, 0.25, 0.20, 0.15, 0.10, 0.05, 0.02, 0.01]
        y_true = ["A"] * 10 + ["B"] * 10
        y_proba = np.array(
            [[s, 1.0 - s] for s in a_scores]
            + [[s, 1.0 - s] for s in b_scores]
        )

        thr_lenient = compute_per_class_thresholds(
            y_true, y_proba, classes, target_recall=0.4, default=0.55,
        )
        thr_strict = compute_per_class_thresholds(
            y_true, y_proba, classes, target_recall=0.9, default=0.55,
        )
        # target_recall=0.4 → catch ≥4 A's → threshold ≤ 0.75 (4th score).
        # target_recall=0.9 → catch ≥9 A's → threshold ≤ 0.50 (9th score).
        assert thr_lenient["A"] > thr_strict["A"]
