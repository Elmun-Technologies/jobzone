// meili-sync — invoked by a Postgres DB webhook on `jobs` / `companies`.
// Upserts/deletes the corresponding Meilisearch documents. Holds the Meili
// ADMIN key server-side (never shipped to the client).
//
// Required function secrets:
//   MEILI_HOST, MEILI_ADMIN_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//   EDGE_SHARED_SECRET (optional; must match app.edge_shared_secret if set)

import { MeiliSearch } from "https://esm.sh/meilisearch@0.41.0";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { corsHeaders, json } from "../_shared/cors.ts";
import { JOBS_INDEX, toJobDocument } from "../_shared/job_document.ts";
import { requireEdgeSecret } from "../_shared/auth.ts";

const meili = new MeiliSearch({
  host: Deno.env.get("MEILI_HOST")!,
  apiKey: Deno.env.get("MEILI_ADMIN_KEY")!,
});

function adminClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  // verify_jwt = false; invoked by the DB webhook. Fail closed.
  const denied = requireEdgeSecret(req);
  if (denied) return denied;

  const payload = await req.json().catch(() => null);
  if (!payload?.table) return json({ ok: false, error: "bad payload" }, 400);

  const index = meili.index(JOBS_INDEX);

  try {
    if (payload.table === "jobs") {
      const job = payload.record;
      const isDelete = payload.type === "DELETE";
      const notOpen = job && job.status !== "open";

      if (isDelete || notOpen) {
        const id = payload.old_record?.id ?? job?.id;
        if (id) await index.deleteDocument(id);
        return json({ ok: true, action: "delete" });
      }

      const supa = adminClient();
      const { data: company } = await supa
        .from("companies")
        .select("name,logo_url,is_verified")
        .eq("id", job.company_id)
        .single();

      let categoryName = "";
      if (job.category_id) {
        const { data: cat } = await supa
          .from("job_categories")
          .select("name")
          .eq("id", job.category_id)
          .single();
        categoryName = cat?.name ?? "";
      }

      await index.addDocuments([toJobDocument(job, company ?? undefined, categoryName)]);
      return json({ ok: true, action: "upsert" });
    }

    if (payload.table === "companies" && payload.type === "UPDATE") {
      const company = payload.record;
      const supa = adminClient();
      const { data: jobs } = await supa
        .from("jobs")
        .select("*")
        .eq("company_id", company.id)
        .eq("status", "open");
      if (jobs?.length) {
        await index.addDocuments(jobs.map((j: any) => toJobDocument(j, company)));
      }
      return json({ ok: true, action: "reindex-company", count: jobs?.length ?? 0 });
    }

    return json({ ok: true, action: "ignored" });
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});
