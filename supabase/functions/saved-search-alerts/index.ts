// saved-search-alerts — periodically turns saved searches into alerts. It calls
// the run_saved_search_alerts() SQL function (migration 0036), which matches
// newly-posted open jobs against every saved search and inserts a job_match
// notification per match; the notifications AFTER-INSERT trigger (0026) then
// fans each one out to in-app + Telegram + push, respecting the recipient's
// push_job_match setting.
//
// This is the secret-gated HTTP entry point a scheduler invokes (Supabase cron,
// or pg_cron + pg_net). The matching + watermark bookkeeping all live in SQL, so
// this stays a thin, idempotent trigger.
//
// Required secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, EDGE_SHARED_SECRET

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { requireEdgeSecret } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // Server-to-server only (scheduler / cron). Fail closed.
  const denied = requireEdgeSecret(req);
  if (denied) return denied;

  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data, error } = await supa.rpc("run_saved_search_alerts");
  if (error) return json({ ok: false, error: error.message }, 500);

  // `data` is the number of alert notifications created this run.
  return json({ ok: true, notified: typeof data === "number" ? data : 0 });
});
