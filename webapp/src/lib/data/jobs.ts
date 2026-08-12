import "server-only";

import { unstable_cache } from "next/cache";

import { createClient, createPublicClient } from "@/lib/supabase/server";

import { toJob } from "./mappers";
import { hasSupabase } from "./supabase-env";
import type { Job, JobQuery } from "./types";

const COLUMNS = "*";
const DAY_MS = 86_400_000;

/**
 * The signed-in caller's dismissed job ids ("archived" / "not interested" —
 * see 0052), or [] for a guest. Used to exclude them from the open-jobs feed
 * everywhere it's read (mirrors bookmarks' own separate-lookup pattern) —
 * dismissal only affects browsing, not a direct link or Bookmarks (a job
 * stays saved there even if later dismissed from the feed).
 */
async function dismissedJobIds(
  supabase: Awaited<ReturnType<typeof createClient>>,
): Promise<string[]> {
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return [];
  const { data } = await supabase
    .from("dismissed_jobs")
    .select("job_id")
    .eq("profile_id", user.id);
  return (data ?? []).map((r) => String((r as { job_id: unknown }).job_id));
}

/**
 * Neutralize PostgREST filter-grammar metacharacters before interpolating a
 * user search term into an `.or(...)` string. Commas separate conditions and
 * parens group them, so a raw term could otherwise inject extra filter
 * conditions; `*`/`%` are ilike wildcards and `\` an escape. RLS + the ANDed
 * status='open' already bound the blast radius — this closes the vector.
 */
function ilikeTerm(q: string): string {
  return q.replace(/[,()*%\\:]/g, " ").trim();
}

// The `posted_at` cutoff for a "posted within N days" filter, or null.
function postedCutoff(query: JobQuery): string | null {
  if (query.postedWithin == null || query.postedWithin <= 0) return null;
  return new Date(Date.now() - query.postedWithin * DAY_MS).toISOString();
}

/**
 * The filter chain shared by every read of the open-job feed — the browse
 * feed, its count, and the cached public variants below. One function so the
 * count can never disagree with the list it counts.
 */
// The narrow slice of the PostgREST builder these filters need. Every method
// on it returns the builder itself, so the chain is type-preserving — stated
// structurally here because resolving the real generic through the builder's
// own recursive types makes tsc give up ("excessively deep").
interface JobFilterable {
  or(filter: string): JobFilterable;
  eq(column: string, value: unknown): JobFilterable;
  gte(column: string, value: unknown): JobFilterable;
}

function applyJobFilters<T>(req: T, query: JobQuery): T {
  let r = req as JobFilterable;
  if (query.q) {
    const term = ilikeTerm(query.q);
    // Match title, company, AND category — mirrors the saved-search alert
    // matcher (0036), so a saved category search (stored as its keyword and
    // re-run as ?q=) finds its jobs instead of returning empty.
    if (term)
      r = r.or(
        `title.ilike.%${term}%,company_name.ilike.%${term}%,category_name.ilike.%${term}%`,
      );
  }
  if (query.city) r = r.eq("city", query.city);
  if (query.category) r = r.eq("category_name", query.category);
  if (query.jobType) r = r.eq("job_type", query.jobType);
  if (query.workingModel) r = r.eq("working_model", query.workingModel);
  if (query.experienceLevel)
    r = r.eq("experience_level", query.experienceLevel);
  if (query.salaryMin != null) {
    r = r
      .eq("currency", query.currency ?? "UZS")
      .or(
        `salary_max.gte.${query.salaryMin},salary_min.gte.${query.salaryMin}`,
      );
  }
  const cutoff = postedCutoff(query);
  if (cutoff) r = r.gte("posted_at", cutoff);
  return r as T;
}

/** A page of open jobs matching [query]. Boosted jobs first, then ordered. */
export async function getOpenJobs(query: JobQuery = {}): Promise<Job[]> {
  const limit = query.limit ?? 20;
  const offset = query.offset ?? 0;

  // Online-only: without a configured backend there is nothing to show.
  if (!hasSupabase()) return [];

  try {
    const supabase = await createClient();
    let req = supabase
      .from("job_feed")
      .select(COLUMNS)
      .eq("status", "open")
      .order("boost_active", { ascending: false });
    if (query.sort === "salary") {
      req = req
        .order("salary_max", { ascending: false, nullsFirst: false })
        .order("salary_min", { ascending: false, nullsFirst: false });
    } else {
      req = req.order("posted_at", { ascending: false });
    }

    req = applyJobFilters(req, query);

    const dismissed = await dismissedJobIds(supabase);
    if (dismissed.length > 0)
      req = req.not("id", "in", `(${dismissed.join(",")})`);

    req = req.range(offset, offset + limit - 1);

    const { data, error } = await req;
    if (error) throw error;
    return (data ?? []).map(toJob);
  } catch (e) {
    console.error("getOpenJobs failed", e);
    return [];
  }
}

/** Exact count of open jobs matching [query] (for result headers + totals). */
export async function getJobCount(query: JobQuery = {}): Promise<number> {
  if (!hasSupabase()) return 0;
  try {
    const supabase = await createClient();
    let req = supabase
      .from("job_feed")
      .select("id", { count: "exact", head: true })
      .eq("status", "open");

    req = applyJobFilters(req, query);

    // Must match getOpenJobs' exclusions exactly — this count backs the live
    // "N vacancies" button, which has to agree with what actually renders.
    const dismissed = await dismissedJobIds(supabase);
    if (dismissed.length > 0)
      req = req.not("id", "in", `(${dismissed.join(",")})`);

    const { count, error } = await req;
    if (error) throw error;
    return count ?? 0;
  } catch (e) {
    console.error("getJobCount failed", e);
    return 0;
  }
}

/**
 * The same feed, read as the public sees it: the anon client, no session, no
 * per-seeker archive filter — and therefore cacheable.
 *
 * This pair is what the landing pages use (category, category × city, and the
 * region pages, which already worked this way). The distinction is the whole
 * reason those pages can be prerendered and served from the CDN: a read that
 * touches the session cannot be, no matter how cacheable the rest of the page
 * is. The trade is deliberate and matches what the region landings have done
 * since they shipped — a shared landing page shows the market, not one
 * visitor's edit of it, so a vacancy someone archived still appears there.
 * `/jobs` and the home feed keep the personal variants above.
 *
 * A publish or a close calls `revalidateTag("jobs")` (actions/employer.ts), so
 * a new posting appears immediately rather than at the end of the window —
 * which is what invariant #3 actually asks for.
 */
const PUBLIC_FEED_REVALIDATE = 300;

const _getPublicJobs = unstable_cache(
  async (query: JobQuery): Promise<Job[]> => {
    const limit = query.limit ?? 20;
    const offset = query.offset ?? 0;
    const supabase = createPublicClient();
    let req = supabase
      .from("job_feed")
      .select(COLUMNS)
      .eq("status", "open")
      .order("boost_active", { ascending: false });
    if (query.sort === "salary") {
      req = req
        .order("salary_max", { ascending: false, nullsFirst: false })
        .order("salary_min", { ascending: false, nullsFirst: false });
    } else {
      req = req.order("posted_at", { ascending: false });
    }
    req = applyJobFilters(req, query).range(offset, offset + limit - 1);
    const { data, error } = await req;
    if (error) throw error;
    return (data ?? []).map(toJob);
  },
  ["public-jobs"],
  { tags: ["jobs"], revalidate: PUBLIC_FEED_REVALIDATE },
);

/** Open jobs matching [query], shared by every visitor. See _getPublicJobs. */
export async function getPublicJobs(query: JobQuery = {}): Promise<Job[]> {
  if (!hasSupabase()) return [];
  try {
    return await _getPublicJobs(query);
  } catch (e) {
    console.error("getPublicJobs failed", e);
    return [];
  }
}

const _getPublicJobCount = unstable_cache(
  async (query: JobQuery): Promise<number> => {
    const supabase = createPublicClient();
    const req = applyJobFilters(
      supabase
        .from("job_feed")
        .select("id", { count: "exact", head: true })
        .eq("status", "open"),
      query,
    );
    const { count, error } = await req;
    if (error) throw error;
    return count ?? 0;
  },
  ["public-job-count"],
  { tags: ["jobs"], revalidate: PUBLIC_FEED_REVALIDATE },
);

/** Count for [query], shared by every visitor. See _getPublicJobs. */
export async function getPublicJobCount(query: JobQuery = {}): Promise<number> {
  if (!hasSupabase()) return 0;
  try {
    return await _getPublicJobCount(query);
  } catch (e) {
    console.error("getPublicJobCount failed", e);
    return 0;
  }
}

/** Distinct cities that currently have open jobs (for the region selector). */
// The region selector is the same for every visitor and changes rarely, but it
// renders on the home page and every category landing. Cache it (5-min window)
// so it stops scanning up to `limit` open-job rows on every request.
const _getCities = unstable_cache(
  async (limit: number): Promise<string[]> => {
    const supabase = createPublicClient();
    const { data, error } = await supabase
      .from("job_feed")
      .select("city")
      .eq("status", "open")
      .not("city", "is", null)
      .limit(limit);
    if (error) throw error;
    const set = new Set<string>();
    for (const row of data ?? []) {
      const c = (row as { city: unknown }).city;
      if (typeof c === "string" && c.trim()) set.add(c.trim());
    }
    return [...set].sort((a, b) => a.localeCompare(b));
  },
  ["cities"],
  { tags: ["jobs"], revalidate: 300 },
);

export async function getCities(limit = 1000): Promise<string[]> {
  if (!hasSupabase()) return [];
  try {
    return await _getCities(limit);
  } catch (e) {
    console.error("getCities failed", e);
    return [];
  }
}

/** Recent open jobs for the landing page. */
export async function getRecentJobs(limit = 6): Promise<Job[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const dismissed = await dismissedJobIds(supabase);
    let req = supabase
      .from("job_feed")
      .select(COLUMNS)
      .eq("status", "open")
      .order("boost_active", { ascending: false })
      .order("posted_at", { ascending: false })
      .limit(limit);
    if (dismissed.length > 0)
      req = req.not("id", "in", `(${dismissed.join(",")})`);
    const { data, error } = await req;
    if (error) throw error;
    return (data ?? []).map(toJob);
  } catch (e) {
    console.error("getRecentJobs failed", e);
    return [];
  }
}

const _getPublicJobById = unstable_cache(
  async (id: string): Promise<Job | null> => {
    const supabase = createPublicClient();
    const { data, error } = await supabase
      .from("job_feed")
      .select(COLUMNS)
      .eq("id", id)
      .eq("status", "open")
      .maybeSingle();
    if (error) throw error;
    return data ? toJob(data) : null;
  },
  ["public-job"],
  { tags: ["jobs"], revalidate: PUBLIC_FEED_REVALIDATE },
);

/**
 * A single open vacancy as the public sees it — the read behind the vacancy
 * page, and the reason that page can be prerendered.
 *
 * Narrower than `getJobById` on purpose. That one reads through the session,
 * so an employer could open their own draft at its public URL; here the
 * `status = 'open'` filter is explicit and a draft or closed vacancy is a 404
 * for everyone, owner included. Employers preview and edit from
 * `/employer/jobs/[id]/edit`, which is where that belongs.
 */
export async function getPublicJobById(id: string): Promise<Job | null> {
  if (!hasSupabase()) return null;
  try {
    return await _getPublicJobById(id);
  } catch (e) {
    console.error("getPublicJobById failed", e);
    return null;
  }
}

/** A single job by id as the *caller* may see it (owners include drafts). */
export async function getJobById(id: string): Promise<Job | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_feed")
      .select(COLUMNS)
      .eq("id", id)
      .maybeSingle();
    if (error) throw error;
    return data ? toJob(data) : null;
  } catch (e) {
    console.error("getJobById failed", e);
    return null;
  }
}

/**
 * Open jobs matched to the signed-in seeker's résumé, ranked by the shared
 * `recommended_jobs` RPC (0051) — the same algorithm the mobile app calls, so
 * both rank identically. Returns [] for a guest / no profile / no matches.
 */
export async function getRecommendedJobs(): Promise<Job[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const { data, error } = await supabase.rpc("recommended_jobs");
    if (error) throw error;
    return ((data ?? []) as Record<string, unknown>[]).map(toJob);
  } catch (e) {
    console.error("getRecommendedJobs failed", e);
    return [];
  }
}

/** Ids of all open jobs (for the sitemap). Capped to keep the sitemap sane. */
export async function getAllJobIds(limit = 1000): Promise<string[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_feed")
      .select("id")
      .eq("status", "open")
      .limit(limit);
    if (error) throw error;
    return (data ?? []).map((r) => String((r as { id: unknown }).id));
  } catch (e) {
    console.error("getAllJobIds failed", e);
    return [];
  }
}

/** Minimal per-job shape the sitemap needs. `categoryName` + `city` let
 * the caller compute per-category and per-city×category `lastmod` from
 * one query rather than N+N×M round trips. */
export interface SitemapJob {
  id: string;
  postedAt: string | null;
  categoryName: string | null;
  city: string | null;
}

/** All open job (id, postedAt, category, city) tuples — for sitemap
 * `lastmod`. Capped for the same reason as getAllJobIds (bounded
 * sitemap). */
export async function getAllJobsForSitemap(
  limit = 1000,
): Promise<SitemapJob[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_feed")
      .select("id, posted_at, category_name, city")
      .eq("status", "open")
      .order("posted_at", { ascending: false })
      .limit(limit);
    if (error) throw error;
    return (data ?? []).map((r) => {
      const row = r as {
        id: unknown;
        posted_at: unknown;
        category_name: unknown;
        city: unknown;
      };
      return {
        id: String(row.id),
        postedAt: row.posted_at == null ? null : String(row.posted_at),
        categoryName:
          row.category_name == null ? null : String(row.category_name),
        city: row.city == null ? null : String(row.city),
      };
    });
  } catch (e) {
    console.error("getAllJobsForSitemap failed", e);
    return [];
  }
}
