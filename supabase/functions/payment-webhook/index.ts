// payment-webhook — marks a promotion order paid when the gateway confirms
// payment. The DB trigger (apply_promotion) then applies the boost; the client
// never sets status=paid itself.
//
// This is a SCAFFOLD: it flips an order to `paid` after verifying a shared
// secret. Wire the real Click / Payme callback shape + signature verification
// where marked, and set the secrets in the project:
//   PAYMENT_WEBHOOK_SECRET   — shared secret guarding this endpoint
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY — to update the order (service role)
// No-ops (501) until PAYMENT_WEBHOOK_SECRET is configured.

import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, x-webhook-secret",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const secret = Deno.env.get("PAYMENT_WEBHOOK_SECRET");
  if (!secret) return json({ error: "gateway_not_configured" }, 501);

  // TODO(Click/Payme): replace this shared-secret check with the provider's
  // signature verification (Click uses an md5 `sign_string`; Payme uses Basic
  // auth with the merchant key). Map the provider payload → { orderId, paid }.
  if (req.headers.get("x-webhook-secret") !== secret) {
    return json({ error: "unauthorized" }, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad_json" }, 400);
  }

  const orderId = body.order_id as string | undefined;
  const paid = body.paid === true || body.status === "paid";
  if (!orderId) return json({ error: "missing_order_id" }, 400);
  if (!paid) return json({ ok: true, ignored: true });

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await supa
    .from("promotion_orders")
    .update({ status: "paid", paid_at: new Date().toISOString() })
    .eq("id", orderId)
    .eq("status", "pending");
  if (error) return json({ error: error.message }, 500);

  return json({ ok: true });
});

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...cors, "content-type": "application/json" },
  });
}
