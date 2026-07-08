import "server-only";

import type { JobDraft } from "@/components/employer/post-job-form";
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
    // select("*") (not an explicit column list) so a DB that's behind on
    // migrations — e.g. missing blocked_at (0038) — doesn't make the whole
    // read fail with PGRST204 and hide the employer's real jobs. Fields are
    // read defensively below, so an absent column is simply null.
    const { data, error } = await supabase
      .from("jobs")
      .select("*")
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

/**
 * A job's current values as the post-a-job wizard's draft shape, for editing.
 * Reads the raw row (RLS lets the owner see their own job at any status) and
 * confirms company ownership; returns null if not found / not owned.
 */
export async function getEmployerJobDraft(
  jobId: string,
): Promise<JobDraft | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return null;
    const { data } = await supabase
      .from("jobs")
      .select("*")
      .eq("id", jobId)
      .maybeSingle();
    if (!data) return null;
    const r = data as Record<string, unknown>;

    const owns = await supabase
      .from("companies")
      .select("id")
      .eq("id", String(r.company_id))
      .eq("owner_id", user.id)
      .maybeSingle();
    if (!owns.data) return null;

    const str = (v: unknown) => (v == null ? "" : String(v));
    const numStr = (v: unknown) =>
      typeof v === "number" ? String(v) : v ? String(v) : "";
    return {
      title: str(r.title),
      aiNotes: "",
      description: str(r.description),
      requirements: str(r.requirements),
      responsibilities: str(r.responsibilities),
      benefits: str(r.benefits),
      categoryId: str(r.category_id),
      salaryMin: numStr(r.salary_min),
      salaryMax: numStr(r.salary_max),
      currency: str(r.currency) || "UZS",
      salaryPeriod: str(r.salary_period) || "month",
      city: str(r.city),
      addressText: str(r.address_text),
      lat: typeof r.lat === "number" ? r.lat : null,
      lng: typeof r.lng === "number" ? r.lng : null,
      jobType: str(r.job_type),
      workingModel: str(r.working_model),
      experienceLevel: str(r.experience_level),
      schedulePattern: str(r.schedule_pattern),
      nightShift: r.night_shift === true,
      contactPhone: str(r.contact_phone),
      showPhone: r.show_phone_on_listing === true,
      requireCoverLetter: r.require_cover_letter === true,
      womenFriendly: r.women_friendly === true,
      disabilityFriendly: r.disability_friendly === true,
      screeningQuestions: Array.isArray(r.screening_questions)
        ? (r.screening_questions as JobDraft["screeningQuestions"])
        : [],
    };
  } catch (e) {
    console.error("getEmployerJobDraft failed", e);
    return null;
  }
}

export interface EmployerJobBoost {
  id: string;
  title: string;
  status: string;
  /** Boost end (0011). Non-null + future = a promotion is live. */
  boostedUntil: string | null;
  boostKind: string | null;
  /** boostedUntil is in the future — a promotion is live right now. Computed
   * here (server-only) rather than in the page, so the render stays pure. */
  boostActive: boolean;
}

/**
 * A job's title + current boost state, for the promote (reklama) page. Reads
 * the raw row (owner sees any status via RLS) and confirms company ownership;
 * returns null if not found / not owned. select("*") so a DB behind on the
 * boost migration (0011) doesn't fail the whole read.
 */
export async function getEmployerJobBoost(
  jobId: string,
): Promise<EmployerJobBoost | null> {
  if (!hasSupabase()) return null;
  try {
    const supabase = await createClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) return null;
    const { data } = await supabase
      .from("jobs")
      .select("*")
      .eq("id", jobId)
      .maybeSingle();
    if (!data) return null;
    const r = data as Record<string, unknown>;

    const owns = await supabase
      .from("companies")
      .select("id")
      .eq("id", String(r.company_id))
      .eq("owner_id", user.id)
      .maybeSingle();
    if (!owns.data) return null;

    const boostedUntil =
      typeof r.boosted_until === "string" ? r.boosted_until : null;
    return {
      id: String(r.id),
      title: String(r.title ?? ""),
      status: String(r.status ?? "open"),
      boostedUntil,
      boostKind: typeof r.boost_kind === "string" ? r.boost_kind : null,
      boostActive:
        boostedUntil != null && new Date(boostedUntil).getTime() > Date.now(),
    };
  } catch (e) {
    console.error("getEmployerJobBoost failed", e);
    return null;
  }
}

export interface EmployerStats {
  totalJobs: number;
  openJobs: number;
  totalApplicants: number;
  /** Has this company ever published a vacancy (any non-draft status)? Used
   * to gate the first-vacancy-free pricing rule — a draft never counts. */
  hasPublishedBefore: boolean;
}

export async function getEmployerStats(
  companyId: string,
): Promise<EmployerStats> {
  const jobs = await getMyJobs(companyId);
  return {
    totalJobs: jobs.length,
    openJobs: jobs.filter((j) => j.status === "open").length,
    totalApplicants: jobs.reduce((sum, j) => sum + j.applicantsCount, 0),
    hasPublishedBefore: jobs.some((j) => j.status !== "draft"),
  };
}
