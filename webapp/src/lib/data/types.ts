// Domain types for the public web surface, mapped from the Supabase `job_feed`
// view and `companies` / `job_categories` / `company_reviews` tables. Snake_case
// DB rows are converted to these camelCase shapes by the mappers in this folder.

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
  city: string | null;
  country: string | null;
  location: string | null;
  salaryMin: number | null;
  salaryMax: number | null;
  currency: string;
  salaryPeriod: string;
  skills: string[];
  postedAt: string | null;
  expiresAt: string | null;
  boostActive: boolean;
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
  limit?: number;
  offset?: number;
}
