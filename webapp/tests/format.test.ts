import { describe, expect, it } from "vitest";

import type { Job } from "@/lib/data/types";
import { formatDate, salaryText } from "@/lib/format";

const base: Job = {
  id: "1",
  title: "Role",
  description: null,
  responsibilities: null,
  requirements: null,
  benefits: null,
  companyId: "c",
  companyName: "Co",
  companyLogoUrl: null,
  companyVerified: false,
  categoryName: null,
  jobType: null,
  experienceLevel: null,
  workingModel: null,
  city: null,
  country: null,
  location: null,
  salaryMin: null,
  salaryMax: null,
  currency: "UZS",
  salaryPeriod: "month",
  skills: [],
  postedAt: null,
  expiresAt: null,
  boostActive: false,
  screeningQuestions: [],
};

describe("salaryText", () => {
  it("returns null when no salary is set", () => {
    expect(salaryText(base)).toBeNull();
  });

  it("formats a UZS range with grouped digits and suffix", () => {
    expect(
      salaryText({ ...base, salaryMin: 3000000, salaryMax: 5000000 }),
    ).toBe("3 000 000 - 5 000 000 so'm");
  });

  it("formats a USD minimum with the symbol prefix", () => {
    expect(
      salaryText({
        ...base,
        currency: "USD",
        salaryMin: 2500,
        salaryMax: null,
      }),
    ).toBe("$2 500+");
  });
});

describe("formatDate", () => {
  it("formats an ISO date as dd.mm.yyyy (UTC)", () => {
    expect(formatDate("2026-06-20T09:00:00Z")).toBe("20.06.2026");
  });

  it("returns empty string for null", () => {
    expect(formatDate(null)).toBe("");
  });
});
