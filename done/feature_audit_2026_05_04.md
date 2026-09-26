# Feature audit & build plan — 2026-05-04

Audit against eight requested features, plus draft SQL/Dart for the gaps.

## Status matrix

| Feature                                         | DB schema | Repo / logic | UI       |
| ----------------------------------------------- | --------- | ------------ | -------- |
| Receipts: upload                                | done      | done         | done     |
| Receipts: pair to bank transaction              | done      | gap          | stub     |
| Receipts: per-line-item category split          | done      | done         | gap      |
| Contractor tab                                  | gap       | gap          | gap      |
| Budgets: 1wk / 2wk / month / 6mo / year         | done      | done         | done     |
| Transaction import dedup                        | done      | done         | done     |
| Scenarios tab                                   | done      | done         | done     |
| Net worth                                       | done      | done         | done     |
| Net worth: growth suggestions                   | n/a       | gap          | gap      |
| Investment account totals (401k/IRA/brokerage)  | done      | done         | done     |
| Investment holdings / positions                 | gap       | gap          | gap      |

"Stub" means a placeholder comment exists but no behaviour is wired up.

---

## 1. Receipt ↔ transaction pairing

DB link already exists: `transactions.receipt_id UUID REFERENCES receipts(id)` ([001_initial_schema.sql:131](../supabase/migrations/001_initial_schema.sql)). The UI placeholder is in [receipt_detail_screen.dart:5](../mobile/lib/features/receipts/screens/receipt_detail_screen.dart): `// The "Pair to Transaction" action is a placeholder for future linking logic.`

### Pairing model

Two flows, one shared backend:

1. **From the receipt side** (most common): user opens a receipt, app shows ranked candidates, user picks one.
2. **From the transaction side** (less common): user opens a transaction with no receipt, app shows recent unpaired receipts.

Ranking heuristic for candidates:

- Same household
- Transaction date within ±3 days of receipt date (or receipt upload date if `receipt_date` is null)
- `transactions.amount.abs()` within ±5% of `receipts.total_amount` (or exact match preferred)
- No existing `receipt_id` on the transaction (don't steal from another receipt)
- Score = (date proximity) + (amount proximity) + (merchant string similarity if both present)

Fuzzy merchant match is a nice-to-have, not v1. Top 5 candidates is enough.

### Migration 019 — candidate-finder RPC

Putting the matcher in SQL keeps it consistent with `save_receipt_line_items` (migration 018) and means the client doesn't need to over-fetch transactions to filter in Dart. Runs as caller, RLS-respecting.

```sql
-- supabase/migrations/019_receipt_match_candidates.sql
-- ============================================================
-- Find candidate transactions to pair with a receipt.
--
-- Returns up to N transactions in the same household, near the
-- receipt's date and total, that are not already paired with a
-- receipt. Score is higher = better match.
--
-- Runs as caller (no SECURITY DEFINER) so RLS on transactions
-- and receipts is preserved.
-- ============================================================

CREATE OR REPLACE FUNCTION find_receipt_match_candidates(
  p_receipt_id UUID,
  p_max_results INTEGER DEFAULT 5,
  p_date_window_days INTEGER DEFAULT 3,
  p_amount_tolerance_pct NUMERIC DEFAULT 0.05
)
RETURNS TABLE (
  transaction_id UUID,
  account_id UUID,
  transaction_date DATE,
  amount INTEGER,
  description TEXT,
  merchant TEXT,
  score NUMERIC
)
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  v_receipt receipts%ROWTYPE;
  v_anchor_date DATE;
  v_target_amount INTEGER;
BEGIN
  SELECT * INTO v_receipt FROM receipts WHERE id = p_receipt_id;
  IF v_receipt IS NULL THEN
    RETURN;  -- RLS hid it, or it was deleted; empty set
  END IF;

  -- Use receipt_date if confirmed, else upload date.
  v_anchor_date := COALESCE(v_receipt.receipt_date, v_receipt.uploaded_at::DATE);
  v_target_amount := v_receipt.total_amount;

  -- If we don't have a total yet, fall back to date-only matching.
  RETURN QUERY
    SELECT
      t.id,
      t.account_id,
      t.transaction_date,
      t.amount,
      t.description,
      t.merchant,
      (
        -- Date score: 1.0 at exact match, drops linearly to 0 at edge of window
        (1.0 - (ABS(t.transaction_date - v_anchor_date)::NUMERIC
                / GREATEST(p_date_window_days, 1))) * 0.5
        +
        -- Amount score: 1.0 at exact match, 0 at edge of tolerance, 0 if no total
        CASE
          WHEN v_target_amount IS NULL THEN 0
          WHEN ABS(t.amount) = v_target_amount THEN 0.5
          ELSE GREATEST(
            0,
            (1.0 - (ABS(ABS(t.amount) - v_target_amount)::NUMERIC
                    / NULLIF(v_target_amount * p_amount_tolerance_pct, 0)))
          ) * 0.5
        END
      )::NUMERIC AS score
    FROM transactions t
    WHERE t.household_id = v_receipt.household_id
      AND t.receipt_id IS NULL
      AND t.transaction_date BETWEEN v_anchor_date - p_date_window_days
                                 AND v_anchor_date + p_date_window_days
      AND (
        v_target_amount IS NULL
        OR ABS(ABS(t.amount) - v_target_amount)
           <= GREATEST(v_target_amount * p_amount_tolerance_pct, 100)
      )
    ORDER BY score DESC, t.transaction_date DESC
    LIMIT p_max_results;
END;
$$;
```

### TransactionsRepository addition

Single line on the existing transactions table; no schema change needed for the actual pairing write.

```dart
// mobile/lib/features/transactions/repositories/transactions_repository.dart

/// Pair an existing transaction to a receipt. Setting [receiptId] to null
/// unpairs. Returns nothing — caller invalidates the relevant providers.
Future<void> setReceiptId({
  required String transactionId,
  required String? receiptId,
}) async {
  await supabase
      .from('transactions')
      .update({'receipt_id': receiptId})
      .eq('id', transactionId);
}
```

### ReceiptsRepository addition

```dart
// mobile/lib/features/receipts/repositories/receipts_repository.dart

class ReceiptMatchCandidate {
  const ReceiptMatchCandidate({
    required this.transactionId,
    required this.accountId,
    required this.transactionDate,
    required this.amountCents,
    required this.description,
    required this.merchant,
    required this.score,
  });

  final String transactionId;
  final String accountId;
  final DateTime transactionDate;
  final int amountCents;
  final String description;
  final String? merchant;
  final double score;
}

Future<List<ReceiptMatchCandidate>> findMatchCandidates(String receiptId) async {
  final data = await supabase.rpc(
    'find_receipt_match_candidates',
    params: {'p_receipt_id': receiptId},
  );
  if (data == null) return [];
  return (data as List).map((row) {
    final r = row as Map<String, dynamic>;
    return ReceiptMatchCandidate(
      transactionId: r['transaction_id'] as String,
      accountId: r['account_id'] as String,
      transactionDate: DateTime.parse(r['transaction_date'] as String),
      amountCents: r['amount'] as int,
      description: r['description'] as String,
      merchant: r['merchant'] as String?,
      score: (r['score'] as num).toDouble(),
    );
  }).toList();
}
```

### UI sketch — `pair_receipt_sheet.dart`

Bottom sheet with the candidates list, one tap to pair. Reuses `app_sheet.dart`.

```dart
// mobile/lib/features/receipts/widgets/pair_receipt_sheet.dart

class PairReceiptSheet extends ConsumerStatefulWidget {
  const PairReceiptSheet({super.key, required this.receiptId});
  final String receiptId;

  @override
  ConsumerState<PairReceiptSheet> createState() => _PairReceiptSheetState();
}

class _PairReceiptSheetState extends ConsumerState<PairReceiptSheet> {
  late Future<List<ReceiptMatchCandidate>> _candidates;

  @override
  void initState() {
    super.initState();
    _candidates = ref
        .read(receiptsRepositoryProvider)
        .findMatchCandidates(widget.receiptId);
  }

  Future<void> _pair(ReceiptMatchCandidate c) async {
    await ref.read(transactionsRepositoryProvider).setReceiptId(
          transactionId: c.transactionId,
          receiptId: widget.receiptId,
        );
    ref.invalidate(receiptProvider(widget.receiptId));
    ref.invalidate(transactionsProvider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Pair to Transaction',
      child: FutureBuilder<List<ReceiptMatchCandidate>>(
        future: _candidates,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final cs = snap.data!;
          if (cs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No nearby transactions match this receipt. '
                'You can fill in merchant/date/total above and try again.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: cs.map((c) => ListTile(
              title: Text(c.description),
              subtitle: Text(
                '${DateFormat.yMMMd().format(c.transactionDate)}'
                '${c.merchant != null ? ' · ${c.merchant}' : ''}',
              ),
              trailing: Text(
                NumberFormat.currency(symbol: '\$').format(c.amountCents.abs() / 100),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () => _pair(c),
            )).toList(),
          );
        },
      ),
    );
  }
}
```

Then on `receipt_detail_screen.dart`, add a button next to "Save Changes":

```dart
OutlinedButton.icon(
  onPressed: () => showAppSheet<void>(
    context,
    child: PairReceiptSheet(receiptId: receipt.id),
  ),
  icon: const Icon(Icons.link_outlined),
  label: const Text('Pair to Transaction'),
),
```

When a transaction has a `receipt_id`, the existing `TransactionCard` should show a small receipt icon — that's a 5-line change.

---

## 2. Per-line-item category split — UI only

Backend is already complete: `receipt_line_items.category_id` exists, the `save_receipt_line_items` RPC writes per-item categories atomically, and `ReceiptsRepository.saveLineItems()` is wired up. The block in `receipt_detail_screen.dart:378-435` just needs to become editable.

### Open design question

Splitting line items across categories is data, not budget motion. Right now budgets aggregate from `transactions.category_id`, so even after splitting a $200 Home Depot receipt across "Home Repair" and "Pottery Studio Supplies", spending on Pottery Studio Supplies stays $0 in the budget view because the underlying transaction is still single-category.

Two ways to fix it. Pick before building the UI.

**Option A — split the transaction.**
When a receipt is paired to a transaction and has line items in multiple categories, automatically split that transaction into N child transactions, one per category. Adds complexity around editing/deleting splits and reconciling with the bank account. The split children should sum to the parent.

**Option B — change budget rollups.**
Spending on category X = `SUM(transactions.amount WHERE category_id = X AND receipt_id IS NULL)` + `SUM(receipt_line_items.amount WHERE category_id = X)`. Simpler. Means a transaction's `category_id` becomes "primary category for filing," and the line items dictate budget impact when present. Requires updating every budget query.

Recommend B. Cleaner mental model: transaction is filing, line items are accounting.

### UI: editable line items

Replace the read-only `_LineItemsList` with a list of editable rows. Each row has:

- Description (TextField)
- Amount (MoneyTextField — already exists)
- Category dropdown (reusing the category picker from `add_transaction_sheet.dart`)
- A "Split" / "Delete" overflow menu

A "Save Line Items" button at the bottom calls `saveLineItems()`. Existing OCR-extracted items pre-populate the form.

Don't try to do this inline — push it to a `_LineItemEditor` screen or full-height sheet so the keyboard isn't fighting the receipt image. The current `receipt_detail_screen.dart` is already busy.

---

## 3. Contractor tab — pick a dimension first

Three options, in order of scope. The right answer depends on whether you ever need a *third* dimension (e.g. pottery studio expenses separate from contractor expenses).

### Option A — `transaction_tags` table (recommended)

```sql
-- supabase/migrations/020_transaction_tags.sql
CREATE TABLE transaction_tags (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id  UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  color         CHAR(7),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (household_id, name)
);

CREATE TABLE transaction_tag_assignments (
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  tag_id         UUID NOT NULL REFERENCES transaction_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (transaction_id, tag_id)
);

CREATE TABLE receipt_line_item_tag_assignments (
  line_item_id UUID NOT NULL REFERENCES receipt_line_items(id) ON DELETE CASCADE,
  tag_id       UUID NOT NULL REFERENCES transaction_tags(id) ON DELETE CASCADE,
  PRIMARY KEY (line_item_id, tag_id)
);

-- RLS: visible/manageable by household members; standard pattern.
```

Pros: extensible (contractor + pottery studio + tax-deductible can all coexist on one transaction), works at line-item granularity.
Cons: more UI surface (tag picker), join overhead in queries.

The Contractor tab is then a `WHERE` filter on a `contractor` tag.

### Option B — `business_context` enum on transactions and line items

```sql
CREATE TYPE business_context AS ENUM ('personal', 'contractor', 'pottery_studio');

ALTER TABLE transactions
  ADD COLUMN business_context business_context NOT NULL DEFAULT 'personal';

ALTER TABLE receipt_line_items
  ADD COLUMN business_context business_context;  -- NULL = inherit from transaction
```

Pros: faster queries, simpler picker (one dropdown), no join.
Cons: a transaction is exactly one business. Can't tag the same Costco run as both "contractor" and "pottery_studio" if you bought materials for both. Requires a migration every time you add a new business.

### Option C — `is_contractor_expense` boolean

Smallest change. Quickest to ship. You will regret it the first time you want to track the pottery studio separately.

### Recommendation

**Option A.** You already separate contractor and pottery studio in your work life — the schema should reflect that. Tags also let you adopt patterns like `tax_deductible`, `reimbursable`, `client:acme` without further migrations. The slight query overhead is invisible at household-scale data.

Implementation order: tag CRUD → tag picker on transaction edit → tag picker on line-item edit → Contractor tab as a filtered transactions view → CSV export for tax time.

---

## 4. Investment holdings / portfolio

Investment account types already exist and contribute to net worth. Missing: per-security tracking.

### Schema sketch

```sql
-- supabase/migrations/021_holdings.sql
CREATE TABLE holdings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,
  account_id      UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  symbol          TEXT NOT NULL,                   -- 'AAPL', 'VTSAX', 'BTC'
  description     TEXT,                            -- 'Apple Inc.'
  quantity        NUMERIC(20, 8) NOT NULL,         -- shares; high precision for crypto/fractional
  cost_basis      INTEGER,                         -- cents; total cost basis (null = unknown)
  current_value   INTEGER NOT NULL,                -- cents; manual or stale price feed
  asset_class     TEXT,                            -- 'us_equity', 'intl_equity', 'bond', 'cash', 'crypto', 'other'
  last_priced_at  TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX holdings_account_idx ON holdings(account_id);
-- Standard household-scoped RLS.
```

### How holdings interact with `accounts.current_balance`

Two approaches:

1. **Holdings replace account balance.** For investment accounts, `current_balance` becomes a derived value: `SUM(holdings.current_value WHERE account_id = X)`. Add a trigger or a recalc RPC like migration `015_recalculate_balance_function.sql` did for transactions.
2. **Holdings supplement account balance.** `current_balance` stays manual. Holdings are a detail view inside the account.

(1) is correct in the long run but requires changing how investment-account balances are entered. (2) is simpler to ship and lets you adopt holdings incrementally — backfill an account's holdings whenever you feel like it without breaking net worth.

Recommend (2) for v1, (1) once holdings entry is comfortable.

### What to skip for v1

No price feed. The repo's no-Plaid stance generalizes here — any external market-data API has the same compliance footprint. `current_value` is user-entered. Add a "Refresh Holdings Value" sheet later if you want.

### Asset allocation view

With `asset_class`, the dashboard gets a new "Asset Allocation" donut: `SUM(current_value) GROUP BY asset_class`. That's the visible payoff for adding holdings.

---

## 5. Net worth growth suggestions

Rules-based, no external data. The README's lowercase-confidence brand voice applies here — observations and questions, not exhortations.

### Engine sketch

```dart
// mobile/lib/features/dashboard/services/growth_advisor.dart

abstract class GrowthRule {
  String get id;
  GrowthSuggestion? evaluate(DashboardData data);
}

class GrowthSuggestion {
  const GrowthSuggestion({
    required this.id,
    required this.severity,    // info / opportunity / warning
    required this.title,       // 'Roth IRA contributions look low'
    required this.detail,      // body text, evidence-first
    this.actionLabel,          // 'Open IRA' navigates somewhere
    this.actionRoute,
  });
  // ...
}
```

### Starter rules

These all run on data already in the schema. No new tables.

| Rule                              | Trigger                                                                                                | Suggestion                                                                                              |
| --------------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Emergency fund                    | `cash + savings < 3 × monthlySpending`                                                                 | "Liquid savings cover N months of spending. Industry rule of thumb is 3–6."                             |
| Credit card carry                 | Any credit card with `current_balance < 0` AND `interest_rate > 0.10`                                  | "$X carrying at Y% APR. Paying this down beats most investment returns."                                |
| Roth IRA underused                | Sum of Roth IRA contributions YTD `< $7,000` (2026 limit) AND user has earned income                   | "$X of $7,000 Roth IRA limit used this year."                                                           |
| 401(k) match left on the table    | Need a `monthly_401k_contribution` field somewhere, plus expected employer match — out of v1 schema    | (skip until you add employment metadata)                                                                |
| HSA underused                     | HSA balance not growing AND user has high-deductible plan — same problem (no metadata)                 | (skip)                                                                                                  |
| Negative net worth trajectory     | Net worth at month-end lower than 6-month rolling average for 3+ months                                | "Net worth is trending down. Want to open a scenario to project where this lands?"                      |
| Subscription drift                | Recurring `transactions.merchant` patterns where MoM totals grew >20%                                  | "Streaming/subscription spending grew X% this quarter."                                                 |
| Idle cash                         | `checking + savings > 12 × monthlySpending` AND no contributions to investment accounts in last 90d    | "$X in checking/savings is more than a year of expenses. Consider moving the excess into investments."  |

The dashboard gets a new "Suggestions" section, each rule rendered as a card with its `severity` color.

### Things this is not

Not a robo-advisor. Not personalized financial advice. Phrasing should observe and ask, never instruct. "Roth IRA contributions look low" not "You should max your Roth." That's the brand voice anyway.

---

## Suggested build order

1. Migration 019 (candidate-finder RPC) + pairing UI. Smallest surface, immediate value.
2. Editable line items + Option B budget rollup. Schema's already there; this is pure UI + query update.
3. Migration 020 (`transaction_tags`) + tag picker + Contractor tab. New schema, but standalone — nothing else depends on it.
4. Growth-suggestions engine v1 (rules 1–3 and 7). Pure Dart, no migration.
5. Migration 021 (holdings) + holdings entry + asset-allocation donut. Biggest scope; defer until 1–4 are stable.

Each step is independently shippable. None of them require a new external service or compliance review.
