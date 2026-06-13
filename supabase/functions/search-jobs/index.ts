// search-jobs — client-facing search proxy. Flutter calls this with
// { q, filters, sort, limit, offset, facets }. Uses a search-only Meili key
// and always constrains results to open jobs.
//
// Required function secrets: MEILI_HOST, MEILI_SEARCH_KEY (falls back to MEILI_ADMIN_KEY)

import { MeiliSearch } from "https://esm.sh/meilisearch@0.41.0";
import { corsHeaders, json } from "../_shared/cors.ts";
import { JOBS_INDEX } from "../_shared/job_document.ts";

const meili = new MeiliSearch({
  host: Deno.env.get("MEILI_HOST")!,
  apiKey: Deno.env.get("MEILI_SEARCH_KEY") ?? Deno.env.get("MEILI_ADMIN_KEY")!,
});

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const {
    q = "",
    filters = [],
    sort = [],
    limit = 20,
    offset = 0,
    facets,
  } = await req.json().catch(() => ({}));

  // Never expose non-open jobs through search.
  const filter = ['status = "open"', ...(Array.isArray(filters) ? filters : [])];

  try {
    const res = await meili.index(JOBS_INDEX).search(q, {
      filter,
      sort: Array.isArray(sort) && sort.length ? sort : undefined,
      limit,
      offset,
      facets: facets ?? [
        "job_type",
        "experience_level",
        "working_model",
        "category_id",
        "city",
      ],
    });
    return json(res);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
