// meili-reindex — full rebuild of the `jobs` index from Postgres. Run manually
// or on a schedule (pg_cron + pg_net) as a self-healing backstop for any missed
// webhook events. Also (re)applies index settings.
//
// Required function secrets:
//   MEILI_HOST, MEILI_ADMIN_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { MeiliSearch } from "https://esm.sh/meilisearch@0.41.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { JOBS_INDEX, JOBS_SETTINGS, toJobDocument } from "../_shared/job_document.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const meili = new MeiliSearch({
    host: Deno.env.get("MEILI_HOST")!,
    apiKey: Deno.env.get("MEILI_ADMIN_KEY")!,
  });
  const supa = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const index = meili.index(JOBS_INDEX);

  try {
    await index.updateSettings(JOBS_SETTINGS);

    const { data: jobs, error } = await supa
      .from("job_feed")
      .select("*")
      .eq("status", "open");
    if (error) throw error;

    const docs = (jobs ?? []).map((j: any) =>
      toJobDocument(
        j,
        { name: j.company_name, logo_url: j.company_logo_url, is_verified: j.company_is_verified },
        j.category_name,
      )
    );
    if (docs.length) await index.addDocuments(docs);

    return json({ ok: true, count: docs.length });
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});
