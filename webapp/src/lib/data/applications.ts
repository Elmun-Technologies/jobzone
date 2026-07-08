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
}

function pickOne(v: unknown): Record<string, unknown> | null {
  if (Array.isArray(v)) return (v[0] as Record<string, unknown>) ?? null;
  if (v && typeof v === "object") return v as Record<string, unknown>;
  return null;
}

/** The signed-in user's applications, newest first. */
export async function getMyApplications(): Promise<MyApplication[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return [];

    const { data, error } = await supabase
      .from("applications")
      .select(
        "id, current_status, applied_at, job:jobs(id, title, company:companies(name))",
      )
      .eq("applicant_id", user.id)
      .order("applied_at", { ascending: false });
    if (error) throw error;

    return (data ?? [])
      .map((row) => {
        const r = row as Record<string, unknown>;
        const job = pickOne(r.job);
        const company = pickOne(job?.company);
        return {
          id: String(r.id),
          status: String(r.current_status ?? "submitted"),
          appliedAt: typeof r.applied_at === "string" ? r.applied_at : null,
          jobId: job?.id ? String(job.id) : "",
          jobTitle: job?.title ? String(job.title) : "—",
          companyName: company?.name ? String(company.name) : "",
        };
      })
      // A closed/deleted job is unreadable to the applicant (jobs RLS exposes
      // only status='open' to non-owners), so its embed resolves to null. Drop
      // those rows instead of rendering a dead "—" card with a broken /jobs/
      // link — matching the mobile app, which filters applications to the jobs
      // present in job_feed.
      .filter((a) => a.jobId !== "");
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
