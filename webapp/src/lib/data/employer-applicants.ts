import "server-only";

import { createClient } from "@/lib/supabase/server";

import { hasSupabase } from "./supabase-env";

export interface Applicant {
  applicationId: string;
  applicantId: string;
  status: string;
  appliedAt: string | null;
  coverLetter: string | null;
  answers: Record<string, string>;
  name: string;
  headline: string | null;
  avatarUrl: string | null;
}

export interface CompanyCandidate {
  applicationId: string;
  applicantId: string;
  jobId: string;
  jobTitle: string;
  status: string;
  appliedAt: string | null;
  name: string;
  headline: string | null;
  avatarUrl: string | null;
}

export interface ApplicantDetail {
  applicationId: string;
  applicantId: string;
  status: string;
  appliedAt: string | null;
  coverLetter: string | null;
  answers: Record<string, string>;
  name: string;
  headline: string | null;
  avatarUrl: string | null;
  city: string | null;
  workerVerified: boolean;
}

/**
 * Recent applicants across ALL of a company's jobs (the "Nomzodlar" hub).
 * RLS on `applications` already restricts reads to the job owner; scoping the
 * query to the company's own job ids keeps it correct if an owner has more
 * than one company. Public applicant fields come from profiles_public.
 */
export async function getCompanyCandidates(
  companyId: string,
  limit = 100,
): Promise<CompanyCandidate[]> {
  if (!hasSupabase()) return [];
  try {
    const supabase = await createClient();
    const { data: jobRows, error: jobErr } = await supabase
      .from("jobs")
      .select("id, title")
      .eq("company_id", companyId);
    if (jobErr) throw jobErr;
    const titles = new Map<string, string>();
    for (const j of jobRows ?? []) {
      const r = j as Record<string, unknown>;
      titles.set(String(r.id), String(r.title ?? ""));
    }
    if (titles.size === 0) return [];

    const { data: apps, error } = await supabase
      .from("applications")
      .select("id, current_status, applied_at, applicant_id, job_id")
      .in("job_id", [...titles.keys()])
      .order("applied_at", { ascending: false })
      .limit(limit);
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
        applicantId: String(r.applicant_id),
        jobId: String(r.job_id),
        jobTitle: titles.get(String(r.job_id)) ?? "",
        status: String(r.current_status ?? "submitted"),
        appliedAt: typeof r.applied_at === "string" ? r.applied_at : null,
        name: p?.full_name ? String(p.full_name) : "—",
        headline: p?.headline ? String(p.headline) : null,
        avatarUrl: p?.avatar_url ? String(p.avatar_url) : null,
      };
    });
  } catch (e) {
    console.error("getCompanyCandidates failed", e);
    return [];
  }
}

/** A job's title + owning company (so the page can confirm ownership) plus its
 *  screening questions as an id→label map (to caption applicant answers). */
export async function getJobTitleAndCompany(jobId: string): Promise<{
  title: string;
  companyId: string;
  questionLabels: Record<string, string>;
} | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const { data } = await supabase
      .from("jobs")
      .select("title, company_id, screening_questions")
      .eq("id", jobId)
      .maybeSingle();
    if (!data) return null;
    const r = data as Record<string, unknown>;
    const questionLabels: Record<string, string> = {};
    if (Array.isArray(r.screening_questions)) {
      for (const raw of r.screening_questions) {
        if (raw && typeof raw === "object") {
          const q = raw as Record<string, unknown>;
          if (q.id && q.label) questionLabels[String(q.id)] = String(q.label);
        }
      }
    }
    return {
      title: String(r.title ?? ""),
      companyId: String(r.company_id),
      questionLabels,
    };
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
        applicantId: String(r.applicant_id),
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

/**
 * One application for a job + the applicant's column-safe public profile.
 * Scoped to `job_id` so the applications RLS (job owner only) confirms the
 * caller owns it; returns null if it isn't found / isn't the owner's. Backs the
 * per-applicant résumé page.
 */
export async function getApplicantForJob(
  jobId: string,
  applicationId: string,
): Promise<ApplicantDetail | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const { data: app } = await supabase
      .from("applications")
      .select(
        "id, current_status, applied_at, cover_letter, answers, applicant_id",
      )
      .eq("id", applicationId)
      .eq("job_id", jobId)
      .maybeSingle();
    if (!app) return null;
    const r = app as Record<string, unknown>;
    const applicantId = String(r.applicant_id);

    const { data: prof } = await supabase
      .from("profiles_public")
      .select("full_name, headline, avatar_url, city, worker_verified")
      .eq("id", applicantId)
      .maybeSingle();
    const p = (prof ?? {}) as Record<string, unknown>;

    return {
      applicationId: String(r.id),
      applicantId,
      status: String(r.current_status ?? "submitted"),
      appliedAt: typeof r.applied_at === "string" ? r.applied_at : null,
      coverLetter: typeof r.cover_letter === "string" ? r.cover_letter : null,
      answers:
        r.answers && typeof r.answers === "object"
          ? (r.answers as Record<string, string>)
          : {},
      name: p.full_name ? String(p.full_name) : "—",
      headline: p.headline ? String(p.headline) : null,
      avatarUrl: p.avatar_url ? String(p.avatar_url) : null,
      city: p.city ? String(p.city) : null,
      workerVerified: p.worker_verified === true,
    };
  } catch (e) {
    console.error("getApplicantForJob failed", e);
    return null;
  }
}
