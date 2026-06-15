// agora-token — mints a short-lived Agora RTC token for a channel (Phase 8).
//
// The Agora App Certificate stays server-side; the client only ever receives a
// scoped, expiring token. Called by the Flutter `SupabaseCallTokenProvider`.
//
// To go live:
//   1. Set function secrets: AGORA_APP_ID, AGORA_APP_CERTIFICATE.
//   2. Uncomment the token build below (uses the Agora token package for Deno).
//   3. `supabase functions deploy agora-token`.
//
// Required secrets: SUPABASE_URL, AGORA_APP_ID, AGORA_APP_CERTIFICATE

import { corsHeaders, json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const { channel, uid = 0, expireSeconds = 3600 } =
    await req.json().catch(() => ({}));
  if (!channel) return json({ ok: false, error: "channel is required" }, 400);

  const appId = Deno.env.get("AGORA_APP_ID");
  const appCertificate = Deno.env.get("AGORA_APP_CERTIFICATE");
  if (!appId || !appCertificate) {
    // Not configured yet — calls fall back to the simulated service client-side.
    return json({ ok: false, error: "agora not configured" }, 501);
  }

  // AGORA: build an RTC token (publisher role), e.g. with
  // https://esm.sh/agora-token — pseudocode:
  //
  // import { RtcTokenBuilder, RtcRole } from "https://esm.sh/agora-token";
  // const expireAt = Math.floor(Date.now() / 1000) + expireSeconds;
  // const token = RtcTokenBuilder.buildTokenWithUid(
  //   appId, appCertificate, channel, uid, RtcRole.PUBLISHER, expireAt, expireAt,
  // );
  // return json({ ok: true, token, appId, channel, uid, expireSeconds });

  return json({ ok: false, error: "token builder not wired" }, 501);
});
