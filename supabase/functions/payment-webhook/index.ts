// payment-webhook — generic webhook for custom gateways or admin callbacks.
// Settles either a promotion order or a wallet top-up using the robust
// gateway_settle_order RPC (migration 0085).
//
// Required secrets:
//   PAYMENT_WEBHOOK_SECRET — shared secret guarding this endpoint
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY — service role DB writes

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { timingSafeEqual } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405);
  }

  const secret = Deno.env.get("PAYMENT_WEBHOOK_SECRET");
  if (!secret) {
    return json({ ok: false, error: "gateway_not_configured" }, 503);
  }

  const gotSecret = req.headers.get("x-webhook-secret") ?? "";
  if (!timingSafeEqual(gotSecret, secret)) {
    return json({ ok: false, error: "unauthorized" }, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ ok: false, error: "bad_json" }, 400);
  }

  const orderId = body.order_id as string | undefined;
  const status = (body.status as string | undefined) ?? (body.paid === true ? "paid" : "pending");
  const externalRef = body.external_ref as string | undefined;

  if (!orderId) {
    return json({ ok: false, error: "missing_order_id" }, 400);
  }

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    const { data: settled, error } = await supa.rpc("gateway_settle_order", {
      p_order_id: orderId,
      p_status: status,
      p_external_ref: externalRef,
    });

    if (error) {
      console.error("payment-webhook: gateway_settle_order failed", error);
      return json({ ok: false, error: error.message }, 500);
    }

    return json({ ok: true, settled: Boolean(settled) });
  } catch (e) {
    console.error("payment-webhook exception", e);
    return json({ ok: false, error: String(e) }, 500);
  }
});
