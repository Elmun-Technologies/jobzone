// search-jobs — legacy Meilisearch proxy, kept for tests; live search on both
// clients now runs on `job_feed` (Postgres). Not called by any shipping
// client (grep confirms), but still network-reachable, so it's hardened the
// same as any other endpoint: gated, and inputs are bounded instead of
// trusted verbatim from the caller.
//
// Required function secrets: MEILI_HOST, MEILI_SEARCH_KEY (falls back to MEILI_ADMIN_KEY),
//                             EDGE_SHARED_SECRET

import { MeiliSearch } from "https://esm.sh/meilisearch@0.41.0";
import { corsHeaders, json } from "../_shared/cors.ts";
import { JOBS_INDEX } from "../_shared/job_document.ts";
import { requireEdgeSecret } from "../_shared/auth.ts";

const meili = new MeiliSearch({
  host: Deno.env.get("MEILI_HOST")!,
  apiKey: Deno.env.get("MEILI_SEARCH_KEY") ?? Deno.env.get("MEILI_ADMIN_KEY")!,
});

// Only these attributes may be filtered on — the caller's `filters` are
// checked against this prefix list, not passed through as arbitrary
// Meilisearch filter-expression strings.
const FILTERABLE_PREFIXES = [
  "job_type",
  "experience_level",
  "working_model",
  "schedule_pattern",
  "formalization",
  "category_id",
  "city",
  "salary_min",
  "salary_max",
  "posted_at",
];

function isSafeFilter(f: unknown): f is string {
  return typeof f === "string" &&
    f.length <= 200 &&
    FILTERABLE_PREFIXES.some((p) => f.startsWith(p));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const denied = requireEdgeSecret(req);
  if (denied) return denied;

  const {
    q = "",
    filters = [],
    sort = [],
    limit = 20,
    offset = 0,
    facets,
  } = await req.json().catch(() => ({}));

  const safeQ = typeof q === "string" ? q.slice(0, 200) : "";
  const safeFilters = Array.isArray(filters) ? filters.filter(isSafeFilter) : [];
  const safeLimit = Math.min(Math.max(Number(limit) || 20, 1), 50);
  const safeOffset = Math.min(Math.max(Number(offset) || 0, 0), 10_000);

  // Never expose non-open jobs through search.
  const filter = ['status = "open"', ...safeFilters];

  try {
    const res = await meili.index(JOBS_INDEX).search(safeQ, {
      filter,
      sort: Array.isArray(sort) && sort.length ? sort : undefined,
      limit: safeLimit,
      offset: safeOffset,
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
