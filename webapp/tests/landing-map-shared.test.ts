import { describe, expect, it } from "vitest";

import {
  LANDING_MAP_PIN_COUNT,
  pickLandingMapJobs,
} from "@/components/landing/landing-map-shared";

import { makeJob } from "./fixtures";

describe("pickLandingMapJobs", () => {
  it("keeps only salaried jobs", () => {
    const withPay = makeJob({ id: "a", salaryMin: 4_000_000 });
    const noPay = makeJob({ id: "b", salaryMin: null, salaryMax: null });
    const picked = pickLandingMapJobs([withPay, noPay]);
    expect(picked.map((j) => j.id)).toEqual(["a"]);
  });

  it("caps at LANDING_MAP_PIN_COUNT", () => {
    const many = Array.from({ length: LANDING_MAP_PIN_COUNT + 5 }, (_, i) =>
      makeJob({ id: `j${i}`, salaryMax: 5_000_000, city: "Toshkent" }),
    );
    expect(pickLandingMapJobs(many)).toHaveLength(LANDING_MAP_PIN_COUNT);
  });

  it("drops jobs outside Uzbekistan so the poster frames the country", () => {
    const tashkent = makeJob({
      id: "tas",
      salaryMax: 6_000_000,
      city: "Toshkent",
    });
    // A "Foreign jobs" listing pinned at Moscow's real coordinates — the exact
    // pin that blew the landing frame out to a continent view.
    const moscow = makeJob({
      id: "msk",
      salaryMax: 35_000_000,
      lat: 55.7558,
      lng: 37.6173,
    });
    const picked = pickLandingMapJobs([tashkent, moscow]);
    expect(picked.map((j) => j.id)).toEqual(["tas"]);
  });

  it("keeps jobs across Uzbekistan's extents (Nukus, Termiz, Andijon)", () => {
    const edges = [
      makeJob({ id: "nukus", salaryMax: 5_000_000, city: "Nukus" }),
      makeJob({ id: "termiz", salaryMax: 5_000_000, city: "Termiz" }),
      makeJob({ id: "andijon", salaryMax: 5_000_000, city: "Andijon" }),
    ];
    expect(pickLandingMapJobs(edges).map((j) => j.id)).toEqual([
      "nukus",
      "termiz",
      "andijon",
    ]);
  });
});
