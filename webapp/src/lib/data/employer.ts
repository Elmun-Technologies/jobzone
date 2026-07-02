import "server-only";

import { createClient } from "@/lib/supabase/server";

import { toCompany } from "./mappers";
import { hasSupabase } from "./supabase-env";
import type { Company } from "./types";

/** The signed-in user's role (job_seeker | employer), or null. */
export async function getMyRole(): Promise<string | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return null;
    const { data } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();
    return data
      ? String((data as { role: unknown }).role ?? "job_seeker")
      : null;
  } catch {
    return null;
  }
}

/** The company owned by the signed-in user, or null. */
export async function getMyCompany(): Promise<Company | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return null;
    const { data } = await supabase
      .from("companies")
      .select("*")
      .eq("owner_id", user.id)
      .limit(1)
      .maybeSingle();
    return data ? toCompany(data) : null;
  } catch {
    return null;
  }
}

export interface EmployerJob {
  id: string;
  title: string;
  status: string;
  applicantsCount: number;
  postedAt: string | null;
  /** Set when an admin took the job down (0038) — owners can't clear it. */
  blockedAt: string | null;
}

/** All jobs (any status) for a company the user owns. */
export async function getMyJobs(companyId: string): Promise<EmployerJob[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const { data, error } = await supabase
      .from("jobs")
      .select("id, title, status, applicants_count, posted_at, blocked_at")
      .eq("company_id", companyId)
      .order("created_at", { ascending: false });
    if (error) throw error;
    return (data ?? []).map((row) => {
      const r = row as Record<string, unknown>;
      return {
        id: String(r.id),
        title: String(r.title ?? ""),
        status: String(r.status ?? "open"),
        applicantsCount: Number(r.applicants_count ?? 0),
        postedAt: typeof r.posted_at === "string" ? r.posted_at : null,
        blockedAt: typeof r.blocked_at === "string" ? r.blocked_at : null,
      };
    });
  } catch (e) {
    console.error("getMyJobs failed", e);
    return [];
  }
}

export interface EmployerStats {
  totalJobs: number;
  openJobs: number;
  totalApplicants: number;
}

export async function getEmployerStats(
  companyId: string,
): Promise<EmployerStats> {
  const jobs = await getMyJobs(companyId);
  return {
    totalJobs: jobs.length,
    openJobs: jobs.filter((j) => j.status === "open").length,
    totalApplicants: jobs.reduce((sum, j) => sum + j.applicantsCount, 0),
  };
}
