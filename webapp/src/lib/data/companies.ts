import "server-only";

import { createClient } from "@/lib/supabase/server";

import { getOpenJobs } from "./jobs";
import { toCompany, toReview } from "./mappers";
import { mockCompanies } from "./mock";
import { hasSupabase } from "./supabase-env";
import type { Company, CompanyReview, Job } from "./types";

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
