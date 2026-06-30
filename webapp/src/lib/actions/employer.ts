"use server";

import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

export interface CompanyFormState {
  error?: string;
}
export interface JobFormState {
  error?: string;
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

/** Creates the employer's company (owner_id = uid) and lands on the dashboard. */
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

  redirect(`/${locale}/employer`);
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

/** Posts a new open job for the employer's company. */
export async function createJob(
  _prev: JobFormState,
  formData: FormData,
): Promise<JobFormState> {
  const locale = field(formData, "locale") || "uz";
  const companyId = field(formData, "companyId");
  const title = field(formData, "title");
  if (!companyId || !title) return { error: "missing" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const number = (name: string) => {
    const v = field(formData, name);
    return v ? Number(v) : null;
  };
  const bool = (name: string) => field(formData, name) === "1";
  const status = field(formData, "status") === "draft" ? "draft" : "open";

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
    status,
  });
  if (error) return { error: "unknown" };

  redirect(`/${locale}/employer/jobs`);
}
