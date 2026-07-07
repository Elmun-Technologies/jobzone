import "server-only";

import { createClient } from "@/lib/supabase/server";

import { getOpenJobs } from "./jobs";
import { toCompany, toReview } from "./mappers";
import { mockCompanies, mockJobs } from "./mock";
import { hasSupabase } from "./supabase-env";
import type { Company, CompanyReview, CompanyWithJobs, Job } from "./types";

/** Average review rating + review count, keyed by company id. */
export type CompanyRatings = Record<string, { avg: number; count: number }>;

/**
 * Public company reputation (from the `company_rating_summary` view) for the
 * map's "by rating" facet. Anonymous-safe; degrades to `{}` on error.
 */
export async function getCompanyRatings(): Promise<CompanyRatings> {
  if (!hasSupabase()) {
    return {
      "c-acme": { avg: 4.6, count: 12 },
      "c-nimbus": { avg: 3.2, count: 5 },
    };
  }
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("company_rating_summary")
      .select("company_id, avg_rating, review_count");
    if (error) throw error;
    const out: CompanyRatings = {};
    for (const r of data ?? []) {
      out[r.company_id as string] = {
        avg: Number(r.avg_rating) || 0,
        count: Number(r.review_count) || 0,
      };
    }
    return out;
  } catch (e) {
    console.error("getCompanyRatings failed", e);
    return {};
  }
}

/** One company's rating from `company_rating_summary`; zeroed if it has no reviews yet. */
export async function getCompanyRating(
  companyId: string,
): Promise<{ avg: number; count: number }> {
  const empty = { avg: 0, count: 0 };
  if (!hasSupabase()) return empty;
  try {
    const supabase = await createClient();
    const { data } = await supabase
      .from("company_rating_summary")
      .select("avg_rating, review_count")
      .eq("company_id", companyId)
      .maybeSingle();
    if (!data) return empty;
    return {
      avg: Number(data.avg_rating) || 0,
      count: Number(data.review_count) || 0,
    };
  } catch (e) {
    console.error("getCompanyRating failed", e);
    return empty;
  }
}

/**
 * Company directory — verified first, then alphabetical. Each carries its
 * open-job count (one bounded query scoped to the listed companies).
 */
export async function getCompanies(opts?: {
  q?: string;
  limit?: number;
}): Promise<CompanyWithJobs[]> {
  const limit = opts?.limit ?? 48;
  const q = opts?.q?.trim().toLowerCase();

  if (!hasSupabase()) {
    return mockCompanies
      .filter((c) => !q || c.name.toLowerCase().includes(q))
      .map((c) => ({
        ...c,
        openJobs: mockJobs.filter((j) => j.companyId === c.id).length,
      }))
      .sort(
        (a, b) =>
          Number(b.isVerified) - Number(a.isVerified) ||
          a.name.localeCompare(b.name),
      );
  }

  try {
    const supabase = await createClient();
    let req = supabase
      .from("companies")
      .select("*")
      .order("is_verified", { ascending: false })
      .order("name", { ascending: true })
      .limit(limit);
    if (opts?.q) req = req.ilike("name", `%${opts.q}%`);

    const { data, error } = await req;
    if (error) throw error;
    const companies = (data ?? []).map(toCompany);
    if (companies.length === 0) return [];

    // Bounded count: only open jobs belonging to the listed companies.
    const ids = companies.map((c) => c.id);
    const counts = new Map<string, number>();
    const { data: jobRows } = await supabase
      .from("job_feed")
      .select("company_id")
      .eq("status", "open")
      .in("company_id", ids);
    for (const row of jobRows ?? []) {
      const id = String((row as { company_id: unknown }).company_id);
      counts.set(id, (counts.get(id) ?? 0) + 1);
    }

    return companies.map((c) => ({ ...c, openJobs: counts.get(c.id) ?? 0 }));
  } catch (e) {
    console.error("getCompanies failed", e);
    return [];
  }
}

/** A company profile by id, or null. */
export async function getCompanyById(id: string): Promise<Company | null> {
  if (!hasSupabase()) return mockCompanies.find((c) => c.id === id) ?? null;
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("companies")
      .select("*")
      .eq("id", id)
      .maybeSingle();
    if (error) throw error;
    return data ? toCompany(data) : null;
  } catch (e) {
    console.error("getCompanyById failed", e);
    return null;
  }
}

/** Open jobs posted by a company. */
export async function getCompanyJobs(companyId: string): Promise<Job[]> {
  if (!hasSupabase()) {
    const { mockJobs } = await import("./mock");
    return mockJobs.filter((j) => j.companyId === companyId);
  }
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("job_feed")
      .select("*")
      .eq("company_id", companyId)
      .eq("status", "open")
      .order("posted_at", { ascending: false });
    if (error) throw error;
    const { toJob } = await import("./mappers");
    return (data ?? []).map(toJob);
  } catch (e) {
    console.error("getCompanyJobs failed", e);
    return [];
  }
}

/** Public reviews for a company (author names require auth, so omitted). */
export async function getCompanyReviews(
  companyId: string,
): Promise<CompanyReview[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("company_reviews")
      .select("id, rating, body, created_at")
      .eq("company_id", companyId)
      .order("created_at", { ascending: false })
      .limit(20);
    if (error) throw error;
    return (data ?? []).map(toReview);
  } catch (e) {
    console.error("getCompanyReviews failed", e);
    return [];
  }
}

/** All company ids (for the sitemap). */
export async function getAllCompanyIds(limit = 1000): Promise<string[]> {
  if (!hasSupabase()) return mockCompanies.map((c) => c.id);
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("companies")
      .select("id")
      .limit(limit);
    if (error) throw error;
    return (data ?? []).map((r) => String((r as { id: unknown }).id));
  } catch (e) {
    console.error("getAllCompanyIds failed", e);
    return [];
  }
}

// Re-export for convenience on the company page.
export { getOpenJobs };
