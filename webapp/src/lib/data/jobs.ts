import "server-only";

import { createClient } from "@/lib/supabase/server";

import { toJob } from "./mappers";
import { mockJobs } from "./mock";
import { hasSupabase } from "./supabase-env";
import type { Job, JobQuery } from "./types";

const COLUMNS = "*";
const DAY_MS = 86_400_000;

function salaryTop(j: Job): number | null {
  return j.salaryMax ?? j.salaryMin;
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

function filterMock(query: JobQuery): Job[] {
  const q = query.q?.toLowerCase().trim();
  const nowMs = Date.now();
  const rows = mockJobs.filter((j) => {
    if (
      q &&
      !`${j.title} ${j.companyName} ${j.categoryName ?? ""}`
        .toLowerCase()
        .includes(q)
    ) {
      return false;
    }
    if (query.city && j.city !== query.city) return false;
    if (query.category && j.categoryName !== query.category) return false;
    if (query.jobType && j.jobType !== query.jobType) return false;
    if (query.workingModel && j.workingModel !== query.workingModel) {
      return false;
    }
    if (query.experienceLevel && j.experienceLevel !== query.experienceLevel) {
      return false;
    }
    if (query.salaryMin != null) {
      if ((query.currency ?? "UZS") !== j.currency) return false;
      const matches =
        (j.salaryMax != null && j.salaryMax >= query.salaryMin) ||
        (j.salaryMin != null && j.salaryMin >= query.salaryMin);
      if (!matches) return false;
    }
    if (query.postedWithin != null && query.postedWithin > 0) {
      const t = j.postedAt ? Date.parse(j.postedAt) : NaN;
      if (Number.isNaN(t) || nowMs - t > query.postedWithin * DAY_MS) {
        return false;
      }
    }
    return true;
  });
  if (query.sort === "salary") {
    return [...rows].sort((a, b) => (salaryTop(b) ?? 0) - (salaryTop(a) ?? 0));
  }
  return rows;
}

// The `posted_at` cutoff for a "posted within N days" filter, or null.
function postedCutoff(query: JobQuery): string | null {
  if (query.postedWithin == null || query.postedWithin <= 0) return null;
  return new Date(Date.now() - query.postedWithin * DAY_MS).toISOString();
}

/** A page of open jobs matching [query]. Boosted jobs first, then ordered. */
export async function getOpenJobs(query: JobQuery = {}): Promise<Job[]> {
  const limit = query.limit ?? 20;
  const offset = query.offset ?? 0;

  if (!hasSupabase()) {
    return filterMock(query).slice(offset, offset + limit);
  }

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

    if (query.q) {
      const term = ilikeTerm(query.q);
      // Match title, company, AND category — mirrors the saved-search alert
      // matcher (0036), so a saved category search (stored as its keyword and
      // re-run as ?q=) finds its jobs instead of returning empty.
      if (term)
        req = req.or(
          `title.ilike.%${term}%,company_name.ilike.%${term}%,category_name.ilike.%${term}%`,
        );
    }
    if (query.city) req = req.eq("city", query.city);
    if (query.category) req = req.eq("category_name", query.category);
    if (query.jobType) req = req.eq("job_type", query.jobType);
    if (query.workingModel) req = req.eq("working_model", query.workingModel);
    if (query.experienceLevel) {
      req = req.eq("experience_level", query.experienceLevel);
    }
    if (query.salaryMin != null) {
      req = req
        .eq("currency", query.currency ?? "UZS")
        .or(
          `salary_max.gte.${query.salaryMin},salary_min.gte.${query.salaryMin}`,
        );
    }
    const cutoff = postedCutoff(query);
    if (cutoff) req = req.gte("posted_at", cutoff);

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
  if (!hasSupabase()) return filterMock(query).length;
  try {
    const supabase = await createClient();
    let req = supabase
      .from("job_feed")
      .select("id", { count: "exact", head: true })
      .eq("status", "open");

    if (query.q) {
      const term = ilikeTerm(query.q);
      // Same title/company/category match as getOpenJobs, so the live count
      // stays consistent with the results a query returns.
      if (term)
        req = req.or(
          `title.ilike.%${term}%,company_name.ilike.%${term}%,category_name.ilike.%${term}%`,
        );
    }
    if (query.city) req = req.eq("city", query.city);
    if (query.category) req = req.eq("category_name", query.category);
    if (query.jobType) req = req.eq("job_type", query.jobType);
    if (query.workingModel) req = req.eq("working_model", query.workingModel);
    if (query.experienceLevel) {
      req = req.eq("experience_level", query.experienceLevel);
    }
    if (query.salaryMin != null) {
      req = req
        .eq("currency", query.currency ?? "UZS")
        .or(
          `salary_max.gte.${query.salaryMin},salary_min.gte.${query.salaryMin}`,
        );
    }
    const cutoff = postedCutoff(query);
    if (cutoff) req = req.gte("posted_at", cutoff);

    const { count, error } = await req;
    if (error) throw error;
    return count ?? 0;
  } catch (e) {
    console.error("getJobCount failed", e);
    return 0;
  }
}

/** Distinct cities that currently have open jobs (for the region selector). */
export async function getCities(limit = 1000): Promise<string[]> {
  if (!hasSupabase()) {
    return [
      ...new Set(mockJobs.map((j) => j.city).filter((c): c is string => !!c)),
    ].sort((a, b) => a.localeCompare(b));
  }
  try {
    const supabase = await createClient();
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
  } catch (e) {
    console.error("getCities failed", e);
    return [];
  }
}

/** Recent open jobs for the landing page. */
export async function getRecentJobs(limit = 6): Promise<Job[]> {
  if (!hasSupabase()) return mockJobs.slice(0, limit);
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_feed")
      .select(COLUMNS)
      .eq("status", "open")
      .order("boost_active", { ascending: false })
      .order("posted_at", { ascending: false })
      .limit(limit);
    if (error) throw error;
    return (data ?? []).map(toJob);
  } catch (e) {
    console.error("getRecentJobs failed", e);
    return [];
  }
}

/** A single open job by id, or null. */
export async function getJobById(id: string): Promise<Job | null> {
  if (!hasSupabase()) return mockJobs.find((j) => j.id === id) ?? null;
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

/** Ids of all open jobs (for the sitemap). Capped to keep the sitemap sane. */
export async function getAllJobIds(limit = 1000): Promise<string[]> {
  if (!hasSupabase()) return mockJobs.map((j) => j.id);
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
