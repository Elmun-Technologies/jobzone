"use server";

import { revalidatePath, revalidateTag } from "next/cache";
import { headers } from "next/headers";
import { redirect } from "next/navigation";

import { safeNext } from "@/lib/auth/safe-next";
import { getEmployerStats } from "@/lib/data/employer";
import {
  clickCheckoutUrl,
  paymeCheckoutUrl,
} from "@/lib/payments/checkout-url";
import { createClient } from "@/lib/supabase/server";

export interface CompanyFormState {
  error?: string;
}
export interface JobFormState {
  error?: string;
  /** Raw DB/RPC failure detail, surfaced so a stuck employer can report the
   * exact cause (e.g. a missing migration column) instead of a blank "error". */
  detail?: string;
  signedOut?: boolean;
  noCompany?: boolean;
  insufficientFunds?: boolean;
  requiredUzs?: number;
}

export interface PayListingState {
  error?: "unconfigured" | "unknown" | "signedOut" | "notDraft";
}

/** A short, safe one-liner from a Supabase error for surfacing to the employer
 * (their own action) so a stuck publish can be diagnosed from a screenshot. */
function dbDetail(error: { message?: string; code?: string } | null): string {
  if (!error) return "";
  const code = error.code ? `[${error.code}] ` : "";
  return `${code}${error.message ?? ""}`.slice(0, 300);
}

/** Columns the insert can never drop (a job is meaningless without them). */
const REQUIRED_JOB_COLUMNS = new Set([
  "company_id",
  "posted_by",
  "title",
  "status",
]);

/**
 * Insert a job, tolerating a DB that's behind on migrations. If PostgREST
 * reports an unknown column (PGRST204 "Could not find the 'X' column of 'jobs'
 * in the schema cache"), drop that optional column and retry — so a stale
 * schema cache or an unapplied migration degrades to "posted without field X"
 * (logged) instead of a hard failure. Bounded retries; core columns are never
 * dropped.
 */
async function insertJobResilient(
  supabase: Awaited<ReturnType<typeof createClient>>,
  payload: Record<string, unknown>,
): Promise<{
  id: string | null;
  error: { message?: string; code?: string } | null;
  dropped: string[];
}> {
  const attempt: Record<string, unknown> = { ...payload };
  const dropped: string[] = [];
  for (let i = 0; i < 12; i++) {
    const { data, error } = await supabase
      .from("jobs")
      .insert(attempt)
      .select("id")
      .single();
    if (!error && data) {
      return { id: String((data as { id: unknown }).id), error: null, dropped };
    }
    const col = error?.message?.match(
      /Could not find the '([^']+)' column/,
    )?.[1];
    if (col && col in attempt && !REQUIRED_JOB_COLUMNS.has(col)) {
      delete attempt[col];
      dropped.push(col);
      continue;
    }
    return { id: null, error: error ?? null, dropped };
  }
  return { id: null, error: { message: "too many unknown columns" }, dropped };
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
  if (error) {
    console.error("createCompany failed", error);
    return { error: "unknown" };
  }

  // Owning a company is what makes this account an employer — flip the role
  // regardless of how they signed up (defaulted to job_seeker, or via Google,
  // which carries no role at all), so requireEmployer() doesn't strand them.
  await supabase
    .from("profiles")
    .update({ role: "employer" })
    .eq("id", user.id);

  redirect(safeNext(field(formData, "next"), `/${locale}/employer`));
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
  if (error) {
    console.error("updateCompany failed", error);
    return { error: "unknown" };
  }

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

  // Attribution guard: a job may only be posted under a company the caller
  // owns. RLS's INSERT check also enforces this, but verifying here gives a
  // clean error instead of a policy violation, and blocks brand-spoofing at
  // the action layer (posting under someone else's verified company).
  const { data: ownedCompany } = await supabase
    .from("companies")
    .select("id")
    .eq("id", companyId)
    .eq("owner_id", user.id)
    .maybeSingle();
  if (!ownedCompany) return { noCompany: true };

  const locale = field(formData, "locale") || "uz";
  const number = (name: string) => {
    const v = field(formData, name);
    return v ? Number(v) : null;
  };
  // Salary fields are typed with thousands separators ("5 000 000"); strip
  // any non-digit before parsing so the number survives.
  const money = (name: string) => {
    const v = field(formData, name).replace(/\D/g, "");
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

  // Direct pay-per-listing: the employer's first published vacancy is free and
  // goes live immediately; the 2nd+ is created as a DRAFT and paid per listing
  // (a tier + Payme/Click) on the next step, which publishes it. Drafts never
  // reach the market, so they neither cost nor count toward "first". Decide
  // BEFORE inserting so the new row doesn't skew the "has published before" count.
  let charged = false;
  if (status === "open") {
    const stats = await getEmployerStats(companyId);
    charged = stats.hasPublishedBefore;
  }
  const effectiveStatus = charged ? "draft" : status;

  const payload: Record<string, unknown> = {
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
    salary_min: money("salaryMin"),
    salary_max: money("salaryMax"),
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
    status: effectiveStatus,
  };

  const {
    id: insertedId,
    error,
    dropped,
  } = await insertJobResilient(supabase, payload);
  if (error || !insertedId) {
    console.error("createJob insert failed", error);
    return { error: "unknown", detail: dbDetail(error) };
  }
  if (dropped.length) {
    // The DB is behind on migrations (or PostgREST's schema cache is stale):
    // the job posted, minus these optional columns. Fix on the DB side with
    // `supabase db push` + `NOTIFY pgrst, 'reload schema';`.
    console.warn(
      `createJob: posted without unknown columns [${dropped.join(", ")}] — the jobs table / PostgREST schema cache is behind the app`,
    );
  }
  const inserted = { id: insertedId };

  // A charged (2nd+) post is a draft awaiting payment → send the employer to
  // pick a tier and pay; paying publishes it. A free first post is already live.
  if (charged) {
    redirect(`/${locale}/employer/jobs/${inserted.id}/pay`);
  }
  // A free first post is live immediately → refresh the cached category counts /
  // city facet so it shows up in those aggregates without waiting for the window.
  if (status === "open") revalidateTag("jobs", "max");
  // ?posted signals the "My jobs" page to confirm the post (draft vs open).
  redirect(`/${locale}/employer/jobs?posted=${status}`);
}

/**
 * Direct pay-per-listing: create the tier order for a draft vacancy and send the
 * employer to the Payme/Click checkout. The tier PRICE is resolved server-side
 * by `create_listing_order` (a tampered client amount can never under-pay); the
 * gateway's callback flips the order to paid, which publishes the vacancy with
 * its tier. Merchant ids are public (only the webhook secret keys are private);
 * with none set the checkout can't be built and we report `unconfigured`.
 */
export async function payListing(
  _prev: PayListingState,
  formData: FormData,
): Promise<PayListingState> {
  const locale = field(formData, "locale") || "uz";
  const jobId = field(formData, "jobId");
  const tierRaw = field(formData, "tier");
  const provider = field(formData, "provider");
  if (!jobId) return { error: "unknown" };
  const tier = ["standard", "brand", "premium"].includes(tierRaw)
    ? tierRaw
    : "standard";

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: "signedOut" };

  const { data, error } = await supabase.rpc("create_listing_order", {
    p_job_id: jobId,
    p_tier_code: `tier_${tier}`,
  });
  const row = Array.isArray(data)
    ? (data[0] as OrderRow | undefined)
    : undefined;
  if (error || !row) {
    return {
      error: error?.message.includes("not_draft") ? "notDraft" : "unknown",
    };
  }

  const h = await headers();
  const origin = `${h.get("x-forwarded-proto") ?? "https"}://${h.get("host") ?? ""}`;
  const returnUrl = `${origin}/${locale}/employer/jobs/${jobId}/paid`;
  const amountUzs = Number(row.amount_uzs);

  let url: string | null = null;
  if (provider === "click") {
    const serviceId = process.env.NEXT_PUBLIC_CLICK_SERVICE_ID;
    const merchantId = process.env.NEXT_PUBLIC_CLICK_MERCHANT_ID;
    if (serviceId && merchantId) {
      url = clickCheckoutUrl({
        serviceId,
        merchantId,
        orderId: row.order_id,
        amountUzs,
        returnUrl,
      });
    }
  } else if (provider === "rahmat") {
    // Rahmat is Multicard's hosted-checkout rail — unlike Payme/Click the URL
    // isn't static; the `rahmat-invoice` edge fn authenticates to Multicard
    // and asks for a fresh checkout URL for our order. The user JWT is
    // forwarded automatically by `functions.invoke`; server-side price and
    // ownership are re-checked inside the function.
    if (process.env.NEXT_PUBLIC_RAHMAT_ENABLED === "1") {
      const { data: inv, error: invErr } = await supabase.functions.invoke<{
        ok: boolean;
        checkout_url?: string;
        error?: string;
      }>("rahmat-invoice", {
        body: { order_id: row.order_id, return_url: returnUrl },
      });
      if (invErr || !inv?.ok || !inv?.checkout_url) {
        return { error: "unconfigured" };
      }
      url = inv.checkout_url;
    }
  } else {
    const merchantId = process.env.NEXT_PUBLIC_PAYME_MERCHANT_ID;
    if (merchantId) {
      url = paymeCheckoutUrl({
        merchantId,
        orderId: row.order_id,
        amountUzs,
        returnUrl,
      });
    }
  }
  if (!url) return { error: "unconfigured" };
  redirect(url);
}

interface OrderRow {
  order_id: string;
  amount_uzs: number;
}

/**
 * Vacancy lifecycle from the "My jobs" list: publish a draft, close an open
 * job, or reopen a closed one. Ownership is verified here (RLS also enforces
 * it). Publishing a draft runs the SAME charge gate as a fresh open post — so
 * "save draft then publish" can't bypass the first-free / then-paid rule.
 */
export async function updateJobStatus(formData: FormData): Promise<void> {
  const locale = field(formData, "locale") || "uz";
  const jobId = field(formData, "jobId");
  const action = field(formData, "action"); // publish | close | reopen
  const jobsPath = `/${locale}/employer/jobs`;
  if (!jobId) redirect(jobsPath);

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect(`/${locale}/sign-in`);

  const { data: job } = await supabase
    .from("jobs")
    .select("status, company_id, title")
    .eq("id", jobId)
    .maybeSingle();
  if (!job) redirect(jobsPath);
  const j = job as { status: string; company_id: string; title: string };

  const { data: owned } = await supabase
    .from("companies")
    .select("id")
    .eq("id", j.company_id)
    .eq("owner_id", user.id)
    .maybeSingle();
  if (!owned) redirect(jobsPath);

  let newStatus: string | null = null;
  if (action === "close" && j.status === "open") newStatus = "closed";
  else if (action === "reopen" && j.status === "closed") newStatus = "open";
  else if (action === "publish" && j.status === "draft") {
    // A draft becoming live is a new market entry. The first is free; a 2nd+
    // draft is paid per listing → send the employer to pick a tier + pay, which
    // publishes it. Only a first-time poster publishes straight to open here.
    const stats = await getEmployerStats(j.company_id);
    if (stats.hasPublishedBefore) {
      redirect(`/${locale}/employer/jobs/${jobId}/pay`);
    }
    newStatus = "open";
  }

  if (!newStatus) redirect(jobsPath);
  await supabase.from("jobs").update({ status: newStatus }).eq("id", jobId);
  revalidatePath(jobsPath);
  // The open-job set changed → refresh the cached category counts / city facet
  // so a just-published (or closed) vacancy is reflected without the 5-min lag.
  revalidateTag("jobs", "max");
  redirect(jobsPath);
}

/** The editable content columns of a job, parsed from the wizard's FormData
 * (everything except company_id / posted_by / status, which edit never sets). */
function jobContentFields(formData: FormData): Record<string, unknown> {
  const number = (name: string) => {
    const v = field(formData, name);
    return v ? Number(v) : null;
  };
  const money = (name: string) => {
    const v = field(formData, name).replace(/\D/g, "");
    return v ? Number(v) : null;
  };
  const bool = (name: string) => field(formData, name) === "1";
  let screening: unknown = [];
  try {
    screening = JSON.parse(field(formData, "screeningQuestions") || "[]");
  } catch {
    screening = [];
  }
  return {
    title: field(formData, "title"),
    description: optional(formData, "description"),
    responsibilities: optional(formData, "responsibilities"),
    requirements: optional(formData, "requirements"),
    benefits: optional(formData, "benefits"),
    category_id: optional(formData, "categoryId"),
    city: optional(formData, "city"),
    address_text: optional(formData, "addressText"),
    lat: number("lat"),
    lng: number("lng"),
    salary_min: money("salaryMin"),
    salary_max: money("salaryMax"),
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
  };
}

/** UPDATE variant of insertJobResilient — drops unknown columns and retries. */
async function updateJobResilient(
  supabase: Awaited<ReturnType<typeof createClient>>,
  jobId: string,
  payload: Record<string, unknown>,
): Promise<{
  error: { message?: string; code?: string } | null;
  dropped: string[];
}> {
  const attempt: Record<string, unknown> = { ...payload };
  const dropped: string[] = [];
  for (let i = 0; i < 12; i++) {
    const { error } = await supabase
      .from("jobs")
      .update(attempt)
      .eq("id", jobId);
    if (!error) return { error: null, dropped };
    const col = error?.message?.match(
      /Could not find the '([^']+)' column/,
    )?.[1];
    if (col && col in attempt) {
      delete attempt[col];
      dropped.push(col);
      continue;
    }
    return { error, dropped };
  }
  return { error: { message: "too many unknown columns" }, dropped };
}

/**
 * Edits an existing vacancy (content only — status and attribution are
 * unchanged). Free; ownership-checked (RLS also confines the write). Reuses
 * the same wizard FormData as createJob.
 */
export async function updateJob(
  _prev: JobFormState,
  formData: FormData,
): Promise<JobFormState> {
  const title = field(formData, "title");
  const jobId = field(formData, "jobId");
  if (!title || !jobId) return { error: "missing" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signedOut: true };

  const locale = field(formData, "locale") || "uz";

  const { data: job } = await supabase
    .from("jobs")
    .select("company_id")
    .eq("id", jobId)
    .maybeSingle();
  if (!job) return { error: "unknown" };
  const { data: owned } = await supabase
    .from("companies")
    .select("id")
    .eq("id", (job as { company_id: string }).company_id)
    .eq("owner_id", user.id)
    .maybeSingle();
  if (!owned) return { error: "unknown" };

  const { error, dropped } = await updateJobResilient(
    supabase,
    jobId,
    jobContentFields(formData),
  );
  if (error) {
    console.error("updateJob failed", error);
    return { error: "unknown", detail: dbDetail(error) };
  }
  if (dropped.length) {
    console.warn(
      `updateJob: saved without unknown columns [${dropped.join(", ")}] — the jobs table / PostgREST schema cache is behind the app`,
    );
  }

  redirect(`/${locale}/employer/jobs?updated=1`);
}

/**
 * Buys a visibility boost (reklama) for one of the employer's live vacancies,
 * spending the Hamyon balance. All the real work — ownership + live-status
 * check, balance guard, debit, boost, order record — happens atomically in the
 * buy_promotion() RPC; this action just relays the outcome. Not-enough-balance
 * surfaces as `insufficientFunds` so the page can point them at top-up.
 */
export async function promoteJob(
  _prev: JobFormState,
  formData: FormData,
): Promise<JobFormState> {
  const locale = field(formData, "locale") || "uz";
  const jobId = field(formData, "jobId");
  const productCode = field(formData, "productCode");
  if (!jobId || !productCode) return { error: "missing" };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { signedOut: true };

  const { error } = await supabase.rpc("buy_promotion", {
    p_job_id: jobId,
    p_product_code: productCode,
  });
  if (error) {
    if (error.message.includes("insufficient_funds")) {
      return { insufficientFunds: true };
    }
    console.error("promoteJob failed", error);
    return { error: "unknown", detail: dbDetail(error) };
  }

  redirect(`/${locale}/employer/jobs?promoted=1`);
}
