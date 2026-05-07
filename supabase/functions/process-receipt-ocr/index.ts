// Stub OCR Edge Function for local development.
//
// The production version of this function calls Google Cloud Vision and is
// deployed outside this repo. This stub mirrors its **output shape** so the
// receipts flow can be exercised locally without API keys or network egress:
// it advances `receipts.ocr_status` from 'pending' to 'complete', writes a
// synthetic `ocr_raw` payload, and inserts a few `receipt_line_items` rows.
//
// Invocation:
//   POST /functions/v1/process-receipt-ocr
//   Body: { "receipt_id": "<uuid>", "items"?: [{description, amount, ...}] }
//   - `items` is optional. If omitted, three deterministic placeholder items
//     are generated (so tests can call without setting up fixture data).
//   - The caller's bearer token is forwarded to PostgREST so RLS still gates
//     the writes — the stub doesn't bypass auth.
//
// What this is NOT:
//   - This does not download the image, run actual OCR, or read the storage
//     bucket. It writes synthetic data to the DB. The production function
//     does the real work; only its DB shape is mirrored here.

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

interface RequestBody {
  receipt_id: string;
  items?: ReceiptLineItemInput[];
}

interface ReceiptLineItemInput {
  description: string;
  amount: number;       // cents (positive)
  quantity?: number;
  unit_price?: number;  // cents
  is_tax?: boolean;
  is_tip?: boolean;
  is_discount?: boolean;
}

const DEFAULT_ITEMS: ReceiptLineItemInput[] = [
  { description: "Synthetic line item A", amount: 499 },
  { description: "Synthetic line item B", amount: 1299 },
  { description: "Tax",                   amount: 144, is_tax: true },
];

// Top-level handler. Kept thin — the work happens in `processReceipt`.
serve(async (req) => {
  if (req.method !== "POST") {
    return jsonError(405, "method not allowed");
  }

  let body: RequestBody;
  try {
    body = await req.json() as RequestBody;
  } catch {
    return jsonError(400, "invalid JSON body");
  }
  if (!body.receipt_id) {
    return jsonError(400, "receipt_id is required");
  }

  // Forward the caller's auth so RLS applies to the writes. SUPABASE_URL
  // and SUPABASE_ANON_KEY are injected by the Edge Functions runtime —
  // the anon key is what the client uses too, RLS does the gating.
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  try {
    const result = await processReceipt(
      supabase,
      body.receipt_id,
      body.items ?? DEFAULT_ITEMS,
    );
    return Response.json(result, { status: 200 });
  } catch (err) {
    // Mark as failed so the UI can surface it. Best-effort — if the row is
    // gone or inaccessible the original error is what the caller sees.
    await supabase
      .from("receipts")
      .update({ ocr_status: "failed", ocr_raw: { error: String(err) } })
      .eq("id", body.receipt_id);
    return jsonError(500, String(err));
  }
});

async function processReceipt(
  supabase: SupabaseClient,
  receiptId: string,
  items: ReceiptLineItemInput[],
) {
  // 1. Move the row into 'processing' so concurrent invocations notice.
  const { error: pErr } = await supabase
    .from("receipts")
    .update({ ocr_status: "processing" })
    .eq("id", receiptId);
  if (pErr) throw pErr;

  // 2. Insert line items via the atomic RPC (migration 018) so a failure
  //    half-way through doesn't leave the receipt with partial items.
  const itemPayloads = items.map((it) => ({
    description: it.description,
    amount: it.amount,
    quantity: it.quantity ?? null,
    unit_price: it.unit_price ?? null,
    is_tax: it.is_tax ?? false,
    is_tip: it.is_tip ?? false,
    is_discount: it.is_discount ?? false,
  }));
  const { data: lineItems, error: liErr } = await supabase.rpc(
    "save_receipt_line_items",
    { p_receipt_id: receiptId, p_items: itemPayloads },
  );
  if (liErr) throw liErr;

  // 3. Sum non-discount, non-tip lines to derive a total. Tax counts.
  //    The production function uses the total reported by Vision; we
  //    fake the same field so downstream Dart sees a populated value.
  const total = items
    .filter((it) => !it.is_tip && !it.is_discount)
    .reduce((s, it) => s + it.amount, 0);

  // 4. Mark complete and stash a synthetic ocr_raw shape that mirrors
  //    what production would store (a Vision-like response envelope).
  const { error: cErr } = await supabase
    .from("receipts")
    .update({
      ocr_status: "complete",
      total_amount: total,
      ocr_raw: {
        source: "stub",
        generated_at: new Date().toISOString(),
        item_count: items.length,
        // Mimic the production envelope's shape; values are placeholders.
        vision_response: {
          textAnnotations: items.map((it) => ({
            description: it.description,
            confidence: 0.99,
          })),
        },
      },
    })
    .eq("id", receiptId);
  if (cErr) throw cErr;

  return {
    receipt_id: receiptId,
    ocr_status: "complete",
    total_amount: total,
    line_items: lineItems ?? [],
  };
}

function jsonError(status: number, message: string): Response {
  return Response.json({ error: message }, { status });
}
