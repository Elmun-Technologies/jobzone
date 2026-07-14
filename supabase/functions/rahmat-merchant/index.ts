// rahmat-merchant — Rahmat (Multicard) callback endpoint for direct
// pay-per-listing. Multicard posts here after a payer completes the payment on
// Rahmat's hosted checkout page (built via the sibling `rahmat-invoice` fn).
// On a verified successful callback we flip the promotion_orders row to `paid`,
// which fires the DB trigger `apply_promotion` (migration 0063) that publishes
// the draft vacancy and stamps its tier. Idempotency lives in
// `payment_transactions` (migration 0064) keyed by Multicard's payment uuid;
// the 'rahmat' provider is enabled by migration 0068.
//
// Auth: Multicard sends no JWT — the callback signature is the gate. Two
// schemes are supported (select via RAHMAT_CALLBACK_SCHEME env, default
// 'webhooks' — the Mesh Webhooks scheme):
//   'webhooks': sha1(uuid + invoice_id + amount + secret)
//   'success' : md5(store_id + invoice_id + amount + secret)
// Both are compared constant-time. A missing or wrong signature returns 401
// and never touches the DB. Amount is re-validated against the CATALOG price
// (a tampered callback can never over/under-charge).
//
// Secrets (fail closed until all are set):
//   RAHMAT_SECRET            merchant secret (signature key)
//   RAHMAT_STORE_ID          store id (only used by the 'success' scheme)
//   RAHMAT_CALLBACK_SCHEME   'webhooks' (default) | 'success'
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY   service-role DB writes
//
// verify_jwt = false in supabase/config.toml — Multicard sends no user JWT.
// The pair endpoint that creates invoices (which DOES require a user JWT) is
// `rahmat-invoice`.

import { createClient } from "jsr:@supabase/supabase-js@2";

import { corsHeaders, json } from "../_shared/cors.ts";
import { timingSafeEqual } from "../_shared/auth.ts";
import { rahmatSign, type CallbackScheme } from "./sign.ts";

type Supa = ReturnType<typeof createClient>;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);

  const env = readEnv();
  if ("error" in env) return json({ ok: false, error: env.error }, 501);

  try {
    return await handleCallback(req, env);
  } catch (e) {
    console.error("rahmat-merchant error", e);
    return json({ ok: false, error: "internal_error" }, 500);
  }
});

async function handleCallback(req: Request, env: Env): Promise<Response> {
  // Multicard may post form-encoded or JSON depending on how the store is set
  // up; accept both.
  const ctype = req.headers.get("content-type") ?? "";
  const payload: Record<string, string> = {};
  if (ctype.includes("application/json")) {
    const j = await req.json().catch(() => ({})) as Record<string, unknown>;
    for (const [k, v] of Object.entries(j)) payload[k] = String(v ?? "");
  } else {
    const form = await req.formData().catch(() => null);
    if (form) for (const [k, v] of form.entries()) payload[k] = String(v ?? "");
  }

  const invoiceId = payload.invoice_id ?? payload.order_id ?? "";
  const uuid = payload.uuid ?? payload.payment_id ?? "";
  const amount = payload.amount ?? "";
  const gotSign = (payload.sign ?? payload.signature ?? "").toLowerCase();
  const status = (payload.status ?? "").toLowerCase();
  if (!invoiceId || !uuid || !amount || !gotSign) {
    return json({ ok: false, error: "missing_fields" }, 400);
  }

  const expected = await rahmatSign({
    scheme: env.callbackScheme,
    uuid,
    invoiceId,
    amount,
    secret: env.secret,
    storeId: env.storeId,
  });
  if (!timingSafeEqual(expected, gotSign)) {
    return json({ ok: false, error: "bad_signature" }, 401);
  }

  const supa = createClient(env.supabaseUrl, env.supabaseServiceKey);
  const order = await resolveOrder(supa, invoiceId);
  if ("error" in order) return json({ ok: false, error: order.error }, 400);
  if (Math.round(order.expectedUzs * 100) !== Number(amount)) {
    return json({ ok: false, error: "amount_mismatch" }, 400);
  }

  const existing = await supa
    .from("payment_transactions")
    .select("id, state")
    .eq("provider", "rahmat")
    .eq("provider_txn_id", uuid)
    .maybeSingle();

  let txnId: string;
  if (existing.data) {
    if (existing.data.state === 2) return json({ ok: true, idempotent: true });
    txnId = existing.data.id as string;
  } else {
    // Defensive create — if we somehow get the callback before rahmat-invoice
    // recorded the txn, we still capture it instead of losing the payment.
    const ins = await supa
      .from("payment_transactions")
      .insert({
        provider: "rahmat",
        provider_txn_id: uuid,
        order_id: order.orderId,
        amount_uzs: order.expectedUzs,
        state: 1,
        create_time: Date.now(),
      })
      .select("id")
      .single();
    if (ins.error || !ins.data) throw ins.error ?? new Error("txn insert failed");
    txnId = ins.data.id as string;
  }

  // Anything other than 'success'/'ok'/'paid' or an empty status is treated as
  // a cancellation. Multicard sometimes omits the field on the happy path.
  const isSuccess = status === "" || status === "success" || status === "ok" || status === "paid";
  if (!isSuccess) {
    await supa
      .from("payment_transactions")
      .update({ state: -1, cancel_time: Date.now() })
      .eq("id", txnId);
    await supa
      .from("promotion_orders")
      .update({ status: "cancelled" })
      .eq("id", order.orderId)
      .eq("status", "pending");
    return json({ ok: true, status: "cancelled" });
  }

  await supa
    .from("payment_transactions")
    .update({ state: 2, perform_time: Date.now() })
    .eq("id", txnId);
  await supa
    .from("promotion_orders")
    .update({ status: "paid", paid_at: new Date().toISOString(), external_ref: uuid })
    .eq("id", order.orderId)
    .eq("status", "pending");

  return json({ ok: true, status: "paid" });
}

async function resolveOrder(
  supa: Supa,
  orderId: string,
): Promise<{ orderId: string; expectedUzs: number } | { error: string }> {
  const { data: order } = await supa
    .from("promotion_orders")
    .select("id, product_code")
    .eq("id", orderId)
    .maybeSingle();
  if (!order) return { error: "order_not_found" };
  const { data: product } = await supa
    .from("promotion_products")
    .select("price_uzs")
    .eq("code", order.product_code)
    .maybeSingle();
  const expectedUzs = Number(product?.price_uzs ?? 0);
  if (!(expectedUzs > 0)) return { error: "no_price" };
  return { orderId: order.id as string, expectedUzs };
}

interface Env {
  secret: string;
  storeId: string;
  callbackScheme: CallbackScheme;
  supabaseUrl: string;
  supabaseServiceKey: string;
}

function readEnv(): Env | { error: string } {
  const secret = Deno.env.get("RAHMAT_SECRET") ?? "";
  const storeId = Deno.env.get("RAHMAT_STORE_ID") ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!secret || !storeId || !supabaseUrl || !supabaseServiceKey) {
    return { error: "not_configured" };
  }
  const schemeRaw = (Deno.env.get("RAHMAT_CALLBACK_SCHEME") ?? "webhooks").toLowerCase();
  const callbackScheme: CallbackScheme = schemeRaw === "success" ? "success" : "webhooks";
  return { secret, storeId, callbackScheme, supabaseUrl, supabaseServiceKey };
}
