import "server-only";

import { createClient } from "@/lib/supabase/server";

import { toJob } from "./mappers";
import { mockJobs } from "./mock";
import { hasSupabase } from "./supabase-env";
import type { Job, JobQuery } from "./types";

const COLUMNS = "*";

function filterMock(query: JobQuery): Job[] {
  const q = query.q?.toLowerCase().trim();
  return mockJobs.filter((j) => {
    if (q && !`${j.title} ${j.companyName}`.toLowerCase().includes(q)) {
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
    return true;
  });
}

/** A page of open jobs matching [query]. Boosted jobs first, then recent. */
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
      .order("boost_active", { ascending: false })
      .order("posted_at", { ascending: false })
      .range(offset, offset + limit - 1);

    if (query.q) {
      req = req.or(`title.ilike.%${query.q}%,company_name.ilike.%${query.q}%`);
    }
    if (query.city) req = req.eq("city", query.city);
    if (query.category) req = req.eq("category_name", query.category);
    if (query.jobType) req = req.eq("job_type", query.jobType);
    if (query.workingModel) req = req.eq("working_model", query.workingModel);
    if (query.experienceLevel) {
      req = req.eq("experience_level", query.experienceLevel);
    }

    const { data, error } = await req;
    if (error) throw error;
    return (data ?? []).map(toJob);
  } catch (e) {
    console.error("getOpenJobs failed", e);
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
      .limit(limit);
    if (error) throw error;
    return (data ?? []).map((r) => String((r as { id: unknown }).id));
  } catch (e) {
    console.error("getAllJobIds failed", e);
    return [];
  }
}
