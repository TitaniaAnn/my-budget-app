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
                    # Magnitude isn't a feature; train.py only looks at sign.
                    "amount": amount_sign * 1000,
                    "category_name": cat_name,
                })

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["id", "description", "merchant", "amount", "category_name"],
        )
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} synthetic rows to {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
