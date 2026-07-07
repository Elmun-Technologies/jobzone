"use server";

import { redirect } from "next/navigation";

import { getEmployerStats } from "@/lib/data/employer";
import { getJobPostPrice } from "@/lib/data/pricing";
import { willChargeForJobPost } from "@/lib/job-post-pricing";
import { createClient } from "@/lib/supabase/server";

export interface CompanyFormState {
  error?: string;
}
export interface JobFormState {
  error?: string;
  signedOut?: boolean;
  noCompany?: boolean;
  insufficientFunds?: boolean;
  requiredUzs?: number;
}

function field(formData: FormData, name: string): string {
  return (formData.get(name) ?? "").toString().trim();
}
function optional(formData: FormData, name: string): string | null {
  return field(formData, name) || null;
}
function slugify(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40);
}

/**
 * Creates the employer's company (owner_id = uid). Lands on `next` when given
 * (e.g. back on a post-vacancy draft that was waiting on a company to exist)
 * or the dashboard otherwise.
 */
export async function createCompany(
  _prev: CompanyFormState,
  formData: FormData,
): Promise<CompanyFormState> {
  const locale = field(formData, "locale") || "uz";
  const name = field(formData, "name");
  if (!name) return { error: "missing" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const { error } = await supabase.from("companies").insert({
    owner_id: user.id,
    name,
    slug: `${slugify(name) || "company"}-${user.id.slice(0, 6)}`,
    about: optional(formData, "about"),
    industry: optional(formData, "industry"),
    website: optional(formData, "website"),
    headquarters: optional(formData, "headquarters"),
  });
  if (error) return { error: "unknown" };

  // Owning a company is what makes this account an employer — flip the role
  // regardless of how they signed up (defaulted to job_seeker, or via Google,
  // which carries no role at all), so requireEmployer() doesn't strand them.
  await supabase
    .from("profiles")
    .update({ role: "employer" })
    .eq("id", user.id);

  const next = field(formData, "next");
  redirect(next || `/${locale}/employer`);
}

/** Updates the employer's company (RLS confines the write to the owner). */
export async function updateCompany(
  _prev: CompanyFormState,
  formData: FormData,
): Promise<CompanyFormState> {
  const locale = field(formData, "locale") || "uz";
  const companyId = field(formData, "companyId");
  const name = field(formData, "name");
  if (!companyId || !name) return { error: "missing" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const { error } = await supabase
    .from("companies")
    .update({
      name,
      about: optional(formData, "about"),
      industry: optional(formData, "industry"),
      website: optional(formData, "website"),
      headquarters: optional(formData, "headquarters"),
    })
    .eq("id", companyId)
    .eq("owner_id", user.id);
  if (error) return { error: "unknown" };

  redirect(`/${locale}/employer`);
}

/**
 * Posts a new open job for the employer's company. Guest-first: a visitor can
 * fill out and submit this without an account or a company yet — this
 * reports what's missing (`signedOut` / `noCompany`) instead of redirecting,
 * so the caller can send them to get it and come back with the draft intact.
 */
export async function createJob(
  _prev: JobFormState,
  formData: FormData,
): Promise<JobFormState> {
  const title = field(formData, "title");
  if (!title) return { error: "missing" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signedOut: true };

  const companyId = field(formData, "companyId");
  if (!companyId) return { noCompany: true };

  const locale = field(formData, "locale") || "uz";
  const number = (name: string) => {
    const v = field(formData, name);
    return v ? Number(v) : null;
  };
  const bool = (name: string) => field(formData, name) === "1";
  const status = field(formData, "status") === "draft" ? "draft" : "open";

  let screening: unknown = [];
  try {
    screening = JSON.parse(field(formData, "screeningQuestions") || "[]");
  } catch {
    screening = [];
  }

  // The employer's first published vacancy is free; every one after that is
  // charged from Hamyon before it goes live. Drafts are always free — they
  // never reach the market, so they neither cost nor count toward "first".
  let charged = false;
  let price = 0;
  if (status === "open") {
    const stats = await getEmployerStats(companyId);
    price = await getJobPostPrice();
    if (willChargeForJobPost(stats.hasPublishedBefore, price)) {
      const { error: payError } = await supabase.rpc("adjust_wallet", {
        p_company_id: companyId,
        p_amount_uzs: -price,
        p_kind: "spend",
        p_description: `Vakansiya: ${title}`,
      });
      if (payError) {
        if (payError.message.includes("insufficient_funds")) {
          return { insufficientFunds: true, requiredUzs: price };
        }
        return { error: "unknown" };
      }
      charged = true;
    }
  }

  const { error } = await supabase.from("jobs").insert({
    company_id: companyId,
    posted_by: user.id,
    title,
    description: optional(formData, "description"),
    responsibilities: optional(formData, "responsibilities"),
    requirements: optional(formData, "requirements"),
    benefits: optional(formData, "benefits"),
    category_id: optional(formData, "categoryId"),
    city: optional(formData, "city"),
    address_text: optional(formData, "addressText"),
    lat: number("lat"),
    lng: number("lng"),
    country: "UZ",
    salary_min: number("salaryMin"),
    salary_max: number("salaryMax"),
    currency: optional(formData, "currency") ?? "UZS",
    salary_period: optional(formData, "salaryPeriod") ?? "month",
    job_type: optional(formData, "jobType"),
    experience_level: optional(formData, "experienceLevel"),
    working_model: optional(formData, "workingModel"),
    schedule_pattern: optional(formData, "schedulePattern"),
    night_shift: bool("nightShift"),
    contact_phone: optional(formData, "contactPhone"),
    show_phone_on_listing: bool("showPhone"),
    require_cover_letter: bool("requireCoverLetter"),
    women_friendly: bool("womenFriendly"),
    disability_friendly: bool("disabilityFriendly"),
    screening_questions: Array.isArray(screening) ? screening : [],
    status,
  });
  if (error) {
    if (charged) {
      await supabase.rpc("adjust_wallet", {
        p_company_id: companyId,
        p_amount_uzs: price,
        p_kind: "refund",
        p_description: `Qaytarish: ${title}`,
      });
    }
    return { error: "unknown" };
  }

  redirect(`/${locale}/employer/jobs`);
}
