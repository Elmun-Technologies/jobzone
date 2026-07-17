// delete-account — self-service account deletion. Required by Apple App
// Store 5.1.1(v) and Play Store Data Safety (2024): a signed-in user
// must be able to delete their account from inside the product.
//
// Flow:
//   1. Client sends its user JWT in Authorization: Bearer <token>.
//   2. We create a Supabase client bound to that token; supabase.auth
//      .getUser() returns the caller. Refuse anything without a session.
//   3. Log the deletion (log_account_deletion RPC) BEFORE the destructive
//      call so we always have a proof-of-deletion row even if step 4 hangs
//      partway. A stray log with no actual delete is auditable; a delete
//      with no log is not.
//   4. Call supabase.auth.admin.deleteUser(userId) with the service-role
//      client. The `on delete cascade` chain on profiles.id (0001) then
//      wipes every user-scoped row across the schema.
//
// Required secrets:
//   SUPABASE_URL             — bound at Function creation
//   SUPABASE_SERVICE_ROLE_KEY — bound at Function creation
//   SUPABASE_ANON_KEY        — for the caller-context client
//
// verify_jwt = true (default) so we get the JWT auto-attached; if the
// caller isn't signed in Supabase already returns 401 before we run.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

import { corsHeaders, json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ ok: false, error: "method_not_allowed" }, 405);
  }

  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!url || !serviceKey || !anonKey) {
    return json({ ok: false, error: "service_not_configured" }, 503);
  }

  // Caller identity — the Bearer token attached by the mobile/web client.
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";
  if (!token) return json({ ok: false, error: "no_session" }, 401);

  const asCaller = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: userData, error: userErr } = await asCaller.auth.getUser();
  if (userErr || !userData.user) {
    return json({ ok: false, error: "invalid_session" }, 401);
  }
  const userId = userData.user.id;

  // Optional reason from the client — helps ops understand churn without
  // exposing anything sensitive. We DO NOT keep the raw IP; hash it so
  // repeat abusive deletions can be traced by pattern without a PII trail.
  const body = await req.json().catch(() => ({}));
  const reason =
    typeof body?.reason === "string" ? body.reason.slice(0, 500) : null;
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
    req.headers.get("cf-connecting-ip") ??
    "";
  const ipHash = ip ? await sha256Hex(ip) : null;

  const asService = createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Log first (see header comment). We tolerate log failures — the
  // deletion itself is more important than the audit row.
  await asService.rpc("log_account_deletion", {
    p_user: userId,
    p_reason: reason,
    p_ip_hash: ipHash,
    p_meta: {},
  });

  const { error: delErr } = await asService.auth.admin.deleteUser(userId);
  if (delErr) {
    return json({ ok: false, error: "delete_failed", detail: delErr.message }, 500);
  }

  return json({ ok: true });
});

async function sha256Hex(input: string): Promise<string> {
  const buf = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(input),
  );
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
