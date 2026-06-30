import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface Applicant {
  applicationId: string;
  status: string;
  appliedAt: string | null;
  coverLetter: string | null;
  answers: Record<string, string>;
  name: string;
  headline: string | null;
  avatarUrl: string | null;
}

/** A job's title + owning company (so the page can confirm ownership), or null. */
export async function getJobTitleAndCompany(
  jobId: string,
): Promise<{ title: string; companyId: string } | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const { data } = await supabase
      .from("jobs")
      .select("title, company_id")
      .eq("id", jobId)
      .maybeSingle();
    if (!data) return null;
    const r = data as Record<string, unknown>;
    return { title: String(r.title ?? ""), companyId: String(r.company_id) };
  } catch {
    return null;
  }
}

/** Applicants for a job. RLS restricts to the job owner; applicant public
 *  profiles come from the column-safe profiles_public view. */
export async function getJobApplicants(jobId: string): Promise<Applicant[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const { data: apps, error } = await supabase
      .from("applications")
      .select(
        "id, current_status, applied_at, cover_letter, answers, applicant_id",
      )
      .eq("job_id", jobId)
      .order("applied_at", { ascending: false });
    if (error) throw error;

    const rows = (apps ?? []).map((a) => a as Record<string, unknown>);
    const ids = [...new Set(rows.map((r) => String(r.applicant_id)))];

    const profiles = new Map<string, Record<string, unknown>>();
    if (ids.length) {
      const { data: profs } = await supabase
        .from("profiles_public")
        .select("id, full_name, headline, avatar_url")
        .in("id", ids);
      for (const p of profs ?? []) {
        const pr = p as Record<string, unknown>;
        profiles.set(String(pr.id), pr);
      }
    }

    return rows.map((r) => {
      const p = profiles.get(String(r.applicant_id));
      return {
        applicationId: String(r.id),
        status: String(r.current_status ?? "submitted"),
        appliedAt: typeof r.applied_at === "string" ? r.applied_at : null,
        coverLetter: typeof r.cover_letter === "string" ? r.cover_letter : null,
        answers:
          r.answers && typeof r.answers === "object"
            ? (r.answers as Record<string, string>)
            : {},
        name: p?.full_name ? String(p.full_name) : "—",
        headline: p?.headline ? String(p.headline) : null,
        avatarUrl: p?.avatar_url ? String(p.avatar_url) : null,
      };
    });
  } catch (e) {
    console.error("getJobApplicants failed", e);
    return [];
  }
}
