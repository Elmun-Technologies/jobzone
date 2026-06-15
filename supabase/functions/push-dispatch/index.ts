// push-dispatch — sends an FCM push to all of a recipient's devices (Phase 8).
//
// Pairs with `send-notification` (which writes the in-app row). Call this to
// also deliver a remote push. Looks up the recipient's tokens in `devices`
// (migration 0008) and posts to FCM HTTP v1.
//
// To go live:
//   1. Set secrets: FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT (JSON), or an
//      FCM_SERVER_KEY for the legacy API.
//   2. Uncomment the FCM send below.
//   3. `supabase functions deploy push-dispatch`.
//
// Required secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, FCM_* as above.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const secret = Deno.env.get("EDGE_SHARED_SECRET");
  if (secret && req.headers.get("x-edge-secret") !== secret) {
    return json({ ok: false, error: "unauthorized" }, 401);
  }

  const { recipient_id, title, body, data = {} } =
    await req.json().catch(() => ({}));
  if (!recipient_id || !title) {
    return json({ ok: false, error: "recipient_id and title are required" }, 400);
  }

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: devices, error } = await supa
    .from("devices")
    .select("fcm_token")
    .eq("profile_id", recipient_id);
  if (error) return json({ ok: false, error: error.message }, 500);

  const tokens = (devices ?? []).map((d: { fcm_token: string }) => d.fcm_token);
  if (tokens.length === 0) return json({ ok: true, sent: 0 });

  // FCM: for each token, POST to
  // https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send
  // with an OAuth2 bearer token derived from the service account, payload:
  // { message: { token, notification: { title, body }, data } }
  // Collect failures and prune invalid tokens from `devices`.

  return json({ ok: false, error: "fcm sender not wired", tokens: tokens.length }, 501);
});
