// push-dispatch — sends an FCM push to all of a recipient's devices.
//
// Pairs with `send-notification` (which writes the in-app row) and with the
// `notify-dispatch` trigger fan-out. The actual FCM HTTP v1 send lives in
// `_shared/fcm.ts`; this is a thin authenticated endpoint over it. Returns
// `{ ok: true, sent: 0 }` (no error) when FCM isn't configured yet.
//
// Required secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// Optional: FCM_SERVICE_ACCOUNT (enables sending), EDGE_SHARED_SECRET (gate)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { sendFcmToUser } from "../_shared/fcm.ts";
import { requireEdgeSecret } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Fail closed — this delivers push to arbitrary recipients.
  const denied = requireEdgeSecret(req);
  if (denied) return denied;

  const { recipient_id, title, body = "", data = {} } = await req.json().catch(
    () => ({}),
  );
  if (!recipient_id || !title) {
    return json(
      { ok: false, error: "recipient_id and title are required" },
      400,
    );
  }

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const sent = await sendFcmToUser(supa, recipient_id, title, body, data);
  return json({ ok: true, sent });
});
