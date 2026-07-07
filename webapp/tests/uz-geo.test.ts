import { describe, expect, it } from "vitest";

import type { Job } from "@/lib/data/types";
import { cityLatLng, jobLatLng } from "@/lib/uz-geo";

function job(overrides: Partial<Job>): Job {
  return {
    id: "j1",
    title: "Sotuvchi",
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
    skills: [],
    postedAt: null,
    expiresAt: null,
    boostActive: false,
    screeningQuestions: [],
    ...overrides,
  };
}

describe("cityLatLng", () => {
  it("resolves the canonical uz spelling", () => {
    expect(cityLatLng("Toshkent")).toEqual({ lat: 41.3111, lng: 69.2797 });
  });

  it("resolves latin + cyrillic aliases to the same centroid", () => {
    const s = cityLatLng("Samarqand");
    expect(cityLatLng("Tashkent")).toEqual(cityLatLng("ташкент"));
    expect(cityLatLng("Samarkand")).toEqual(s);
    expect(cityLatLng("самарканд")).toEqual(s);
  });

  it("ignores apostrophe variants (Farg'ona)", () => {
    expect(cityLatLng("Farg'ona")).toEqual(cityLatLng("Fargona"));
    expect(cityLatLng("Farg'ona")).not.toBeNull();
  });

  it("returns null for unknown or empty cities", () => {
    expect(cityLatLng(null)).toBeNull();
    expect(cityLatLng("Atlantis")).toBeNull();
  });

  it("strips admin markers (shahri / tumani / город)", () => {
    const tk = cityLatLng("Toshkent");
    expect(cityLatLng("Toshkent shahri")).toEqual(tk);
    expect(cityLatLng("г. Ташкент")).toEqual(tk);
    expect(cityLatLng("Chilonzor tumani")).toEqual(tk); // district → city
    // a real name that merely contains a marker substring must survive
    expect(cityLatLng("Shahrisabz")).not.toBeNull();
  });
});

describe("jobLatLng", () => {
  it("uses the exact pin when set", () => {
    expect(jobLatLng(job({ lat: 41.5, lng: 69.5 }))).toEqual({
      lat: 41.5,
      lng: 69.5,
    });
  });

  it("falls back to the city centroid (jittered) when no pin", () => {
    const pos = jobLatLng(job({ city: "Toshkent" }));
    // within the ±0.015° jitter window of the Tashkent centroid
    expect(Math.abs(pos.lat - 41.3111)).toBeLessThan(0.016);
    expect(Math.abs(pos.lng - 69.2797)).toBeLessThan(0.016);
  });

  it("is deterministic per job id and fans same-city jobs apart", () => {
    const a1 = jobLatLng(job({ id: "a", city: "Samarqand" }));
    const a2 = jobLatLng(job({ id: "a", city: "Samarqand" }));
    const b = jobLatLng(job({ id: "b", city: "Samarqand" }));
    expect(a1).toEqual(a2); // stable for the same id
    expect(a1).not.toEqual(b); // different ids don't overlap
  });

  it("defaults to Tashkent (never dropped) when city is blank or unknown", () => {
    for (const city of [null, "Atlantis"]) {
      const pos = jobLatLng(job({ id: `x-${city}`, city }));
      expect(Math.abs(pos.lat - 41.3111)).toBeLessThan(0.016);
      expect(Math.abs(pos.lng - 69.2797)).toBeLessThan(0.016);
    }
  });
});
