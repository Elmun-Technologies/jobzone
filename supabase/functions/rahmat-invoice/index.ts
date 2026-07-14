// rahmat-invoice — creates a Rahmat (Multicard) invoice for one of our
// `promotion_orders` rows and returns the hosted checkout URL for the client
// to open. Sibling of `rahmat-merchant`, which is the callback endpoint that
// flips the order to `paid` once Multicard confirms payment.
//
// The webapp server action and the mobile app both call this with the user's
// Supabase JWT (via `functions.invoke(...)`); we manually verify the JWT and
// re-check ownership of the order before hitting Multicard. Amount and order
// integrity are re-derived from the CATALOG price server-side — a tampered
// client-supplied amount can never under-pay.
//
// Flow:
//   1. Verify user JWT → user id.
//   2. Resolve the order + its expected UZS price + ownership (company owner).
//   3. Authenticate to Multicard (`POST /auth`, in-memory-cached bearer, 24h).
//   4. Create an invoice (`POST /payment/invoice`) with `store_id`, our
//      `order_id` as `invoice_id`, amount in TIYIN, and the `callback_url`
//      pointing at `rahmat-merchant`.
//   5. Record the Multicard `uuid` in `payment_transactions` (idempotent).
//   6. Return `{ checkout_url, uuid }` to the client.
//
// Secrets (fail closed until all set):
//   RAHMAT_BASE_URL          e.g. https://dev-mesh.multicard.uz/ (test)
//                            or  https://mesh.multicard.uz/     (prod)
//   RAHMAT_APPLICATION_ID    from Multicard cabinet
//   RAHMAT_SECRET            from Multicard cabinet
//   RAHMAT_STORE_ID          from Multicard cabinet
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY  service-role DB writes
//   SUPABASE_ANON_KEY        used to verify the caller's JWT
//
// verify_jwt = true (default) in supabase/config.toml — Supabase itself
// rejects unauthenticated calls; the manual getUser() here is a belt-and-
// braces check that gives us the caller's uid for ownership verification.

import { createClient } from "jsr:@supabase/supabase-js@2";

import { corsHeaders, json } from "../_shared/cors.ts";

type Supa = ReturnType<typeof createClient>;

// ── Multicard bearer-token cache (instance-local; edge fns are short-lived) ─
let cachedToken: { value: string; expiresAt: number } | null = null;

async function multicardAuth(baseUrl: string, appId: string, secret: string): Promise<string> {
  const now = Date.now();
  if (cachedToken && cachedToken.expiresAt > now + 5 * 60_000) {
    return cachedToken.value;
  }
  const res = await fetch(new URL("auth", baseUrl).toString(), {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ application_id: appId, secret }),
  });
  if (!res.ok) throw new Error(`multicard auth failed: ${res.status}`);
  const body = await res.json().catch(() => ({})) as Record<string, unknown>;
  const data = (body.data ?? body) as Record<string, unknown>;
  const token = (data.token ?? data.access_token ?? data.jwt) as string | undefined;
  if (!token) throw new Error("multicard auth: no token in response");
  const expiryRaw = Number(data.expiry ?? data.expires_in ?? 0);
  const ttlMs = expiryRaw > 0
    ? (expiryRaw > 1_000_000_000 ? expiryRaw * 1000 - now : expiryRaw * 1000)
    : 24 * 60 * 60 * 1000;
  cachedToken = { value: token, expiresAt: now + ttlMs };
  return token;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ ok: false, error: "method_not_allowed" }, 405);

  const env = readEnv();
  if ("error" in env) return json({ ok: false, error: env.error }, 501);

  // Verify the caller's JWT. `functions.invoke` from either client forwards the
  // user's access token as `Authorization: Bearer …`. We build a per-request
  // Supabase client with that token so `.auth.getUser()` resolves it.
  const authHeader = req.headers.get("authorization") ?? "";
  const jwt = authHeader.toLowerCase().startsWith("bearer ")
    ? authHeader.slice(7).trim()
    : "";
  if (!jwt) return json({ ok: false, error: "unauthorized" }, 401);
  const userClient = createClient(env.supabaseUrl, env.supabaseAnonKey, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const {
    data: { user },
    error: userErr,
  } = await userClient.auth.getUser();
  if (userErr || !user) return json({ ok: false, error: "unauthorized" }, 401);

  const body = await req.json().catch(() => null) as
    | { order_id?: string; return_url?: string }
    | null;
  if (!body?.order_id) return json({ ok: false, error: "missing_order_id" }, 400);
  const returnUrl = String(body.return_url ?? "").trim();

  // All ownership + price checks run on the service-role client so we never
  // rely on RLS to keep an employer from paying another employer's order.
  const supa = createClient(env.supabaseUrl, env.supabaseServiceKey);
  const order = await resolveOrder(supa, body.order_id, user.id);
  if ("error" in order) return json({ ok: false, error: order.error }, 400);

  try {
    const token = await multicardAuth(env.baseUrl, env.applicationId, env.secret);
    const amountTiyin = Math.round(order.expectedUzs * 100);
    const invRes = await fetch(new URL("payment/invoice", env.baseUrl).toString(), {
      method: "POST",
      headers: {
        "content-type": "application/json",
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        store_id: Number(env.storeId),
        invoice_id: order.orderId,
        amount: amountTiyin,
        return_url: returnUrl || undefined,
        callback_url: env.callbackUrl,
      }),
    });
    if (!invRes.ok) {
      const detail = await invRes.text().catch(() => "");
      console.error("rahmat invoice failed", invRes.status, detail);
      return json({ ok: false, error: "gateway_rejected" }, 502);
    }
    const invBody = await invRes.json().catch(() => ({})) as Record<string, unknown>;
    const invData = (invBody.data ?? invBody) as Record<string, unknown>;
    const uuid = String(invData.uuid ?? invData.id ?? "");
    const checkoutUrl = String(
      invData.checkout_url ?? invData.payment_url ?? invData.url ?? "",
    );
    if (!uuid || !checkoutUrl) {
      console.error("rahmat invoice: missing uuid/checkout_url", invBody);
      return json({ ok: false, error: "gateway_bad_response" }, 502);
    }

    // Idempotent upsert on (provider, provider_txn_id) — a client retry lands
    // in the same row instead of creating duplicates.
    const { error: upErr } = await supa
      .from("payment_transactions")
      .upsert(
        {
          provider: "rahmat",
          provider_txn_id: uuid,
          order_id: order.orderId,
          amount_uzs: order.expectedUzs,
          state: 1,
          create_time: Date.now(),
        },
        { onConflict: "provider,provider_txn_id" },
      );
    if (upErr) throw upErr;

    return json({ ok: true, checkout_url: checkoutUrl, uuid });
  } catch (e) {
    console.error("rahmat-invoice error", e);
    return json({ ok: false, error: "internal_error" }, 500);
  }
});

async function resolveOrder(
  supa: Supa,
  orderId: string,
  userId: string,
): Promise<{ orderId: string; expectedUzs: number } | { error: string }> {
  const { data: order } = await supa
    .from("promotion_orders")
    .select("id, status, product_code, company_id, companies!inner(owner_id)")
    .eq("id", orderId)
    .maybeSingle();
  if (!order) return { error: "order_not_found" };
  // Ownership: caller must own the company the order belongs to.
  const ownerId = (order as { companies?: { owner_id?: string } | { owner_id?: string }[] }).companies;
  const ownerVal = Array.isArray(ownerId) ? ownerId[0]?.owner_id : ownerId?.owner_id;
  if (ownerVal !== userId) return { error: "not_owner" };
  if ((order as { status: string }).status !== "pending") {
    return { error: "order_not_payable" };
  }
  const { data: product } = await supa
    .from("promotion_products")
    .select("price_uzs")
    .eq("code", (order as { product_code: string }).product_code)
    .maybeSingle();
  const expectedUzs = Number(product?.price_uzs ?? 0);
  if (!(expectedUzs > 0)) return { error: "no_price" };
  return { orderId: (order as { id: string }).id, expectedUzs };
}

interface Env {
  baseUrl: string;
  applicationId: string;
  secret: string;
  storeId: string;
  callbackUrl: string;
  supabaseUrl: string;
  supabaseAnonKey: string;
  supabaseServiceKey: string;
}

function readEnv(): Env | { error: string } {
  const baseUrlRaw = Deno.env.get("RAHMAT_BASE_URL") ?? "";
  const applicationId = Deno.env.get("RAHMAT_APPLICATION_ID") ?? "";
  const secret = Deno.env.get("RAHMAT_SECRET") ?? "";
  const storeId = Deno.env.get("RAHMAT_STORE_ID") ?? "";
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (
    !baseUrlRaw || !applicationId || !secret || !storeId ||
    !supabaseUrl || !supabaseAnonKey || !supabaseServiceKey
  ) {
    return { error: "not_configured" };
  }
  const baseUrl = baseUrlRaw.endsWith("/") ? baseUrlRaw : `${baseUrlRaw}/`;
  const callbackUrl = `${supabaseUrl.replace(/\/$/, "")}/functions/v1/rahmat-merchant`;
  return {
    baseUrl,
    applicationId,
    secret,
    storeId,
    callbackUrl,
    supabaseUrl,
    supabaseAnonKey,
    supabaseServiceKey,
  };
}
