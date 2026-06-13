// send-notification — central notification entry point.
//
// NOTE: remote push (FCM) is deferred to Phase 8. For now this writes an in-app
// notification row using the service role. Wire FCM fan-out (using the `devices`
// table) here in the later phase.
//
// Required function secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, EDGE_SHARED_SECRET (optional)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const secret = Deno.env.get("EDGE_SHARED_SECRET");
  if (secret && req.headers.get("x-edge-secret") !== secret) {
    return json({ ok: false, error: "unauthorized" }, 401);
  }

  const { recipient_id, type = "system", title, body, data = {} } =
    await req.json().catch(() => ({}));
  if (!recipient_id || !title) {
    return json({ ok: false, error: "recipient_id and title are required" }, 400);
  }

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await supa
    .from("notifications")
    .insert({ recipient_id, type, title, body, data });

  if (error) return json({ ok: false, error: error.message }, 500);
  return json({ ok: true });
});
