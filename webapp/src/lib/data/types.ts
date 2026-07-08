// Domain types for the public web surface, mapped from the Supabase `job_feed`
// view and `companies` / `job_categories` / `company_reviews` tables. Snake_case
// DB rows are converted to these camelCase shapes by the mappers in this folder.

export interface ScreeningQuestion {
  id: string;
  label: string;
  type: string; // "text" | "yesno" | "choice"
  required: boolean;
  /** Present for `choice` questions — the options the applicant picks from. */
  options?: string[];
}

/** A language requirement on a job: code ("uz"|"ru"|"en"|…) + CEFR level. */
export interface JobLanguage {
  code: string;
  level: string; // "a1"…"c2" | "native"
}

export interface Job {
  id: string;
  title: string;
  description: string | null;
  responsibilities: string | null;
  requirements: string | null;
  benefits: string | null;
  companyId: string;
  companyName: string;
  companyLogoUrl: string | null;
  companyVerified: boolean;
  categoryName: string | null;
  jobType: string | null;
  experienceLevel: string | null;
  workingModel: string | null;
  /** Blue-collar work schedule: "6_1" | "5_2" | "4_4" | "2_2" | "custom". */
  schedulePattern: string | null;
  city: string | null;
  country: string | null;
  location: string | null;
  lat: number | null;
  lng: number | null;
  salaryMin: number | null;
  salaryMax: number | null;
  currency: string;
  salaryPeriod: string;
  /** Whether the stated pay is gross (before tax) rather than net (take-home). */
  salaryGross: boolean;
  skills: string[];
  // Blue-collar posting depth (already flows through job_feed's j.*).
  nightShift: boolean;
  womenFriendly: boolean;
  disabilityFriendly: boolean;
  /** "employment_contract" | "gph" | "self_employed" | "none" | null. */
  formalization: string | null;
  /** "secondary" | "specialized_secondary" | "higher" | null ("none" → null). */
  educationRequired: string | null;
  /** Free-text work hours, e.g. "9:00–18:00". */
  workHours: string | null;
  driverLicenses: string[];
  languages: JobLanguage[];
  contactPhone: string | null;
  showPhoneOnListing: boolean;
  postedAt: string | null;
  expiresAt: string | null;
  boostActive: boolean;
  screeningQuestions: ScreeningQuestion[];
}

export interface Company {
  id: string;
  name: string;
  logoUrl: string | null;
  coverUrl: string | null;
  about: string | null;
  industry: string | null;
  size: string | null;
  website: string | null;
  headquarters: string | null;
  isVerified: boolean;
}

export interface CompanyWithJobs extends Company {
  /** Number of currently-open jobs at this company. */
  openJobs: number;
}

export interface JobCategory {
  id: string;
  slug: string;
  name: string;
}

export interface CompanyReview {
  id: string;
  rating: number;
  body: string | null;
  createdAt: string | null;
}

export interface JobQuery {
  q?: string;
  city?: string;
  category?: string;
  jobType?: string;
  workingModel?: string;
  experienceLevel?: string;
  /** Minimum salary the seeker will accept, in [currency]. */
  salaryMin?: number;
  /** Currency the salaryMin is expressed in ("UZS" | "USD"). */
  currency?: string;
  /** Only jobs posted within the last N days. */
  postedWithin?: number;
  /** Result ordering: "recent" (default) | "salary". */
  sort?: string;
  limit?: number;
  offset?: number;
}
