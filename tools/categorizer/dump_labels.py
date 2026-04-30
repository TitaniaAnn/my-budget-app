"""
Dump user-confirmed transaction labels from Supabase to a CSV ready for
train.py.

Only `category_assigned_by = 'user'` rows are pulled — these are ground
truth (manual entry, manual edit, or accepting a suggestion). Predictions
made by the keyword matcher or the ML model itself are excluded so the
classifier doesn't overfit to its own past mistakes.

The CSV's label column is `category_name` (not the UUID), because:
  • Training models on UUIDs is meaningless (they're random).
  • Predictions decode to a name; the Dart side then resolves the name
    against the household's category list to get a category_id.
  • Lets bootstrap_seed.py emit synthetic rows without needing to match
    real DB UUIDs.

Auth: requires the SERVICE-ROLE key (not the anon key) so RLS doesn't
hide other households' rows. Loaded from env or a .env file in this dir.
"""
from __future__ import annotations

import argparse
import csv
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

PAGE_SIZE = 1000

CSV_FIELDS = ["id", "description", "merchant", "amount", "category_name"]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", default="labels.csv", type=Path,
                        help="Output CSV path (default: labels.csv)")
    args = parser.parse_args()

    load_dotenv(Path(__file__).parent / ".env")
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    if not url or not key:
        print("ERROR: SUPABASE_URL and SUPABASE_SERVICE_KEY must be set "
              "(env or .env in tools/categorizer/).", file=sys.stderr)
        return 1

    client = create_client(url, key)

    rows: list[dict] = []
    offset = 0
    while True:
        resp = (
            client.table("transactions")
            .select("id, description, merchant, amount, category:categories(name)")
            .eq("category_assigned_by", "user")
            .not_.is_("category_id", "null")
            .range(offset, offset + PAGE_SIZE - 1)
            .execute()
        )
        page = resp.data or []
        if not page:
            break
        for r in page:
            cat = r.get("category") or {}
            rows.append({
                "id": r.get("id"),
                "description": r.get("description") or "",
                "merchant": r.get("merchant") or "",
                "amount": r.get("amount") or 0,
                "category_name": cat.get("name") or "",
            })
        if len(page) < PAGE_SIZE:
            break
        offset += PAGE_SIZE

    # Drop any rows with an empty label (orphaned join — shouldn't happen,
    # but easy to defend against).
    rows = [r for r in rows if r["category_name"]]

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_FIELDS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {len(rows)} labelled rows to {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
