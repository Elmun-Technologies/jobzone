import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface MyApplication {
  id: string;
  status: string;
  appliedAt: string | null;
  jobId: string;
  jobTitle: string;
  companyName: string;
  /** "open" | "closed" | "draft" | "" (unknown — job row itself is gone). */
  jobStatus: string;
}

/** The signed-in user's applications, newest first. A closed job still shows
 *  (e.g. the applicant was hired for the now-filled position) via the
 *  `my_applied_jobs` definer view (0048), scoped to the caller's own
 *  applications — not general `jobs` read access. */
export async function getMyApplications(): Promise<MyApplication[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return [];

    const { data: apps, error } = await supabase
      .from("applications")
      .select("id, current_status, applied_at, job_id")
      .eq("applicant_id", user.id)
      .order("applied_at", { ascending: false });
    if (error) throw error;

    const rows = (apps ?? []).map((a) => a as Record<string, unknown>);
    const jobIds = [...new Set(rows.map((r) => String(r.job_id)))];

    const jobs = new Map<string, Record<string, unknown>>();
    if (jobIds.length) {
      const { data: jobRows } = await supabase
        .from("my_applied_jobs")
        .select("id, title, status, company_name")
        .in("id", jobIds);
      for (const j of jobRows ?? []) {
        const jr = j as Record<string, unknown>;
        jobs.set(String(jr.id), jr);
      }
    }

    return rows.map((r) => {
      const jobId = String(r.job_id);
      const job = jobs.get(jobId);
      return {
        id: String(r.id),
        status: String(r.current_status ?? "submitted"),
        appliedAt: typeof r.applied_at === "string" ? r.applied_at : null,
        jobId,
        jobTitle: job?.title ? String(job.title) : "—",
        companyName: job?.company_name ? String(job.company_name) : "",
        jobStatus: job?.status ? String(job.status) : "",
      };
    });
  } catch (e) {
    console.error("getMyApplications failed", e);
    return [];
  }
}

/** Whether the signed-in user already applied to a job. */
export async function hasApplied(jobId: string): Promise<boolean> {
  if (!hasSupabase()) return false;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return false;
    const { data } = await supabase
      .from("applications")
      .select("id")
      .eq("applicant_id", user.id)
      .eq("job_id", jobId)
      .maybeSingle();
    return !!data;
  } catch {
    return false;
  }
}
