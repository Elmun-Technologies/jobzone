import type { Company, JobCategory } from "./types";
import type { Job } from "./types";

// Offline/demo fallback used when Supabase env vars are absent (mirrors the
// Flutter app's mock data). Real deployments query Supabase instead.

export const mockCompanies: Company[] = [
  {
    id: "c-acme",
    name: "Acme",
    logoUrl: "https://picsum.photos/seed/acme-logo/200/200",
    coverUrl: null,
    about:
      "Building cross-platform products used by millions across Uzbekistan.",
    industry: "Technology",
    size: "50-200",
    website: "https://acme.uz",
    headquarters: "Tashkent, UZ",
    isVerified: true,
  },
  {
    id: "c-nimbus",
    name: "Nimbus Retail",
    logoUrl: "https://picsum.photos/seed/nimbus-logo/200/200",
    coverUrl: null,
    about: "A growing retail chain hiring across the country.",
    industry: "Retail",
    size: "200-500",
    website: null,
    headquarters: "Samarkand, UZ",
    isVerified: false,
  },
];

function job(p: Partial<Job> & Pick<Job, "id" | "title" | "companyId">): Job {
  const company = mockCompanies.find((c) => c.id === p.companyId)!;
  return {
    description: null,
    responsibilities: null,
    requirements: null,
    benefits: null,
    companyName: company.name,
    companyLogoUrl: company.logoUrl,
    companyVerified: company.isVerified,
    categoryName: null,
    jobType: "full_time",
    experienceLevel: "mid",
    workingModel: "onsite",
    city: "Tashkent",
    country: "UZ",
    location: null,
    salaryMin: null,
    salaryMax: null,
    currency: "UZS",
    salaryPeriod: "month",
    skills: [],
    postedAt: "2026-06-20T09:00:00Z",
    expiresAt: null,
    boostActive: false,
    screeningQuestions: [],
    ...p,
  };
}

export const mockJobs: Job[] = [
  job({
    id: "mock-1",
    title: "Senior Flutter Engineer",
    companyId: "c-acme",
    categoryName: "IT / Dasturlash",
    description:
      "Build and scale our cross-platform mobile apps used by millions.",
    experienceLevel: "senior",
    workingModel: "remote",
    salaryMin: 2500,
    salaryMax: 4000,
    currency: "USD",
    skills: ["Dart", "Flutter", "Riverpod", "Supabase"],
    boostActive: true,
  }),
  job({
    id: "mock-2",
    title: "Sotuvchi-konsultant",
    companyId: "c-nimbus",
    categoryName: "Savdo / Retail",
    city: "Samarkand",
    salaryMin: 3000000,
    salaryMax: 5000000,
    skills: ["Mijozlar bilan ishlash", "Kassa"],
  }),
  job({
    id: "mock-3",
    title: "Omborchi",
    companyId: "c-nimbus",
    categoryName: "Logistika",
    jobType: "full_time",
    experienceLevel: "junior",
    salaryMin: 4000000,
    salaryMax: 6000000,
    skills: ["1C", "Inventarizatsiya"],
  }),
];

export const mockCategories: JobCategory[] = [
  { id: "cat-it", slug: "it", name: "IT / Dasturlash" },
  { id: "cat-retail", slug: "retail", name: "Savdo / Retail" },
  { id: "cat-logistics", slug: "logistics", name: "Logistika" },
  { id: "cat-horeca", slug: "horeca", name: "HoReCa" },
];
