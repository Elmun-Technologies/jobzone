import type { Job } from "@/lib/data/types";

/**
 * A complete, minimal [Job] for tests. Spread `overrides` on top. Keeping the
 * full shape here (not inline in each test) means enriching the Job type only
 * touches this one file, not every test that happens to construct a Job.
 */
export function makeJob(overrides: Partial<Job> = {}): Job {
  return {
    id: "j1",
    title: "Role",
    description: null,
    responsibilities: null,
    requirements: null,
    benefits: null,
    companyId: "c1",
    companyName: "Co",
    companyLogoUrl: null,
    companyVerified: false,
    categoryName: null,
    jobType: null,
    experienceLevel: null,
    workingModel: null,
    schedulePattern: null,
    city: null,
    country: "UZ",
    location: null,
    lat: null,
    lng: null,
    salaryMin: null,
    salaryMax: null,
    currency: "UZS",
    salaryPeriod: "month",
    salaryGross: true,
    skills: [],
    nightShift: false,
    womenFriendly: false,
    disabilityFriendly: false,
    formalization: null,
    educationRequired: null,
    workHours: null,
    driverLicenses: [],
    languages: [],
    contactPhone: null,
    showPhoneOnListing: false,
    postedAt: null,
    expiresAt: null,
    boostActive: false,
    screeningQuestions: [],
    ...overrides,
  };
}
