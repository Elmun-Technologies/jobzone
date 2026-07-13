// click-merchant — Click (SHOP-API) endpoint for direct pay-per-listing. Click
// calls this twice per payment: Prepare (action=0) then Complete (action=1),
// form-encoded, each signed with an MD5 `sign_string`. `merchant_trans_id` is our
// `promotion_orders.id`. On a successful Complete we flip the order to `paid`,
// which fires the `apply_promotion` trigger (migration 0063) that publishes the
// draft vacancy and stamps its tier. Idempotency lives in `payment_transactions`
// (migration 0064), keyed by Click's `click_trans_id`.
//
// Protocol: https://docs.click.uz/en/ (SHOP-API). Amount is in so'm (decimal).
// Sign (Prepare):  md5(click_trans_id + service_id + SECRET_KEY + merchant_trans_id + amount + action + sign_time)
// Sign (Complete): md5(click_trans_id + service_id + SECRET_KEY + merchant_trans_id + merchant_prepare_id + amount + action + sign_time)
//
// Secrets (set before go-live; fails closed until then):
//   CLICK_SERVICE_ID, CLICK_SECRET_KEY          — from the Click cabinet
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY    — service-role DB writes
// Register both the Prepare and Complete URLs (this same endpoint) in the Click
// cabinet; set verify_jwt = false in supabase/config.toml (Click sends no JWT —
// the signature is the gate).

import { createClient } from "jsr:@supabase/supabase-js@2";
import { crypto } from "jsr:@std/crypto";

// Click SHOP-API error codes.
const OK = 0;
const ERR = {
  SIGN: -1,
  AMOUNT: -2,
  ACTION: -3,
  ALREADY_PAID: -4,
  ORDER_NOT_FOUND: -5,
  TXN_NOT_FOUND: -6,
  BAD_REQUEST: -8,
  CANCELLED: -9,
} as const;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: ERR.BAD_REQUEST, error_note: "POST only" });

  const serviceId = Deno.env.get("CLICK_SERVICE_ID");
  const secret = Deno.env.get("CLICK_SECRET_KEY");
  if (!serviceId || !secret) {
    return json({ error: ERR.BAD_REQUEST, error_note: "Not configured" });
  }

  const form = await req.formData().catch(() => null);
  if (!form) return json({ error: ERR.BAD_REQUEST, error_note: "Bad request" });
  const p = (k: string) => (form.get(k) ?? "").toString();

  const clickTransId = p("click_trans_id");
  const reqServiceId = p("service_id");
  const merchantTransId = p("merchant_trans_id"); // our promotion_orders.id
  const merchantPrepareId = p("merchant_prepare_id");
  const amount = p("amount");
  const action = p("action");
  const signTime = p("sign_time");
  const signString = p("sign_string");
  const clickError = Number(p("error")) || 0;

  const echo = { click_trans_id: clickTransId, merchant_trans_id: merchantTransId };

  if (reqServiceId !== serviceId) {
    return json({ ...echo, error: ERR.BAD_REQUEST, error_note: "Bad service" });
  }

  // Verify the MD5 signature (Complete folds in merchant_prepare_id).
  const base =
    action === "1"
      ? clickTransId + serviceId + secret + merchantTransId + merchantPrepareId + amount + action + signTime
      : clickTransId + serviceId + secret + merchantTransId + amount + action + signTime;
  const expectedSign = await md5Hex(base);
  if (!timingSafeEqualStr(expectedSign, signString)) {
    return json({ ...echo, error: ERR.SIGN, error_note: "Sign check failed" });
  }

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    if (action === "0") return await prepare(supa, { clickTransId, merchantTransId, amount, echo });
    if (action === "1") {
      return await complete(supa, { clickTransId, merchantPrepareId, clickError, echo });
    }
    return json({ ...echo, error: ERR.ACTION, error_note: "Action not found" });
  } catch (e) {
    console.error("click-merchant error", e);
    return json({ ...echo, error: ERR.BAD_REQUEST, error_note: "Error" });
  }
});

async function prepare(
  supa: Supa,
  a: { clickTransId: string; merchantTransId: string; amount: string; echo: Echo },
) {
  const order = await resolveOrder(supa, a.merchantTransId);
  if ("error" in order) return json({ ...a.echo, error: order.error, error_note: order.note });
  if (Number(a.amount) !== order.expectedUzs) {
    return json({ ...a.echo, error: ERR.AMOUNT, error_note: "Incorrect amount" });
  }
  // Idempotent: reuse the txn row for this click_trans_id, else create it.
  let txnId: string;
  const existing = await getTxn(supa, a.clickTransId);
  if (existing) {
    txnId = existing.id;
  } else {
    const { data, error } = await supa
      .from("payment_transactions")
      .insert({
        provider: "click",
        provider_txn_id: a.clickTransId,
        order_id: order.orderId,
        amount_uzs: order.expectedUzs,
        state: 1,
        create_time: Date.now(),
      })
      .select("id")
      .single();
    if (error || !data) throw error ?? new Error("insert failed");
    txnId = data.id;
  }
  return json({ ...a.echo, merchant_prepare_id: txnId, error: OK, error_note: "Success" });
}

async function complete(
  supa: Supa,
  a: { clickTransId: string; merchantPrepareId: string; clickError: number; echo: Echo },
) {
  const txn = await getTxn(supa, a.clickTransId);
  if (!txn || txn.id !== a.merchantPrepareId) {
    return json({ ...a.echo, error: ERR.TXN_NOT_FOUND, error_note: "Transaction not found" });
  }
  if (txn.state === 2) {
    // Already confirmed — idempotent success.
    return json({ ...a.echo, merchant_confirm_id: txn.id, error: OK, error_note: "Success" });
  }
  if (txn.state < 0) {
    return json({ ...a.echo, error: ERR.CANCELLED, error_note: "Cancelled" });
  }
  // Click reports its own failure via a negative `error` → cancel our side.
  if (a.clickError < 0) {
    await supa.from("payment_transactions").update({ state: -1, cancel_time: Date.now() }).eq("id", txn.id);
    await supa.from("promotion_orders").update({ status: "cancelled" }).eq("id", txn.order_id).eq("status", "pending");
    return json({ ...a.echo, error: ERR.CANCELLED, error_note: "Cancelled" });
  }
  // Confirm: mark performed + flip the order to paid → trigger publishes the job.
  await supa.from("payment_transactions").update({ state: 2, perform_time: Date.now() }).eq("id", txn.id);
  await supa
    .from("promotion_orders")
    .update({ status: "paid", paid_at: new Date().toISOString(), external_ref: txn.id })
    .eq("id", txn.order_id)
    .eq("status", "pending");
  return json({ ...a.echo, merchant_confirm_id: txn.id, error: OK, error_note: "Success" });
}

// ── Helpers ──────────────────────────────────────────────────────────────

type Supa = ReturnType<typeof createClient>;
type Echo = { click_trans_id: string; merchant_trans_id: string };

/** Resolve + validate the order; expected charge from the CATALOG price. */
async function resolveOrder(supa: Supa, orderId: string) {
  if (!orderId) return { error: ERR.ORDER_NOT_FOUND, note: "No order" };
  const { data: order } = await supa
    .from("promotion_orders")
    .select("id, status, product_code")
    .eq("id", orderId)
    .maybeSingle();
  if (!order) return { error: ERR.ORDER_NOT_FOUND, note: "Order not found" };
  if (order.status === "paid") return { error: ERR.ALREADY_PAID, note: "Already paid" };
  if (order.status !== "pending") return { error: ERR.CANCELLED, note: "Not payable" };
  const { data: product } = await supa
    .from("promotion_products")
    .select("price_uzs")
    .eq("code", order.product_code)
    .maybeSingle();
  const expectedUzs = Number(product?.price_uzs ?? 0);
  if (!(expectedUzs > 0)) return { error: ERR.AMOUNT, note: "No price" };
  return { orderId: order.id as string, expectedUzs };
}

async function getTxn(supa: Supa, clickTransId: string) {
  if (!clickTransId) return null;
  const { data } = await supa
    .from("payment_transactions")
    .select("id, order_id, state")
    .eq("provider", "click")
    .eq("provider_txn_id", clickTransId)
    .maybeSingle();
  return data as { id: string; order_id: string; state: number } | null;
}

async function md5Hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("MD5", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function timingSafeEqualStr(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const ab = enc.encode(a);
  const bb = enc.encode(b);
  if (ab.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ab.length; i++) diff |= ab[i] ^ bb[i];
  return diff === 0;
}

function json(body: unknown) {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}
