import { describe, expect, it } from "vitest";

import { jobPostingJsonLd } from "@/lib/seo";

import { makeJob } from "./fixtures";

const job = makeJob({
  id: "mock-1",
  title: "Senior Flutter Engineer",
  description: "Build cross-platform apps.",
  responsibilities: "Ship features.",
  requirements: "5y experience.",
  companyId: "c-acme",
  companyName: "Acme",
  companyLogoUrl: "https://example.com/logo.png",
  companyVerified: true,
  categoryName: "IT",
  jobType: "full_time",
  experienceLevel: "senior",
  workingModel: "remote",
  schedulePattern: "5_2",
  city: "Tashkent",
  lat: 41.3111,
  lng: 69.2797,
  salaryMin: 2500,
  salaryMax: 4000,
  currency: "USD",
  skills: ["Dart", "Flutter"],
  postedAt: "2026-06-20T09:00:00Z",
  expiresAt: "2026-08-20T09:00:00Z",
  boostActive: true,
  boostKind: null,
});

describe("jobPostingJsonLd", () => {
  const ld = jobPostingJsonLd(job);

  it("is a JobPosting with the core fields", () => {
    expect(ld["@type"]).toBe("JobPosting");
    expect(ld.title).toBe("Senior Flutter Engineer");
    expect(ld.datePosted).toBe("2026-06-20T09:00:00Z");
    expect(ld.validThrough).toBe("2026-08-20T09:00:00Z");
    expect(ld.employmentType).toBe("FULL_TIME");
  });

  it("includes the hiring organization", () => {
    expect(ld.hiringOrganization).toMatchObject({
      "@type": "Organization",
      name: "Acme",
      logo: "https://example.com/logo.png",
    });
  });

  it("marks remote jobs as telecommute and sets the country", () => {
    expect(ld.jobLocationType).toBe("TELECOMMUTE");
    expect(ld.jobLocation).toMatchObject({
      address: { addressCountry: "UZ", addressLocality: "Tashkent" },
    });
  });

  it("emits a base salary range with the right unit", () => {
    expect(ld.baseSalary).toMatchObject({
      currency: "USD",
      value: { minValue: 2500, maxValue: 4000, unitText: "MONTH" },
    });
  });

  it("omits salary when none is set", () => {
    const noSalary = jobPostingJsonLd({
      ...job,
      salaryMin: null,
      salaryMax: null,
    });
    expect(noSalary.baseSalary).toBeUndefined();
  });
});
