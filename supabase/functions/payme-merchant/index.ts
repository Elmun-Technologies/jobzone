// payme-merchant — Payme (Paycom) Merchant API endpoint for direct
// pay-per-listing. Payme calls this JSON-RPC endpoint to drive a payment against
// one of our `promotion_orders` (a tier purchase for a draft vacancy). On
// PerformTransaction we flip the order to `paid`, which fires the DB trigger
// `apply_promotion` (migration 0063) that publishes the draft and stamps its
// tier. Idempotency + Payme's create→perform/cancel state machine live in
// `payment_transactions` (migration 0064).
//
// Protocol: https://developer.help.paycom.uz/ (Merchant API, JSON-RPC 2.0).
// Auth: HTTP Basic `Paycom:<PAYME_KEY>`. Amounts are in TIYIN (1 so'm = 100).
// The order is addressed by the `account.order_id` field — configure that field
// name in the Payme merchant cabinet. Register this function's URL there.
//
// Secrets (set before go-live; fails closed until then):
//   PAYME_KEY                     — merchant key for the Basic-auth check
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY — service-role DB writes
// Configure in supabase/config.toml with verify_jwt = false (Payme sends no JWT;
// the Basic key is the gate).

import { createClient } from "jsr:@supabase/supabase-js@2";

// Payme JSON-RPC error codes (per the Merchant API spec).
const E = {
  AUTH: -32504,
  PARSE: -32700,
  METHOD: -32601,
  AMOUNT: -31001,
  ORDER: -31050, // -31050..-31099 = "account" (our order) problems
  IN_PROGRESS: -31099,
  TXN_NOT_FOUND: -31003,
  CANT_PERFORM: -31008,
  CANT_CANCEL: -31007,
} as const;

const MSG = (uz: string, ru: string, en: string) => ({ uz, ru, en });

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return rpcError(null, E.METHOD, MSG("Faqat POST", "Только POST", "POST only"));
  }

  const key = Deno.env.get("PAYME_KEY");
  if (!key) {
    // Fail closed until the merchant key is configured.
    return rpcError(null, E.AUTH, MSG("Sozlanmagan", "Не настроено", "Not configured"));
  }
  // Basic auth: the login part is ignored by Payme convention ("Paycom"); the
  // password must equal the merchant key. Constant-time compare.
  const auth = req.headers.get("authorization") ?? "";
  const expected = "Basic " + btoa("Paycom:" + key);
  if (!timingSafeEqualStr(auth, expected)) {
    return rpcError(null, E.AUTH, MSG("Ruxsat yo'q", "Нет доступа", "Unauthorized"));
  }

  let body: { method?: string; params?: Record<string, unknown>; id?: unknown };
  try {
    body = await req.json();
  } catch {
    return rpcError(null, E.PARSE, MSG("Xato so'rov", "Плохой запрос", "Bad request"));
  }
  const { method, params = {}, id = null } = body;

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    switch (method) {
      case "CheckPerformTransaction":
        return await checkPerform(supa, params, id);
      case "CreateTransaction":
        return await createTransaction(supa, params, id);
      case "PerformTransaction":
        return await performTransaction(supa, params, id);
      case "CancelTransaction":
        return await cancelTransaction(supa, params, id);
      case "CheckTransaction":
        return await checkTransaction(supa, params, id);
      case "GetStatement":
        return await getStatement(supa, params, id);
      default:
        return rpcError(id, E.METHOD, MSG("Metod yo'q", "Нет метода", "No method"));
    }
  } catch (e) {
    console.error("payme-merchant error", e);
    return rpcError(id, E.CANT_PERFORM, MSG("Xatolik", "Ошибка", "Error"));
  }
});

// ── Methods ────────────────────────────────────────────────────────────────

async function checkPerform(supa: Supa, params: P, id: unknown) {
  const order = await resolveOrder(supa, params);
  if ("error" in order) return rpcError(id, order.error, order.message);
  if (Number(params.amount) !== order.expectedTiyin) {
    return rpcError(id, E.AMOUNT, MSG("Summa xato", "Неверная сумма", "Invalid amount"));
  }
  return rpcOk(id, { allow: true });
}

async function createTransaction(supa: Supa, params: P, id: unknown) {
  const paymeId = String(params.id ?? "");
  const existing = await getTxn(supa, paymeId);
  if (existing) {
    if (existing.state !== 1) {
      return rpcError(id, E.CANT_PERFORM, MSG("Holat xato", "Неверное состояние", "Bad state"));
    }
    return rpcOk(id, {
      create_time: Number(existing.create_time),
      transaction: existing.id,
      state: 1,
    });
  }
  const order = await resolveOrder(supa, params);
  if ("error" in order) return rpcError(id, order.error, order.message);
  if (Number(params.amount) !== order.expectedTiyin) {
    return rpcError(id, E.AMOUNT, MSG("Summa xato", "Неверная сумма", "Invalid amount"));
  }
  // One live transaction per order: if another Payme txn is already
  // created/performed for this order, refuse (Payme retries CheckPerform).
  const active = await supa
    .from("payment_transactions")
    .select("id")
    .eq("order_id", order.orderId)
    .in("state", [1, 2])
    .maybeSingle();
  if (active.data) {
    return rpcError(id, E.IN_PROGRESS, MSG("Band", "Занято", "In progress"));
  }
  const createTime = Number(params.time) || Date.now();
  const { data, error } = await supa
    .from("payment_transactions")
    .insert({
      provider: "payme",
      provider_txn_id: paymeId,
      order_id: order.orderId,
      amount_uzs: order.expectedUzs,
      state: 1,
      create_time: createTime,
    })
    .select("id")
    .single();
  if (error || !data) throw error ?? new Error("insert failed");
  return rpcOk(id, { create_time: createTime, transaction: data.id, state: 1 });
}

async function performTransaction(supa: Supa, params: P, id: unknown) {
  const txn = await getTxn(supa, String(params.id ?? ""));
  if (!txn) return rpcError(id, E.TXN_NOT_FOUND, MSG("Topilmadi", "Не найдено", "Not found"));
  if (txn.state === 2) {
    return rpcOk(id, {
      transaction: txn.id,
      perform_time: Number(txn.perform_time),
      state: 2,
    });
  }
  if (txn.state !== 1) {
    return rpcError(id, E.CANT_PERFORM, MSG("Holat xato", "Неверное состояние", "Bad state"));
  }
  const performTime = Date.now();
  await supa
    .from("payment_transactions")
    .update({ state: 2, perform_time: performTime })
    .eq("id", txn.id);
  // Flip the order to paid → the apply_promotion trigger publishes the draft
  // vacancy and stamps its tier. Only touch a still-pending order (idempotent).
  await supa
    .from("promotion_orders")
    .update({ status: "paid", paid_at: new Date().toISOString(), external_ref: txn.id })
    .eq("id", txn.order_id)
    .eq("status", "pending");
  return rpcOk(id, { transaction: txn.id, perform_time: performTime, state: 2 });
}

async function cancelTransaction(supa: Supa, params: P, id: unknown) {
  const txn = await getTxn(supa, String(params.id ?? ""));
  if (!txn) return rpcError(id, E.TXN_NOT_FOUND, MSG("Topilmadi", "Не найдено", "Not found"));
  const reason = Number(params.reason) || null;
  if (txn.state < 0) {
    return rpcOk(id, {
      transaction: txn.id,
      cancel_time: Number(txn.cancel_time),
      state: txn.state,
    });
  }
  const cancelTime = Date.now();
  const newState = txn.state === 2 ? -2 : -1;
  await supa
    .from("payment_transactions")
    .update({ state: newState, cancel_time: cancelTime, reason })
    .eq("id", txn.id);
  // A cancelled/refunded order: leave a published (already-paid) vacancy live —
  // a refund is a business decision — but mark the order so it isn't re-paid.
  await supa
    .from("promotion_orders")
    .update({ status: txn.state === 2 ? "refunded" : "cancelled" })
    .eq("id", txn.order_id)
    .in("status", ["pending", "paid"]);
  return rpcOk(id, { transaction: txn.id, cancel_time: cancelTime, state: newState });
}

async function checkTransaction(supa: Supa, params: P, id: unknown) {
  const txn = await getTxn(supa, String(params.id ?? ""));
  if (!txn) return rpcError(id, E.TXN_NOT_FOUND, MSG("Topilmadi", "Не найдено", "Not found"));
  return rpcOk(id, {
    create_time: Number(txn.create_time) || 0,
    perform_time: Number(txn.perform_time) || 0,
    cancel_time: Number(txn.cancel_time) || 0,
    transaction: txn.id,
    state: txn.state,
    reason: txn.reason ?? null,
  });
}

async function getStatement(supa: Supa, params: P, id: unknown) {
  const from = Number(params.from) || 0;
  const to = Number(params.to) || Date.now();
  const { data } = await supa
    .from("payment_transactions")
    .select("id, provider_txn_id, order_id, amount_uzs, state, reason, create_time, perform_time, cancel_time")
    .eq("provider", "payme")
    .gte("create_time", from)
    .lte("create_time", to);
  const transactions = (data ?? []).map((t) => ({
    id: t.provider_txn_id,
    time: Number(t.create_time),
    amount: Math.round(Number(t.amount_uzs) * 100),
    account: { order_id: t.order_id },
    create_time: Number(t.create_time) || 0,
    perform_time: Number(t.perform_time) || 0,
    cancel_time: Number(t.cancel_time) || 0,
    transaction: t.id,
    state: t.state,
    reason: t.reason ?? null,
  }));
  return rpcOk(id, { transactions });
}

// ── Helpers ──────────────────────────────────────────────────────────────

type Supa = ReturnType<typeof createClient>;
type P = Record<string, unknown>;

/** Resolve + validate the order named by `account.order_id`; compute the
 * expected charge from the CATALOG price (never trust a stored/client amount). */
async function resolveOrder(supa: Supa, params: P) {
  const account = (params.account ?? {}) as Record<string, unknown>;
  const orderId = String(account.order_id ?? "");
  if (!orderId) {
    return { error: E.ORDER, message: MSG("Buyurtma yo'q", "Нет заказа", "No order") };
  }
  const { data: order } = await supa
    .from("promotion_orders")
    .select("id, status, product_code")
    .eq("id", orderId)
    .maybeSingle();
  if (!order) {
    return { error: E.ORDER, message: MSG("Topilmadi", "Не найдено", "Order not found") };
  }
  if (order.status !== "pending") {
    return { error: E.ORDER, message: MSG("To'langan", "Оплачено", "Already handled") };
  }
  const { data: product } = await supa
    .from("promotion_products")
    .select("price_uzs")
    .eq("code", order.product_code)
    .maybeSingle();
  const expectedUzs = Number(product?.price_uzs ?? 0);
  if (!(expectedUzs > 0)) {
    return { error: E.ORDER, message: MSG("Narx yo'q", "Нет цены", "No price") };
  }
  return {
    orderId: order.id as string,
    expectedUzs,
    expectedTiyin: Math.round(expectedUzs * 100),
  };
}

async function getTxn(supa: Supa, paymeId: string) {
  if (!paymeId) return null;
  const { data } = await supa
    .from("payment_transactions")
    .select("id, order_id, amount_uzs, state, reason, create_time, perform_time, cancel_time")
    .eq("provider", "payme")
    .eq("provider_txn_id", paymeId)
    .maybeSingle();
  return data as
    | {
        id: string;
        order_id: string;
        amount_uzs: number;
        state: number;
        reason: number | null;
        create_time: number | null;
        perform_time: number | null;
        cancel_time: number | null;
      }
    | null;
}

function rpcOk(id: unknown, result: unknown) {
  return json({ jsonrpc: "2.0", id, result });
}
function rpcError(
  id: unknown,
  code: number,
  message: { uz: string; ru: string; en: string },
) {
  return json({ jsonrpc: "2.0", id, error: { code, message } });
}
function json(body: unknown) {
  // Payme expects HTTP 200 with the error inside the JSON-RPC envelope.
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

/** Constant-time string compare (avoids leaking the key via timing). */
function timingSafeEqualStr(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const ab = enc.encode(a);
  const bb = enc.encode(b);
  if (ab.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ab.length; i++) diff |= ab[i] ^ bb[i];
  return diff === 0;
}
