// Shared contract: how a Postgres `jobs` row maps to a Meilisearch document,
// plus the index settings. Used by meili-sync and meili-reindex.

export const JOBS_INDEX = "jobs";

export interface JobRow {
  id: string;
  title: string;
  description?: string | null;
  company_id: string;
  category_id?: string | null;
  job_type?: string | null;
  experience_level?: string | null;
  working_model?: string | null;
  schedule_pattern?: string | null;
  hours_per_day?: number | null;
  night_shift?: boolean | null;
  formalization?: string | null;
  women_friendly?: boolean | null;
  driver_licenses?: string[] | null;
  languages?: unknown;
  salary_gross?: boolean | null;
  country?: string | null;
  city?: string | null;
  location?: string | null;
  address_text?: string | null;
  lat?: number | null;
  lng?: number | null;
  salary_min?: number | null;
  salary_max?: number | null;
  currency?: string | null;
  skills_required?: string[] | null;
  applicants_count?: number | null;
  posted_at?: string | null;
  expires_at?: string | null;
  status?: string | null;
}

export interface CompanyFields {
  name?: string | null;
  logo_url?: string | null;
  is_verified?: boolean | null;
}

const toEpoch = (v?: string | null) =>
  v ? Math.floor(new Date(v).getTime() / 1000) : null;

export function toJobDocument(
  job: JobRow,
  company?: CompanyFields,
  categoryName?: string | null,
) {
  const doc: Record<string, unknown> = {
    id: job.id,
    title: job.title,
    description: job.description ?? "",
    company_id: job.company_id,
    company_name: company?.name ?? "",
    company_logo_url: company?.logo_url ?? null,
    company_is_verified: company?.is_verified ?? false,
    category_id: job.category_id ?? null,
    category_name: categoryName ?? "",
    job_type: job.job_type ?? null,
    experience_level: job.experience_level ?? null,
    working_model: job.working_model ?? null,
    schedule_pattern: job.schedule_pattern ?? null,
    hours_per_day: job.hours_per_day ?? null,
    night_shift: job.night_shift ?? false,
    formalization: job.formalization ?? null,
    women_friendly: job.women_friendly ?? false,
    driver_licenses: job.driver_licenses ?? [],
    languages: job.languages ?? [],
    salary_gross: job.salary_gross ?? true,
    country: job.country ?? null,
    city: job.city ?? null,
    location: job.location ?? null,
    address_text: job.address_text ?? null,
    salary_min: job.salary_min ?? null,
    salary_max: job.salary_max ?? null,
    currency: job.currency ?? null,
    skills_required: job.skills_required ?? [],
    applicants_count: job.applicants_count ?? 0,
    posted_at: toEpoch(job.posted_at),
    expires_at: toEpoch(job.expires_at),
    status: job.status ?? "open",
  };
  if (job.lat != null && job.lng != null) {
    doc._geo = { lat: job.lat, lng: job.lng };
  }
  return doc;
}

export const JOBS_SETTINGS = {
  searchableAttributes: [
    "title",
    "company_name",
    "skills_required",
    "category_name",
    "description",
  ],
  filterableAttributes: [
    "job_type",
    "experience_level",
    "working_model",
    "schedule_pattern",
    "night_shift",
    "formalization",
    "women_friendly",
    "driver_licenses",
    "category_id",
    "company_id",
    "country",
    "city",
    "salary_min",
    "salary_max",
    "currency",
    "company_is_verified",
    "status",
    "_geo",
  ],
  sortableAttributes: [
    "posted_at",
    "salary_max",
    "salary_min",
    "applicants_count",
    "_geo",
  ],
  rankingRules: [
    "words",
    "typo",
    "proximity",
    "attribute",
    "sort",
    "exactness",
    "posted_at:desc",
  ],
};
