# `process-receipt-ocr` (stub)

Local-development stub that mirrors the **output shape** of the production
OCR Edge Function. The production function calls Google Cloud Vision and is
deployed outside this repo; this stub exists so the receipts flow can be
exercised without API keys or network egress.

## What it does

Given a receipt id, this function:

1. Sets `receipts.ocr_status` to `'processing'`.
2. Calls the `save_receipt_line_items` RPC (migration 018) to atomically
   insert line items.
3. Sums non-tip, non-discount lines into `receipts.total_amount`.
4. Sets `ocr_status` to `'complete'` and stashes a synthetic `ocr_raw`
   payload whose shape mimics a Cloud Vision response.
5. On failure: marks `ocr_status` as `'failed'` and stores the error in
   `ocr_raw`.

## Invoke from Dart

```dart
final result = await Supabase.instance.client.functions.invoke(
  'process-receipt-ocr',
  body: {
    'receipt_id': receiptId,
    // Optional — omit to get three deterministic placeholder items.
    'items': [
      {'description': 'Coffee', 'amount': 450},
      {'description': 'Tax',    'amount': 36, 'is_tax': true},
    ],
  },
);
```

## Invoke via curl

```bash
curl -X POST 'http://localhost:54321/functions/v1/process-receipt-ocr' \
  -H 'Authorization: Bearer <anon-or-user-jwt>' \
  -H 'Content-Type: application/json' \
  -d '{"receipt_id":"<uuid>"}'
```

The `Authorization` header is forwarded to PostgREST so RLS still applies —
this stub does not bypass auth. Use the anon key for unauthenticated tests
that exercise pre-login paths.

## What this is NOT

- Not a Cloud Vision client. It writes synthetic data; nothing reads the
  uploaded image bytes.
- Not auto-invoked. The Dart upload path leaves `ocr_status = 'pending'`
  on insert; tests or developers call this function explicitly. (The
  production path is invoked by an external trigger that we don't model
  here — wire one up via `supabase/migrations/` if you want auto-invoke.)
