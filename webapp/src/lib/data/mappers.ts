import type { Company, CompanyReview, Job, JobCategory } from "./types";

type Row = Record<string, unknown>;

const str = (v: unknown): string | null =>
  typeof v === "string" && v.length > 0 ? v : null;
const num = (v: unknown): number | null =>
  typeof v === "number" ? v : v == null ? null : Number(v) || null;
const bool = (v: unknown): boolean => v === true;

/** Maps a `job_feed` row to a [Job]. */
export function toJob(r: Row): Job {
  return {
    id: String(r.id),
    title: String(r.title ?? ""),
    description: str(r.description),
    responsibilities: str(r.responsibilities),
    requirements: str(r.requirements),
    benefits: str(r.benefits),
    companyId: String(r.company_id ?? ""),
    companyName: String(r.company_name ?? ""),
    companyLogoUrl: str(r.company_logo_url),
    companyVerified: bool(r.company_is_verified),
    categoryName: str(r.category_name),
    jobType: str(r.job_type),
    experienceLevel: str(r.experience_level),
    workingModel: str(r.working_model),
    city: str(r.city),
    country: str(r.country),
    location: str(r.location),
    salaryMin: num(r.salary_min),
    salaryMax: num(r.salary_max),
    currency: String(r.currency ?? "UZS"),
    salaryPeriod: String(r.salary_period ?? "month"),
    skills: Array.isArray(r.skills_required)
      ? (r.skills_required as unknown[]).map(String)
      : [],
    postedAt: str(r.posted_at),
    expiresAt: str(r.expires_at),
    boostActive: bool(r.boost_active),
  };
}

/** Maps a `companies` row to a [Company]. */
export function toCompany(r: Row): Company {
  return {
    id: String(r.id),
    name: String(r.name ?? ""),
    logoUrl: str(r.logo_url),
    coverUrl: str(r.cover_url),
    about: str(r.about),
    industry: str(r.industry),
    size: str(r.size),
    website: str(r.website),
    headquarters: str(r.headquarters),
    isVerified: bool(r.is_verified),
  };
}

/** Maps a `job_categories` row to a [JobCategory]. */
export function toCategory(r: Row): JobCategory {
  return {
    id: String(r.id),
    slug: String(r.slug ?? r.id),
    name: String(r.name ?? ""),
  };
}

/** Maps a `company_reviews` row to a [CompanyReview]. */
export function toReview(r: Row): CompanyReview {
  return {
    id: String(r.id),
    rating: num(r.rating) ?? 0,
    body: str(r.body),
    createdAt: str(r.created_at),
  };
}
