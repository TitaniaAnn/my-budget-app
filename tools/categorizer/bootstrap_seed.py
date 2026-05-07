"""
Cold-start training data: parse the legacy keyword rules out of
`mobile/lib/features/transactions/services/category_matcher.dart` and emit
one synthetic labelled row per keyword, in the same CSV shape that
dump_labels.py produces.

Use this only when the real label dump is too small to train on. Drop the
seed rows from training as soon as you have enough real user labels.

The label is the system category NAME (e.g. "Groceries"), not a UUID —
seed UUIDs are generated at INSERT time so they're not stable across DB
resets, and using names lets the trained model resolve to whichever
category id the user's household has for that name (mirrors how the
legacy CategoryMatcher already works).

KNOWN CONSTRAINT — regex parsing of Dart source.
The RULE_BLOCK_RE / QUOTED_STR_RE pair below is fragile to refactors of
the Dart map literal in category_matcher.dart (e.g. switching to a
function builder, splitting the rules across files, or introducing
multi-line raw strings). Acceptable trade-off: the alternative is
maintaining a duplicate Python copy of the keyword rules, which would
silently drift. If you change the shape of `_incomeRules` /
`_expenseRules`, re-run `python bootstrap_seed.py --out /tmp/seed.csv`
and eyeball the result — empty CSV means the regex stopped matching.
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
import uuid
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MATCHER_DART = (
    REPO_ROOT
    / "mobile" / "lib" / "features" / "transactions" / "services" / "category_matcher.dart"
)

# Matches a category-name → keyword-list block, e.g.
#     'Coffee & Drinks': [
#         'starbucks', "dutch bros", "dunkin'", 'coffee',
#     ],
# Handles both single- and double-quoted Dart strings (Dart allows either),
# and escaped quotes via backslash (e.g. 'bj\'s wholesale').
RULE_BLOCK_RE = re.compile(
    r"""(?:'([^'\\]*(?:\\.[^'\\]*)*)'|"([^"\\]*(?:\\.[^"\\]*)*)")
        \s*:\s*\[(?P<body>[^\]]*)\]""",
    re.VERBOSE | re.DOTALL,
)
# Matches a single quoted string literal — single OR double quoted, with
# backslash escapes — and returns the inner text via group 1 or 2.
QUOTED_STR_RE = re.compile(
    r"""'([^'\\]*(?:\\.[^'\\]*)*)'|"([^"\\]*(?:\\.[^"\\]*)*)\""""
)


def _decode_dart_str(s: str) -> str:
    """Resolve Dart string escapes we actually use (just \\' and \\")."""
    return s.replace("\\'", "'").replace('\\"', '"').replace("\\\\", "\\")


def parse_rules(dart_src: str) -> dict[str, dict[str, list[str]]]:
    """Returns {'income': {cat: [kw,...]}, 'expense': {...}}."""
    out: dict[str, dict[str, list[str]]] = {"income": {}, "expense": {}}
    for kind, marker in (("income", "_incomeRules"), ("expense", "_expenseRules")):
        m = re.search(rf"{marker}\s*=\s*<String,\s*List<String>>\{{(.*?)\n\s*\}};",
                      dart_src, re.DOTALL)
        if not m:
            raise RuntimeError(f"Could not find {marker} block in matcher source")
        block = m.group(1)
        for rb in RULE_BLOCK_RE.finditer(block):
            name = _decode_dart_str(rb.group(1) or rb.group(2) or "")
            keywords = [
                _decode_dart_str(g1 or g2 or "")
                for g1, g2 in QUOTED_STR_RE.findall(rb.group("body"))
            ]
            keywords = [k for k in keywords if k]
            if keywords:
                out[kind][name] = keywords
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default="seed.csv", type=Path)
    parser.add_argument("--matcher", default=MATCHER_DART, type=Path)
    args = parser.parse_args()

    if not args.matcher.exists():
        print(f"ERROR: matcher source not found at {args.matcher}", file=sys.stderr)
        return 1

    rules = parse_rules(args.matcher.read_text(encoding="utf-8"))

    rows: list[dict] = []
    for kind, by_name in rules.items():
        amount_sign = 1 if kind == "income" else -1
        for cat_name, keywords in by_name.items():
            for kw in keywords:
                rows.append({
                    "id": str(uuid.uuid4()),
                    "description": kw,
                    "merchant": "",
                    # Magnitude is now a feature (amount bucket). Pick a
                    # plausible per-category default so seed rows don't all
                    # land in the same bucket: rent/mortgage is large,
                    # subscriptions are small, payroll is xl, etc. The
                    # bucketing is in train.py:_amount_bucket; values here
                    # are absolute cents.
                    "amount": amount_sign * _seed_amount_cents(cat_name),
                    # Bootstrap rows have no real account context; leave
                    # account_type empty so the model treats them as the
                    # "unknown account" prior. Real labels from
                    # dump_labels.py supply the account_type.
                    "account_type": "",
                    "category_name": cat_name,
                })

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "id", "description", "merchant", "amount",
                "account_type", "category_name",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} synthetic rows to {args.out}")
    return 0


# Per-category amount priors for seed rows, in absolute cents. Loose hand-
# picked values that put each seeded category in a plausible bucket so the
# model picks up the amount-bucket signal even from synthetic data. Falls
# back to $20 (which lands in 's') for unknown categories.
_SEED_AMOUNT_CENTS = {
    # Income — typically large
    "Salary": 250000,           # xl
    "Freelance": 80000,         # l
    "Investment Income": 5000,  # m
    "Other Income": 2000,       # s
    # Housing
    "Rent / Mortgage": 150000,  # xl
    "Home Insurance": 12000,    # m
    "Utilities": 8000,          # m
    "Internet / Phone": 7500,   # m
    "Home Maintenance": 4000,   # s
    # Food
    "Groceries": 8000,          # m
    "Restaurants": 3500,        # s
    "Coffee & Drinks": 600,     # xs
    "Takeout & Delivery": 2500, # s
    # Transport
    "Gas": 4000,                # s
    "Car Insurance": 12000,     # m
    "Car Payment": 35000,       # l
    "Car Maintenance": 8000,    # m
    "Rideshare / Parking": 1500,
    "Public Transit": 500,
    # Health
    "Health Insurance": 30000,  # l
    "Doctor / Dentist": 15000,  # m
    "Prescriptions": 2500,      # s
    "Gym & Fitness": 4000,      # s
    "Vision & Dental": 8000,    # m
    # Personal / lifestyle
    "Subscriptions": 1500,      # s
    "Entertainment": 3000,      # s
    "Personal Care": 4000,      # s
    "Clothing": 5000,           # m
    "Books & Education": 3000,  # s
    "Hobbies": 4000,            # s
    # Kids
    "Childcare": 80000,         # l
    "School & Supplies": 4000,  # s
    "Activities & Sports": 5000,
    # Debt
    "Credit Card Payment": 50000,  # l
    "Student Loan": 30000,         # l
    # Savings — vary
    "401k / Retirement": 50000,    # l
    "HSA Contribution": 30000,     # l
    "529 / College Savings": 25000,
    # Other
    "Charitable Donations": 5000,  # m
    "Gifts": 5000,                  # m
    "Taxes": 100000,                # xl
    "Transfer": 50000,              # l
}


def _seed_amount_cents(category_name: str) -> int:
    return _SEED_AMOUNT_CENTS.get(category_name, 2000)  # default $20 → 's'


if __name__ == "__main__":
    sys.exit(main())
